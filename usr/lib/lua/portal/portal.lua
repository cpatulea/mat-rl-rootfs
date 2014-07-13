require "luci.http"
require "luci.template"
require "luci.util"

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

  if env.REQUEST_METHOD == "GET" then
    params = luci.http.protocol.urldecode_params(env.QUERY_STRING)
  elseif env.REQUEST_METHOD == "POST" then
    local len = tonumber(env.CONTENT_LENGTH) or 0
    if len > 10000 then
      simple_response(send, "400 Bad Request", "POST data too long.\n")
      return
    end

    local data = ""
    while len > 0 do
      local rlen, chunk = uhttpd.recv(256)
      len = len - rlen
      data = data .. chunk
    end

    params = luci.http.protocol.urldecode_params(data)
  else
    simple_response(send, "400 Bad Request", "Unsupported method.\n")
    return
  end

  if params.userurl then
    params.userurl = params.userurl:gsub("[^!-~]", "_")
  end

  local tpl = require("luci.template")
  tpl.context.viewns = {
    luci = luci,
    write = function (chunk) response = response .. chunk end,
    tostring = tostring,
  }

  if not params.continue then
    response = "Status: 200 OK\r\n" ..
      "\r\n"

    function portal(targeturl)
      return "/cgi-bin/portal.lua?continue=1&userurl=" ..
          luci.http.protocol.urlencode(targeturl)
    end
    tpl.render("portal/portal", {portal = portal, params = params})
  else
    os.execute("/usr/sbin/ipset -exist add known " .. env.REMOTE_ADDR ..
      " 2>&1 | logger portal")
    response = "Status: 302 Found\r\n" ..
      "Location: " .. params.userurl .. "\r\n" ..
      "\r\n"
  end

  send(response)
  --[[for k, v in pairs(params) do
    send(k .. "=" .. tostring(v) .. "\n")
  end]]--
end

function handle_request(env)
  local ok, error = xpcall(function () handle_req(env) end, debug.traceback)
  if not ok then
    simple_response(uhttpd.send, "500 Server Error", tostring(error) .. "\n")
  end
end
