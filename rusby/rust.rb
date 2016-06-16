module Rusby
  class Rust
    def initialize
      @locals = []
    end

    def set_locals(*args)
      @locals = args.map(&:to_sym)
    end

    def flush_locals(*args)
      @locals |= args.map(&:to_sym)
    end

    def generate(ast)
      return ast unless ast.respond_to?(:type)
      result = send("generate_#{ast.type.to_s.tr('-', '_')}", ast)
    end

    def generate_begin(ast)
      ast.children.map { |node| generate(node) }.join("\n")
    end

    def generate_args(_ast)
    end

    def generate_if(ast)
      inverted = ast.children[2]
      condition = generate(ast.children[0])
      condition = "!(#{condition})" if inverted
      bulk = inverted ? ast.children[2] : ast.children[1]
      "if #{condition} {\n#{generate(bulk)}\n}"
    end

    def generate_send(ast)
      if ast.children[0]
        ast.children.map { |node| generate(node) }.join(' ')
      else
        ri = ast.children[2..-1].map { |node| generate(node) }
        result = "#{ast.children[1]}(#{ri.join(', ')});"
        result = 'internal_method_' + result unless @locals.include?(ast.children[1])
        result
      end
    end

    def generate_lvasgn(ast)
      return ast.children[0] if ast.children.size == 1
      result = "#{ast.children[0]} = #{generate(ast.children[1])};"
      unless @locals.include? ast.children[0]
        result = "let mut " + result
        @locals << ast.children[0]
      end
      result
    end

    def generate_lvar(ast)
      generate(ast.children[0])
    end

    def generate_int(ast)
      ast.children[0]
    end

    def generate_return(ast)
      ri = ast.children.map { |node| generate(node) }
      "return #{ri.join(',')};"
    end

    def generate_block(ast)
      block_operator = ast.children[0].children[1]
      ri = ast.children[1..-1].map { |node| generate(node) }.compact
      case block_operator
      when :loop
        "loop {\n#{ri.join("\n")}\n}"
      else
        "#{ast.children[0].children[1]} {\n#{ri.join("\n")}\n}"
      end
    end

    def generate_while(ast)
      "while #{generate(ast.children[0])} {\n#{generate(ast.children[1])}\n}"
    end

    def generate_while_post(ast)
      "while {\n#{generate(ast.children[1])};\n#{generate(ast.children[0])}\n}{}"
    end

    def generate_masgn(ast)
      left = ast.children[0].children
      right = ast.children[1].children

      result = []
      result += right.each_with_index.map do |_statement, i|
        "let lv#{i} = #{generate(right[i])};"
      end
      result += left.each_with_index.map do |statement, i|
        "#{generate(statement)} = lv#{i};"
      end
      result.join("\n")
    end

    def generate_kwbegin(ast)
      ri = ast.children.map { |node| generate(node) }
      ri.join(';')
    end

    def generate_true(_ast)
      'true'
    end

    def generate_false(_ast)
      'false'
    end

    def generate_array(_ast)
      'Vec::new()'
    end

    def generate_op_asgn(ast)
      "#{generate(ast.children[0])} #{ast.children[1]}= #{generate(ast.children[2])}"
    end
  end
end
