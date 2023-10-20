---------------------------------------------------------
local DOMAIN = "MY_DOMAIN"
local CUSTOMERNO = 12345
local APIKEY = "APIKEY_AS_CREATED_IN_CCP"
local APIPASSWD = "APIPASSWD_AS_CREATED_IN_CCP"
local IP6_DEVICE = "/64 of the device that runs the script"
local IP6_SERVER = "/64 of the server"
---------------------------------------------------------
local cjson = require "luci.jsonc"
local https = require "ssl.https"
local ltn12 = require "ltn12"
local socket = require "socket"
local http = socket.http
local string = require "string"

local function send_command(coms,ids)
	local postbod
	local resbod = {}
	local post = {}
	coms.param.apikey = APIKEY
	coms.param.customernumber = CUSTOMERNO
	if (ids) then
		coms.param.apisessionid = ids 
	end
	postbod = cjson.stringify(coms)
	post = { 
		method = "POST",
		url = "https://ccp.netcup.net/run/webservice/servers/endpoint.php?JSON",
		headers = {
			["content-length"] = tostring(#postbod)
		},
		source = ltn12.source.string(postbod),
		sink = ltn12.sink.table(resbod)}
	https.request(post)
	return cjson.parse(table.concat(resbod))
end

local function clear()
	local t = {}
	t.param = {}
	return t
end

local com, id, response, ip4, ipv6, modified

response = {}
http.request{url = "http://v4.ident.me", sink = ltn12.sink.table(response)}
ip4=table.concat(response)
if ip4 == "" then -- something went terribly wrong. Give up.
	print ("no network")
	return
end

response = {}
http.request{url = "http://v6.ident.me", sink = ltn12.sink.table(response)}
ipv6 = table.concat(response)
ipv6,_ = (string.gsub(ipv6, IP6_DEVICE, IP6_SERVER))

response = socket.dns.toip(DOMAIN)
if ip4 == response then 
	print ("address not changed")
	return
end
local logfile=io.open("ddns.log","a")
io.output(logfile)
io.write(os.date() .. " new IP " .. ip4 .. "\n")
	
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
	elseif v.type == "AAAA" and v.destination ~= ipv6 then
		v.destination = ipv6
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
io.close(logfile)
