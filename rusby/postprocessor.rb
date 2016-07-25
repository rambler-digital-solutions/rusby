module Rusby
  module Postrocessor
    extend self

    def apply(code, meta)
      # fold the array syntax
      meta[:args].each_with_index do |el, idx|
        if el == 'String'
          code = code.gsub(/#{meta[:names][idx]}\[(.+?)\]/, "#{meta[:names][idx]}.chars().nth(\\1)")
        end
      end
      code
    end
  end
end
