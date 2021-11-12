require 'socket'

module DBLChecker
  module Manager
    # Very simple TCP server to serve a /healthz endpoint
    # that will return 200 if the DBLChecker::Manager::Client (that executs jobs) is running.
    class Healthz
      def initialize
        port = (ENV.fetch('DBL_CHECKER_HEALTHZ_PORT') { '3000' }).to_i
        @server = TCPServer.new('0.0.0.0', port)
      end

      # rubocop:disable Metrics/MethodLength
      def serve(client_pid)
        puts 'Running DBLChecker::Manager::Healthz..'

        while session = @server.accept
          request = session.gets

          # https://kubernetes.io/docs/reference/using-api/health-checks/
          if request.match?(/\/(?:healthz|readyz|livez)\s/)
            if client_is_running?(client_pid)
              respond_with(200, session)
              puts 'serve /healthz   OK'
            else
              respond_with(400, session)
              puts 'serve /healthz   CLIENT ERROR, DBLChecker::Manager::Client not running'
            end
          else
            respond_with(404, session)
          end

          session.close
        end
      end
      # rubocop:enable Metrics/MethodLength

      def respond_with(status, session)
        session.print "HTTP/1.1 #{status}\r\n"
        session.print "Content-Type: text/html\r\n"
        session.print "\r\n"
        session.print '404'          if status == 404
        session.print "\u2713"       if status == 200
        session.print 'Runner died!' if status == 400
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
