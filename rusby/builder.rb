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
      code = rust.file_header
      code += construct_method(
        orig_method.source,
        meta[method_name][:args],
        meta[method_name][:result]
      )
      code = expand_internal_methods(meta, code, owner)
      code = postprocess(code)
      File.open("#{root_path}/lib/#{method_name}.rs", 'w') do |file|
        file.write(code)
      end
      `rustfmt #{root_path}/lib/#{method_name}.rs`

      puts 'Done generating source code'.colorize(:yellow)
      File.open("#{root_path}/lib/#{method_name}.rs") do |file|
        code = file.read
        code.split("\n").each_with_index do |line, i|
          puts "#{(i + 1).to_s.rjust(3).colorize(:light_black)}.  #{line}"
        end
      end

      compile_and_load_rust(method_name, meta)
    end

    def compile_and_load_rust(method_name, meta)
      signature = construct_signature(
        meta[method_name][:args],
        meta[method_name][:result]
      )
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

    def expand_internal_methods(meta, code, owner)
      result = code
      code.scan(/internal_method_(\w+)\([^\)]+\)/)[0].each do |method_name|
        source = owner.method(method_name).source
        result += construct_method(
          source,
          meta[method_name.to_sym][:args],
          meta[method_name.to_sym][:result],
          false
        )
      end
      result
    end

    def construct_method(source, arg_types, return_type, exposed = true)
      ast = Parser::Ruby22.parse(source)
      method_name = ast.children[0]
      arg_names = ast.children[1].children.map { |ch| ch.children[0].to_s }

      result = rust.method_prefix
      if exposed
        args = arg_names.each_with_index.map do |arg_name, i|
          if rust.ffi_to_rust_types[arg_types[i]]
            rust.ffi_to_rust_types[arg_types[i]].gsub('<name>', arg_name)
          else
            "#{arg_name}: #{rust.rust_types[arg_types[i]]}"
          end
        end
        result = []
        result << "#{rust.exposed_method_prefix} fn ffi_#{method_name}(#{args.join(', ')}) -> #{rust.rust_to_ffi_types[return_type]} {"
        args = arg_names.each_with_index.map do |arg_name, i|
          next unless rust.ffi_to_rust[arg_types[i]] # for simple args we don't need any convertion
          result << rust.ffi_to_rust[arg_types[i]].gsub('<name>', arg_name).to_s
        end
        result << "let result = #{method_name}(#{arg_names.join(', ')});" # calls the real method with ffi args folded
        result << rust.rust_to_ffi[return_type]
        result << '}'

        result << rust.method_prefix
        result = result.join("\n")
      end

      args = arg_names.each_with_index.map do |arg_name, i|
        "#{arg_name}: #{rust.rust_types[arg_types[i]]}"
      end
      result += "fn #{exposed ? '' : 'internal_method_'}#{method_name}(#{args.join(', ')}) -> #{rust.rust_types[return_type]} {"
      result += rust_method_body(ast)
      result += '}'

      result
    end

    def construct_signature(arg_types, return_type)
      args = arg_types.map { |arg| rust.ffi_types[arg].to_sym }
      [
        args.map { |arg| arg == :pointer ? [arg, :int] : arg }.flatten,
        rust.ffi_types[return_type].to_sym
      ]
    end
  end
end
