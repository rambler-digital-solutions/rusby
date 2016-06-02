require 'method_source'
require 'parser/current'

Parser::Builders::Default.emit_lambda = true # opt-in to most recent AST format

module Rusby
  module Builder
    extend self

    TYPES = {
      'Fixnum' => 'i64'
    }.freeze

    STYPES = {
      'Fixnum' => 'int'
    }.freeze

    def method_to_rust(ast, arg_types, return_type)
      result = [
        '#[no_mangle]'
      ]

      name = ast.children.first
      args = ast.children[1].children.each_with_index.map do |child, i|
        "#{child.children[0]}: #{TYPES[arg_types[i].to_s]}"
      end

      result << "pub extern \"C\" fn #{name}(#{args.join(', ')}) -> #{TYPES[return_type.to_s]} {"

      ast.children[2..-1].each do |node|
        ast_to_rust(node, result)
      end

      result << '}'

      signature = "#{STYPES[return_type.to_s]} #{name}(#{arg_types.map { |arg| STYPES[arg.to_s] }.join(', ')})"
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
