module Rusby
  module Preprocessor
    extend self

    def apply(code)
      code = code.gsub(
        /(\w+)\s?=\s?Array\.new\((.*)\)\s?{\s?Array\.new\((.*)\)\s?}/,
        'rust_variable :\1' \
        "\n" \
        'rust "let mut \1 = vec![vec![0; \3]; \2];"'
      )
      code
    end
  end
end
