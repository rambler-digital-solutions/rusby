module Rusby
  module Generators
    module Conditionals
      def generate_if(ast)
        result = <<-EOF
          if #{generate(ast.children[0])} {
            #{generate(ast.children[1])}
          }
        EOF
        if ast.children[2]
          result += <<-EOF
            else {
              #{generate(ast.children[2])}
            }
          EOF
        end
        result.strip
      end
    end
  end
end
