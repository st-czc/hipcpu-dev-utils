# HIP CPU Backend

This file is the entry point for HIP CPU backend work. All paths are relative
to the super-project root.

## Global instructions

Limit the amount of comments you put in the code to a strict minimum. You should almost never add comments, except sometimes on non-trivial code, function definitions if the arguments aren't self-explanatory, and class definitions and their members.

Do not remove existing comments unless they are directly related to what you are changing.

The repository is very big and so it isn't advised to blindly run rg or grep commands without specifying a narrow set of directories to search.


## Layout

- `compiler/llvm-project` — the main LLVM and Clang compiler. It is based on an
  upstream main commit.
- `compiler/amd-llvm` — a pruned and customed checkout of the ROCm/llvm-project
  (the AMD-side pieces: comgr, device-libs, hipcc, …).
  It builds against `compiler/llvm-project`.
- `compiler/hipcpu-passes` — the pass plugin for the SYCL Native CPU backend.
  It builds against `compiler/llvm-project`.
  It is a pruned and customed checkout of the ROCm/llvm-project
- `compiler/hipcpu-artifacts` — prebuilt `libsycl-nativecpu_utils.bc` for
  `compiler/hipcpu-passes`, built from `intel-llvm`.
- `compiler/hipcpu-artifacts/intel-llvm` — a full intel/llvm checkout. It is the
  reference source for `compiler/hipcpu-passes`.
- `rocm-systems/projects/clr` — the HIP runtime. The CPU backend code is in
  `clr/rocclr/device/cpu`.
- `hipcpu-dev-utils/hip-tests` — the HIP unit-test harness.

## Sub-project docs

Read the matching doc before working under these paths:

- `compiler/hipcpu-passes` — [subprojects/hipcpu-passes.md](subprojects/hipcpu-passes.md)
- `rocm-systems/projects/clr` — [subprojects/clr.md](subprojects/clr.md)

## Compilation flow

Device code becomes a device image in four steps:

1. Clang compiles device code for the `spvcpu` target to LLVM bitcode.
2. `llvm-link` merges that bitcode with the CPU support library
   `libsycl-nativecpu_utils.bc`.
3. `opt` runs the `sycl-native-cpu` pipeline from the `hipcpu-passes` plugin.
   The pipeline lowers the bitcode to host code.
4. Clang compiles the host code to a shared library (the device image).

## Build

For a full build, run the scripts in this order.

```sh
./update_submodules.sh
./hipcpu_build.sh
```

For an incremental rebuild, run:

```sh
cmake --build build -- install
```

The compiler is the one exception: after editing `compiler/llvm-project`,
`compiler/hipcpu-passes`, or `compiler/amd-llvm`, rebuild the `compiler/amd-llvm`
subproject first — it compiles clang/LLVM from `compiler/llvm-project`:

```sh
cmake --build build/compiler/amd-llvm/build -- install
cmake --build build -- install
```

## Test

```sh
hipcpu-dev-utils/hip-tests/run.sh --help
```

Read `hipcpu-dev-utils/hip-tests/readme.md` before you use the test harness.

## Bounds

- Use only the build entry points above.
- Do not run `build_tools/fetch_sources.py`. It resets all submodules and
  reapplies patches.
- The remote configuration (URLs, branches, pins) is user-maintained. Do not
  change it.
