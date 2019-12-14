---
title: "Cuda Pathtracer"
tag:
  - code
  - cuda
  - c++
  - pathtracing
---

## Macbeth chart

<https://github.com/colour-science/colour-nuke/tree/master/colour_nuke/resources/images/ColorChecker2005>
<http://www.nukepedia.com/gizmos/draw/x-rite-colorchecker-classic-2005-gretagmacbeth>

## Cornell box

<https://github.com/sergeyreznik/raytracing-references>
<https://twitter.com/colour_science/status/1066513523763597312?s=09>

## Stream compaction

<http://www.orangeowlsolutions.com/archives/1977>
<https://stackoverflow.com/questions/34059753/cuda-stream-compaction-algorithm>
<https://www.jstage.jst.go.jp/article/ijnc/7/2/7_208/_pdf/-char/ja>
<http://www.davidespataro.it/cuda-stream-compaction-efficient-implementation/>

## Noise

From: <https://www.shadertoy.com/view/lsByDw>

{% highlight cpp %}
// single iteration of Bob Jenkins' One-At-A-Time hashing algorithm:
//  http://www.burtleburtle.net/bob/hash/doobs.html
// suggested by Spatial on stackoverflow:
//  http://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
uint BJXorShift(uint x) 
{
    x += x << 10u;
    x ^= x >>  6u;
    x += x <<  3u;
    x ^= x >> 11u;
    x += x << 15u;
	
    return x;
}


// xor-shift algorithm by George Marsaglia
//  https://www.thecodingforums.com/threads/re-rngs-a-super-kiss.704080/
// suggested by Nathan Reed:
//  http://www.reedbeta.com/blog/quick-and-easy-gpu-random-numbers-in-d3d11/
uint GMXorShift(uint x)
{
    x ^= x << 13u;
    x ^= x >> 17u;
    x ^= x <<  5u;
    
    return x;
}

// hashing algorithm by Thomas Wang 
//  http://www.burtleburtle.net/bob/hash/integer.html
// suggested by Nathan Reed:
//  http://www.reedbeta.com/blog/quick-and-easy-gpu-random-numbers-in-d3d11/
uint WangHash(uint x)
{
    x  = (x ^ 61u) ^ (x >> 16u);
    x *= 9u;
    x ^= x >> 4u;
    x *= 0x27d4eb2du;
    x ^= x >> 15u;
    
    return x;
}

// "floatConstruct"          | renamed to "ConstructFloat" here 
// By so-user Spatial        | http://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
// used under CC BY-SA 3.0   | https://creativecommons.org/licenses/by-sa/3.0/             
// reformatted and changed from original to extend interval from [0..1) to [-1..1) 
//-----------------------------------------------------------------------------------------
// Constructs a float within interval [-1..1) using the low 23 bits + msb of an uint.
// All zeroes yields -1.0, all ones yields the next smallest representable value below 1.0. 
float ConstructFloat(uint m) 
{
    float flt = uintBitsToFloat(m & 0x007FFFFFu | 0x3F800000u);// [1..2)
    float sub = (m >> 31u) == 0u ? 2.0 : 1.0;
    
    return flt - sub;// [-1..1)             
}

vec2 ConstructFloat(uvec2 m) { return vec2(ConstructFloat(m.x), ConstructFloat(m.y)); }
vec3 ConstructFloat(uvec3 m) { return vec3(ConstructFloat(m.xy), ConstructFloat(m.z)); }
vec4 ConstructFloat(uvec4 m) { return vec4(ConstructFloat(m.xyz), ConstructFloat(m.w)); }


uint Hash(uint  v, uint  r) { return Hash(v ^ r); }
uint Hash(uvec2 v, uvec2 r) { return Hash(Hash(v.x , r.x ) ^ (v.y ^ r.y)); }
uint Hash(uvec3 v, uvec3 r) { return Hash(Hash(v.xy, r.xy) ^ (v.z ^ r.z)); }
uint Hash(uvec4 v, uvec4 r) { return Hash(Hash(v.xy, r.xy) ^ Hash(v.zw, r.zw)); }

// Pseudo-random float value in interval [-1:1).
float Hash(float v, uint  r) { return ConstructFloat(Hash(floatBitsToUint(v), r)); }
float Hash(vec2  v, uvec2 r) { return ConstructFloat(Hash(floatBitsToUint(v), r)); }
float Hash(vec3  v, uvec3 r) { return ConstructFloat(Hash(floatBitsToUint(v), r)); }
float Hash(vec4  v, uvec4 r) { return ConstructFloat(Hash(floatBitsToUint(v), r)); }


float HashFlt(uint   v, uint  r) { return ConstructFloat(Hash(v, r)); }
float HashFlt(uvec2  v, uvec2 r) { return ConstructFloat(Hash(v, r)); }
float HashFlt(uvec3  v, uvec3 r) { return ConstructFloat(Hash(v, r)); }
float HashFlt(uvec4  v, uvec4 r) { return ConstructFloat(Hash(v, r)); }

uint HashUInt(float v, uint  r) { return Hash(floatBitsToUint(v), r); }
uint HashUInt(vec2  v, uvec2 r) { return Hash(floatBitsToUint(v), r); }
uint HashUInt(vec3  v, uvec3 r) { return Hash(floatBitsToUint(v), r); }
uint HashUInt(vec4  v, uvec4 r) { return Hash(floatBitsToUint(v), r); }
{% endhighlight %}


## Sample PDF

From: <https://www.shadertoy.com/view/lsByDw>

{% highlight cpp %}
/*
"Building an Orthonormal Basis from a 3D Unit Vector Without Normalization"
		http://orbit.dtu.dk/files/126824972/onb_frisvad_jgt2012_v2.pdf
		
	"Building an Orthonormal Basis, Revisited" 
		http://jcgt.org/published/0006/01/01/
	
	- modified for right-handedness here
	
DESCR:
	Constructs a right-handed, orthonormal coordinate system from a given vector of unit length.

IN:
	n  : normalized vector
	
OUT:
	ox	: orthonormal vector
	oz	: orthonormal vector
	
EXAMPLE:
	float3 ox, oz;
	OrthonormalBasis(N, OUT ox, oz);
*/
void OrthonormalBasisRH(vec3 n, out vec3 ox, out vec3 oz)
{
	float sig = n.z < 0.0 ? 1.0 : -1.0;
	
	float a = 1.0 / (n.z - sig);
	float b = n.x * n.y * a;
	
	ox = vec3(1.0 + sig * n.x * n.x * a, sig * b, sig * n.x);
	oz = vec3(b, sig + n.y * n.y * a, n.y);
}

// s0 [-1..1], s1 [-1..1]
// samples spherical cap for s1 [cosAng..1]
// samples hemisphere if s1 [0..1]
vec3 Sample_Sphere(float s0, float s1)
{
    float ang = Pi * s0;
    float s1p = sqrt(clamp01(1.0 - s1*s1));
    
    return vec3(cos(ang) * s1p, 
                           s1 , 
                sin(ang) * s1p);
}

// s0 [-1..1], s1 [-1..1]
// samples spherical cap for s1 [cosAng..1]
vec3 Sample_Sphere(float s0, float s1, vec3 normal)
{	 
    vec3 sph = Sample_Sphere(s0, s1);

    vec3 ox, oz;
    OrthonormalBasisRH(normal, ox, oz);

    return (ox * sph.x) + (normal * sph.y) + (oz * sph.z);
}

// s0 [-1..1], s1 [-1..1]
vec3 Sample_Hemisphere(float s0, float s1, vec3 normal)
{
    vec3 smpl = Sample_Sphere(s0, s1);

    if(dot(smpl, normal) < 0.0)
        return -smpl;
    else
        return smpl;
}

// s0 [-1..1], s1 [0..1]
vec2 Sample_Disk(float s0, float s1)
{
    return vec2(cos(Pi * s0), sin(Pi * s0)) * sqrt(s1);
}

// s0 [-1..1], s1 [0..1]
vec3 Sample_ClampedCosineLobe(float s0, float s1)
{	 
    vec2 d  = Sample_Disk(s0, s1);
    float y = sqrt(clamp01(1.0 - s1));
    
    return vec3(d.x, y, d.y);
}

// s0 [-1..1], s1 [0..1]
vec3 Sample_ClampedCosineLobe(float s0, float s1, vec3 normal)
{	 
    vec2 d  = Sample_Disk(s0, s1);
    float y = sqrt(clamp01(1.0 - s1));

    vec3 ox, oz;
    OrthonormalBasisRH(normal, ox, oz);

    return (ox * d.x) + (normal * y) + (oz * d.y);
}

// s [-1..1]
float Sample_Triangle(float s) 
{ 
    float v = 1.0 - sqrt(abs(s));
    
    return s < 0.0 ? -v : v; 
}
{% endhighlight %}
