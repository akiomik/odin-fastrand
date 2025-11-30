# odin-fastrand

A port implementation of Rust's [fastrand](https://github.com/smol-rs/fastrand) crate ([wyrand](https://github.com/wangyi-fudan/wyhash)) for [Odin](https://odin-lang.org/).

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
