// __device__ / __constant__ globals accessed through the HIP symbol APIs.
// Expected: compile PASS, run FAIL while GlobalVar resolution is unimplemented.
#include <hip/hip_runtime.h>
#include <cmath>
#include <cstdio>

constexpr int kN = 256;

__constant__ float c_coeff[3];
__device__ float d_result[kN];

__global__ void apply_quadratic(const float* x) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < kN) {
    float v = x[i];
    d_result[i] = c_coeff[0] * v * v + c_coeff[1] * v + c_coeff[2];
  }
}

int main() {
  float h_x[kN];
  float h_ref[kN];
  float h_out[kN];
  const float coeff[3] = {2.0f, -3.0f, 1.0f};
  for (int i = 0; i < kN; ++i) {
    h_x[i] = static_cast<float>(i) / kN - 0.5f;
    h_ref[i] = coeff[0] * h_x[i] * h_x[i] + coeff[1] * h_x[i] + coeff[2];
  }

  size_t coeff_bytes = 0;
  size_t result_bytes = 0;
  void* result_ptr = nullptr;
  hipGetSymbolSize(&coeff_bytes, HIP_SYMBOL(c_coeff));
  hipGetSymbolSize(&result_bytes, HIP_SYMBOL(d_result));
  hipGetSymbolAddress(&result_ptr, HIP_SYMBOL(d_result));
  if (coeff_bytes != sizeof(coeff) || result_bytes != sizeof(h_out) ||
      result_ptr == nullptr) {
    printf("FAIL: symbol size/address (coeff=%zu result=%zu addr=%p)\n",
           coeff_bytes, result_bytes, result_ptr);
    return 1;
  }

  float* d_x = nullptr;
  hipMalloc(&d_x, sizeof(h_x));
  hipMemcpy(d_x, h_x, sizeof(h_x), hipMemcpyHostToDevice);
  hipMemcpyToSymbol(HIP_SYMBOL(c_coeff), coeff, sizeof(coeff));

  apply_quadratic<<<kN / 128, 128>>>(d_x);
  hipDeviceSynchronize();

  hipMemcpyFromSymbol(h_out, HIP_SYMBOL(d_result), sizeof(h_out));

  float max_err = 0.0f;
  for (int i = 0; i < kN; ++i)
    max_err = std::fmax(max_err, std::fabs(h_out[i] - h_ref[i]));

  hipFree(d_x);
  bool ok = max_err < 1e-5f;
  printf("%s: %s (max err %.3g)\n", "quadratic", ok ? "PASS" : "FAIL", max_err);
  return ok ? 0 : 1;
}
