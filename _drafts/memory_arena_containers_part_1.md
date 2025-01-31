---
title: "Memory Arena - Containers - Part 1"
#date: 2025-01-19 19:00:00 +0100
tag:
  - code
  - c++
  - memory arena
assets_path: /assets/drafts/memory_arena_containers_part_1
mermaid: true
comments: true
---

This post is a follow up on my initial post on memory arenas.

> TODO link to previous post
{: .prompt-danger }


## Misc

For the implementation of MemoryArena-backed containers, I decided to follow some "rules":

- The containers directly backed by a `MemoryArena` cannot shrink without "wasting" memory[^fn-cannot_shrink]:
	* this is mostly true when the memory arena backing the container is shared by multiple containers or systems that allocate in it
- Since deallocation happens at once, by either the releasing of the whole `MemoryArena` or via rewinding (`MemoryArena::rewind`), **no destructor are called**:
	* the types held by the containers must be **trivially destructible**.
- The containers *can* provide the option to "initialize" the objects by calling their constructor
	* this is a *convenience* feature
	* usually this implies that types stored in the containers must be *trivially constructible*

By following these rules/constraints, the implementation of MemoryArena-backed containers is made easier (and shorter).

[^fn-cannot_shrink]: With some exceptions as we will see

## MemoryArenaVector

Dynamic size array similar to `std::vector` that is backed by a memory arena.

> TODO show interface
{: .prompt-danger }

A nice [trick](https://nullprogram.com/blog/2023/10/05/) explained by Dennis Schön and Chris Wellon is that if we detect that the `MemoryArenaVector` storage is the last memory arena,
we can grow it without moving the current elements by just allocating a bit more from the memory arena and only updating the vector size (the data pointer stays the same).

> TODO Mermaid diagram
{: .prompt-danger }

Similarily, we can also shrink the vector and return memory to the arena with `MemoryArena::rewind`.

> TODO code snippet
{: .prompt-danger }

> TODO gist
{: .prompt-danger }

When used alone with a `VirtualMemoryArena` with a *huge* memory range, it can act like an "infinite" dynamic array (similar to the [`VMemArray`](https://github.com/jlaumon/AssetCooker/blob/main/src/VMemArray.h) described by Jeremy Laumon)

A drawback with the `MemoryArenaVector` is that, when it needs to grow, it wastes memory if any allocation happens after the initial `MemoryArenaVector` allocation within the same memory arena
and it does not keep pointers stability.

> TODO Mermaid diagram
{: .prompt-danger }

If there is the need to have a sequence of values that can be contiguously indexed but not necessarily contiguous in memory and that do not waste memory on growth, the `MemoryArenaDeque` is a better fit.


## MemoryArenaDeque

The `MemoryArenaDeque` is an indexed sequence container that allows fast insertion and deletion at both its beginning and its end similar to the [`std::deque`](https://en.cppreference.com/w/cpp/container/deque).

> TODO Mermaid diagram
{: .prompt-danger }

It is implemented as an array of pointers to fixed-size memory blocks backed a `MemoryArena`. When the `MemoryArenaDeque` needs to grow a new block is allocated and added to the list of blocks:
even if another allocation happened is the memory arena, it does not waste memory... Well this is not *exactly* true because the array of pointers needs to grow so is it reallocated and the old one is wasted.
However, the waste should not be significant for "reasonnable" block size: I accept this extra memory as part of the `MemoryArenaDeque` memory footprint.

> TODO Mermaid diagram
{: .prompt-danger }

> TODO show interface
{: .prompt-danger }

> TODO gist
{: .prompt-danger }

It can be used to implement a **stack**, a **queue**, a **growable pool of objects**, etc.

### Stack

The `MemoryArenaDeque` can be used as a **stack** (*last in, first out*) by using either `push_back` + `pop_back` or `push_front` + `pop_front`:

```cpp
deque.push_back(0); // { 0 }
deque.push_back(1); // { 0, 1 }
deque.push_back(2); // { 0, 1, 2 }
deque.pop_back(x); // x = 2, { 0, 1 }
deque.pop_back(x); // x = 1, { 0 } 
deque.pop_back(x); // x = 0, { }
```
or
```cpp
deque.push_front(0); // { 0 }
deque.push_front(1); // { 1, 0 }
deque.push_front(2); // { 2, 1, 0 }
deque.pop_front(x); // x = 2, { 1, 0 }
deque.pop_front(x); // x = 1, { 0 } 
deque.pop_front(x); // x = 0, { }
```

### Queue

The `MemoryArenaDeque` can be used as a **queue** (*first in, first out*) by using either `push_back` + `pop_front` or `push_front` + `pop_back`:

```cpp
deque.push_back(0); // { 0 }
deque.push_back(1); // { 0, 1 }
deque.push_back(2); // { 0, 1, 2 }
deque.pop_front(x); // x = 0, { 1, 2 }
deque.pop_front(x); // x = 1, { 2 } 
deque.pop_front(x); // x = 2, { }
```
or
```cpp
deque.push_front(0); // { 0 }
deque.push_front(1); // { 1, 0 }
deque.push_front(2); // { 2, 1, 0 }
deque.pop_back(x); // x = 0, { 2, 1 }
deque.pop_back(x); // x = 1, { 0 } 
deque.pop_back(x); // x = 2, { }
```

### ResourceHandleManager

The "resource handle manager" (or sometimes called "handle-based resource pool") is a system that manages a collection of objects using [generational indices](https://floooh.github.io/2018/06/17/handles-vs-pointers.html).
<br/>It assigns lightweight handles (IDs) to objects rather than exposing direct pointers, improving safety and control over resource lifetimes:

- objects are accessed via handles (`{index, generation}`), preventing dangling references when objects are deleted
- each object slot has a generation counter that increments when an object is removed and replaced, invalidating old handles
- freed slots can be reused with the generation number used to prevent stale access

This kind of system is commonly used in game engines, ECS architectures, and resource management systems where safe and efficient object pooling is needed.

By combining a `MemoryArenaDeque` with a [free-list](https://en.wikipedia.org/wiki/Free_list) and generational handles, we can implement a growable "resource handle manager" backed by a memory arena with a few lines of code:

```cpp
// Note: the { 0, 0 } handle represents the "invalid handle"
template <typename Tag, size_t TNumBitsIndex = 16>
struct TResourceHandle32
{
	enum : U32
	{
		NumBitsIndex      = TNumBitsIndex,
		NumBitsGeneration = 32 - NumBitsIndex,
		MaxIndex          = (1u << NumBitsIndex) - 1,
		MaxGeneration     = (1u << NumBitsGeneration) - 1
	};

	U32 index : NumBitsIndex;
	U32 generation = NumBitsGeneration;

	TResourceHandle32(): index(0), generation(0) { }
};

template <typename T, typename THandle, size_t Granularity = 128>
class ResourceHandleManager
{
	public:
		using Handle = THandle;

	private:
		struct Entry
		{
			T resource;
			Handle handle;

			template <typename ...Args>
			Entry(Args && ...args): resource(K_FWD(args)...), handle()
			{
			
			}
		};

		using ResourceContainer = MemoryArenaDeque<Entry, Granularity>;
		ResourceContainer m_resources;
		Handle m_freelistHead;

	public:

		void init(MemoryArena & memoryArena)
		{
			m_resources = ResourceContainer{memoryArena};
		}

		bool reserve(U32 numResources)
		{
			return m_resources.reserve_back(numResources);
		}

		template <typename ...Args>
		Handle createResource(Args && ...args)
		{
			if(m_freelistHead.index != 0) // First try to reuse a slot from the freelist
			{
				Entry & entry = m_resources[m_freelistHead.index-1];

				// Remove from freelist
				const Handle freeSlot = m_freelistHead;
				m_freelistHead.index = entry.handle.index;

				// Initialize entry
				entry.handle.index = freeSlot.index;
				entry.resource = T{K_FWD(args)...};

				return entry.handle;
			}

			// If we could not find a free slot, allocate a new one
			if(m_resources.push_back(T{K_FWD(args)...}))
			{
				const U32 n = numeric_cast<U32>(m_resources.size());
				Entry & entry = m_resources[n-1];
				entry.handle.index = n; // Note: handle indices start at 1 (0 means invalid)
				entry.handle.generation = 0;
				return entry.handle;
			}

			return Handle{ };
		}

		T * getResource(Handle const & h)
		{
			if(h.index != 0 && h.index <= m_resources.size())
			{
				Entry & entry = m_resources[h.index-1];
				if(h.generation == entry.handle.generation)
				{
					return &entry.resource;
				}
			}
			return nullptr;
		}

		T const * getResource(Handle const & h) const
		{
			if(h.index != 0 && h.index <= m_resources.size())
			{
				Entry const & entry = m_resources[h.index-1];
				if(h.generation == entry.handle.generation)
				{
					return &entry.resource;
				}
			}
			return nullptr;
		}

		void destroyResource(Handle const & h)
		{
			if(h.index != 0 && h.index <= m_resources.size())
			{
				Entry & entry = m_resources[h.index-1];

				//entry.resource.~T();

				// Increase generation to invalidate existing handles and add the slot to the freelist,
				// except if we reached the max generation, in which case we disable the slot
				// (by not putting it in the freelist).
				if(entry.handle.generation < Handle::MaxGeneration)
				{
					entry.handle.generation += 1;
				
					if(entry.handle.generation != Handle::MaxGeneration)
					{
						// Prepend to freelist (use Handle::index to store next free slot)
						entry.handle.index = m_freelistHead.index;
						m_freelistHead.index = h.index;
					}
				}
			}
		}
};
```

Example usage:

```cpp
struct Foo
{
	int i;
	float f;

	Foo(): i(0), f(0) { }
	Foo(int ii, float ff): i(ii), f(ff) { }
};

VirtualMemoryArena memoryArena;
memoryArena.init(64ull * 1024ull * 1024ull * 1024ull);

using FooHandle = TResourceHandle32<Foo>;
ResourceHandleManager<Foo, FooHandle> handleMgr;
handleMgr.init(memoryArena);

FooHandle h0 = handleMgr.createResource();
FooHandle h1 = handleMgr.createResource(5, 8.f);
	
Foo * f0 = handleMgr.getResource(h0);
K_ASSERT(f0 != nullptr);

Foo * f1 = handleMgr.getResource(h1);
K_ASSERT(f1 != nullptr);

handleMgr.destroyResource(h0);
f0 = handleMgr.getResource(h0);
K_ASSERT(f0 != nullptr);

FooHandle h2 = handleMgr.createResource(6, 9.f); // Reuse slot 0
Foo * f2 = handleMgr.getResource(h2);
K_ASSERT(f2 != nullptr);
```

## Laying the foundation: what's next?

In this post we mostly explored some "array-like" containers.
<br/>I did not (and probably will not) dive too deep into the rabbit-hole of containers because the containers presented here are already quite versatile and cover a lot of my practical use cases.
<br/>There is still however a second type of containers that I want to use with arenas: hashmaps[^fn-arrays_and_hashmaps]!

[^fn-arrays_and_hashmaps]: All we need are arrays and hashmaps, right?

But that's it for now, thanks for reading!


## References

* **Untangling Lifetimes: The Arena Allocator**: <https://www.rfleury.com/p/untangling-lifetimes-the-arena-allocator>
* **Arena allocator tips and tricks**: <https://nullprogram.com/blog/2023/09/27/>
* **A simple, arena-backed, generic dynamic array for C**: <https://nullprogram.com/blog/2023/10/05/>
* **Handles are the better pointers**: <https://floooh.github.io/2018/06/17/handles-vs-pointers.html>

## Footnotes
