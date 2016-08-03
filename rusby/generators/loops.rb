module Rusby
  module Generators
    module Loops
      def generate_loop(ast)
        statements = ast.children[1..-1].map { |node| generate(node) }.compact
        "loop {\n#{statements.join("\n")}\n}"
      end

      def generate_each_loop(ast)
        if ast.children[0].children[0].type == :lvar
          generate_each_loop_plain(ast)
        else
          generate_each_loop_range(ast)
        end
      end

      def generate_each_loop_plain(ast)
        collection = ast.children[0].children[0].children[0]
        variable = ast.children[1].children[0].children[0]
        body = ast.children[2..-1].map{|node| generate(node)}.join("\n")
        "for #{variable} in #{collection} {
          #{body}
        }"
      end

      def generate_each_with_index_loop(ast)
        collection = ast.children[0].children[0].children[0]
        variable = ast.children[1].children[0].children[0]
        index = ast.children[1].children[1].children[0]
        body = ast.children[2..-1].map{|node| generate(node)}.join("\n")
        "for (#{index}, #{variable}) in #{collection}.iter().enumerate() {
          #{body}
        }"
      end

      def generate_each_loop_range(ast)
        range = ast.children[0].children[0].children[0]
        range_start = range.children[0].children[0]
        range_end = "(#{range.children[1].children[0]} + 1)" # rust range is inclusive
        range_variable = ast.children[1].children[0].children[0]
        statements = ast.children[1..-1].map { |node| generate(node) }.compact
        "for #{range_variable} in #{range_start}..#{range_end} {\n#{statements.join("\n")}\n}"
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
