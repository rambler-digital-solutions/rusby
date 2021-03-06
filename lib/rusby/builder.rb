module Rusby
  module Builder
    extend self

    def root_path
      @root ||= File.expand_path('../../..', __FILE__)
    end

    def lib_path
      return @lib_path if @lib_path
      path = './tmp/rusby'
      Dir.mkdir('./tmp') unless Dir.exist?('./tmp')
      Dir.mkdir(path) unless Dir.exist?(path)
      @lib_path = path
    end

    def rust
      @rust ||= Hashie::Mash.new YAML.load_file("#{root_path}/rust.yaml")
    end

    def convert_to_rust(meta, method_name, orig_method, owner)
      code = rust.file_header
      code += construct_method(
        Preprocessor.apply(orig_method.source),
        meta[method_name]
      )
      code = expand_internal_methods(meta, code, owner)
      code = Postrocessor.apply(code, meta[method_name])

      File.open("#{lib_path}/#{method_name}.rs", 'w') do |file|
        file.write(code)
      end
      `rustfmt #{lib_path}/#{method_name}.rs`

      puts 'Done generating source code'.colorize(:yellow)
      File.open("#{lib_path}/#{method_name}.rs") do |file|
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
      puts "Compiling #{signature.last} #{method_name}" \
        "(#{signature.first.join(', ')})".colorize(:yellow)
      command = 'rustc -A unused_imports --crate-type=dylib '
      command += "-O -o #{lib_path}/#{method_name}.dylib "
      command += "#{lib_path}/#{method_name}.rs"
      puts `#{command}`


      Proxy.rusby_load "#{lib_path}/#{method_name}"
      Proxy.attach_function "ffi_#{method_name}", *signature

      Proxy.method("ffi_#{method_name}")
    end

    def rust_method_body(meta, ast)
      name = ast.children.first
      rust = Rust.new(@rust.rust_types[meta[:result]])
      rust.remember_method(name)

      result = ''
      ast.children[2..-1].each do |node|
        result += rust.generate(node)
      end
      result
    end

    def expand_internal_methods(meta, code, owner)
      method_names = code.scan(/internal_method_(\w+)\([^\)]+\)/)[0]
      return code unless method_names

      result = code
      method_names.each do |method_name|
        source = owner.method(method_name).source
        result += construct_method(
          source,
          meta[method_name.to_sym],
          false
        )
      end
      result
    end

    def ffi_wrapper(method_name, arg_names, arg_types, return_type)
      args = arg_names.each_with_index.map do |arg_name, i|
        if rust.ffi_to_rust_types[arg_types[i]]
          rust.ffi_to_rust_types[arg_types[i]].gsub('<name>', arg_name)
        else
          "#{arg_name}: #{rust.rust_types[arg_types[i]]}"
        end
      end
      result = [
        '',
        '// this function folds ffi arguments and unfolds result to ffi types'
      ]
      result << "#{rust.exposed_method_prefix} fn " \
        "ffi_#{method_name}(#{args.join(', ')}) -> " \
        "#{rust.rust_to_ffi_types[return_type] || rust.rust_types[return_type]}" \
        ' {'
      arg_names.each_with_index.map do |arg_name, i|
        # for simple args we don't need any convertion
        next unless rust.ffi_to_rust[arg_types[i]]
        result << rust.ffi_to_rust[arg_types[i]].gsub('<name>', arg_name).to_s
      end
      # calls the real method with ffi args folded
      result << "let result = #{method_name}(#{arg_names.join(', ')});"
      result << "return #{rust.rust_to_ffi[return_type] || 'result'};"
      result << '}'

      result
    end

    def construct_method(source, meta, exposed = true)
      arg_types = meta[:args]
      return_type = meta[:result]

      ast = Parser::CurrentRuby.parse(source)
      method_name = ast.children[0]
      arg_names = ast.children[1].children.map { |ch| ch.children[0].to_s }
      meta[:names] = arg_names

      result = []
      if exposed
        result = ffi_wrapper(method_name, arg_names, arg_types, return_type)
      end
      result << rust.method_prefix

      args = arg_names.each_with_index.map do |arg_name, i|
        "#{arg_name}: #{rust.rust_types[arg_types[i]]}"
      end

      result << "fn #{exposed ? '' : 'internal_method_'}" \
        "#{method_name}(#{args.join(', ')}) -> " \
        "#{rust.rust_types[return_type]} {"
      result << rust_method_body(meta, ast)
      result << '}'

      result.join("\n")
    end

    def construct_signature(arg_types, return_type)
      args = arg_types.map do |arg|
        rust_type = rust.ffi_types[arg]
        unless rust_type
          puts "Please define mapping from '#{arg}' " \
            'to rust equivalent in rust.yaml'.colorize(:red)
          raise 'Missing mapping'
        end
        rust_type.to_sym
      end
      [
        args.map { |arg| arg == :pointer ? [arg, :int] : arg }.flatten,
        rust.ffi_types[return_type].to_sym
      ]
    end
  end
end
