package fastrand

import "base:intrinsics"
import "base:runtime"

import "core:math/rand"

// Constants taken from https://github.com/wangyi-fudan/wyhash/blob/46cebe9dc4e51f94d0dca287733bc5a94f76a10d/wyhash.h#L151
ADDITIVE_CONST :: 0x2d358dccaa6c78a5
MIXING_CONST :: 0x8bb84b93962eacc9

// The state
Random_State :: struct {
  s: u64,
}

// Returns an instance of the pseudorandom generator
@(require_results)
random_generator :: proc "contextless" (state: ^Random_State = nil) -> rand.Generator {
  return rand.Generator{
    procedure = random_generator_proc,
    data = state,
  }
}

// Random procedure for rand.Generator
@(private)
random_generator_proc :: proc(data: rawptr, mode: runtime.Random_Generator_Mode, p: []u8) {
  @(thread_local)
  global_rand_seed: Random_State

  r: ^Random_State = ---
  if data == nil {
    r = &global_rand_seed
  } else {
    r = cast(^Random_State)data
  }

  switch mode {
  case .Read:
    // fill_bytes(r, p)
    // Fast path for a 64-bit destination.
    buf_len := len(p)
    if buf_len == size_of(u64) {
      val := gen_u64(r)
      intrinsics.unaligned_store((^u64)(raw_data(p)), val)
      return
    }

    i := 0
    for i + 8 <= buf_len {
      val := gen_u64(r)
      #no_bounds_check {
        intrinsics.unaligned_store((^u64)(&p[i]), val)
      }
      i += 8
    }

    if i < buf_len {
      val := gen_u64(r)
      #no_bounds_check {
        runtime.mem_copy_non_overlapping(&p[i], &val, buf_len - i)
      }
    }

  case .Reset:
    seed: u64
    runtime.mem_copy_non_overlapping(&seed, raw_data(p), min(size_of(seed), len(p)))
    r.s = seed

  case .Query_Info:
    info := (^rand.Generator_Query_Info)(raw_data(p))
    info^ += {.Uniform, .Resettable}
  }
}

@(require_results)
wrapping_add :: #force_inline proc "contextless" (a, b: u64) -> u64 {
  return a + b
}

// Generate next u64
@(require_results)
gen_u64 :: proc "contextless" (r: ^Random_State) -> u64 {
  r.s = wrapping_add(r.s, ADDITIVE_CONST)
  prod := u128(r.s) * u128(r.s ~ MIXING_CONST)
  hi := u64(prod >> 64)
  lo := u64(prod)
  return hi ~ lo
}

// Fill buffer with random bytes
fill_bytes :: #force_inline proc "contextless" (r: ^Random_State, buf: []byte) {
  // Fast path for a 64-bit destination.
	buf_len := len(buf)
  if buf_len == size_of(u64) {
    val := gen_u64(r)
    intrinsics.unaligned_store((^u64)(raw_data(buf)), val)
    return
  }

  i := 0
  for i + 8 <= buf_len {
    val := gen_u64(r)
    #no_bounds_check {
      intrinsics.unaligned_store((^u64)(&buf[i]), val)
    }
    i += 8
  }

  if i < buf_len {
    val := gen_u64(r)
    #no_bounds_check {
      runtime.mem_copy_non_overlapping(&buf[i], &val, buf_len - i)
    }
  }
}
