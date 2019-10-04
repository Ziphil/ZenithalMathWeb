# coding: utf-8


parser.register_math_macro("m") do |attributes, children_list|
  this = Nodes[]
  this << children_list.first
  next this
end

parser.register_math_macro("mb") do |attributes, children_list|
  this = Nodes[]
  this << Element.build("span") do |this|
    this["class"] = "display-math"
    this << children_list.first
  end
  next this
end