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
      code.gsub!(/(\w+) \[\] (\w+)/, '\1[\2 as usize]')
      code.gsub!(/(\w+) \[\]= (\w+) =/, '\1[\2 as usize] =')
    end

    def convert_to_rust(meta, method_name, orig_method, owner)
      signature, code = construct_method(
        orig_method.source,
        meta[method_name][:args],
        meta[method_name][:result]
      )
      code = internal_methods(meta, code, owner)
      postprocess(code)

      File.open("#{root_path}/lib/#{method_name}.rs", 'w') { |file| file.write(code) }
      `rustfmt #{root_path}/lib/#{method_name}.rs`
      File.open("#{root_path}/lib/#{method_name}.rs") { |file| puts file.read }

      puts "Compiling #{signature.last} #{method_name}(#{signature.first.join(', ')})..."
      puts `rustc --crate-type=dylib -O -o #{root_path}/lib/#{method_name}.dylib #{root_path}/lib/#{method_name}.rs`

      Proxy.rusby_load "#{root_path}/lib/#{method_name}"
      Proxy.attach_function method_name, *signature

      Proxy.method(method_name)
    end

    def rust_method_body(ast)
      name = ast.children.first
      rust = Rust.new
      rust.set_locals(name)

      result = ''
      ast.children[2..-1].each do |node|
        result += rust.generate(node)
      end
      result
    end

    def internal_methods(meta, code, owner)
      result = code
      code.scan(/internal_method_(\w+)\([^\)]+\)/)[0].each do |method_name|
        source = owner.method(method_name).source
        result += construct_method(
          source,
          meta[method_name.to_sym][:args],
          meta[method_name.to_sym][:result],
          false
        )[1]
      end
      return result
    end

    def construct_method(source, arg_types, return_type, exposed = true)
      result = exposed ? rust.method_declaration_prefix_extern + "\n" : ''
      result += rust.method_declaration_prefix

      ast = Parser::Ruby22.parse(source)
      args = ast.children[1].children.each_with_index.map do |child, i|
        "#{child.children[0]}: #{rust.types[arg_types[i]]}"
      end

      result += "#{exposed ? rust.method_prefix : ''} fn #{exposed ? '' : 'internal_method_'}#{ast.children[0]}(#{args.join(', ')}) -> #{rust.types[return_type]} {"
      result += rust_method_body(ast)
      result += '}'

      signature = [
        arg_types.map { |arg| rust.c_types[arg].to_sym },
        rust.c_types[return_type].to_sym
      ]
      [signature, result]
    end
  end
end
