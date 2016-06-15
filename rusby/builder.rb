require 'parser/ruby22'
require 'yaml'

module Rusby
  module Builder
    extend self

    def root_path
      @root ||= File.expand_path('../..', __FILE__)
    end

    def rust
      @rust ||= Hashie::Mash.new YAML.load_file("#{root_path}/rust.yaml")
    end

    def postprocess(code)
      # fold the array syntax
      code.gsub!(/(\w+) \[\] (\w+)/, '\1[\2]')
      code.gsub!(/(\w+) \[\]= (\w+) =/, '\1[\2] =')
    end

    def convert_to_rust(name, orig_method, owner, result, *args)
      signature, code = main_method(
        orig_method.source,
        args.map(&:class),
        result.class
      )
      expand_inline_methods(code, owner)
      postprocess(code)

      File.open("#{root_path}/lib/#{name}.rs", 'w') { |file| file.write(code) }
      `rustfmt #{root_path}/lib/#{name}.rs`
      File.open("#{root_path}/lib/#{name}.rs") { |file| puts file.read }

      puts "Compiling #{signature.last} #{name}(#{signature.first.join(', ')})..."
      # puts `rustc --crate-type=dylib -O -o #{root_path}/lib/#{name}.dylib #{root_path}/lib/#{name}.rs`

      # Proxy.rusby_load "#{root_path}/lib/#{name}"
      # Proxy.attach_function name, *signature
      #
      # Proxy.method(name)
    end

    def rust_method_body(ast)
      name = ast.children.first
      Rust.set_locals(name)

      result = ''
      ast.children[2..-1].each do |node|
        result += Rust.generate(node)
      end
      result
    end

    def expand_inline_methods(code, owner)
      code.gsub!(/inline_method_(\w+)\([^\)]+\)/) do
        source = owner.method(Regexp.last_match(1)).source
        ast = Parser::Ruby22.parse(source)
        rust_method_body(ast)
      end
    end

    def main_method(source, arg_types, return_type)
      result = rust.method_declaration_prefix + "\n"

      ast = Parser::Ruby22.parse(source)
      args = ast.children[1].children.each_with_index.map do |child, i|
        "#{child.children[0]}: #{rust.types[arg_types[i]]}"
      end

      result += "#{rust.method_prefix} #{ast.children[0]}(#{args.join(', ')}) -> #{rust.types[return_type]} {"
      result += rust_method_body(ast)
      result += '}'

      signature = [arg_types.map { |arg| rust.c_types[arg] }, rust.c_types[return_type]]
      [signature, result]
    end
  end
end
