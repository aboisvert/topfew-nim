
# Benchmark Results
## single-threaded
```sh
$ ./topfew -w 1 -f 7 access.log.xlarge
```
| Command | Mean [ms] | Min [ms] | Max [ms] | Relative |
|:---|---:|---:|---:|---:|
| `Nim` | 940.4 ± 57.9 | 878.1 | 1008.8 | 2.29 ± 0.14 |
| `Go` | 410.7 ± 4.5 | 404.4 | 416.6 | 1.00 |

## multi-threaded
```sh
$ ./topfew -f 7 access.log.xlarge
```
| Command | Mean [ms] | Min [ms] | Max [ms] | Relative |
|:---|---:|---:|---:|---:|
| `Nim` | 314.3 ± 31.3 | 271.9 | 350.3 | 1.83 ± 0.23 |
| `Go` | 171.7 ± 13.6 | 139.5 | 206.4 | 1.00 |

## regex filter
```sh
$ ./topfew -f 7 -g "googlebot|bingbot|Twitterbot" access.log.xlarge
```
| Command | Mean [ms] | Min [ms] | Max [ms] | Relative |
|:---|---:|---:|---:|---:|
| `Nim` | 789.7 ± 21.6 | 762.3 | 818.1 | 1.00 |
| `Go` | 7198.4 ± 131.9 | 7061.5 | 7366.0 | 9.12 ± 0.30 |

## sed substitutions
```sh
$ ./topfew -f 4 -s "\[[^:]*:" "" -s ":.*\$" "" -n 24 access.log.xlarge
```
| Command | Mean [s] | Min [s] | Max [s] | Relative |
|:---|---:|---:|---:|---:|
| `Nim` | 4.564 ± 0.077 | 4.476 | 4.635 | 5.44 ± 0.10 |
| `Go` | 0.839 ± 0.006 | 0.834 | 0.847 | 1.00 |

## Date
Sun Jan 16 11:58:45 AM PST 2022
## System Information
Linux alex-precision-5530 5.13.0-25-generic #26-Ubuntu SMP Fri Jan 7 15:48:31 UTC 2022 x86_64 x86_64 x86_64 GNU/Linux

```
Architecture:                    x86_64
CPU op-mode(s):                  32-bit, 64-bit
Byte Order:                      Little Endian
Address sizes:                   39 bits physical, 48 bits virtual
CPU(s):                          8
On-line CPU(s) list:             0-7
Thread(s) per core:              2
Core(s) per socket:              4
Socket(s):                       1
NUMA node(s):                    1
Vendor ID:                       GenuineIntel
CPU family:                      6
Model:                           158
Model name:                      Intel(R) Core(TM) i5-8400H CPU @ 2.50GHz
Stepping:                        10
CPU MHz:                         2500.000
CPU max MHz:                     4200.0000
CPU min MHz:                     800.0000
BogoMIPS:                        4999.90
Virtualization:                  VT-x
L1d cache:                       128 KiB
L1i cache:                       128 KiB
L2 cache:                        1 MiB
L3 cache:                        8 MiB
NUMA node0 CPU(s):               0-7
Vulnerability Itlb multihit:     KVM: Mitigation: VMX disabled
Vulnerability L1tf:              Mitigation; PTE Inversion; VMX conditional cache flushes, SMT vulnerable
Vulnerability Mds:               Mitigation; Clear CPU buffers; SMT vulnerable
Vulnerability Meltdown:          Mitigation; PTI
Vulnerability Spec store bypass: Mitigation; Speculative Store Bypass disabled via prctl and seccomp
Vulnerability Spectre v1:        Mitigation; usercopy/swapgs barriers and __user pointer sanitization
Vulnerability Spectre v2:        Mitigation; Full generic retpoline, IBPB conditional, IBRS_FW, STIBP conditional, RSB filling
Vulnerability Srbds:             Mitigation; Microcode
Vulnerability Tsx async abort:   Mitigation; Clear CPU buffers; SMT vulnerable
Flags:                           fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch cpuid_fault epb invpcid_single pti ssbd ibrs ibpb stibp tpr_shadow vnmi flexpriority ept vpid ept_ad fsgsbase tsc_adjust sgx bmi1 hle avx2 smep bmi2 erms invpcid rtm mpx rdseed adx smap clflushopt intel_pt xsaveopt xsavec xgetbv1 xsaves dtherm ida arat pln pts hwp hwp_notify hwp_act_window hwp_epp sgx_lc md_clear flush_l1d
```
