require "socket"
require 'uri'

directory = ARGV[0]
server = TCPServer.open(2626)

def template(status:200, mime_type:"text/html", body:"")
  prefix = "HTTP/1.1 #{status}\r\nContent-Type: #{mime_type}\r\n\r\n"
  if mime_type == "text/html"
    return "#{prefix}<!doctype html>\n#{body}"
  else
    return "#{prefix}#{body}"
  end
end

while session=server.accept
  fork do
    request = session.gets
    if request
      method, full_path = request.split(' ')
      encoded_path, query = full_path.split('?')
      path = URI.decode(encoded_path)[1..-1]
      file_path = "#{directory}/#{path}"
      if path == "" or File.directory?(file_path)
        links = Dir.entries(file_path).map do |p|
          new_path = "#{path}/#{p}"
          if new_path[0] != "/"
            new_path = "/" + new_path
          end
          uri = URI.encode(new_path)
          "<li><a href=#{uri}>#{p}</a></li>"
        end
        body = "<ul>#{links.join("")}</ul>"
        session.puts(template(body: body))
      elsif File.file?(file_path)
        body = File.read(file_path)
        mime_type = `file --mime -b #{file_path}`.chomp
        session.puts(template(body:body, mime_type:mime_type))
      else
        session.puts(template(status:404, body:'Could not find file'))
      end
    end
  end
  session.close
end
