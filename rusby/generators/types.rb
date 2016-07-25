module Rusby
  module Generators
    module Types
      def generate_int(ast)
        ast.children[0]
      end

      def generate_str(ast)
        "\"#{ast.children[0]}\""
      end

      def generate_true(_ast)
        'true'
      end

      def generate_false(_ast)
        'false'
      end

      def generate_array(_ast)
        'Vec::new()'
      end

      def generate_const(ast)
        '<array>' if ast.children[1] == :Array
      end
    end
  end
end
