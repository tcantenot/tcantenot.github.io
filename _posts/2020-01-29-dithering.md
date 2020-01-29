---
title: "Dithering"
tag:
  - code
  - color
  - dithering
  - random
  - noise
---

## Correct sRGB Dithering

[http://www.thetenthplanet.de/archives/5367](http://www.thetenthplanet.de/archives/5367)

Dither pattern that preserves the physical brightness of the original pixels in average.

{% highlight cpp %}
vec3 oetf( vec3 );    // = pow( .4545 )
vec3 eotf( vec3 );    // = pow( 2.2 )
 
vec3 dither( vec3 linear_color, vec3 noise, float quant )
{
    vec3 c0 = floor( oetf( linear_color ) / quant ) * quant;
    vec3 c1 = c0 + quant;
    vec3 discr = mix( eotf( c0 ), eotf( c1 ), noise );
    return mix( c0, c1, lessThan( discr, linear_color ) );
}
{% endhighlight %}
