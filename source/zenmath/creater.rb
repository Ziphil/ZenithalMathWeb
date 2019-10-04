# coding: utf-8


require 'pp'
require 'rexml/document'
include REXML


module ZenithalMathCreater

  include ZenithalMathCreaterConstant

  private

  def create_math_element(name, attributes, children_list)
    nodes = Nodes[]
    if PAREN_SYMBOLS.key?(name)
      nodes = send("create_paren", name, attributes, children_list)
    elsif INTEGRAL_SYMBOLS.key?(name)
      nodes = send("create_integral", name, attributes, children_list)
    elsif FUNCTIONS.include?(name)
      nodes = send("create_function", name, attributes, children_list)
    elsif OPERATORS.key?(name)
      nodes = send("create_operator", name, attributes, children_list)
    elsif CREATION_METHODS.key?(name)
      method_name = CREATION_METHODS[name]
      nodes = send("create_#{method_name}", name, attributes, children_list)
    end
    return nodes
  end

  def create_math_text(text)
    this = Nodes[]
    text.each_char do |char|
      if char =~ /\d/
        this << Element.build("math-n") do |this|
          this << Text.new(char, true, nil, false)
        end
      elsif char =~ /[[:alpha:]]/
        this << Element.build("math-i") do |this|
          this << Text.new(char, true, nil, false)
        end
      elsif char !~ /\s/
        this << Element.build("math-o") do |this|
          this << Text.new(char, true, nil, false)
        end
      end
    end
    return this
  end

  def create_math_escape(char)
    next_char = char
    if GREEKS.key?(char)
      next_char = GREEKS[char]
    end
    return next_char
  end

  def create_number(name, attributes, children_list)
    this = Nodes[]
    this << Element.build("math-n") do |this|
      this << children_list[0]
    end
    return this
  end

  def create_identifier(name, attributes, children_list)
    this = Nodes[]
    this << Element.build("math-i") do |this|
      this << children_list[0]
    end
    return this
  end

  def create_operator(name, attributes, children_list)
    this = Nodes[]
    this << Element.build("math-o") do |this|
      this << children_list[0]
    end
    return this
  end

  def create_superscript(name, attributes, children_list)
    this = Nodes[]
    this << Element.build("math-sup") do |this|
      this << Element.build("math-base") do |this|
        this << children_list[0]
      end
      this << Element.build("math-scr") do |this|
        this << children_list[1]
      end
    end
    return this
  end

  def create_fraction(name, attributes, children_list)
    this = Nodes[]
    this << Element.build("math-frac") do |this|
      this << Element.build("math-num") do |this|
        this << children_list[0]
      end
      this << Element.build("math-denwrap") do |this|
        this << Element.build("math-den") do |this|
          this << children_list[1]
        end
      end
    end
    return this
  end

  def create_radical(name, attributes, children_list)
    this = Nodes[]
    stretch_level = attributes["s"].to_i
    this << Element.build("math-sqrt") do |this|
      this << Element.build("math-surd") do |this|
        if stretch_level > 0
          this["class"] = "s#{stretch_level}"
        end
        this << Element.build("math-o") do |this|
          this << ~RADICAL_SYMBOLS.fetch(stretch_level, "")
        end
      end
      this << Element.build("math-sqrtcont") do |this|
        this << children_list[0]
      end
    end
    return this
  end

  def create_paren(name, attributes, children_list)
    this = Nodes[]
    stretch_level = attributes["s"].to_i
    this << Element.build("math-o") do |this|
      this["class"] = "lp"
      this << ~PAREN_SYMBOLS[name][stretch_level][0]
    end
    this << Element.build("math-row") do |this|
      this << children_list[0]
    end
    this << Element.build("math-o") do |this|
      this["class"] = "rp"
      this << ~PAREN_SYMBOLS[name][stretch_level][1]
    end
    return this
  end

end