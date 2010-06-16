require 'rubygems'
require 'cgi'
require 'json'
require 'base64'
require 'sinatra'
#require 'sinatra/base'
require 'thin'
require 'logger'
# coding: utf8
require 'tokyocabinet'
include TokyoCabinet

tdb = TDB.new

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
end

post '/twitter' do
  tdb.open('db/data.tct', TDB::OWRITER | TDB::OCREAT) # データの保存先指定など
  filename = tdb.addint('max_id', 1).to_i.to_s(36)
  tdb.close
  File.open('public/i/' + filename, 'w') do |f|
    f.write Base64.decode64(request.body.read.split(',')[1])
  end

  '/show/' + filename
end

get '/show/:filename' do
  @filename = params[:filename]
  erb :show
end
