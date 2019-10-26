---
title: "Pathtracer AOV"
tag:
  - code
  - c++
  - cuda
  - pathtracing
  - architecture
---

## Arbitrary Output Values (AOV)

{% highlight cpp %}

struct AOVMode
{
    enum Enum
    {
        NONE,
        GBUFFER,
        PIXEL_DEBUG
    };

    enum { Count = PIXEL_DEBUG+1};
};

using EAOVMode = AOVMode::Enum;

template <EAOVMode TAOVMode>
struct AOV { };

template <>
struct AOV<EAOVMode::NONE> { };

using NoAOV = AOV<EAOVMode::NONE>;

template <>
struct AOV<EAOVMode::GBUFFER>
{
    vec3 * albedo;
    float * depth;
    vec3 * normal;
};

template <>
struct AOV<EAOVMode::PIXEL_DEBUG>
{
    struct Input
    {
        U32 pixelIdx;
    };

    Input i;

    vec3 * path;
    float * pdfs;
    vec3 * shadowRays;
    ShadingData * shadingData;
};

template <EAOVMode TAOVMode>
__device__ void KernelImpl(
    ...,
    AOV<TAOVMode> aov
)
{
    /*static*/ switch(TAOVMode)
    {
        default:
        case EAOVMode::NONE: break;

        case EAOVMode::GBUFFER:
        {
            aov.albedo[gtid] = albedo;
            aov.depth[gtid]  = depth;
            aov.normal[gtid] = normal;
            break;
        }

        case EAOVMode::PIXEL_DEBUG:
        {
            if(aov.i.pixelIdx == pixelIdx)
            {

            }
            break;
        }
    }
}

__global__ void Kernel(
    ...,
    EAOVMode eAOVMode,

)
{
    switch(eAOVMode)
    {
        case EAOVMode::NONE:
        {
            KernelImpl<EAOVMode::NONE><<<..., ...>>>(...);
            break; 
        }

        case EAOVMode::GBUFFER:
        {
            KernelImpl<EAOVMode::GBUFFER><<<..., ...>>>(...);
            break;
        }

        case EAOVMode::PIXEL_DEBUG:
        {
            KernelImpl<EAOVMode::PIXEL_DEBUG><<<..., ...>>>(...);
            break;
        }
    }
}

{% endhighlight %}
