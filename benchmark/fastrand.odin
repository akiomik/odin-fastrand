package benchmark

import "base:runtime"

import "core:fmt"
import "core:log"
import "core:math/rand"
import "core:strings"
import "core:testing"
import "core:time"

import fastrand ".."

@(private = "file")
ITERS :: 10_000_000

@(test)
benchmark_fill_bytes :: proc(t: ^testing.T) {
  r := fastrand.Random_State{s = 12345}

  buf := make([]byte, 1024)
  defer delete(buf)

  start := time.now()

  for i in 0..<ITERS {
    fastrand.fill_bytes(&r, buf)
  }

  duration := time.since(start)
  ns_per_op := time.duration_nanoseconds(duration) / ITERS

	sb := strings.builder_make()
  defer strings.builder_destroy(&sb)

  s := fmt.sbprintf(&sb, "fastrand.fill_bytes (1KB): %d ns/op", ns_per_op)
  log.info(s)
}

@(test)
benchmark_fastrand_uint64 :: proc(t: ^testing.T) {
  gen := fastrand.random_generator()
  context.random_generator = gen

  start := time.now()

  for i in 0..<ITERS {
    _ = rand.uint64()
  }

  duration := time.since(start)
  ns_per_op := time.duration_nanoseconds(duration) / ITERS

	sb := strings.builder_make()
  defer strings.builder_destroy(&sb)

  s := fmt.sbprintf(&sb, "rand.uint64 (fastrand): %d ns/op", ns_per_op)
  log.info(s)
}

@(test)
benchmark_default_uint64 :: proc(t: ^testing.T) {
  gen := runtime.default_random_generator()
  context.random_generator = gen

  start := time.now()

  for i in 0..<ITERS {
    _ = rand.uint64()
  }

  duration := time.since(start)
  ns_per_op := time.duration_nanoseconds(duration) / ITERS

	sb := strings.builder_make()
  defer strings.builder_destroy(&sb)

  s := fmt.sbprintf(&sb, "rand.uint64 (default: chacha8): %d ns/op", ns_per_op)
  log.info(s)
}

@(test)
benchmark_pcg_uint64 :: proc(t: ^testing.T) {
  gen := rand.pcg_random_generator()
  context.random_generator = gen

  start := time.now()

  for i in 0..<ITERS {
    _ = rand.uint64()
  }

  duration := time.since(start)
  ns_per_op := time.duration_nanoseconds(duration) / ITERS

	sb := strings.builder_make()
  defer strings.builder_destroy(&sb)

  s := fmt.sbprintf(&sb, "rand.uint64 (pcg): %d ns/op", ns_per_op)
  log.info(s)
}

@(test)
benchmark_xoshiro256_uint64 :: proc(t: ^testing.T) {
  gen := rand.xoshiro256_random_generator()
  context.random_generator = gen

  start := time.now()

  for i in 0..<ITERS {
    _ = rand.uint64()
  }

  duration := time.since(start)
  ns_per_op := time.duration_nanoseconds(duration) / ITERS

	sb := strings.builder_make()
  defer strings.builder_destroy(&sb)

  s := fmt.sbprintf(&sb, "rand.uint64 (xoshiro256): %d ns/op", ns_per_op)
  log.info(s)
}
