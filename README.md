# netcup-ddns
This is a simple script to update DNS-records hosted by [netcup](https://netcup.de). It is implemented in [lua](https://lua.org), so that it can be run on [OpenWRT](https://openwrt.org) routers. The script needs to be edited to contain the customer specific information. All subdomains (except "mail") will be changed to point to the public ip of the device this script is being run on.

## Dependencies
- luasocket
- luasec
- luci-lib-jsonc (a lightweight alternative to lua-cjson)
