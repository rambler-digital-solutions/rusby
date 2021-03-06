module Rusby
  module Generators
    module Misc
      def generate_begin(ast)
        ast.children.map { |node| generate(node) }.join("\n")
      end

      def generate_args(_ast)
      end

      def generate_and(ast)
        "#{generate(ast.children[0])} && #{generate(ast.children[1])}"
      end

      def generate_return(ast)
        statements = ast.children.map { |node| generate(node) }
        "return #{statements.any? ? statements.join(',') : '&-ptr'}" \
          " as #{@return_type};"
      end

      def generate_kwbegin(ast)
        statements = ast.children.map { |node| generate(node) }
        statements.join(';')
      end
    end
  end
end
