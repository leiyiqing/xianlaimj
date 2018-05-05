-- Creator ArthurSong
-- Create Time 2016/1/29
local bit = require("app/libs/bit")
local gt = cc.exports.gt

require("app/protocols/MessageInit")
require("socket")

local SocketClient = class("SocketClient")

function SocketClient:ctor()
	-- 加载消息打包库
	local msgPackLib = require("app/libs/MessagePack")
	msgPackLib.set_number("integer")
	msgPackLib.set_string("string")
	msgPackLib.set_array("without_hole")
	self.msgPackLib = msgPackLib

	-- 发送消息缓冲
	self.sendMsgCache = {}

	-- 注册消息逻辑处理函数回调
	self.rcvMsgListeners = {}

	-- 收发消息超时
	self.isCheckTimeout = false
	self.timeDuration = 0

	-- 是否已经弹出网络错误提示
	self.isPopupNetErrorTips = false

	-- 登录到服务器标识
	self.isStartGame = false
	self.heatTime = 4
	-- 发送心跳时间
	self.heartbeatCD = self.heatTime
	-- 心跳回复时间间隔
	-- 上一次时间间隔
	self.lastReplayInterval = 0
	-- 当前时间间隔
	self.curReplayInterval = 0

	-- 登录状态,有三次自动重连的机会
	self.loginReconnectNum = 0

	self.scheduleHandler = gt.scheduler:scheduleScriptFunc(handler(self, self.update), 0, false)
	gt.registerEventListener(gt.EventType.NETWORK_ERROR, self, self.networkErrorEvt)
end

-- start --
--------------------------------
-- @class function
-- @description 和指定的ip/port服务器建立socket链接
-- @param serverIp 服务器ip地址
-- @param serverPort 服务器端口号
-- @param isBlock 是否阻塞
-- @return socket链接创建是否成功
-- end --
function SocketClient:connect(serverIp, serverPort, isBlock)
	if not serverIp or not serverPort then
		return
	end
	self:initSocketBuffer()
	
	self.serverIp = serverIp
	self.serverPort = serverPort
	self.isBlock = isBlock

	-- tcp 协议 socket
	local tcpConnection, errorInfo = self:getTcp(serverIp)
	-- local tcpConnection, errorInfo = socket.tcp()
 	if not tcpConnection then
		gt.log(string.format("Connect failed when creating socket | %s", errorInfo))
		gt.dispatchEvent(gt.EventType.NETWORK_ERROR, errorInfo)
		return false
	end
	self.tcpConnection = tcpConnection
	tcpConnection:setoption("tcp-nodelay",true)
	-- 和服务器建立tcp链接
	tcpConnection:settimeout(isBlock and 5 or 0)
	local connectCode, errorInfo = tcpConnection:connect(serverIp, serverPort)
	-- print("=======新的ip，端口2",self.serverIp, self.serverPort,connectCode, errorInfo)
	if connectCode == 1 then
		self.isConnectSucc = true
		gt.log("Socket connect success!")
	else
		gt.log(string.format("Socket %s Connect failed | %s", (isBlock and "Blocked" or ""), errorInfo))
		gt.dispatchEvent(gt.EventType.NETWORK_ERROR, errorInfo)
		return false
	end

	return true
end

function SocketClient:getTcp(host)
	local isipv6_only = false
	local addrinfo, err = socket.dns.getaddrinfo(host);
	if addrinfo then
		for i,v in ipairs(addrinfo) do
			if v.family == "inet6" then
				isipv6_only = true;
				break
			end
		end
	end
	print("isipv6_only", isipv6_only)
	if isipv6_only then
		return socket.tcp6()
	else
		return socket.tcp()
	end
end


function SocketClient:connectResume()
	if gt.localVersion == false and gt.localapk == false then -- 如果是正式包,那么取ip
			if gt.isIOSPlatform() then
				self.luaBridge = require("cocos/cocos2d/luaoc")
			elseif gt.isAndroidPlatform() then
				self.luaBridge = require("cocos/cocos2d/luaj")
			end

			local isRightIp = false
			
			--if gt.isIOSPlatform() then
				-- for i=1,3 do
				-- 	local ok, ret = self.luaBridge.callStaticMethod("AppController", "getYunIP",{ipKey = "xianlai1.u0qr4x4wk3.aliyungf.com"})
				-- 	-- print("===========ffffffffff1",ok,ret)
				-- 	local ipTab = string.split(ret, ".")
				-- 	-- print("===========ffffffffff2",#ipTab)
				-- 	if #ipTab == 4 then -- 正确的ip地址
				-- 		isRightIp = true
				-- 		self.serverIp = ret
				-- 		break
				-- 	end
				-- end
				
				-- 如果三次都有错误,那么不做任何处理,继续使用原先的域名去连接服务器
				--if isRightIp == false then
					--self.serverIp = self.serverIp
				--end
			--elseif gt.isAndroidPlatform() then

				-- for i=1,3 do
				-- 	local ok, ret = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getIP", nil, "()Ljava/lang/String;")
				-- 	local ipTab = string.split(ret, ".")
				-- 	if #ipTab == 4 then -- 正确的ip地址
				-- 		isRightIp = true
				-- 		self.serverIp = ret
				-- 		break
				-- 	end
				-- end
				-- 如果三次都有错误,那么不做任何处理,继续使用原先的域名去连接服务器
				--if isRightIp == false then
				--	gt.log("====gt.LoginServer.ip=======88===" .. gt.LoginServer.ip)
				--	self.serverIp = gt.LoginServer.ip
				--end
				local unionid = cc.UserDefault:getInstance():getStringForKey( "WX_Uuid" )
				self:getHttpServerIp(unionid)
			--end
	
	else
		-- 如果是本地版本,那么应该用测试服
		self.serverIp = self.serverIp
		self:connect(gt.LoginServer.ip, self.serverPort, self.isBlock)
		self:reLogin()
	end
	-- print("=======新的ip，端口",self.serverIp, self.serverPort)

	--self:connect(self.serverIp, self.serverPort, self.isBlock)
end

function SocketClient:getHttpServerIp(uuid)	
    print("SocketClient ip策略 打印信息－－－－－－－－－－－－－－－－－－－－－－－－－－－")
	self.loginState = "ipServer"
	local servername = "jiangxi"
	local srcSign = string.format("%s%s", uuid, servername)
	local sign = cc.UtilityExtension:generateMD5(srcSign, string.len(srcSign))
	local xhr = cc.XMLHttpRequest:new()
	xhr.timeout = 5
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	local refreshTokenURL = string.format("http://secureapi.ixianlai.com/security/server/getIPbyZoneUid")
	xhr:open("POST", refreshTokenURL)
	local function onResp()
		--print("SocketClient xhr.readyState = " .. xhr.readyState .. ", xhr.status = " .. xhr.status)
		--print("SocketClient xhr.statusText = " .. xhr.statusText)
		if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
			--print("xhr.response = " .. xhr.response)
			-- local response = string.sub(xhr.response, 4)
			require("json")

			local respJson = json.decode(xhr.response)
			print("respJson.errorCode = " .. respJson.errorCode)
			if respJson.errorCode == 0 then -- 服务器现在是 字符"0",应该修改为 数字0
				print("SocketClientA respJson.ip = " .. respJson.ip)
				-- errorCode为0则说明成功,否则不成功
				gt.LoginServer.ip = respJson.ip -- 获得可用ip
				print("SocketClientA connect ")
				self:connect(gt.LoginServer.ip, self.serverPort, self.isBlock)
				self:reLogin()
			else
				gt.LoginServer.ip = "jx.xianlaiyx.com"
				print("SocketClientB connect ")
				self:connect(gt.LoginServer.ip, self.serverPort, self.isBlock)
				self:reLogin()
			end
		elseif xhr.readyState == 1 and xhr.status == 0 then
			print("SocketClientC jx2")
			gt.LoginServer.ip = "jx.xianlaiyx.com"
			print("SocketClientC connect")
			self:connect(gt.LoginServer.ip, self.serverPort, self.isBlock)
			self:reLogin()
		end
		xhr:unregisterScriptHandler()
	end
	xhr:registerScriptHandler(onResp)
	xhr:send(string.format("uuid=%s&servername=%s&sign=%s", uuid, servername, sign))
end


-- start --
--------------------------------
-- @class function
-- @description 恢复链接
-- @param
-- @param
-- @param
-- @return
-- end --
function SocketClient:connectResumeBK()
	if self.isConnectSucc or not self.tcpConnection then
		-- 连接成功或者socket.tcp句柄创建失败
		return
	end

	local r, w, e = socket.select({self.tcpConnection}, {self.tcpConnection}, 0.02)
	if not w or e == "timeout" then
		gt.log("Socket select timeout")
		-- gt.dispatchEvent(gt.EventType.NETWORK_ERROR)
		return false
	end
	local connectCode, errorInfo = self.tcpConnection:connect(self.serverIp, self.serverPort)
	if errorInfo ~= "already connected" then
		gt.log("Socket connect errorInfo: " .. errorInfo)
		-- gt.dispatchEvent(gt.EventType.NETWORK_ERROR)
		return false
	end
	self.isConnectSucc = true
	return true
end

-- start --
--------------------------------
-- @class function
-- @description 关闭socket链接
-- end --
function SocketClient:close()
	if self.tcpConnection then
		self.tcpConnection:close()
	end
	self.tcpConnection = nil
	self.isConnectSucc = false
	self.sendMsgCache = {}

	self.isCheckTimeout = false
	self.isPopupNetErrorTips = false
end

-- start --
--------------------------------
-- @class function
-- @description 发送消息放入到缓冲,非真正的发送
-- @param msgTbl 消息体
-- end --
function SocketClient:sendMessage(msgTbl)
	if msgTbl.m_msgId ~= 15 and msgTbl.m_msgId ~= 16 then
		gt.dump(msgTbl)
	end

	-- 打包成messagepack格式
	-- local msgPackData = self.msgPackLib.pack(msgTbl)
	-- local msgLength = string.len(msgPackData)
	-- local highByte = string.char(math.floor(msgLength / 256))
	-- local lowByte = string.char(msgLength % 256)
	-- local msgToSend = lowByte .. highByte .. msgPackData

	-- 打包成messagepack格式
	-- local msgPackData = self.msgPackLib.pack(msgTbl)
	-- local msgLength = string.len(msgPackData)
	-- local highByte = string.char(math.floor(msgLength / 256))
	-- local lowByte = string.char(msgLength % 256)
	-- local msgToSend = lowByte .. highByte .. msgPackData

	local msgPackData = self.msgPackLib.pack(msgTbl)
	local msgLength = string.len(msgPackData)
	local len = self:luaToCByShort(msgLength)

	local curTime = os.time()
	local time = self:luaToCByInt(curTime)
	local msgId = self:luaToCByInt(msgTbl.m_msgId * ((curTime % 10000) + 1))
	local checksum = self:getCheckSum(time .. msgId, msgLength, msgPackData)
	local msgToSend = len .. checksum .. time .. msgId .. msgPackData
	-- 放入到消息缓冲
	table.insert(self.sendMsgCache, msgToSend)
end



function SocketClient:getCheckSum(time, msgLength, msgPackData)
	local crc = ""
	local len = string.len(time) + msgLength
	if len < 8 then
		crc = self:CRC(time .. msgPackData, len)
	else
		crc = self:CRC(time .. msgPackData, 8)
	end
	return self:luaToCByShort(crc)
end

function SocketClient:CRC(data, length)
    local sum = 65535
    for i = 1, length do
        local d = string.byte(data, i)    -- get i-th element, like data[i] in C
        sum = self:ByteCRC(sum, d)
    end
    return sum
end

function SocketClient:ByteCRC(sum, data)
    -- sum = sum ~ data
    local sum = bit:_xor(sum, data)
    for i = 0, 3 do     -- lua for loop includes upper bound, so 7, not 8
        -- if ((sum & 1) == 0) then
        if (bit:_and(sum, 1) == 0) then
            sum = sum / 2
        else
            -- sum = (sum >> 1) ~ 0xA001  -- it is integer, no need for string func
            sum = bit:_xor((sum / 2), 0x70B1)
        end
    end
    return sum
end


function SocketClient:luaToCByInt(value)
	local lowByte1 = string.char(math.floor(value / (256 * 256 * 256)))
	local lowByte2 = string.char(math.floor(value / (256 * 256)) % 256)
	local lowByte3 = string.char(math.floor(value / 256) % 256)
	local lowByte4 = string.char(value % 256)
	return lowByte4 .. lowByte3 .. lowByte2 .. lowByte1
end

function SocketClient:luaToCByShort(value)
	return string.char(value % 256) .. string.char(math.floor(value / 256))
end


-- start --
--------------------------------
-- @class function
-- @description 发送消息
-- @param msgTbl 消息表结构体
-- end --
function SocketClient:send()
	if not self.isConnectSucc or not self.tcpConnection then
		-- 链接未建立
		return false
	end

	if #self.sendMsgCache <= 0 then
		return true
	end

	-- 先发送队列头消息
	local msgToSend = self.sendMsgCache[1]
	self.tcpConnection:settimeout(0)
	gt.log("Send message length:" .. string.len(msgToSend))
	local sendLength, errorInfo = self.tcpConnection:send(msgToSend)
	if sendLength then
		table.remove(self.sendMsgCache, 1)
		gt.log("Send success sendLength: " .. sendLength)

		self.isCheckTimeout = true
		self.timeDuration = 0
	else
		gt.log("Send failed errorInfo:" .. errorInfo)
		-- gt.dispatchEvent(gt.EventType.NETWORK_ERROR, errorInfo)
		return false
	end

	return true
end

-- start --
--------------------------------
-- @class function
-- @description 接收消息并且分发到注册的消息回调
-- end --
-- function SocketClient:receive11()
-- 	if not self.isConnectSucc or not self.tcpConnection then
-- 		-- 链接未建立
-- 		return false
-- 	end

-- 	local rcvContent, errorInfo = self.tcpConnection:receive(2)
-- 	if not rcvContent then
-- 		-- gt.log("SocketClient receive nothing!")
-- 		return
-- 	end
-- 	local needRcvSize = string.byte(rcvContent, 2) * 256 + string.byte(rcvContent, 1)
-- 	gt.log("Need receive message size: " .. needRcvSize)
-- 	local rcvBuffer = ""
-- 	rcvBuffer = self:receiveBuffer(needRcvSize, rcvBuffer)
-- 	-- 解包成lua表结构
-- 	local rcvMsgData = self.msgPackLib.unpack(rcvBuffer)
	
-- 	if rcvMsgData.m_msgId ~= 15 and rcvMsgData.m_msgId ~= 16 and  rcvBuffer then
-- 		gt.dump(rcvMsgData)
-- 	end
-- 	-- 终止检测网络超时
-- 	self.isCheckTimeout = false
-- 	-- 分发消息
-- 	self:dispatchMessage(rcvMsgData)
-- end

-- start --
--------------------------------
-- @class function
-- @description 接收消息内容
-- @param sizeLeft 剩余字节数
-- @param buffer 缓冲区
-- @return 接收的消息体
-- end --
-- function SocketClient:receiveBuffer(sizeLeft, buffer)
-- 	if sizeLeft <= 0 then
-- 		return buffer
-- 	end
-- 	local rcvContent, errorInfo, partialContent = self.tcpConnection:receive(sizeLeft)
-- 	if errorInfo == "closed" then
-- 		gt.log("Socket closed!")
-- 		-- gt.dispatchEvent(gt.EventType.NETWORK_ERROR, errorInfo)
-- 		return nil
-- 	elseif errorInfo == "timeout" then
-- 		gt.log("Socket receive timeout!")

-- 		-- gt.log("rcvContent == " ..rcvContent)
-- 		-- gt.log("errorInfo == " ..errorInfo)
-- 		-- gt.log("partialContent == " ..partialContent)
-- 		-- gt.log("sizeLeft == " ..sizeLeft)
-- 		if partialContent and #partialContent > 0 then
-- 			buffer = buffer .. partialContent
-- 			gt.log(" time out 有数据 接着接")
-- 			return self:receiveBuffer(sizeLeft - #partialContent, buffer)
-- 		end
-- 		-- gt.dispatchEvent(gt.EventType.NETWORK_ERROR)
-- 			gt.log(" time out 没数据，返回空")
-- 		return nil
-- 	else
-- 		gt.log("Success receive size: " .. #rcvContent)
-- 		buffer = buffer .. rcvContent
-- 		return self:receiveBuffer(sizeLeft - #rcvContent, buffer)
-- 	end
-- end

-- start --
--------------------------------
-- @class function
-- @description 注册msgId消息回调
-- @param msgId 消息号
-- @param msgTarget
-- @param msgFunc 回调函数
-- end --
function SocketClient:registerMsgListener(msgId, msgTarget, msgFunc)
	-- if not msgTarget or not msgFunc then
	-- 	return
	-- end

	self.rcvMsgListeners[msgId] = {msgTarget, msgFunc}
end

-- start --
--------------------------------
-- @class function
-- @description 注销msgId消息回调
-- @param msgId 消息号
-- end --
function SocketClient:unregisterMsgListener(msgId)
	self.rcvMsgListeners[msgId] = nil
end

-- start --
--------------------------------
-- @class function
-- @description 分发消息
-- @param msgTbl 消息表结构
-- end --
function SocketClient:dispatchMessage(msgTbl)
	local rcvMsgListener = self.rcvMsgListeners[msgTbl.m_msgId]
	if rcvMsgListener then
		rcvMsgListener[2](rcvMsgListener[1], msgTbl)
	else
		gt.log("Could not handle Message " .. tostring(msgTbl.m_msgId))
	end
end

function SocketClient:setIsStartGame(isStartGame)
	self.isStartGame = isStartGame

	self.loginReconnectNum = 10

	-- 心跳消息回复
	self:registerMsgListener(gt.GC_HEARTBEAT, self, self.onRcvHeartbeat)
end

-- start --
--------------------------------
-- @class function
-- @description 向服务器发送心跳
-- @param isCheckNet 检测和服务器的网络连接
-- end --
function SocketClient:sendHeartbeat(isCheckNet)
	if not self.isStartGame then
		return
	end

	local msgTbl = {}
	msgTbl.m_msgId = gt.CG_HEARTBEAT
	self:sendMessage(msgTbl)

	self.curReplayInterval = 0

	self.isCheckNet = isCheckNet
	if isCheckNet then
		-- 防止重复发送心跳,直接进入等待回复状态
		self.heartbeatCD = -1
	end
end

-- start --
--------------------------------
-- @class function
-- @description 服务器回复心跳
-- @param msgTbl
-- end --
function SocketClient:onRcvHeartbeat(msgTbl)
	self.heartbeatCD = self.heatTime
	self.lastReplayInterval = self.curReplayInterval
end

-- start --
--------------------------------
-- @class function
-- @description 获取上一次心跳回复时间间隔用来判断网络信号强弱
-- @return 上一次心跳回复时间间隔
-- end --
function SocketClient:getLastReplayInterval()
	return self.lastReplayInterval
end

function SocketClient:update(delta)
	self:send()
	self:receive()

	-- 检测网络链接超时
	if self.isCheckTimeout then
		self.timeDuration = self.timeDuration + delta
		if self.timeDuration >= 16 then
			self.isCheckTimeout = false
			self.timeDuration = 0
			gt.dispatchEvent(gt.EventType.NETWORK_ERROR, "timeout")
		end
	end

	if self.isStartGame then
		if self.heartbeatCD >= 0 then
			-- 登录服务器后开始发送心跳消息
			self.heartbeatCD = self.heartbeatCD - delta
			if self.heartbeatCD < 0 then
				-- 发送心跳
				self:sendHeartbeat(true)
			end
		else
			-- 心跳回复时间间隔
			self.curReplayInterval = self.curReplayInterval + delta

			if self.isCheckNet and self.curReplayInterval >= 8 then
				self.isCheckNet = false
				-- 心跳时间稍微长一些,等待重新登录消息返回
				self.heartbeatCD = self.heatTime
				-- 监测网络状况下,心跳回复超时发送重新登录消息
				self:reloginServer()
			end
		end
	end
end

function SocketClient:reloginServer()
	gt.showLoadingTips(gt.getLocationString("LTKey_0001"))

	-- 链接关闭重连
	self:close()
	self.serverPort = gt.LoginServer.port
	if gt.isTestClient then
		self.serverPort = gt.TestLoginServer.port
	end
	self:connectResume()

	-- 发送重联消息
	-- local msgToSend = {}
	-- msgToSend.m_msgId = gt.CG_RECONNECT
	-- msgToSend.m_seed = gt.loginSeed
	-- msgToSend.m_id = gt.playerData.uid
	-- local catStr = tostring(gt.loginSeed)
	-- msgToSend.m_md5 = cc.UtilityExtension:generateMD5(catStr, string.len(catStr))
	-- self:sendMessage(msgToSend)

	--[[
	local runningScene = display.getRunningScene()
	if runningScene then
		gt.log("============66====")
		runningScene:reLogin()
	end
	--]]
end
function SocketClient:reLogin()
	local runningScene = display.getRunningScene()
	if runningScene and runningScene["reLogin"] then
		runningScene:reLogin()
	end
end

function SocketClient:networkErrorEvt(eventType, errorInfo)
	gt.log("networkErrorEvt errorInfo:" .. errorInfo)

	if self.isPopupNetErrorTips then
		return
	end

	if self.isStartGame then
	 	return
	end

	local tipInfoKey = "LTKey_0047"
	if errorInfo == "connection refused" then
		-- 连接被拒提示服务器维护中
		tipInfoKey = "LTKey_0002"
	end

	if self.loginReconnectNum < 3 and self.isStartGame == false then
		self.loginReconnectNum = self.loginReconnectNum + 1
		self:connectResume()
		return
	end

	self.isPopupNetErrorTips = true
	require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString(tipInfoKey),
		function()
			self.isPopupNetErrorTips = false
			gt.removeLoadingTips()

			if errorInfo == "timeout" then
				-- 检测网络连接
				gt.log("-----5555----")
				self:sendHeartbeat(true)
			end
		end, nil, true)
end


function SocketClient:receive()
	if not self.isConnectSucc or not self.tcpConnection then
		-- 链接未建立
		return
	end
	
	local messageQueue = {}
	self:receiveMessage(messageQueue)
	
	if #messageQueue <= 0 then
		return
	end

	-- gt.log("Recv meesage package:" .. #messageQueue)
	
	for i,v in ipairs(messageQueue) do
		if v.m_msgId ~= 15 and v.m_msgId ~= 16 then
			dump(v)
		end
		self:dispatchMessage(v)
	end
end

function SocketClient:receiveMessage(messageQueue)
	if self.remainRecvSize <= 0 then
		return true
	end

	local recvContent,errorInfo,otherContent = self.tcpConnection:receive(self.remainRecvSize)
	if errorInfo ~= nil then
		if errorInfo == "timeout" then --由于timeout为0并且为异步socket，不能认为socket出错
			if otherContent ~= nil and #otherContent > 0 then
				self.recvingBuffer = self.recvingBuffer .. otherContent
				self.remainRecvSize = self.remainRecvSize - #otherContent

				gt.log("recv timeout, but had other content. size:" .. #otherContent)
			end
			
			return true
		else	--发生错误，这个点可以考虑重连了，不用等待heartbeat
			gt.log("Recv failed errorinfo:" .. errorInfo)
			return false
		end
	end
	
	local contentSize = #recvContent
	self.recvingBuffer = self. .. recvContent
	self.remainRecvSize = self.remainRecvSize recvingBuffer- contentSize

	-- gt.log("success recv size:" .. contentSize ..  "   remainRecvSize is:" .. self.remainRecvSize)
	
	if self.remainRecvSize > 0 then	--等待下次接收
		return true
	end
	
	if self.recvState == "Head" then
		self.remainRecvSize = string.byte(self.recvingBuffer, 2) * 256 + string.byte(self.recvingBuffer, 1)
		self.recvingBuffer = ""
		self.recvState = "Body"
	elseif self.recvState == "Body" then
		local messageData = self.msgPackLib.unpack(self.recvingBuffer)
		table.insert(messageQueue, messageData)
		self.remainRecvSize = self.msgHeadSize  --下个包头
		self.recvingBuffer = ""
		self.recvState = "Head"
	end

	--继续接数据包
	--如果有大量网络包发送给客户端可能会有掉帧现象，但目前不需要考虑，解决方案可以1.设定总接收时间2.收完body包就不在继续接收了
	return self:receiveMessage(messageQueue)
end

function SocketClient:initSocketBuffer()
	-- 发送消息缓冲
	self.sendMsgCache = {}
	self.sendingBuffer = ""
	self.remainSendSize = 0
	
	self.msgHeadSize = 12
	-- 接收消息
	self.recvingBuffer = ""
	self.remainRecvSize = self.msgHeadSize --剩余多少数据没有接受完毕,2:头部字节数
	self.recvState = "Head"
end

return SocketClient

