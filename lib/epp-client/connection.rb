# $Abso$

class EPPClient
  module Connection
    HG_KEYWORD_Connection = %q$Abso$
    def self.included(base) # :nodoc:
      base.class_eval do
	HG_KEYWORD << HG_KEYWORD_Connection
      end
    end

    # Establishes the connection to the server, if successful, will return the
    # greeting frame.
    def open_connection
      @tcpserver = TCPSocket.new(server, port)
      @socket = OpenSSL::SSL::SSLSocket.new(@tcpserver, @context)

      # Synchronously close the connection & socket
      @socket.sync_close

      # Connect
      @socket.connect

      # Get the initial greeting frame
      get_frame
    end

    # Gracefully close the connection
    def close_connection
      if defined?(@socket) and @socket.is_a?(OpenSSL::SSL::SSLSocket)
	@socket.close
	@socket = nil
      end

      if defined?(@tcpserver) and @tcpserver.is_a?(TCPSocket)
	@tcpserver.close
	@tcpserver = nil
      end

      return true if @tcpserver.nil? and @socket.nil?
    end

    # Sends a frame and returns the server's answer
    def send_request(xml)
      send_frame(xml)
      get_frame
    end

    # sends a frame
    def send_frame(xml)
      puts parse_response(xml).to_s.gsub(/^/, '>> ') if $DEBUG
      @socket.write([xml.size + 4].pack("N") + xml)
    end

    # gets a frame from the socket and returns the parsed response.
    def get_frame
      size = @socket.read(4)
      if size.nil?
	if @socket.eof?
	  raise SocketError, "Connection closed by remote server"
	else
	  raise SocketError, "Error reading frame from remote server"
	end
      else
	size = size.unpack('N')[0]
	response = parse_response(@socket.read(size - 4))
	puts response.to_s.gsub(/^/, '<< ') if $DEBUG
	response
      end
    end
  end
end