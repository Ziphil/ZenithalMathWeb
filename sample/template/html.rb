# coding: utf-8


OPEN_TAG_NAMES = ["br", "img", "hr", "meta", "input", "embed", "area", "base", "link"]

converter.add(["html"], [""]) do |element|
  this = ""
  this << "<!DOCTYPE html>\n\n"
  this << pass_element(element, "html")
  next this
end

converter.add([//], ["html"]) do |element|
  close = !OPEN_TAG_NAMES.include?(element.name)
  this = pass_element(element, "html", close)
  next this
end

converter.add_default(nil) do |text|
  string = text.to_s.clone
  string.gsub!("、", "、 ")
  string.gsub!("。", "。 ")
  string.gsub!("「", " 「")
  string.gsub!("」", "」 ")
  string.gsub!("『", " 『")
  string.gsub!("』", "』 ")
  string.gsub!("〈", " 〈")
  string.gsub!("〉", "〉 ")
  string.gsub!(/(、|。)\s+(」|』)/){$1 + $2}
  string.gsub!(/(」|』|〉)\s+(、|。|,|\.)/){$1 + $2}
  string.gsub!(/(\(|「|『)\s+(「|『)/){$1 + $2}
  string.gsub!(/(^|>)\s+(「|『)/){$1 + $2}
  next string
end