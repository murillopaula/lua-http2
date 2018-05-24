local connection = require "connection"
local stream = require "stream"
local hpack = require "hpack"
local copas = require "copas"

local function protocol(host, headers)
  local conn = connection.new(host)
  -- Sends an WINDOW_UPDATE frame on the conn level
  conn.send_frame(conn, 0x8, 0x0, 0, string.pack(">I4", "1073741823"))
  local request_headers = headers
  local s = stream.new(conn)
  s.id = conn.max_stream_id + 2
  conn.max_stream_id = s.id
  conn.streams[s.id] = s
  local header_block = hpack.encode(conn.hpack_context, request_headers)
  -- Sends a request header list
  conn.send_frame(conn, 0x1, 0x4 | 0x1, s.id, header_block)
  local header_list = stream.get_headers(s)
  -- Sends an WINDOW_UPDATE frame on the stream level
  conn.send_frame(conn, 0x8, 0x0, s.id, string.pack(">I4", "1073741823"))
  -- Receives DATA frames containing the message payload
  local payload = stream.get_message_data(s)
  io.write(payload)
end

local headers = {{ [1] = {[":method"] = "GET"},
                   [2] = {[":path"] = "/"},
                   [3] = {[":scheme"] = "http"},
                   [4] = {[":authority"] = "localhost:8080"},
                  },
                  {[1] = {[":method"] = "GET"},
                   [2] = {[":path"] = "/image.jpg"},
                   [3] = {[":scheme"] = "http"},
                   [4] = {[":authority"] = "localhost:8080"},
                  }}
copas.addthread(protocol, "localhost", headers)
copas.loop()
