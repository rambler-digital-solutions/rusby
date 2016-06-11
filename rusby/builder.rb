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

    def convert_to_rust(name, orig_method, owner, result, *args)
      ast = Parser::Ruby22.parse(orig_method.source)
      p ast
      signature, code = Builder.method_to_rust(ast, args.map(&:class), result.class)
      puts code
      # Builder.inline_methods(code, owner)
      return

      File.open("#{root_path}/lib/#{name}.rs", 'w') { |file| file.write(code) }
      puts "Compiling #{signature.last} #{name}(#{signature.first.join(', ')})..."
      puts `rustc --crate-type=dylib -O -o #{root_path}/lib/#{name}.dylib #{root_path}/lib/#{name}.rs`

      # Proxy.rusby_load "#{root_path}/lib/#{name}"
      # Proxy.attach_function name, *signature
      #
      # Proxy.method(name)
    end

    def inline_methods(code, owner)
      code.gsub(%r{/\*inline\((.+?)\)\*/}) do
        inline_method_to_rust(owner.method($1).source)
      end
    end

    def inline_method_to_rust(source)
      ast = Parser::Ruby22.parse(source)
      puts ast_to_rust(ast.children[2])
    end

    def method_to_rust(ast, arg_types, return_type)
      result = rust.method_declaration_prefix

      name = ast.children.first
      @method_name = name
      args = ast.children[1].children.each_with_index.map do |child, i|
        "#{child.children[0]}: #{rust.types[arg_types[i]]}"
      end

      result << "#{rust.method_prefix} #{name}(#{args.join(', ')}) -> #{rust.types[return_type]} {"

      ast.children[2..-1].each do |node|
        result << ast_to_rust(node)
      end

      result << '}'

      signature = [arg_types.map { |arg| rust.c_types[arg] }, rust.c_types[return_type]]
      [signature, result.join("\n")]
    end

    private

    def ast_to_rust(ast)
      return ast unless ast.respond_to?(:type)

      case ast.type
      when :begin
        ast.children.map { |node| ast_to_rust(node) }.join("\n")
      when :if
        inverted = ast.children[2]
        condition = ast_to_rust(ast.children[0])
        condition = "!(#{condition})" if inverted
        bulk = inverted ? ast.children[2] : ast.children[1]
        "if #{condition} {\n#{ast_to_rust(bulk)}\n}"
      when :send
        if ast.children[0]
          ast.children.map { |node| ast_to_rust(node)}.join(' ')
        else
          ri = ast.children[2..-1].map { |node| ast_to_rust(node)}
          if @method_name == ast.children[1]
            "#{ast.children[1]}(#{ri.join(', ')});"
          else
            "/*inline(#{ast.children[1]})*/"
          end
        end
      when :lvasgn
        "let #{ast.children[0]} = #{ast_to_rust(ast.children[1])};"
      when :lvar
        ast_to_rust(ast.children[0])
      when :int
        ast_to_rust(ast.children[0])
      when :return
        ri = ast.children.map { |node| ast_to_rust(node)}
        "return #{ri.join(',')};"
      when :block
        ri = ast.children[1..-1].map { |node| ast_to_rust(node)}
        "#{ast.children[0].children[1]} { #{ri.join("\n")} }"
      when :while_post
        "{#{ast_to_rust(ast.children[1])}} while #{ast_to_rust(ast.children[0])};\n"
      when :masgn
        left = ast.children[0].children
        right = ast.children[1].children

        result = []
        result += left.each_with_index.map do |statement, i|
          "let lv#{i} = #{ast_to_rust(right[i])};"
        end
        result += left.each_with_index.map do |statement, i|
            "#{ast_to_rust(statement)} = lv#{i};"
        end
        result.join("\n")
      when :kwbegin
        ri = ast.children.map { |node| ast_to_rust(node)}
        ri.join(';')
      end
    end
  end
end
