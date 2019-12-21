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

- **Reinforcement learning**
  * [Learning Light Transport the Reinforced Way](https://arxiv.org/pdf/1701.07403.pdf) by Ken Dahm and Alexander Keller
  * http://on-demand.gputechconf.com/gtc/2017/presentation/s7256-ken-dahm-learning-light-transport-the-reinforced-way.pdf
  * https://www.youtube.com/watch?v=P7wh6Hvsbb4
  * [Importance Sampling of Many Lights with Reinforcement Lightcuts Learning](https://arxiv.org/pdf/1911.10217.pdf) by Jacopo Pantaleoni
  * [Q-Learned Importance Sampling for Physically Based Light Transport on the GPU](https://dspace.library.uu.nl/handle/1874/362948) by Mastrigt, K. van