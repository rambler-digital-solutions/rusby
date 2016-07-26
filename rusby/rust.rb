Dir['./generators/*.rb'].each { |file| require file }

module Rusby
  class Rust
    include ::Rusby::Generators::Base

    include ::Rusby::Generators::Assignments
    include ::Rusby::Generators::Conditionals
    include ::Rusby::Generators::Loops
    include ::Rusby::Generators::Misc
    include ::Rusby::Generators::Strings
    include ::Rusby::Generators::Types

    def initialize(return_type)
      @known_methods = []
      @known_variables = []
      @return_type = return_type
    end

    def known_method?(name)
      @known_methods.include?(name.to_sym)
    end

    def remember_method(name)
      @known_methods << name.to_sym
    end

    def known_variable?(name)
      @known_variables.include?(name.to_sym)
    end

    def remember_variable(name)
      @known_variables << name.to_sym
    end

    def fold_arrays(nodes)
      result = []
      index_op = false
      index_assignment_op = false

      nodes.each do |node|
        case node
        when :[]
          index_op = true
        when :[]=
          index_assignment_op = true
        else
          code = generate(node)
          if index_op
            code = "[#{code.to_s =~ /[+-]/ ? "(#{code})" : code} as usize]"
            index_op = false
          end
          if index_assignment_op
            code = "[#{code.to_s =~ /[+-]/ ? "(#{code})" : code} as usize]="
            index_assignment_op = false
          end
          result << code
        end
      end

      result
    end

    def method_missing(method_name, *args)
      puts "No method for '#{method_name.to_s.sub('generate_', '')}' AST node.".colorize(:red)
      puts "Please implement #{method_name} in Rusby::Rust.".colorize(:yellow)
      puts "Arguments: #{args.inspect}".colorize(:yellow)
      raise RuntimeError
    end
  end
end
