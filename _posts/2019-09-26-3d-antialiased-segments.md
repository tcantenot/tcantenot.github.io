---
title: "3D antialiased segments"
tag:
  - code
  - c++
  - pathtracing
  - geometry
---

## 3D antialiased lines for ray[tracing|marching]

{% highlight cpp %}
struct DistanceRaySegmentInfo
{
     float distToSegment;
     float tRay;
     float tSegment;
};

struct SqrDistanceRaySegmentInfo
{
     float sqrDistToSegment;
     float tRay;
     float tSegment;
};

// https://www.shadertoy.com/view/4slGz4
// (http://geomalgorithms.com/a07-_distance.html)
inline SqrDistanceRaySegmentInfo SqrDistanceRaySegment(vec3 ro, vec3 rd, vec3 pa, vec3 pb)
{
	vec3 ba = pb - pa;
	vec3 oa = ro - pa;
	
	float oad  = Dot(oa, rd);
	float dba  = Dot(rd, ba);
	float baba = Dot(ba, ba);
	float oaba = Dot(oa, ba);
	
	vec2 th = vec2(-oad * baba + dba * oaba, oaba - oad * dba) / (baba - dba * dba);
	
	th.x = Max(th.x, 0.f);
	th.y = Clamp(th.y, 0.f, 1.f);
	
	vec3 p = pa + ba * th.y;
	vec3 q = ro + rd * th.x;
	
	vec3 pq = p - q;

	SqrDistanceRaySegmentInfo info;
	info.sqrDistToSegment = Dot(pq, pq);
	info.tRay = th.x;
	info.tSegment = th.y;
	return info;
}

// https://www.shadertoy.com/view/4slGz4
// (http://geomalgorithms.com/a07-_distance.html)
inline DistanceRaySegmentInfo DistanceRaySegment(vec3 ro, vec3 rd, vec3 pa, vec3 pb)
{
	SqrDistanceRaySegmentInfo sinfo = SqrDistanceRaySegment(ro, rd, pa, pb);

	DistanceRaySegmentInfo info;
	info.distToSegment = Sqrt(sinfo.sqrDistToSegment);
	info.tRay = sinfo.tRay;
	info.tSegment = sinfo.tSegment;
	return info;
}

// http://geomalgorithms.com/a02-_lines.html
// Distance between a point p and a segment delimited by the points a and b
inline float DistancePointSegment(vec3 p, vec3 a, vec3 b)
{
     vec3 v = b - a;
     vec3 w = p - a;

     float c1 = Dot(w,v);
     if(c1 <= 0)
          return Length(p - a);

     float c2 = Dot(v,v);
     if(c2 <= c1)
          return Length(p - b);

     float h = c1 / c2;
     vec3 cp = a + h * v;
     return Length(p - cp);
}

// Draw antialiased segment

vec3 segmentStart = ...;
vec3 segmentEnd = ...;
vec3 segmentColor = ...;
float segmentRadius = ...;

Ray rayC = GetCameraRay(cameraData, coordsX, coordsY, w, h);
Ray rayX = GetCameraRay(cameraData, coordsX + 1, coordsY, w, h);
Ray rayY = GetCameraRay(cameraData, coordsX, coordsY + 1, w, h);

DistanceRaySegmentInfo raySegmentInfoC = DistanceRaySegment(rayC.o, rayC.d, segmentStart, segmentEnd);
float distToSegmentC = raySegmentInfoC.distToSegment;
float tRayC = raySegmentInfoC.tRay;

// Intersect tangent plane
// https://www.iquilezles.org/www/articles/filtering/filtering.htm
vec3 norC = -rayC.d;
vec3 posC = rayC.o + rayC.d * tRayC;
vec3 posX = rayX.o - rayX.d * Dot(rayX.o - posC, norC) / Dot(rayX.d, norC);
vec3 posY = rayY.o - rayY.d * Dot(rayY.o - posC, norC) / Dot(rayY.d, norC);

#if 0
Ray rayX_ = GetCameraRay(cameraData, coordsX - 1, coordsY, w, h);
Ray rayY_ = GetCameraRay(cameraData, coordsX, coordsY - 1, w, h);
vec3 posX_ = rayX_.o - rayX_.d * Dot(rayX_.o - posC, norC) / Dot(rayX_.d, norC);
vec3 posY_ = rayY_.o - rayY_.d * Dot(rayY_.o - posC, norC) / Dot(rayY_.d, norC);
#else
vec3 posX_ = 2.f * posC - posX; // posC - (posX - posC)
vec3 posY_ = 2.f * posC - posY; // posC - (posY - posC)
#endif

float distToSegmentX  = DistancePointSegment(posX,  segmentStart, segmentEnd);
float distToSegmentY  = DistancePointSegment(posY,  segmentStart, segmentEnd);
float distToSegmentX_ = DistancePointSegment(posX_, segmentStart, segmentEnd);
float distToSegmentY_ = DistancePointSegment(posY_, segmentStart, segmentEnd);

float distdx = Max(Abs(distToSegmentX - distToSegmentC), Abs(distToSegmentX_ - distToSegmentC));
float distdy = Max(Abs(distToSegmentY - distToSegmentC), Abs(distToSegmentY_ - distToSegmentC));
float fwidth = distdx + distdy;
//float fwidth = Length(vec2(distdx, distdy));

float blendFactor = Smoothstep(segmentRadius - fwidth, segmentRadius + fwidth, distToSegmentC);

color = Lerp(segmentColor, color, blendFactor);
{% endhighlight %}


Notes:
- Instead of **DistancePointSegment**, **DistancePointLine** could be used (less correct but faster)

     {% highlight cpp %}
     // http://geomalgorithms.com/a02-_lines.html
     inline float DistancePointLine(vec3 p, vec3 a, vec3 b)
     {
          vec3 v = b - a;
          vec3 w = p - a;

          float c1 = Dot(w, v);
          float c2 = Dot(v, v);
          float h = c1 / c2;

          vec3 cp = a + h * v;
          return Length(p - cp);
     }
     {% endhighlight %}

- To draw a path made of segments or a list of segments, first compute the smallest distance to all the segments and get the corresponding segment. Then compute the antialiased color. 

     {% highlight cpp %}
     struct SegmentInfo
     {
          vec3 segmentStart;
          vec3 segmentEnd;
          float distToSegment;
          float tRay;
          ... // color, radius, ...
     };

     SegmentInfo closestSegmentInfo;
     GetClosestSegment(rayC.o, rayC.d, listOfSegments, /*out*/ closestSegmentInfo);

     float distToSegmentC = closestSegmentInfo.distToSegment;
     float tRayC = closestSegmentInfo.tRay;

     ...
     {% endhighlight %}
