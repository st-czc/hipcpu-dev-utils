# rocm-systems/projects/clr

The HIP runtime. HIP CPU is one of two backends behind the same runtime
interface; this file is about how the two relate and where the CPU backend sits.

## Two backends behind one interface

The HIP API layer (`hipamd/src/`) does not know which backend it is talking to.
It drives `rocclr/platform` objects, which dispatch to a per-device
`device::Program` / `device::Device` / `device::Memory` / `device::Kernel`
implementation. There are two: `rocclr/device/rocm` for GPUs and
`rocclr/device/cpu` for HIP CPU.

So a missing CPU backend feature usually appears as a missing override of a
`device::*` virtual, not as missing HIP API code.

## Prototype vs golden reference

`rocclr/device/cpu` is a prototype. It shows how a backend is wired into the
runtime; it does not define what a device is supposed to do.

`rocclr/device/rocm` is the golden reference. For behaviour, read the `roc`
implementation first and mirror its shape, its order of operations and its
failure paths.

## What we change

- `rocclr/device/cpu/` — the core modification area.
- `rocclr/` elsewhere — change only when the goal cannot be met in
  `device/cpu`, and then with the smallest possible edit.

Everything else, including `hipamd/src/`, is read-only reference.

## Layers, top to bottom

- `hipamd/src/` — HIP API, `hip::Var` / `hip::Function`, static and module
  symbol registration.
- `rocclr/platform/` — `amd::Program`, `amd::Memory`, `amd::Context`.
- `rocclr/device/devprogram.{hpp,cpp}` — `device::Program` base: the virtuals
  every backend implements.
- `rocclr/device/rocm/` — GPU backend, the reference.
- `rocclr/device/cpu/` — CPU backend.

## Gotchas

- Unimplemented `device::Program` virtuals default to `ShouldNotReachHere()`,
  which aborts the process. A missing override surfaces as an abort, not as a
  `hipError_t`.
- The CPU device image is a host shared library that the runtime dlopens, not an
  AMDGPU code object. Anything the GPU path reads out of code object metadata
  has to be answered from the host ELF or from the runtime itself.
