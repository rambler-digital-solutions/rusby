module Rusby
  module Postrocessor
    extend self

    def apply(code, meta)
      # fold the array syntax
      meta[:args].each_with_index do |el, idx|
        if el == 'String'
          code.gsub!(/#{meta[:names][idx]}\[(.+?)\]/, "#{meta[:names][idx]}.chars().nth(\\1)")
          code.gsub!(/;+/, ';')
        end
      end
      # process array :<< and :>> operator
      code.gsub!(/(?:<<|>>)(\S+)/, '.push(\1);')

      code
    end
  end
end
