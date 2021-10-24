require 'socket'

module DBLChecker
  module Manager
    # Very simple TCP server to serve a /healthz endpoint
    # that will return 200 if or client (that executs jobs) is running.
    class Healthz
      def initialize
        port = (ENV.fetch('DBL_CHECKER_HEALTHZ_PORT') { '3073' }).to_i
        @server = TCPServer.new('0.0.0.0', port)
      end

      def serve(client_pid)
        puts 'Running DBLChecker::Manager::Healthz..'

        while session = @server.accept
          request = session.gets

          if request.match?(/\/healthz\s/)
            if client_is_running?(client_pid)
              serve_200(session)
              puts 'serve /healthz   OK'
            else
              serve_400(session)
              puts 'serve /healthz   CLIENT ERROR'
              puts 'DBLChecker::Manager::Client is not running anymore!'
            end
          else
            serve_404(session)
          end

          session.close
        end
      end

      def serve_404(session)
        session.print "HTTP/1.1 404\r\n"
        session.print "Content-Type: text/html\r\n"
        session.print "\r\n"
        session.print "404"
      end

      def serve_200(session)
        session.print "HTTP/1.1 200\r\n"
        session.print "Content-Type: text/html\r\n"
        session.print "\r\n"
        session.print "\u2713"
      end

      def serve_400(session)
        session.print "HTTP/1.1 400\r\n"
        session.print "Content-Type: text/html\r\n"
        session.print "\r\n"
        session.print "Runner is dead!"
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
