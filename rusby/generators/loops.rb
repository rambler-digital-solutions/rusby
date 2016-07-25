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
        range_start = range.children[0].children[0]
        range_end = "(#{range.children[1].children[0]} + 1)" # rust range is inclusive
        range_variable = ast.children[1].children[0].children[0]

        "for #{range_variable} in #{range_start}..#{range_end} {\n#{ri.join("\n")}\n}"
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
