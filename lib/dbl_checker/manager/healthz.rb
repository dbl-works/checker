require 'socket'

module DblChecker
  module Manager
    # Very simple TCP server to serve a /healthz endpoint
    # that will return 200 if or client (that executs jobs) is running.
    class Healthz
      def initialize
        @server = TCPServer.new('0.0.0.0', DblChecker.configuration.healthz_port)
      end

      def serve
        # puts "server pid: #{Process.pid}"

        while session = @server.accept
          request = session.gets

          if request.match?(/\/healthz\s/)
            if manager_is_running?
              serve_200(session)
            else
              serve_400(session)
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
      def manager_is_running?
        Process::kill(0, manager_pid) == 1
      rescue Errno::ESRCH
        false
      end

      def manager_pid
        pid = `cat manager.pid`.chomp.to_i
        raise 'manager.pid is empty' if pid.zero?

        pid
      end
    end
  end
end
