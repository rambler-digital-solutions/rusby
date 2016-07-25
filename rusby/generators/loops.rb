module Rusby
  module Generators
    module Loops
      def generate_loop(ast)
        ri = ast.children[1..-1].map { |node| generate(node) }.compact
        "loop {\n#{ri.join("\n")}\n}"
      end

      def generate_each_loop(ast)
        # only works with numeric range e.g. (1..10).each {|i| ...}
        ri = ast.children[1..-1].map { |node| generate(node) }.compact
        range = ast.children[0].children[0].children[0]
        "for #{ast.children[1].children[0].children[0]} in #{range.children[0].children[0]}..#{range.children[1].children[0]} {\n#{ri.join("\n")}\n}"
      end

      def generate_while(ast)
        "while #{generate(ast.children[0])} {\n#{generate(ast.children[1])}\n}"
      end

      def generate_while_post(ast)
        "while {\n#{generate(ast.children[1])};\n#{generate(ast.children[0])}\n}{}"
      end
    end
  end
end
