require 'addressable/uri'

module EventMachine
  module WebSocket
    class Connection < EventMachine::Connection
      include Debugger

      attr_reader :state, :request

      # define WebSocket callbacks
      def onopen(&blk);     @onopen = blk;    end
      def onclose(&blk);    @onclose = blk;   end
      def onmessage(&blk);  @onmessage = blk; end

      def initialize(options)
        @options = options
        @debug = options[:debug] || false
        @secure = options[:secure] || false
        @state = :handshake
        @request = {}
        @data = ''

        debug [:initialize]
      end

      def post_init
        start_tls if @secure
      end

      def receive_data(data)
        debug [:receive_data, data]

        @data << data
        dispatch
      end

      def unbind
        debug [:unbind, :connection]

        @state = :closed
        @onclose.call if @onclose
      end

      def dispatch
        case @state
          when :handshake
            handshake
          when :connected
            process_message
          else raise RuntimeError, "invalid state: #{@state}"
        end
      end

      def handshake
        if @data.match(/<policy-file-request\s*\/>/)
          send_flash_cross_domain_file
          return false
        else
          debug [:inbound_headers, @data]
          begin
            @handler = HandlerFactory.build(@data, @secure, @debug)
            @data = ''
            send_data @handler.handshake

            @request = @handler.request
            @state = :connected
            @onopen.call if @onopen
            return true
          rescue => e
            debug [:error, e]
            process_bad_request
            return false
          end
        end
      end

      def process_bad_request
        send_data "HTTP/1.1 400 Bad request\r\n\r\n"
        close_connection_after_writing
      end

      def send_flash_cross_domain_file
        file =  '<?xml version="1.0"?><cross-domain-policy><allow-access-from domain="*" to-ports="*"/></cross-domain-policy>'
        debug [:cross_domain, file]
        send_data file

        # handle the cross-domain request transparently
        # no need to notify the user about this connection
        @onclose = nil
        close_connection_after_writing
      end

      def process_message
        debug [:message, @data]

        # This algorithm comes straight from the spec
        # http://tools.ietf.org/html/draft-hixie-thewebsocketprotocol-76#section-4.2

        error = false

        while !error
          pointer = 0
          frame_type = @data[pointer].to_i
          pointer += 1

          if (frame_type & 0x80) == 0x80
            # If the high-order bit of the /frame type/ byte is set
            length = 0

            loop do
              b = @data[pointer].to_i
              return false unless b
              pointer += 1
              b_v = b & 0x7F
              length = length * 128 + b_v
              break unless (b & 0x80) == 0x80
            end

            if @data[pointer+length-1] == nil
              debug [:buffer_incomplete, @data.inspect]
              # Incomplete data - leave @data to accumulate
              error = true
            else
              # Straight from spec - I'm sure this isn't crazy...
              # 6. Read /length/ bytes.
              # 7. Discard the read bytes.
              @data = @data[(pointer+length)..-1]

              # If the /frame type/ is 0xFF and the /length/ was 0, then close
              if length == 0
                send_data("\xff\x00")
                @state = :closing
                close_connection_after_writing
              else
                error = true
              end
            end
          else
            # If the high-order bit of the /frame type/ byte is _not_ set
            msg = @data.slice!(/^\x00([^\xff]*)\xff/)
            if msg
              msg.gsub!(/^\x00|\xff$/, '')
              if @state == :closing
                debug [:ignored_message, msg]
              else
                @onmessage.call(msg) if @onmessage
              end
            else
              error = true
            end
          end
        end

        false
      end

      # should only be invoked after handshake, otherwise it
      # will inject data into the header exchange
      #
      # frames need to start with 0x00-0x7f byte and end with
      # an 0xFF byte. Per spec, we can also set the first
      # byte to a value betweent 0x80 and 0xFF, followed by
      # a leading length indicator
      def send(data)
        debug [:send, data]
        send_data("\x00#{data}\xff")
      end
    end
  end
end
