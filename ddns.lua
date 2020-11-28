---------------------------------------------------------
local DOMAIN = "MY_DOMAIN"
local CUSTOMERNO = 12345
local APIKEY = "APIKEY_AS_CREATED_IN_CCP"
local APIPASSWD = "APIPASSWD_AS_CREATED_IN_CCP"
---------------------------------------------------------
local cjson = require "cjson"
local https = require "ssl.https"
local ltn12 = require "ltn12"
local socket = require "socket"
local http = socket.http

local function send_command(coms,ids)
	local postbod
	local resbod = {}
	local post = {}
	coms.param.apikey = APIKEY
	coms.param.customernumber = CUSTOMERNO
	if (ids) then
		coms.param.apisessionid = ids 
	end
	postbod = cjson.encode(coms)
	post = { 
		method = "POST",
		url = "https://ccp.netcup.net/run/webservice/servers/endpoint.php?JSON",
		headers = {
			["content-length"] = tostring(#postbod)
		},
		source = ltn12.source.string(postbod),
		sink = ltn12.sink.table(resbod)}
	https.request(post)
	return cjson.decode(table.concat(resbod))
end

local function clear()
	local t = {}
	t.param = {}
	return t
end

local com, id, response, ip4, modified

response = {}
http.request{url = "http://v4.ident.me", sink = ltn12.sink.table(response)}
ip4=table.concat(response)

response = socket.dns.toip(DOMAIN)
if ip4 == response then 
	return
end
print ("Change detected! updating database")

com = clear()
com.action = "login"
com.param.apipassword = APIPASSWD
response = send_command(com,id)
id = response.responsedata.apisessionid

com = clear()
com.action = "infoDnsRecords"
com.param.domainname = DOMAIN
response = send_command(com,id)
modified = false
for _,v in pairs (response.responsedata.dnsrecords) do
	if v.type == "A" and v.hostname ~= "mail" and v.destination ~= ip4 then
		v.destination = ip4
		modified = true
	end
end

if modified then
	com = clear()
	com.action = "updateDnsRecords"
	com.param.domainname = DOMAIN
	com.param.dnsrecordset = response.responsedata
	response = send_command(com,id)
	print (response.longmessage)
else
	print ("all records up to date")
end

com = clear()
com.action = "logout"
response = send_command(com,id)
