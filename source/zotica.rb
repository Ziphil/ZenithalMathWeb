# coding: utf-8


module Zenithal

  ZOTICA_VERSION = "1.7.0"
  ZOTICA_VERSION_ARRAY = ZOTICA_VERSION.split(/\./).map(&:to_i)

end


require 'json'
require 'rexml/document'
require 'sassc'
require 'ttfunk'
require 'zenml'

require_relative 'zotica/builder'
require_relative 'zotica/parser'