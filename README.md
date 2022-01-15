# topfew-nim

This is a Nim port of Tim Bray's `topfew` program.

* [TopFew introduction](https://www.tbray.org/ongoing/When/202x/2021/03/27/Topfew-and-Amdahl) (Blog post)
* [Original go-lang TopFew implementation](https://github.com/timbray/topfew) (GitHub link)

## Why?

The intent was:
- to explore the relative performance, expressiveness of Go vs Nim vs Rust
- learn more Nim in the process, particularly writing efficient/high-performance Nim code


## Benchmarking

1) Install the [Hyperfine](https://github.com/sharkdp/hyperfine) benchmarking tool

2) (Optional) Set the `GO_CMD` and `RUST_CMD` environment variables to point to your pre-built Go-lang/Rust topfew executables, e.g.,

```sh
$ export GO_CMD=~/git/topfew/bin/tf
```

3) Run `nimble bench`

PS: The `bench` Nimble task has only been tested (and written for) the Linux platform

PPS: As of today (2022-01-15), the Rust version does not support the same feature set as the Nim/Go implementations.  It does not support single-threaded mode (`-w 1`), nor does it support regex-based filtering (`-g ...`), nor sed-style substitutions (`-s ...`).  For the most basic use-case, with field selection only (`-f ...`), it performs on par with the Go implementation on my system.

## Results

Here are sample results (as of January '22) from my laptop.

In both current implementations, the performance story is mixed.  Performance is measured on a 486MB file (`access.log.xlarge`).  This file may be downloaded from https://alphagame.dev/ by adding `access.log.xlarge.gz` to the URL.

### single-threaded
| Command | Mean [ms] | Min [ms] | Max [ms] | Relative |
|:---|---:|---:|---:|---:|
| `Nim` | 983.4 ± 107.0 | 916.0 | 1167.1 | 1.89 ± 0.33 |
| `Go` | 520.4 ± 72.0 | 448.6 | 640.4 | 1.00 |

### multi-threaded
| Command | Mean [ms] | Min [ms] | Max [ms] | Relative |
|:---|---:|---:|---:|---:|
| `Nim` | 316.1 ± 25.7 | 277.9 | 345.9 | 1.94 ± 0.22 |
| `Go` | 163.0 ± 13.2 | 132.0 | 186.7 | 1.00 |

### regex filter
| Command | Mean [ms] | Min [ms] | Max [ms] | Relative |
|:---|---:|---:|---:|---:|
| `Nim` | 742.4 ± 55.7 | 680.2 | 813.3 | 1.00 |
| `Go` | 7583.4 ± 368.1 | 7215.2 | 8057.9 | 10.22 ± 0.91 |

### sed substitutions
| Command | Mean [s] | Min [s] | Max [s] | Relative |
|:---|---:|---:|---:|---:|
| `Nim` | 4.619 ± 0.061 | 4.526 | 4.688 | 4.55 ± 0.43 |
| `Go` | 1.016 ± 0.095 | 0.847 | 1.064 | 1.00 |

### Hardware

```
Dell Precision 5530 latop
Intel(R) Core(TM) i5-8400H CPU @ 2.50GHz (1 socket; 4 cores; hyperthreading enabled - 2 threads/core)
Linux 5.13.0-25-generic #26-Ubuntu SMP Fri Jan 7 15:48:31 UTC 2022 x86_64 x86_64 x86_64 GNU/Linux`
```

## Expressiveness

At this time, since the Nim version is basically a transliteration (read: follows the same structure and algorithm as the go-lang implementation), the line counts are comparable, although the Nim code is a bit shorer.

```sh
$ find . -type f -name "*.go" | grep -v test | xargs wc -l
  192 ./main.go
  122 ./internal/keyfinder.go
  163 ./internal/segmenter.go
    2 ./internal/package.go
   33 ./internal/stream.go
   43 ./internal/sampler.go
  143 ./internal/counter.go
   74 ./internal/filters.go
  772 total
```

```sh
$ find . -type f -name "*.nim" | grep -v test | xargs wc -l
  148 ./src/topfew.nim
  143 ./src/topfew/segmenter.nim
   30 ./src/topfew/sampler.nim
   97 ./src/topfew/keyfinder.nim
  103 ./src/topfew/counter.nim
   51 ./src/topfew/filter.nim
   25 ./src/topfew/utils.nim
   30 ./src/topfew/streaming.nim
  627 total
```

No attempts at optimizing the code size or code-golfing were made to reduce the LoCs of the Nim implementation.