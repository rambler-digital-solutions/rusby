module Rusby
  module Generators
    module Strings
      # string interpolation
      def generate_dstr(ast)
        ast.children.map { |node| "(#{generate(node)}).to_string()" }.join(' + &')
      end
    end
  end
end
