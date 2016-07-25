module Rusby
  module Generators
    module Misc
      def generate_begin(ast)
        ast.children.map { |node| generate(node) }.join("\n")
      end

      def generate_args(_ast)
      end

      def generate_return(ast)
        ri = ast.children.map { |node| generate(node) }
        "return #{ri.any? ? ri.join(',') : '&-ptr'};"
      end

      def generate_kwbegin(ast)
        ri = ast.children.map { |node| generate(node) }
        ri.join(';')
      end
    end
  end
end
