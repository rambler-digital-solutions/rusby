module Rusby
  module Postrocessor
    extend self

    def apply(code)
      # fold the array syntax
      code = code.gsub(/(\w+) \[\] (\w+)/, '\1[\2 as usize]')
      code = code.gsub(/(\w+) \[\]= (\w+) =/, '\1[\2 as usize] =')
      code
    end
  end
end
