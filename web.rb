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

  @room_name = ERB::Util.h(params[:title])
  @room = CGI.escape(ERB::Util.h(params[:title]))
  @user = CGI.escape(ERB::Util.h(params[:user]))
  erb :room
end

get '/room' do
  redirect '/'
end

post '/save' do
  content_type :png
  send_data request.body.read 
  #send_file 'web.rb'
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

  message = " お絵かきしたよ！ " + "http://" + request.host + '/show/' + filename + ' #paintchat '
  {:plain => message, :encoded => URI.encode(message)}.to_json
end

get '/show/:filename' do
  @filename = params[:filename]
  erb :show
end
