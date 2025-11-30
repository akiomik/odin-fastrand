# odin-fastrand

A port implementation of Rust's [fastrand](https://github.com/smol-rs/fastrand) crate ([wyrand](https://github.com/wangyi-fudan/wyhash)) for [Odin](https://odin-lang.org/).

> [!IMPORTANT]
> fastrand is **not cryptographically secure**. It should not be used for cryptographic purposes, security-sensitive applications, or generating secrets. For cryptographic use cases, please use Odin's `default_random_generator` (ChaCha8) instead.

## Performance

Benchmark results for `rand.uint64()` generation on GitHub Actions:

| Algorithm         | Performance  | Relative Speed     |
|-------------------|--------------|--------------------|
| **fastrand**      | **38 ns/op** | **1.0x (fastest)** |
| xoshiro256        | 51 ns/op     | 1.3x slower        |
| pcg               | 55 ns/op     | 1.4x slower        |
| chacha8 (default) | 110 ns/op    | 2.9x slower        |

### Test Environment

- **Platform**: GitHub Actions Ubuntu 24.04.3 LTS
- **CPU**: AMD EPYC 7763 64-Core Processor
- **Compiler**: Odin dev-2025-11-nightly with LLVM 20.1.8 backend

fastrand shows **~45% better performance** compared to xoshiro256 and **~65% faster** than the default ChaCha8 generator,
making it an excellent choice for applications requiring fast random number generation.

## Usage

Use in combination with `core:math/rand`:

```odin
package main

import "core:math/rand"
import "fastrand"

main :: proc() {
  // Get a generator
  gen := fastrand.random_generator()
  context.random_generator = gen

  // Use with core:math/rand functions
  random_int := rand.int_range(0, 100)
  random_float := rand.float32()
}
```

## Development

```bash
# test
odin test tests

# bench
odin test benchmark
```
