require 'byebug'
require 'method_source'
require 'parser/current'
require "fiddle"
require "fiddle/import"


def libext
  return "dylib" if `uname` =~ /Darwin/
  return "so" if `uname` =~ /Linux/
end

module Rusty
  extend Fiddle::Importer
end

Parser::Builders::Default.emit_lambda = true # opt-in to most recent AST format

module Rs
  def method_added(name)
    super
    return unless @rs_engage
    @rs_engage = false
    orig_method = instance_method(name)
    Rusty::dlload "./lib/lib#{name}.#{libext}"
    define_method(name) do |*args, &blk|
      # Rusty.extern "int plusplus(int)"
      # Rusty.send(name, *args)

      result = orig_method.bind(self).call(*args, &blk)
      self.class.rusty(name, orig_method, result, *args, &blk)
      result
    end
  end


  def ast_to_rust(ast, result)
    puts "-> processing #{ast}"
    unless ast.respond_to? :type
      result << ast
      return
    end

    case ast.type
    when :def
      args = ast.children[1].children.map{|ch| ch.children[0].to_s + ': ???'}.join(', ')
      result << "pub extern \"C\" fn #{ast.children.first}(#{args}) -> ??? {"
      ast.children[2,10].each do |node|
        ast_to_rust(node, result)
      end
      result << "}"
    when :send
      r2 = []
      ast.children.each do |node|
        ast_to_rust(node, r2)
      end
      result << r2.join(" ")
    when :lvar
      ast_to_rust(ast.children[0], result, )
    when :int
      ast_to_rust(ast.children[0], result)
    end
  end

  def rusty(name, orig_method, result, *args)
    puts orig_method.source
    ast = Parser::CurrentRuby.parse(orig_method.source)
    puts "All done"
    result = ["#[no_mangle]"]
    ast_to_rust(ast, result)
    puts result.join("\n")
    puts "rusty called for #{name} with #{args.map(&:class)} -> #{result.class}"
    result
  end

  def rustify_method
    @rs_engage = true
  end

  def singleton_method_added(name)
    # TBD
  end
end

class MySomething
  extend Rs

  rustify_method
  def plusplus(number)
    number + 1
  end

  def minusminus
  end

  # def self.minusminus(number)
  #   number + 1
  # end
end

ms = MySomething.new
# byebug
puts ms.plusplus(1)
puts ms.minusminus
