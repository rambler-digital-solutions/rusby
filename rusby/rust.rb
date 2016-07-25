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

    def initialize(meta)
      @known_methods = []
      @known_variables = []
      @meta = meta
    end

    def recollect_method?(name)
      method_name = name.to_sym
      result = @known_methods.include?(method_name)
      @known_methods << method_name
      result
    end
    alias remember_method recollect_method?

    def recollect_variable?(name)
      variable = name.to_sym
      result = @known_methods.include?(variable)
      @known_variables << variable
      result
    end
    alias remember_variable recollect_variable?

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
            code = "[#{code}]"
            index_op = false
          end
          if index_assignment_op
            code = "[#{code}]="
            index_assignment_op = false
          end
          result << code
        end
      end

      result.join
    end

    def method_missing(method_name, *args)
      puts "No method for '#{method_name.to_s.sub('generate_', '')}' AST node.".colorize(:red)
      puts "Please implement #{method_name} in Rusby::Rust.".colorize(:yellow)
      puts "Arguments: #{args.inspect}".colorize(:yellow)
      raise RuntimeError
    end
  end
end
