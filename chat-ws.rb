require 'rubygems'
require 'em-websocket/lib/em-websocket'
require 'cgi'
require 'json'
#require 'sinatra'
require 'thin'
require 'logger'
require 'erb'

EventMachine.run {
  @logger = Logger.new('log/chat.log')
  @paint_channels = {} 
  @chat_channels  = {} 

  EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080, :debug => true) do |ws|
    ws.onopen {
      room_name = ws.request['Query']['room']
      user_name = ws.request['Query']['user']

      # chat は /chat, お絵かきは /paint
      case URI.split(ws.request['Path'])[5]
      when '/chat'
        # チャンネルを取得(or作成)して、そこに入る
        channel = @chat_channels[room_name] || (@chat_channels[room_name] = EM::Channel.new)
        channel.push({
          :user => ERB::Util.h("システムから"), 
          :comment => ERB::Util.h("#{user_name}さんがチャットに参加しました。"), 
          :time => Time.now.strftime('%H:%M'),
          :user_id => 0
        }.to_json) #<#{sid}> "
        sid = channel.subscribe { |msg| ws.send msg }
    
        ws.onmessage { |msg|
          channel.push({
            :user => ERB::Util.h(user_name), 
            :comment => ERB::Util.h(msg), 
            :time => Time.now.strftime('%H:%M'),
            :user_id => sid
          }.to_json) #<#{sid}> "
        }

        ws.onclose { channel.unsubscribe(sid) }
      when '/paint'
        # チャンネルを取得(or作成)して、そこに入る
        channel = @paint_channels[room_name] || (@paint_channels[room_name] = EM::Channel.new)
        sid = channel.subscribe { |msg| ws.send msg }
        ws.onmessage { |msg| p msg; channel.push(msg) }
        ws.onclose { channel.unsubscribe(sid) }
      end
    }
  end
  
  @logger.info("Server started")
}
