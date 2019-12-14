---
title: "Pathtracing notes"
tag:
  - pathtracing
---

## Lambertian material

When incoming rays hit a Lambertian material with reflectance $$R$$ (albedo), the following ray scattering *policies* are equivalent:
- always scatter the incoming rays and attenuate by the reflection $$R$$
- scatter with no attenuation but scatter only a fraction $$1 - R$$ of the incoming rays
- scatter the incoming rays with a probability $$p$$ and attenuate by $$\frac{R}{p}$$


## References

- **Probability Theory for Physically Based Rendering**
[[1]](https://jacco.ompf2.com/2019/12/11/probability-theory-for-physically-based-rendering/)
[[2]](https://jacco.ompf2.com/2019/12/13/probability-theory-for-physically-based-rendering-part-2/) by Jacco Bikker