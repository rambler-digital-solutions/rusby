module Rusby
  module Generators
    module Conditionals
      def generate_if(ast)
        inverted = ast.children[2]
        condition = generate(ast.children[0])
        condition = "!(#{condition})" if inverted
        bulk = inverted ? ast.children[2] : ast.children[1]
        "if #{condition} {\n#{generate(bulk)}\n}"
      end
    end
  end
end
