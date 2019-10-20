-- handler.lua
local BasePlugin = require "kong.plugins.base_plugin"
local http       = require "resty.http"
local cjson      = require "cjson"
local url        = require "socket.url"

local kong = kong
local RemoteSrvAuthHandler = BasePlugin:extend()

RemoteSrvAuthHandler.PRIORITY = 3000

function RemoteSrvAuthHandler:new()
  RemoteSrvAuthHandler.super.new(self, "remote-server-auth")
end

local function get_request_body() 
  --解析请求API，在http报文中获取各种标识、token等信息
  local deviceId = kong.request.get_header("deviceId")
  if not deviceId then
    deviceId = ""
  end
  ngx.log(ngx.DEBUG, "deviceId"..deviceId)

  local geolat = kong.request.get_header("geo-lat")
  if not geolat then
    geolat = ""
  end
  ngx.log(ngx.DEBUG, "geo-lat"..geolat)

  local geolog = kong.request.get_header("geo-log")
  if not geolog then
     geolog = ""
  end
  ngx.log(ngx.DEBUG, "geo-log"..geolog)

  local ostype = kong.request.get_header("os-type")
  if not ostype then
     ostype = ""
  end
  ngx.log(ngx.DEBUG, "os-type"..ostype)

  local osversion = kong.request.get_header("os-version")
  if not osversion then
     osversion = ""
  end
  ngx.log(ngx.DEBUG, "osversion"..osversion)

  local cookie = kong.request.get_header("cookie")
  if cookie == nil then
    cookie = ""
    --return kong.response.exit(403, "Access Forbidden, Remote-Srv-Auth", {
      --["Content-Type"] = "text/plain",
      --["WWW-Authenticate"] = "Basic"
    --})
  end
  ngx.log(ngx.DEBUG, "cookie"..cookie)

  local subjectIdType = ngx.var.cookie_subjectIdType
  if not subjectIdType then
    subjectIdType = ""
  end

  local subjectIdValue = ngx.var.cookie_subjectIdValue
  if not subjectIdValue then
    subjectIdValue = ""
  end

  local appUrl = ngx.var.cookie_appUrl
  if not appUrl then
    appUrl = ""
  end

  local appId = ngx.var.cookie_appId
  if not appId then
    appId = ""
  end

  local hardwareId = ngx.var.cookie_hardwareId
  if not hardwareId then
     hardwareId = ""
  end

  --local time = ngx.req.start_time

  local userIP = ngx.var.cookie_userIp
  if not userIP then
    userIP = ""
  end

  local subjectId = {}
  subjectId["type"] = subjectIdType
  subjectId["value"] = subjectIdValue
  local objectId = {}
  objectId["url"] = appUrl 
  objectId["appId"] = appId
  local geo = {
 	["log"] = geolog,
       	["lat"] = geolat
  }
  local OS = {
	["type"] = ostype,
       	["version"] = osversion
  }
  local attrs = {}
  attrs["time"] = ""
  attrs["userIP"] = userIP
  attrs["geo"] = geo
  attrs["OS"] = OS
 
  local retTable = {}    --最终产生json的表
  retTable["subjectId"] = subjectId
  retTable["objectId"] = objectId
  retTable["deviceId"] = deviceId
  retTable["hardwareId"] = hardwareId
  retTable["act"] = "0"
  retTable["attrs"] = attrs
  
  --local body_str = cjson.encode(retTable)
  --ngx.log(ngx.DEBUG, "body_str=="..body_str)
  return retTable
end

local function get_request_header(conf)
  local cookie = kong.request.get_header("cookie")
  if cookie == nil then
     cookie = ""
  end

  local userToken = ngx.var.cookie_userToken
  if not (userToken) then
     userToken = ""
  end
  --apptoken获取
  local ngx_cookie = ngx.var.cookie_ngx_cookie
  if not (ngx_cookie) then
        ngx_cookie = ""
  end
  local resbody = get_request_body()
  ngx.log(ngx.DEBUG, "resbody=="..type(resbody),"=======body:",tostring(resbody))
  local arry = {}
  arry[1] = resbody["objectId"]
  local app_body = {
 	["subjectId"] = resbody["subjectId"],
	["deviceId"]  = resbody["deviceId"],
 	["hardwareId"]= resbody["hardwareId"],
 	["app"]	      = arry 	 
  }
  ngx.log(ngx.DEBUG, "=======appbody:",tostring(app_body))
  local cookie = string.format("ngx_cookie=%s;userToken=%s",ngx_cookie,userToken)
  ngx.log(ngx.DEBUG, "=======cookie:",cookie)
  local app_headers = {
     ["Content-Type"] = "application/json",
     ["Cookie"] = cookie,
  }
  local appurl = conf.get_appToken_url
  ngx.log(ngx.DEBUG, "accessurl=="..appurl)
  --apptoken获取请求
  local res = client_request(appurl,"POST",app_headers,app_body)
  if not res then
     ngx.log(ngx.DEBUG, "====获取apptoken失败")
     return nil
  end
  ngx.log(ngx.DEBUG, "res==",res.body)
  local _body = cjson.decode(res.body)
  local appToken = ""
  if _body["code"] == "00000" then
     appToken = _body["data"][1]["token"]
     ngx.log(ngx.DEBUG, "====获取apptoken:",appToken)
  else
     ngx.log(ngx.DEBUG, "====获取apptoken失败")
  end  

  local headers = {
     ["Content-Type"] = "application/json",
     ["userToken"] = userToken,
     ["appToken"] = appToken,
  }
  --local reheaders = cjson.encode(headers)
  return headers
end

function client_request(_url,_method,_headers,_body)
  parsed_url = url.parse(_url)
  local host = parsed_url.host
  local port = tonumber(parsed_url.port)

  local httpc = http.new()
  httpc:set_timeout(5000)
  --if parsed_url.scheme == "https" then
  --  local _, err = httpc:ssl_handshake(true, host, false)
  --  if err then
  --    return nil, "failed to do SSL handshake with " ..
  --           host .. ":" .. tostring(port) .. ": " .. err
  --  end
  --end
  
  ngx.log(ngx.DEBUG,"======",type(_body),type(_headers))
  local sbody = cjson.encode(_body)
  local res, err = httpc:request_uri(_url, {
    ssl_verify = false,
    method = _method,
    body = sbody,
    headers = _headers 
  })
  
  if not res then
    ngx.log(ngx.WARN,"failed to request: ", err)
    return nil
  end
  
  ngx.log(ngx.DEBUG, "------res_status:"..res.status)
  --ngx.log(ngx.DEBUG,"header:"..res.header)
  ngx.log(ngx.DEBUG,"body:"..res.body)

  --请求之后，状态码
  ngx.status = res.status
  if ngx.status ~= 200 then
     ngx.log(ngx.WARN,"非200状态，ngx.status:"..ngx.status)
     return nil
  end
   
  return res
end

function RemoteSrvAuthHandler:rewrite(conf)
  RemoteSrvAuthHandler.super.rewrite(self)
  
  local per_path = kong.request.get_path()
  if per_path == "/authorize/appmodule/query" then
     local _url = "https://authr.proxy.trusted.com:6443/authorize/appmodule/query"
     
     local appUrl = ngx.var.cookie_appUrl
     if not appUrl then
        appUrl = ""
     end

     local appId = ngx.var.cookie_appId
     if not appId then
        appId = ""
     end

     local subjectIdType = ngx.var.cookie_subjectIdType
     if not subjectIdType then
        subjectIdType = ""
     end

     local subjectIdValue = ngx.var.cookie_subjectIdValue
     if not subjectIdValue then
        subjectIdValue = ""
     end     

     local subjectId = {}
     subjectId["type"] = subjectIdType
     subjectId["value"] = subjectIdValue
    
     local _body = {
         ["subjectId"] = subjectId,
         ["appId"] = appId,
	 ["appUrl"] = appUrl,        
     }
     local resheaders = get_request_header(conf)      
    
     res = client_request(_url,"POST",resheaders,_body)
     local _body = cjson.decode(res.body)
     ngx.log(ngx.DEBUG, "========获取功能模块:",tostring(res.body))
     //解析res
     if not res then
    	ngx.log(ngx.WARN," 获取功能模块失败:")
        return kong.response.exit(res.status,“获取功能模块失败”)
     end
     local arr = _body["data"]
     if #arr == 0 then
        arr = ["1","2","3","4"]
     end
     local res_body = {
  	   ["data"] = arr, 
     }
     local sbody = cjson.encode(res_body)    
     return kong.response.exit(res.status,s_body) 
  end
end

function RemoteSrvAuthHandler:access(conf)
  RemoteSrvAuthHandler.super.access(self)

  local resbody = get_request_body()
  ngx.log(ngx.DEBUG, "resbody=="..type(resbody),"=======body:",tostring(resbody))
  local resheaders = get_request_header(conf)
  ngx.log(ngx.DEBUG, "resheaders=="..type(resheaders))
  local accessurl = conf.get_access_url
  ngx.log(ngx.DEBUG, "accessurl=="..accessurl)
  local res = client_request(accessurl,"POST",resheaders,resbody)
  ngx.log(ngx.DEBUG, "res=="..tostring(res))
  local resStr --响应结果  
  if not res then
     return resStr
  end

  ngx.log(ngx.DEBUG, "------res_status:"..res.status)
  ngx.log(ngx.DEBUG,"body:"..res.body)
  local _body = cjson.decode(res.body)
  _judge = _body["data"]["judge"]
  _authtype = _body["data"]["authType"]
  if _judge == "0" then
     return resStr
  elseif _judge == "1" then
     return kong.response.exit(460, { msg ="不允许访问",code=0})
  elseif _judge == "2" then
     ngx.log(ngx.DEBUG, "_authtype==".._authtype)
     return kong.response.exit(460, { msg ="需要二次认证",code=0})
  end
end

return RemoteSrvAuthHandler
