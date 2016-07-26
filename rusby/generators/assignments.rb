module Rusby
  module Generators
    module Assignments
      def generate_lvasgn(ast)
        variable = ast.children[0]
        return variable if ast.children.size == 1

        result = "#{variable} = #{generate(ast.children[1])};"
        result = "let mut #{result}" unless known_variable?(variable)
        remember_variable(variable)

        result
      end

      def generate_lvar(ast)
        variable = ast.children[0]
        variable
      end

      def generate_masgn(ast)
        left = ast.children[0].children
        right = ast.children[1].children

        result = []
        result += right.each_with_index.map do |_statement, i|
          "let lv#{i} = #{generate(right[i])};"
        end
        result += left.each_with_index.map do |statement, i|
          statement = generate(statement)
          "#{statement =~ /=$/ ? statement : "#{statement} = "}lv#{i};"
        end
        result.join("\n")
      end

      def generate_op_asgn(ast)
        "#{generate(ast.children[0])} #{ast.children[1]}= #{generate(ast.children[2])}"
      end
    end
  end
end
