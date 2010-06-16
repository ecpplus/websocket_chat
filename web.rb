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
  @message = '部屋名と名前は必須です。' if params[:nodata] == '1'
  erb :index
end

post '/' do
  erb :index
end

post '/room' do
  if params[:title] =~ /^\s*$/ || params[:user] =~ /^\s*$/
    redirect '/?nodata=1'
  end

  @room = CGI.escape(ERB::Util.h(params[:title]))
  @user = CGI.escape(ERB::Util.h(params[:user]))
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
