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

      puts 'Generating source code'.colorize(:yellow)
      File.open("#{root_path}/lib/#{method_name}.rs") do |file|
        code = file.read
        code.split("\n").each_with_index do |line, i|
          puts "#{(i + 1).to_s.rjust(3).colorize(:light_black)}.  #{line}"
        end
      end

      puts "Compiling #{signature.last} #{method_name}(#{signature.first.join(', ')})".colorize(:yellow)
      puts `rustc --crate-type=dylib -O -o #{root_path}/lib/#{method_name}.dylib #{root_path}/lib/#{method_name}.rs`

      Proxy.rusby_load "#{root_path}/lib/#{method_name}"
      Proxy.attach_function "ffi_#{method_name}", *signature

      Proxy.method("ffi_#{method_name}")
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
      result
    end

    def construct_method(source, arg_types, return_type, exposed = true)
      result = exposed ? "\n#{rust.method_declaration_prefix_extern}\n" : ''
      result += rust.method_declaration_prefix

      ast = Parser::Ruby22.parse(source)
      method_name = ast.children[0]
      arg_names = ast.children[1].children.map { |ch| ch.children[0].to_s }

      if exposed
        args = arg_names.each_with_index.map do |arg_name, i|
          if rust.wrapper_types[arg_types[i]]
            rust.wrapper_types[arg_types[i]].gsub('<name>', arg_name)
          else
            "#{arg_name}: #{rust.types[arg_types[i]]}"
          end
        end
        result += "\n\n#{rust.method_prefix} fn ffi_#{method_name}(#{args.join(', ')}) -> #{rust.wrapper_return_types[return_type]} {\n"
        args = arg_names.each_with_index.map do |arg_name, i|
          if rust.wrapper_exp[arg_types[i]]
            result += "\n#{rust.wrapper_exp[arg_types[i]].gsub('<name>', arg_name)}\n"
          end
        end
        result += "return #{method_name}(#{arg_names.join(', ')}).as_ptr();"
        result += "\n}\n\n"
      end

      args = arg_names.each_with_index.map do |arg_name, i|
        "#{arg_name}: #{rust.types[arg_types[i]]}"
      end
      result += "fn #{exposed ? '' : 'internal_method_'}#{method_name}(#{args.join(', ')}) -> #{rust.types[return_type]} {"
      result += rust_method_body(ast)
      result += '}'

      s_args = arg_types.map { |arg| rust.c_types[arg].to_sym }
      signature = [
        s_args.map { |arg| arg == :pointer ? [arg, :int] : arg }.flatten,
        rust.c_types[return_type].to_sym
      ]
      [signature, result]
    end
  end
end
