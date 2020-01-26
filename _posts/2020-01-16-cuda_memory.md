---
title: "CUDA memory"
tag:
  - cuda
  - memory
  - optimization
---

## Memory transaction

http://on-demand.gputechconf.com/gtc-express/2011/presentations/cuda_webinars_GlobalMemory.pdf

https://docs.nvidia.com/gameworks/content/developertools/desktop/analysis/report/cudaexperiments/sourcelevel/memorytransactions.htm

https://stackoverflow.com/questions/12798503/the-cost-of-cuda-global-memory-transactions

L1 load granularity = 128 bytes per transaction

L2 load granularity = 32 bytes per transaction

In caching mode, memory requests first go through L1 and in case of cache miss, go through L2 and then finally in GMEM.

If a warp reads 32 consecutives 32-bit values (fully coalesced), it generates a single 128-byte memory transaction in L1 (in caching mode) or 4 32-byte memory transactions in L2 (in uncached mode).

