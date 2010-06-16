require 'rubygems'
require 'cgi'
require 'json'
require 'base64'
require 'sinatra'
#require 'sinatra/base'
require 'thin'
require 'logger'
# coding: utf8

get '/' do
  erb :index
end

post '/' do
  erb :index
end

post '/room' do
  @room = CGI.escape(params[:title])
  @user = CGI.escape(params[:user])
  erb :room
end

get '/room' do
  redirect '/'
end

post '/upload' do
  Base64.encode64(request.body.read)
  #p request.methods.sort
  #p request.raw_data
end
