require 'rubygems'
require 'cgi'
require 'json'
require 'sinatra'
#require 'sinatra/base'
require 'thin'
require 'logger'
# coding: utf8

get '/' do
  erb :index
end

post '/room' do
  @room = CGI.escape(params[:title])
  @user = CGI.escape(params[:user])
  erb :sample
end

get '/room' do
  redirect '/'
end
