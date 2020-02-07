require "pry"

require_relative "token"

TYPE_REGEXES = {
  number: /\d+\.?\d*/,
  identifier: /^(_|[a-zA-Z])\w*/,
  operator: /[\+\-\*\/%]/,
  assignment: /=/,
  paren: /[\(\)]/
}

PRECEDENCES = {
  nil => 0, # sentinel
  "(" => 0,
  "=" => 1,
  "+" => 2,
  "-" => 2,
  "*" => 3,
  "/" => 3,
  "%" => 3,
  ")" => 5
}

class Interpreter
  class UndeclaredVariable < StandardError
    def initialize(variable)
      @variable = variable
    end

    def message
      "Undefined variable '#{@variable}' called"
    end
  end

  def initialize
    @vars = {}
    @vars.default_proc = Proc.new { |_vars, key| raise UndeclaredVariable.new(key) }
    @functions = {}
    @tokens = []
  end

  def input(expr)
    @tokens = []
    return "" if expr == "quit" || expr =~ /^\s*$/
    @tokens = tokenize(expr)

    exec_tokens
  end

  private

  def tokenize(program)
    return [] if program == ''

    regex = /\s*([-+*\/\%=\(\)]|[A-Za-z_][A-Za-z0-9_]*|[0-9]*\.?[0-9]+)\s*/

    s_tokens = program.scan(regex).reject { |s| s =~ /^\s*$/ }.map(&:first)
    s_tokens.each do |s_token|
      @tokens << create_token(s_token)
    end

    @tokens
  end

  def exec_tokens
    opr = []
    opd = []
    @tokens.each do |token|
      opd.push(token) && next if [:number, :identifier].include?(token.type)

      if token.type == :paren
        manage_paren(opr, opd, token)
      else
        while PRECEDENCES[token.value] <= PRECEDENCES[opr.last&.value]
          exec_last_opr(opr, opd)
        end
        opr.push(token)
      end
    end

    exec_last_opr(opr, opd) while opr.any?
    result = opd.pop
    result.type == :identifier ? @vars[result.value] : result.value
  end

  def manage_paren(opr, opd, token)
    if token.value == "("
      opr.push(token)
    else
      exec_last_opr(opr, opd) while opr.last.value != "("
      opr.pop
    end
  end

  def exec_last_opr(opr, opd)
    vals = opd.pop(2)
    opr_to_exec = opr.pop
      if opr_to_exec.type == :assignment

        # Save new variable to @vars
        @vars[vals.first.value] = vals.last.value
        opd.push(vals.last)
      elsif opr_to_exec.type == :paren

      else
        # Transform vals tokens to actual numbers
        # TODO here: if @vars doesnt have the identifier, raise error
        numbers = vals.map do |val|
          val.type == :identifier ? @vars[val.value] : val.value
        end
        new_val = numbers.first.to_f.send(opr_to_exec.value, numbers.last)
        opd.push(Token.new(:number, new_val))
      end
  end

  def create_token(s_token)
    type = TYPE_REGEXES.find { |_type, regex| s_token.match(regex) }&.first

    raise SyntaxError if type.nil?
    s_token = s_token.to_f if type == :number
    Token.new(type, s_token)
  end
end
