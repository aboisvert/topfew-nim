# topfew-nim

This is a Nim port of Tim Bray's `topfew` program.

[TopFew introduction](https://www.tbray.org/ongoing/When/202x/2021/03/27/Topfew-and-Amdahl) (Blog post)
[Original TopFew implementation](https://github.com/timbray/topfew) (GitHub link)

## Why?

The intent was:
- to explore the relative performance, expressiveness of Go vs Nim
- learn more Nim in the process, particularly writing efficient/high-performance Nim code

## Takeaways

In both current implementations (December 2021), the performance story is mixed.

Performance measured on a 486MB file:

```sh
$ ls -lh access.log.xlarge
-rw-rw-r-- 1 boisvert boisvert 486M Dec 29 21:05 access.log.xlarge
```

### Performance

- The go-lang implementation is slightly faster when just selecting fields (-f argument alone). This appears to be due to the efficiency of goroutines vs startup overhead of threads in Nim


```sh
# Go-lang
$ time tf -f 7 access.log.xlarge &> go.output
...
...
...
________________________________________________________
Executed in  140.73 millis    fish           external
   usr time  703.88 millis  1833.00 micros  702.05 millis
   sys time  181.56 millis    0.00 micros  181.56 millis
```

```sh
# Nim-lang
$ time tf -f 7 access.log.xlarge &> go.output
...
...
...
________________________________________________________
Executed in  252.49 millis    fish           external
   usr time  1543.91 millis  1359.00 micros  1542.55 millis
   sys time  201.45 millis  428.00 micros  201.02 millis

```


- The nim-lang implementation is faster when filtering using regex.  This appears to be due to a faster implementation of Regex in Nim.

```sh
# Go-lang
$ time ./topfew -n 20 -f 7 -g 'googlebot|bingbot|Twitterbot' access.log.xlarge
...
...
...
________________________________________________________
Executed in    5.77 secs   fish           external
   usr time   45.19 secs    0.00 micros   45.19 secs
   sys time    0.07 secs  520.00 micros    0.07 secs
```

```sh
# Nim-lang
$ time ./topfew -n 20 -f 7 -g 'googlebot|bingbot|Twitterbot' access.log.xlarge
...
...
...
________________________________________________________
Executed in  573.41 millis    fish           external
   usr time    4.07 secs    2.20 millis    4.06 secs
   sys time    0.18 secs    0.00 millis    0.18 secs
```


- The go-lang implementation is faster when applying Sed expression.  This appears to be due to extra string allocations in Nim (I am still hunting those).

```sh

# Go-lang
$ time tf -f 4 -s "\\[[^:]*:" "" -s ':.*$' '' -n 24 access.log.xlarge
...
...
...
________________________________________________________
Executed in  778.18 millis    fish           external
   usr time    4.14 secs   14.49 millis    4.13 secs
   sys time    0.32 secs    0.45 millis    0.31 secs


# Nim-lang
$ time tf -f 4 -s "\\[[^:]*:" "" -s ':.*$' '' -n 24 access.log.xlarge
...
...
...
_______________________________________________________
Executed in    3.58 secs   fish           external
   usr time   12.85 secs  1075.00 micros   12.85 secs
   sys time   12.31 secs  336.00 micros   12.31 secs

$ time tf -f 4 -s "\\[[^:]*:" "" -s ':.*$' '' -n 24 access.log.xlarge

```

### Expressiveness

Since the programs follow the same structure and algorithm, the line counts are comparable, although the Nim code is a bit shorter.

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
