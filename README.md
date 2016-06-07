# Quickstart
```
bundle
ruby boot.rb
```

## Notes
https://github.com/michaelfairley/method_decorators

Thread-safe fiddle:
```
-> first run of plusplus
Measure Mode: wall_time
Thread ID: 70183264051680
Fiber ID: 70183284493160
Total: 0.114449
Sort by: self_time

 %self      total      self      wait     child     calls  name
 43.71      0.114     0.050     0.000     0.064        1   Integer#times
 31.39      0.064     0.036     0.000     0.028   100000   Method#call
 24.87      0.028     0.028     0.000     0.000   100000   FanaticPluser#plusplus
  0.03      0.114     0.000     0.000     0.114        1   Object#timeit
  0.01      0.000     0.000     0.000     0.000        1   Float#to_i

* indicates recursively called methods
Compiling int plusplus(int)...
-> second run of plusplus
★★★  Running Rust! Yeeeah Baby! ★★★
Measure Mode: wall_time
Thread ID: 70183264051680
Fiber ID: 70183284493160
Total: 0.384716
Sort by: self_time

 %self      total      self      wait     child     calls  name
 23.66      0.167     0.091     0.000     0.076   100000   <Module::Fiddle>#last_error=
 23.38      0.257     0.090     0.000     0.167   100000   Fiddle::Function#call
 19.53      0.385     0.075     0.000     0.310        1   Integer#times
 13.58      0.310     0.052     0.000     0.257   100000   Rusby::Proxy#plusplus
 10.80      0.042     0.042     0.000     0.000   200000   Thread#[]=
  9.05      0.035     0.035     0.000     0.000   200000   <Class::Thread>#current
  0.00      0.385     0.000     0.000     0.385        1   Object#timeit
  0.00      0.000     0.000     0.000     0.000        1   Float#to_i

```
