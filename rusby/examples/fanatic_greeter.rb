class FanaticGreeter
  extend Rusby::Core

  rusby!
  def greet(name)
    "Hello, #{name}!"
  end
end
