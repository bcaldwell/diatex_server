#\ -s puma

$LOAD_PATH.unshift File.dirname(__FILE__)

require 'rubygems'
require 'bundler'

Bundler.require

require 'config/application'

require 'server'
run Diatex
