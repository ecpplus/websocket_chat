#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'rubygems'
require './em-websocket/lib/em-websocket'
require 'cgi'
require 'uri'
require 'json'
#require 'sinatra'
require 'thin'
require 'logger'
require 'erb'

EventMachine.run {
  @logger = Logger.new('log/chat.log')
  @paint_channels = {} 
  @chat_channels  = {} 
  @members        = {}

  EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080, :debug => false) do |ws|
    ws.onopen {
      room_name = ws.request['Query']['room']
      user_name = ERB::Util.h(ws.request['Query']['user'])

      # chat は /chat, お絵かきは /paint
      case URI.split(ws.request['Path'])[5]
      when '/chat'
        # チャンネルを取得(or作成)して、そこに入る
        channel = @chat_channels[room_name] || (@chat_channels[room_name] = EM::Channel.new)
        sid = channel.subscribe { |msg| ws.send msg }

        members = @members[room_name] || (@members[room_name] = {})
        members[sid] = user_name

        ws.onmessage { |msg|
          channel.push({
            :user    => user_name,
            :comment => ERB::Util.h(msg),
            :time    => Time.now.strftime('%H:%M'),
            :user_id => sid
          }.to_json) 
        }

        ws.onclose { 
          members.delete(sid)
          channel.push({
            :user    => ERB::Util.h("システム"),
            :comment => "#{user_name}さんがチャットから離脱しました。",
            :time    => Time.now.strftime('%H:%M'),
            :user_id => 0,
            :members => members.values,
          }.to_json) 
          channel.unsubscribe(sid) 
        }
    
        channel.push({
          :user    => ERB::Util.h("システム"),
          :comment => "#{user_name}さんがチャットに参加しました。",
          :time    => Time.now.strftime('%H:%M'),
          :user_id => 0,
          :members => members.values,
        }.to_json) #<#{sid}> "
      when '/paint'
        # チャンネルを取得(or作成)して、そこに入る
        channel = @paint_channels[room_name] || (@paint_channels[room_name] = EM::Channel.new)
        members = @members[room_name] || (@members[room_name] = [])
        sid = channel.subscribe { |msg| ws.send msg }
        ws.onmessage { |msg| channel.push(msg) }
        ws.onclose { channel.unsubscribe(sid) }

        # 自分が2人目以降なら、今までのデータをリクエスト
        if 1 < members.size
          channel.push({
            :sync_send      => true,
            :sync_from_user => CGI.escape(members[members.keys.min]),
            :sync_to_user   => CGI.escape(user_name),
          }.to_json)
        end
      end
    }
  end
  
  @logger.info("Server started")
}
