module Rusby
  module Generators
    module Strings
      # string interpolation
      def generate_dstr(ast)
        ast.children.map do |node|
          "(#{generate(node)}).to_string()"
        end.join(' + &')
      end
    end
  end
end
