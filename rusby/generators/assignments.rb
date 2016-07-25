module Rusby
  module Generators
    module Assignments
      def generate_lvasgn(ast)
        return ast.children[0] if ast.children.size == 1
        result = "#{ast.children[0]} = #{generate(ast.children[1])};"
        unless @known_variables.include? ast.children[0]
          result = 'let mut ' + result
          @known_variables << ast.children[0]
        end
        result
      end

      def generate_lvar(ast)
        generate(ast.children[0])
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

      def generate_op_asgn(ast)
        "#{generate(ast.children[0])} #{ast.children[1]}= #{generate(ast.children[2])}"
      end
    end
  end
end
