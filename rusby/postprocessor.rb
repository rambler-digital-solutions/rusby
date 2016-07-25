module Rusby
  module Postrocessor
    extend self

    def apply(code)
      # fold the array syntax
      code = code.gsub(/(\w+) \[\] (\w+)/, '\1[\2]')
      code = code.gsub(/(\w+) \[\]= (\w+) =/, '\1[\2] =')
      code
    end
  end
end
