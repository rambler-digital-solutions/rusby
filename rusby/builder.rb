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

    def convert_to_rust(name, orig_method, result, *args)
      ast = Parser::Ruby22.parse(orig_method.source)
      signature, code = Builder.method_to_rust(ast, args.map(&:class), result.class)
      instance_variable_set("@rusby_runs_#{name}", signature)
      File.open("#{root_path}/lib/#{name}.rs", 'w') { |file| file.write(code) }

      puts "Compiling #{signature.last} #{name}(#{signature.first.join(', ')})..."
      puts `rustc --crate-type=dylib -O -o #{root_path}/lib/#{name}.dylib #{root_path}/lib/#{name}.rs`

      Proxy.rusby_load "#{root_path}/lib/#{name}"
      Proxy.attach_function name, *signature

      Proxy.method(name)
    end

    def method_to_rust(ast, arg_types, return_type)
      result = rust.method_declaration_prefix

      name = ast.children.first
      args = ast.children[1].children.each_with_index.map do |child, i|
        "#{child.children[0]}: #{rust.types[arg_types[i]]}"
      end

      result << "#{rust.method_prefix} #{name}(#{args.join(', ')}) -> #{rust.types[return_type]} {"

      ast.children[2..-1].each do |node|
        ast_to_rust(node, result)
      end

      result << '}'

      signature = [arg_types.map { |arg| rust.c_types[arg] }, rust.c_types[return_type]]
      [signature, result.join("\n")]
    end

    private

    def ast_to_rust(ast, result)
      unless ast.respond_to? :type
        result << ast
        return
      end

      case ast.type
      when :send
        r2 = []
        ast.children.each do |node|
          ast_to_rust(node, r2)
        end
        result << r2.join(' ')
      when :lvar
        ast_to_rust(ast.children[0], result)
      when :int
        ast_to_rust(ast.children[0], result)
      end
    end
  end
end
