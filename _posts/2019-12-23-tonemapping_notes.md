---
title: "Tonemapping notes"
tag:
  - tonemapping
  - exposure
  - color
---

## Fitting into half-float

http://www.reedbeta.com/blog/artist-friendly-hdr-with-exposure-values/

*RGBA16F is a good choice for an HDR framebuffer these days. It does have a greater memory and bandwidth cost of 64 bits per pixel, but it’s rather nicer than having to deal with the limitations of RGBM, LogLUV, 10-10-10-2 or any of the other formats that have been devised for shoehorning HDR data into 32 bits.*

*Being able to store everything in linear color space, use hardware blending and filtering, etc. is great—but the half-float format does come with a caveat: it doesn’t have a huge range. The maximum representable half-float value is 65504, and the minimum positive normalized value (note that GPU hardware typically flushes denormals to zero) is about 6.1 × 10⁻⁵. The ratio between them is about 1.1 × 10⁹, which is right about the dynamic range of the human eye. So half-float barely has enough range to represent all the luminances we can see, and this range must be husbanded carefully.*

*The half-float normalized range natively extends from −14 to +16 EV. It turns out that +16 EV is about the luminance of a matte white object in noon sunlight, so this range isn’t quite convenient—there’s not enough room on the top end to represent really bright things we can see, like a specular highlight in noon sunlight, or the sun itself. Fortunately, there’s plenty of room at the low end: −14 EV is a ridiculously dark luminance, probably comparable to intergalactic space!*

*To fix this, you can simply shift all luminances by some value, say −10 EV, when converting them to internal linear RGB values. This gives an effective range of −4 to +26 EV, which more neatly brackets the range of luminances you’ll actually want to depict, and allows enough headroom for super-bright things. (Looking directly at the sun at noon, you’d actually see a luminance of more like +33 EV—but I figure that +26 EV is good enough in practice.)*

*Whenever you display EV to the user you’d undo this shift, so that the engine’s notion of EV continues to match up with the photography definition. You’ll also probably want to remove it if you generate HDR screenshots, lightmaps, etc. from the engine, so they won’t appear extremely dark when viewed externally. And when the lighting artist specifies the overall scene EV for tonemapping, the shift will of course need to be accounted for there as well.*

https://github.com/TheRealMJP/BakingLab/blob/master/BakingLab/Exposure.hlsl

## References

- https://64.github.io/tonemapping/
- https://www.slideshare.net/ozlael/hable-john-uncharted2-hdr-lighting/53
- http://filmicworlds.com/blog/filmic-tonemapping-operators/
- http://filmicworlds.com/blog/filmic-tonemapping-with-piecewise-power-curves/
- https://mynameismjp.wordpress.com/2016/10/09/sg-series-part-6-step-into-the-baking-lab/
- http://www.reedbeta.com/blog/artist-friendly-hdr-with-exposure-values/
- http://32ipi028l5q82yhj72224m8j.wpengine.netdna-cdn.com/wp-content/uploads/2016/03/GdcVdrLottes.pdf