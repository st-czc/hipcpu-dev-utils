# compiler/hipcpu-passes

The LLVM pass plugin that lowers device bitcode to native CPU code. This is the
compiler half of HIP CPU; `rocm-systems/projects/clr/rocclr/device/cpu` is the
runtime half.

## Where it sits in the pipeline

HIP compiles device code in stages: clang emits spvcpu bitcode, `llvm-link`
merges it with the CPU support library, the plugin's pipeline lowers it to host
code, then the host clang compiles that to the shared library that becomes the
device image. So a lowering problem is fixed here, and a problem with how the
image is loaded or queried is fixed in the runtime.

## Upstream vs ours

`compiler_passes/` and `vecz/` are vendored from the SYCL Native CPU project in
intel/llvm; `compiler/hipcpu-artifacts/intel-llvm` is the reference checkout.
They are upstream. Our passes and the pipeline that orders them live in
`llvm/lib/SYCLNativeCPUUtils/` and `llvm/include/llvm/SYCLLowerIR/`.

## What we change

Our passes and the pipeline. The vendored trees are read-only reference.

## Conventions

- Passes are `OptionalPassInfoMixin`, not `PassInfoMixin`, and return
  `PreservedAnalyses::none()` only when they changed something.
- A new pass is added in two places: the `add_llvm_pass_plugin` source list in
  `SYCLNativeCPUUtils/CMakeLists.txt`, and `addSYCLNativeCPUBackendPasses` in
  `PipelineSYCLNativeCPU.cpp`.
- The pipeline order is load-bearing. `EmitHIPNoteSYCLNativeCPUPass` runs first
  because the HIP runtime reads back the kernel signature and the group segment
  before anything rewrites them; `RenameKernelSYCLNativeCPUPass` runs last.

## Address spaces

This is where the CPU target differs from GPU targets in a way passes must
account for:

- 1 — `__device__` globals.
- 3 — `__shared__` / local memory. The local memory lowering owns this space
  and filters on it.
- 4 — constant space: `__constant__`, `__device__ const`, and string literals.

A pass that touches one space does not disturb the others.

## Gotchas

- On this target the constant space has no hardware backing. The runtime shares
  the globals' storage with the host, so how the backend places them in the ELF
  decides whether the host can write them.
- ELF section placement is derived by codegen from a global's attributes. A pass
  steers placement by changing the attributes, not by naming sections.
