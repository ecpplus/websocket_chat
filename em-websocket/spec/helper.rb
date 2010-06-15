require 'rubygems'
require 'spec'
require 'pp'
require 'em-http'

require 'lib/em-websocket'

class FakeWebSocketClient < EM::Connection
  attr_writer :onopen, :onclose, :onmessage
  attr_reader :handshake_response, :packets

  def initialize
    @state = :new
    @packets = []
  end

  def receive_data(data)
    # puts "RECEIVE DATA #{data}"
    if @state == :new
      @handshake_response = data
      @onopen.call if @onopen
      @state = :open
    else
      @onmessage.call if @onmessage
      @packets << data
    end
  end

  def send(data)
    send_data("\x00#{data}\xff")
  end

  def unbind
    @onclose.call if @onclose
  end
end

def failed
  EventMachine.stop
  fail
end

def format_request(r)
  data = "#{r[:method]} #{r[:path]} HTTP/1.1\r\n"
  header_lines = r[:headers].map { |k,v| "#{k}: #{v}" }
  data << [header_lines, '', r[:body]].join("\r\n")
  data
end

def format_response(r)
  data = "HTTP/1.1 101 WebSocket Protocol Handshake\r\n"
  header_lines = r[:headers].map { |k,v| "#{k}: #{v}" }
  data << [header_lines, '', r[:body]].join("\r\n")
  data
end

def handler(request, secure = false)
  EM::WebSocket::HandlerFactory.build(format_request(request), secure)
end

def send_handshake(response)
  simple_matcher do |given|
    given.handshake.lines.sort == format_response(response).lines.sort
  end
end
