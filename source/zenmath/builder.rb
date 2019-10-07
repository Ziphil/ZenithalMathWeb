# coding: utf-8


require 'json'
require 'pp'
require 'rexml/document'
include REXML


module ZenmathBuilder

  DATA_PATH = "resource/math.json"
  DATA = JSON.parse(File.read(File.expand_path("../" + DATA_PATH, __FILE__)))

  private

  def create_math_element(name, attributes, children_list)
    nodes = Nodes[]
    case name
    when DATA["paren"].method(:key?)
      stretch_level = attributes["s"]
      nodes = ZenmathBuilder.build_paren(name, stretch_level) do |content_element|
        content_element << children_list[0]
      end
    when DATA["integral"].method(:key?)
      nodes = ZenmathBuilder.build_integral(name) do |subscript_element, superscript_element|
        subscript_element << children_list[0]
        superscript_element << children_list[1]
      end
    when DATA["function"].method(:include?)
      nodes = ZenmathBuilder.build_identifier(name, true)
    when DATA["identifier"].method(:key?)
      symbol = DATA["identifier"].fetch(name, "")
      nodes = ZenmathBuilder.build_identifier(symbol, false)
    when DATA["operator"].method(:key?)
      symbol, kinds = DATA["operator"].fetch(name, [name, ["bin"]])
      nodes = ZenmathBuilder.build_operator(symbol, kinds)
    when "n"
      number = children_list[0].first.to_s
      nodes = ZenmathBuilder.build_number(number)
    when "i"
      name = children_list[0].first.to_s
      nodes = ZenmathBuilder.build_identifier(name, false)
    when "op"
      name = children_list[0].first.to_s
      nodes = ZenmathBuilder.build_identifier(name, true)
    when "o"
      name = children_list[0].first.to_s
      nodes = ZenmathBuilder.build_operator(name, ["bin"])
    when "sb"
      nodes = ZenmathBuilder.build_subsuperscript do |base_element, subscript_element, superscript_element|
        base_element << children_list[0]
        subscript_element << children_list[1]
      end
    when "sp"
      nodes = ZenmathBuilder.build_subsuperscript do |base_element, subscript_element, superscript_element|
        base_element << children_list[0]
        superscript_element << children_list[1]
      end
    when "sbsp"
      nodes = ZenmathBuilder.build_subsuperscript do |base_element, subscript_element, superscript_element|
        base_element << children_list[0]
        subscript_element << children_list[1]
        superscript_element << children_list[2]
      end
    when "un"
      nodes = ZenmathBuilder.build_underoverscript do |base_element, underscript_element, overscript_element|
        base_element << children_list[0]
        underscript_element << children_list[1]
      end
    when "ov"
      nodes = ZenmathBuilder.build_underoverscript do |base_element, underscript_element, overscript_element|
        base_element << children_list[0]
        overscript_element << children_list[1]
      end
    when "unov"
      nodes = ZenmathBuilder.build_underoverscript do |base_element, underscript_element, overscript_element|
        base_element << children_list[0]
        underscript_element << children_list[1]
        overscript_element << children_list[2]
      end
    when "frac"
      nodes = ZenmathBuilder.build_fraction do |numerator_element, denominator_element|
        numerator_element << children_list[0]
        denominator_element << children_list[1]
      end
    when "sqrt"
      stretch_level = attributes["s"]
      nodes = ZenmathBuilder.build_radical(stretch_level) do |content_element|
        content_element << children_list[0]
      end
    when "bb", "scr", "frak"
      alphabets = children_list[0].first.value
      symbol = alphabets.chars.map{|s| DATA["alternative"][name].fetch(s, "")}.join
      nodes = ZenmathBuilder.build_identifier(symbol, false, true)
    end
    return nodes
  end

  def create_math_text(text)
    this = Nodes[]
    text.each_char do |char|
      if char =~ /\d/
        this << ZenmathBuilder.build_number(char)
      elsif char =~ /[[:alpha:]]/
        this << ZenmathBuilder.build_identifier(char, false)
      elsif char !~ /\s/
        name = DATA["operator"].find{|s, (t, u)| char == t}&.first || char
        name = DATA["replacement"].fetch(name, name)
        symbol, kinds = DATA["operator"].fetch(name, [name, ["bin"]])
        this << ZenmathBuilder.build_operator(symbol, kinds)
      end
    end
    return this
  end

  def create_math_escape(char)
    next_char = char
    if DATA["greek"].key?(char)
      next_char = DATA["greek"][char]
    end
    return next_char
  end

  public

  def self.build_number(number)
    this = Nodes[]
    this << Element.build("math-n") do |this|
      this << Text.new(number, true, nil, false)
    end
    return this
  end

  def self.build_identifier(name, function = false, alternative = false)
    this = Nodes[]
    this << Element.build("math-i") do |this|
      if function
        this["class"] += " fun"
      end
      if alternative
        this["class"] += " alt"
      end
      this << Text.new(name, true, nil, false)
    end
    return this
  end

  def self.build_operator(symbol, kinds, &block)
    this = Nodes[]
    this << Element.build("math-o") do |this|
      this["class"] = kinds.join(" ")
      this << Text.new(symbol, true, nil, false)
    end
    return this
  end

  def self.build_subsuperscript(&block)
    this = Nodes[]
    base_element, subscript_element, superscript_element = nil
    this << Element.build("math-subsup") do |this|
      this << Element.build("math-base") do |this|
        base_element = this
      end
      this << Element.build("math-sub") do |this|
        subscript_element = this
      end
      this << Element.build("math-sup") do |this|
        superscript_element = this
      end
    end
    block&.call(base_element, subscript_element, superscript_element)
    return this
  end

  def self.build_underoverscript(&block)
    this = Nodes[]
    base_element, underscript_element, overscript_element = nil
    this << Element.build("math-underover") do |this|
      this << Element.build("math-over") do |this|
        overscript_element = this
      end
      this << Element.build("math-basewrap") do |this|
        this << Element.build("math-base") do |this|
          base_element = this
        end
        this << Element.build("math-under") do |this|
          underscript_element = this
        end
      end
    end
    block&.call(base_element, underscript_element, overscript_element)
    return this
  end

  def self.build_fraction(&block)
    this = Nodes[]
    numerator_element, denominator_element = nil
    this << Element.build("math-frac") do |this|
      this << Element.build("math-num") do |this|
        numerator_element = this
      end
      this << Element.build("math-denwrap") do |this|
        this << Element.build("math-den") do |this|
          denominator_element = this
        end
      end
    end
    block&.call(numerator_element, denominator_element)
    return this
  end

  def self.build_radical(stretch_level, &block)
    this = Nodes[]
    content_element = nil
    this << Element.build("math-sqrt") do |this|
      this << Element.build("math-surd") do |this|
        if stretch_level
          this["class"] = "s#{stretch_level}" 
          symbol = DATA["radical"].fetch(stretch_level, "")
        else
          symbol = DATA["radical"]["0"]
        end
        this << Element.build("math-o") do |this|
          this << Text.new(symbol, true, nil, false)
        end
      end
      this << Element.build("math-sqrtcont") do |this|
        unless stretch_level
          this["class"] = "md-sqrt"
        end
        content_element = this
      end
    end
    block&.call(content_element)
    return this
  end

  def self.build_paren(kind, stretch_level, &block)
    this = Nodes[]
    content_element = nil
    this << Element.build("math-paren") do |this|
      if stretch_level
        left_symbol, right_symbol = DATA["paren"][kind].fetch(stretch_level, ["", ""])
      else
        left_symbol, right_symbol = DATA["paren"][kind].fetch("0", ["", ""])
      end
      this << Element.build("math-o") do |this|
        this["class"] = "lp"
        this << Text.new(left_symbol, true, nil, false)
      end
      this << Element.build("math-parencont") do |this|
        unless stretch_level
          this["class"] = "md-paren md-paren-#{kind}"
        end
        content_element = this
      end
      this << Element.build("math-o") do |this|
        this["class"] = "rp"
        this << Text.new(right_symbol, true, nil, false)
      end
    end
    block&.call(content_element)
    return this
  end

  def self.build_integral(kind, &block)
    this = Nodes[]
    subscript_element, superscript_element = nil
    this << Element.build("math-subsup") do |this|
      this["class"] = "int"
      this << Element.build("math-base") do |this|
        this << Element.build("math-o") do |this|
          this["class"] = "int"
          symbol = DATA["integral"][kind][1]
          this << Text.new(symbol, true, nil, false)
        end
      end
      this << Element.build("math-sub") do |this|
        subscript_element = this
      end
      this << Element.build("math-sup") do |this|
        superscript_element = this
      end
    end
    block&.call(subscript_element, superscript_element)
    return this
  end

  def self.build_text(&block)
    this = Nodes[]
    text_element = nil
    this << Element.build("math-text") do |this|
      text_element = this
    end
    block&.call(text_element)
    return this
  end

end