require_relative("interpreter")

puts "Welcome to the REPL"

interpreter = Interpreter.new
res = true

while res

  print ">"
  input = gets.chomp
  begin
    res = interpreter.input(input)
    puts res
  rescue Interpreter::UndeclaredVariable => e
    puts e.message
  end
end

puts "Goodbye"
