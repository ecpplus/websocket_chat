require 'rubygems'
require 'em-websocket/lib/em-websocket'
require 'cgi'
require 'json'
require 'sinatra'
require 'thin'
require 'logger'

EventMachine.run {
  class App < Sinatra::Base
    set :sessions, true

    get '/' do
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
  end
  
  @logger = Logger.new('log/chat.log')
  @channels = {} 

  EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080, :debug => false) do |ws|
    ws.onopen {
      room_name = ws.request['Query']['room']
      user_name = ws.request['Query']['user']

      # チャンネルを取得(or作成)して、そこに入る
      channel = @channels[room_name] || (@channels[room_name] = EM::Channel.new)
      channel.push "#{ERB::Util.h(user_name)}さんがチャットに参加しました。 #{Time.now.strftime('%H:%M:%S')}"
      sid = channel.subscribe { |msg| 
        ws.send msg 
      }
    
      ws.onmessage { |msg|
        #channel.push "[#{ERB::Util.h(user_name)}]: #{ERB::Util.h(msg)} #{Time.now.strftime('%H:%M:%S')} <#{sid}> "
        #channel.push "{'user': '#{ERB::Util.h(user_name)}': #{ERB::Util.h(msg)} #{Time.now.strftime('%H:%M:%S')} <#{sid}> "
        channel.push({:user => ERB::Util.h(user_name), :comment => ERB::Util.h(msg), :time => Time.now.strftime('%H:%M'), :user_id => sid}.to_json) #<#{sid}> "
      }

      ws.onclose {
        channel.unsubscribe(sid)
      }
    }
  end
  
  App.run!(:port => 4567)
  @logger.info("Server started")
}
