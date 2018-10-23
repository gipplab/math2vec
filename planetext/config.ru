# Gemfile
require 'bundler/setup'
require 'sinatra'
require_relative 'app/planetext'
 
set :run, false
set :raise_errors, true
 
run PlaneText::App
