---
title: "Memory Arena"
tag:
  - code
  - c++
  - memory arena
---

## Introduction

I am currently in the process of converting my codebase to mostly use memory arenas for its allocations and will see where it leads me.
<br/>This blog post is here to gather my thoughts and ideas I had along the way to serve as future reference for me; and hopefully be helpful to others!

This blog [post](https://www.rfleury.com/p/untangling-lifetimes-the-arena-allocator) by Ryan Fleury challenged a lot what I previously learned and quite deeply changed the way I see allocations in a program now.
<br/>Allocations did matter to me before: I tried to hook every allocations in order to track leaks, to gather statistics and to reduce them as much as possible. I could also detect some used-after-free and some kinds of buffer overruns.
However, they were still done the "standard" way: a pair of `malloc`/`free` or `new`/`delete`.

I will not repeat everything that Ryan explains thoroughly in his blog, so go read [it](https://www.rfleury.com/p/untangling-lifetimes-the-arena-allocator) if you haven't yet!
<br/>I also highly recommand the [various](https://nullprogram.com/blog/2023/09/27/) [blog](https://nullprogram.com/blog/2023/09/30/) [posts](https://nullprogram.com/blog/2023/10/05/) of Chris Wellons that were also a source of inspiration for me!


### Some context
The codebase I mentionned is my hobby pathtracer written in C++ and CUDA.
<br/>I am trying to see how using C++ features could "ease" the memory usages of memory arena and what obstacles I would meet along the way.
<br/>I am not really a big fan of all of what "modern" C++ has to offer so I tend to cherry pick the new features when I find them worthwhile. I also avoid the STL and use the more performance-oriented [EASTL](https://github.com/electronicarts/EASTL) (even though I might phase it out at some point).


## Key concepts

A memory arena holds **allocations** with the **same lifetime**. Once the end of the lifetime is reached, **all allocations** are released at **once**.

I think it is important to differentiate the **memory arena** from the **allocation schemes**.
<br/>The **memory arena** provides the **backing memory storage**, while the **allocation schemes** dictates **how** the memory is retrieved from (and eventually released to) the arena.
<br/>Allocation schemes are handled by allocators layered on top of a arena. All kind of allocators can be implemented, just naming a few: linear, block, pool, tlsf, etc.

This separation is here to keep arena interface simple and also to be able to handle **sub-lifetimes** and **transient** memory more efficiently (more on that later).

I also enforce the fact that the memory arena must provide a **contiguous** memory range. That helps to keep the interface quite "minimalist".


### Memory arena types

At first I tried to find some key properties to help me classify memory arena types.
I came up with 4 base types:
  * `FixedMemoryArena`: which represents a **fixed-size** **contiguous** and **stable** memory range
  * `DynamicMemoryArena`: which represents a **growable** **contiguous** but (potentially) **unstable** memory range
  * `BlockMemoryArena`: which represents a **growable** set of **contiguous** and **stable** memory range**s**
  * `VirtualMemoryArena`: which represents a **growable**[^fn-vmem_growable] **contiguous** and **stable** memory range

  [^fn-vmem_growable]: within a predefined limit (the reserve)

With 3 key properties: **contiguous**, **growable** and **stable**:

| Type               | Contiguous | Growable | Stable |
| :----------------- | :--------: | :------: | :----: | 
| FixedMemoryArena   | true       | false    | true   | 
| DynamicMemoryArena | true       | true     | false  | 
| BlockMemoryArena   | false      | true     | true   | 
| VirtualMemoryArena | true       | true     | true   |

However, having a memory arena with a non-stable memory range adds a lot of complexity on the user side because of invalidation of existing allocations upon growing. Moreover, allowing non-contiguous memory range also adds complexity on its own and makes it more difficult to compose with different allocation schemes.
So I quickly dropped the unstable `DynamicMemoryArena` and the non-contiguous `BlockMemoryArena`.

So in this end, I kept only 2 base memory arena types that are both **contiguous** and **stable**: the `FixedMemoryArena` and the `VirtualMemoryArena`; that only differ on their capacity to grow.

| Type               | Growable |
| :----------------- | :------: | 
| FixedMemoryArena   | false    | 
| VirtualMemoryArena | true     |

The allocators can provide the **growable** property over a `FixedMemoryArena` memory sub-range if needed.


### Interface

This resulted in the following interface:


```cpp
TODO: MemoryArena interface
```

Some may argue that the interface I suggest is not really minimalist, and indeed there are examples in Ryan's or in Chris's blogs that are way more succinct.
<br/>However I feel struck a good balance between ease of usage and functionality, but YMMV.


### FixedMemoryArena

### VirtualMemoryArena

- Allow to allocate a huge contiguous virtual memory address range
- Commit pages as needed
- Debug mode with page protection of rewound/freed allocations to detect use after release/free
- Debug mode with page postfix protection to detect out of bounds
- Debug mode with page prefix protection to detect overrun

### ScopedMemoryArena

Use RAII to automatically rewind the wrapped arena at the end of a scope.

```cpp
ScopedMemoryArena scopedMemoryArena{transientMemoryArena}; // Save current arena mark

MemoryArenaVector<Node*> stack{scopedMemoryArena};
stack.push_back(rootNode);
Node * node = nullptr;
while(stack.pop_back(node))
{
    if(node)
    {
        // ...
        for(U64 i = 0; i < node->mNumChildren; ++i)
          stack.push_back(node->mChildren[i]);
    }
}
// At the scope exit, the transientMemoryArena is rewound at the saved arena mark (beginning of the scope)
```

Another approach to provide temporary arena is to pass them by copy as is done
<!-- markdownlint-capture -->
<!-- markdownlint-disable -->
> TODO(link to nullprogram)
{: .prompt-danger }
<!-- markdownlint-restore -->


## References

* **Untangling Lifetimes: The Arena Allocator**: https://www.rfleury.com/p/untangling-lifetimes-the-arena-allocator
* **Arena allocator tips and tricks**: https://nullprogram.com/blog/2023/09/27/
* **An easy-to-implement, arena-friendly hash map**: https://nullprogram.com/blog/2023/09/30/
* **A simple, arena-backed, generic dynamic array for C**: https://nullprogram.com/blog/2023/10/05/

## Footnotes
