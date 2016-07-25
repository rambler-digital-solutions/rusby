module Rusby
  module Preprocessor
    extend self

    def apply(code)
      code = code.gsub(
        /(\w+)\s?=\s?Array\.new\((.*)\)\s?{\s?Array\.new\((.*)\)\s?}/,
        'rust_variable :\1' \
        "\n" \
        'rust "\1 = array[\2][\3];"'
      )
      code
    end
  end
end
