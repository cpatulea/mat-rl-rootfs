require "luci.http.protocol"

function simple_response(send, status, content)
  send(
    "Status: " .. status .. "\r\n" ..
    "Content-Type: text/plain\r\n" ..
    "\r\n" ..
    content
  )
end

function handle_req(env)
	local send = uhttpd.send
  local response = ""

  if env.REQUEST_METHOD ~= "GET" then
    simple_response(send, "400 Bad Request", "Only GET is supported.\n")
    return
  end

  userurl = "http://" .. env.headers.host .. env.REQUEST_URI
  redirecturl = "http://" .. env.SERVER_ADDR .. ":8081" ..
    "/cgi-bin/portal?userurl=" .. luci.http.protocol.urlencode(userurl)
  --[[for k, v in pairs(env) do
    send(k .. "=" .. tostring(v) .. "\n")
  end]]--

  response = "Status: 302 Found\r\n" ..
    "Location: " .. redirecturl .. "\r\n" ..
    "\r\n"

  send(response)
end

function handle_request(env)
  local ok, error = pcall(handle_req, env)
  if not ok then
    simple_response(uhttpd.send, "500 Server Error", tostring(error) .. "\n")
  end
end
