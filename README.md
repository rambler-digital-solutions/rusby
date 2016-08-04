## About

**Rusby** is a *Ruby* to *Rust* transpiler for simple performance-oriented methods.

Computations in plain Ruby are painfully slow.
Almost all internal methods in of Ruby are implemented in C, thus achieving acceptable performance on e.g. [Array#sort](https://github.com/ruby/ruby/blob/trunk/array.c).

On the other hand extension of ruby code with C or other low-level language functions is not to say hard... but at least is tricky. **Rusby** allows to write simple methods in plain ruby and convert them to rust with zero modifications.

Just mark method with `rusby!` and you are ready to rust :/

![Quicksort example](https://raw.githubusercontent.com/rambler-digital-solutions/rusby/master/doc/img1.png)

---

N.B. It's a research project, so at least test for edge cases (e.g. overflows) before production usage.

Transpilation was tested only on cases in `./examples` directory.

---

## How it works?

1. You prefix your method definition with `!rusby`.
1. Native Ruby method is ran for the first time.
1. Its arguments types and return type are recorded.
1. These data along with source code of the method (as AST tree) are passed to the Rusby::Builder.
1. Rusby::Builder calls Rusby::Rust, which recursively generates rust code based on AST tree (Rusby::Generators::\*).
1. Few hacks are applied along the way, see Rusby::Preprocessor, Rusby::Postrocessor.
1. Generated Rust code is dumped to file into `./lib` Dir
1. Rust code is prettified and compiled into dynamic lib.
1. At last we have ruby method and rust counterpart linked via [FFI](https://github.com/ffi/ffi).
1. Benchmark them and find the fastest one.
1. Link the winner into the source class.
1. Profit.

## Features
- In-place ruby/rust method swapping based on benchmarks
- Recursive calls transpiling
- Nested functions transpiling
- Limited string operations support
- Integer matrix manipulation support

## Quickstart
```
brew install rust # or similar
cd examples
bundle
ruby run_examples.rb
```

or

```
gem install rusby
```

Create file test.rb:
```
require 'rusby'

class FanaticGreeter
  extend Rusby::Core

  rusby!
  def greet(name)
    "Hello, #{name}!"
  end
end

greeter = FanaticGreeter.new
2.times { greeter.greet('Ash') }
```

```
ruby test.rb
```

## Tests
```
rake spec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rusby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
