--[[
                 Cinema Modded AcFun Support
                   Powered by OriginalSnow

        You can edit this code.But you cant upload anymore.
]]

-- Last update : 2023/2/8

local SERVICE = {}

SERVICE.Name = "AcFun"
SERVICE.IsTimed = true
SERVICE.Dependency = DEPENDENCY_PARTIAL

-- 目前只支持ac号（我也不知道AcFun还有什么号，看番剧？去哔哩哔哩看！）

local META_URL = "http://103.123.4.216:9966/?play=%s"

function SERVICE:Match( url )
    local ac = url.host:match("www.acfun.cn") and string.match(url.path,"ac[%w*]+")
    return ac or false
end

if CLIENT then
    local PLAYURL = "http://103.123.4.216:9966/?play=%s"

    local JS = [[
        var checkerInterval = setInterval(function() {
			var player = document.getElementsByTagName('video')[0];
			if (!!player && player.paused == false && player.readyState == 4) {
				clearInterval(checkerInterval);

				document.body.style.backgroundColor = "black";
				window.cinema_controller = player;

				exTheater.controllerReady();
			}
		}, 50);
        var myVideo = videojs('myVideo', {
            bigPlayButton: true,
            textTrackDisplay: false,
            posterImage: false,
            errorDisplay: false,
        });
        myVideo.play();
    ]]
    
    function SERVICE:LoadProvider( vi, p )
        --print(vi:Data())
        p:OpenURL(PLAYURL:format(vi:Data()))
        p.OnDocumentReady = function(pnl)
			self:LoadExFunctions( pnl )
			pnl:QueueJavascript(JS)
		end
    end
end

function SERVICE:GetURLInfo( url )
    local info = {}
    
    if url.host:match("www.acfun.cn") then
        info.Data = string.match(url.path,"ac[%w*]+")
    end

	return info.Data and info or false
end

function SERVICE:GetVideoInfo( d , onSuccess, onFailure )
    local f = Format("http://103.123.4.216:9966/?id=%s", d)

    local onReceive = function(b,l,h,c)
        http.Fetch(f, function(r,s)
            if s == 0 then
                return onFailure( "Theater_RequestFailed" )
            end

            local result = util.JSONToTable(r)
            
            if result.message == "failed" then
                return onFailure( "Theater_RequestFailed" )
            end
    
            local info = {}
            info.title = result.data.vedioInfo.title
            info.duration = result.data.vedioInfo.duration / 1000 + 1
    
            if onSuccess then
                pcall(onSuccess, info)
            end
        end)
    end

    local url = META_URL:format( d )
    self:Fetch( url, onReceive, onFailure )
end

theater.RegisterService( "acfun", SERVICE )
print("acfun loaded")