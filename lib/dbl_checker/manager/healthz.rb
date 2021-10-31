require 'socket'

module DBLChecker
  module Manager
    # Very simple TCP server to serve a /healthz endpoint
    # that will return 200 if or client (that executs jobs) is running.
    class Healthz
      def initialize
        port = (ENV.fetch('DBL_CHECKER_HEALTHZ_PORT') { '3000' }).to_i
        @server = TCPServer.new('0.0.0.0', port)
      end

      def serve(client_pid)
        puts 'Running DBLChecker::Manager::Healthz..'

        while session = @server.accept
          request = session.gets

          if request.match?(/\/healthz\s/)
            if client_is_running?(client_pid)
              serve(200, session)
              puts 'serve /healthz   OK'
            else
              serve(400, session)
              puts 'serve /healthz   CLIENT ERROR'
              puts 'DBLChecker::Manager::Client is not running!'
            end
          else
            serve(404, session)
          end

          session.close
        end
      end

      def serve(status, session)
        session.print "HTTP/1.1 #{status}\r\n"
        session.print "Content-Type: text/html\r\n"
        session.print "\r\n"
        session.print "404".         if status == 404
        session.print "\u2713"       if status == 200
        session.print "Runner died!" if status == 400
      end

      # check if our runner process executes jobs
      def client_is_running?(client_pid)
        Process::kill(0, client_pid) == 1
      rescue Errno::ESRCH
        false
      end
    end
  end
end
