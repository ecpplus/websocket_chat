require 'spec/helper'

describe "EventMachine::WebSocket::Handler" do
  before :each do
    @request = {
      :port => 80,
      :method => "GET",
      :path => "/demo",
      :headers => {
        'Host' => 'example.com',
        'Connection' => 'Upgrade',
        'Sec-WebSocket-Key2' => '12998 5 Y3 1  .P00',
        'Sec-WebSocket-Protocol' => 'sample',
        'Upgrade' => 'WebSocket',
        'Sec-WebSocket-Key1' => '4 @1  46546xW%0l 1 5',
        'Origin' => 'http://example.com'
      },
      :body => '^n:ds[4U'
    }
    @secure_request = @request.merge(:port => 443)

    @response = {
      :headers => {
        "Upgrade" => "WebSocket",
        "Connection" => "Upgrade",
        "Sec-WebSocket-Location" => "ws://example.com/demo",
        "Sec-WebSocket-Origin" => "http://example.com",
        "Sec-WebSocket-Protocol" => "sample"
      },
      :body => "8jKS\'y:G*Co,Wxa-"
    }
    @secure_response = @response.merge(:headers => @response[:headers].merge('Sec-WebSocket-Location' => "wss://example.com/demo"))
  end

  it "should handle good request" do
    handler(@request).should send_handshake(@response)
  end

  it "should handle good request to secure default port if secure mode is enabled" do
    handler(@secure_request, true).should send_handshake(@secure_response)
  end

  it "should not handle good request to secure default port if secure mode is disabled" do
    handler(@secure_request, false).should_not send_handshake(@secure_response)
  end

  it "should handle good request on nondefault port" do
    @request[:port] = 8081
    @request[:headers]['Host'] = 'example.com:8081'
    @response[:headers]['Sec-WebSocket-Location'] =
      'ws://example.com:8081/demo'

    handler(@request).should send_handshake(@response)
  end

  it "should handle good request to secure nondefault port" do
    @secure_request[:port] = 8081
    @secure_request[:headers]['Host'] = 'example.com:8081'
    @secure_response[:headers]['Sec-WebSocket-Location'] = 'wss://example.com:8081/demo'
    handler(@secure_request, true).should send_handshake(@secure_response)
  end

  it "should handle good request with no protocol" do
    @request[:headers].delete('Sec-WebSocket-Protocol')
    @response[:headers].delete("Sec-WebSocket-Protocol")

    handler(@request).should send_handshake(@response)
  end

  it "should handle extra headers by simply ignoring them" do
    @request[:headers]['EmptyValue'] = ""
    @request[:headers]['AKey'] = "AValue"

    handler(@request).should send_handshake(@response)
  end
  
  it "should raise error on HTTP request" do
    @request[:headers] = {
      'Host' => 'www.google.com',
      'User-Agent' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1.3) Gecko/20090824 Firefox/3.5.3 GTB6 GTBA',
      'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language' => 'en-us,en;q=0.5',
      'Accept-Encoding' => 'gzip,deflate',
      'Accept-Charset' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
      'Keep-Alive' => '300',
      'Connection' => 'keep-alive',
    }
    
    lambda {
      handler(@request).handshake
    }.should raise_error(EM::WebSocket::HandshakeError)
  end

  it "should raise error on wrong method" do
    @request[:method] = 'POST'

    lambda {
      handler(@request).handshake
    }.should raise_error(EM::WebSocket::HandshakeError)
  end

  it "should raise error if upgrade header incorrect" do
    @request[:headers]['Upgrade'] = 'NonWebSocket'

    lambda {
      handler(@request).handshake
    }.should raise_error(EM::WebSocket::HandshakeError)
  end

  it "should raise error if Sec-WebSocket-Protocol is empty" do
    @request[:headers]['Sec-WebSocket-Protocol'] = ''

    lambda {
      handler(@request).handshake
    }.should raise_error(EM::WebSocket::HandshakeError)
  end
end
