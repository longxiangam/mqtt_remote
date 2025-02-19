
-- LuaTools需要PROJECT和VERSION这两个信息
PROJECT = "pwmdemo"
VERSION = "1.0.0"

log.info("main", PROJECT, VERSION)

-- sys库是标配
_G.sys = require("sys")
--[[特别注意, 使用mqtt库需要下列语句]]
_G.sysplus = require("sysplus")
--添加硬狗防止程序卡死
if wdt then
    wdt.init(15000)--初始化watchdog设置为9s
    sys.timerLoopStart(wdt.feed, 3000)--3s喂一次狗
end

local PWM_ID = 9
-- wifi 信息
local WIFI_SSID = ""
local WIFI_PASSWORD = ""
--根据自己的服务器修改以下参数
local mqtt_host = ""
local mqtt_port = 8883
local mqtt_isssl = true
local client_id = "ep32c3-1"
local user_name = ""
local password = ""

local pub_topic = "/luatos/pub/pc" 
local sub_topic = "/luatos/sub/" .. client_id
local mqttc = nil

local LEDA= gpio.setup(12, 0, gpio.PULLUP)
local LEDB= gpio.setup(13, 0, gpio.PULLUP)
LEDA( 0 ) 
LEDB( 0 ) 
local timer_count = 0
local net_test_count = 0
local enable_net_test = false

fskv.init()
--[[ fskv.set("wendal", 1234) ]]
--log.info("fskv", "wendal", fskv.get("wendal"))

sys.taskInit(function ()
    log.info("os.date()", os.date())
    local t = rtc.get()
    log.info("rtc", json.encode(t))
    sys.wait(2000)
    -- rtc.set({year=2023,mon=6,day=8,hour=0,min=0,sec=0})
    log.info("os.date()", os.date()) 
   
    while true do
        timer_count = timer_count + 1
        if enable_net_test then 
            net_test_count = net_test_count + 1
        end

        sys.wait(1000)
        if net_test_count > 60 then
            net_test_count = 0
            -- 判断网络，无连接则重启
            local net_test_time = 0;
            local code, headers, body
            while net_test_time < 5 do
                code, headers, body = http.request("GET", "http://yii.gisun.top/net_test.txt", nil, nil, { timeout = 5000 })
                .wait()
                if body ~= nil then
                    body = string.gsub(body, " ", "")
                    body = string.gsub(body, "\n", "")
                end
                log.info("request times:", net_test_time)
                log.info("http", code, body)
                if body == "ok" then
                    break
                else
                    net_test_time = net_test_time + 1
                    sys.wait(1000)
                end
            end
            if body ~= "ok" then
                -- 重启
                log.info("reboot :", net_test_time)
                rtos.reboot()
            end


        end
        if(timer_count % 30 == 0) then 
            timer_trigger();
        end

        if (timer_count > 3600) then 
            timer_count = 0
            -- do_click(1, 179)
        end
    end
end)



sys.taskInit(function()
    sys.wait(1000)
    -- pwm.open(PWM_ID, 50, 25, 0, 1000) -- 复位舵机
    wlan.init()
    -- 修改成自己的ssid和password
    wlan.connect(WIFI_SSID, WIFI_PASSWORD,1)
    -- wlan.connect("uiot", "")
    log.info("wlan", "wait for IP_READY")
    
    while not wlan.ready() do
        local ret, ip = sys.waitUntil("IP_READY", 30000)
        -- wlan连上之后, 这里会打印ip地址
        log.info("ip", ret, ip)
        if ip then
            _G.wlan_ip = ip
        end
    end
    log.info("wlan", "ready !!", wlan.getMac())
    sys.wait(1000)

    web_start()

    mqtt_start()

    log.info("web", "pls open url http://" .. _G.wlan_ip .. "/")
end)

function mqtt_start()
    log.info("mqtt_start")
    mqttc = mqtt.create(nil, mqtt_host, mqtt_port, mqtt_isssl)
    if(mqttc ==nil) then
        log.info("mqttc failed")
    else
        log.info("mqtt_start success")
    end
    
    mqttc:auth(client_id,user_name,password) -- client_id必填,其余选填
    mqttc:keepalive(60) -- 默认值240s
    mqttc:autoreconn(true, 3000) -- 自动重连机制

    local reconnect_count = 0
    mqttc:on(function(mqtt_client, event, data, payload)
        --用户自定义代码
        log.info("mqtt", "event", event, mqtt_client, data, payload)
        if event == "conack" then
            reconnect_count = 0
            -- 联上了
            sys.publish("mqtt_conack")
            mqtt_client:subscribe(sub_topic)--单主题订阅

            mqtt_client:publish(pub_topic, "boot sucess")
            light(12, 5)
            -- mqtt_client:subscribe({[topic1]=1,[topic2]=1,[topic3]=1})--多主题订阅
        elseif event == "recv" then
            log.info("mqtt", "downlink", "topic", data, "payload", payload)
            sys.publish("mqtt_payload", data, payload)
            local body_obj = json.decode(payload)
            if (body_obj) then
                if body_obj.action == "trigger" then
                    log.info("second", body_obj.second)
                    log.info("angle", body_obj.angle)
                    do_click(body_obj.second, body_obj.angle)
                    mqtt_client:publish(pub_topic, "has been done"..payload)
                end

                if body_obj.action == "reboot" then
                    log.info("reboot by mqtt")
                   
                    mqtt_client:publish(pub_topic, "do reboot"..payload)
                    sys.wait(10)
                    rtos.reboot()
                end
             
                if body_obj.action == "read_timer" then
                    local  timer_setting = get_timer_setting();
                    local response = {};
                    response.action = "read_timer";
                    response.timer_setting = timer_setting;
                    mqtt_client:publish(pub_topic, "json:"..json.encode(response)); 
                end

                if body_obj.action == "save_timer" then
                    set_timer_setting(body_obj.timer_setting);
                    local response = {};
                    response.action = "save_timer";
                    response.success = 1;
                    mqtt_client:publish(pub_topic, "json:"..json.encode(response)); 
                end
            end
        elseif event == "sent" then
            log.info("mqtt", "sent", "pkgid", data)
        elseif event == "disconnect" then
            -- 非自动重连时,按需重启mqttc
            -- mqtt_client:connect()
            reconnect_count = reconnect_count + 1
            log.info("mqtt disconnect", "reconnect_count :", reconnect_count)
            -- 重连10次重启
            if reconnect_count > 10 then
                rtos.reboot()
            end
        end
    end)
    -- 发起连接之后，mqtt库会自动维护链接，若连接断开，默认会自动重连
    mqttc:connect()
    sys.waitUntil("mqtt_conack")
    log.info("mqtt连接成功")
   
    while true do
        -- mqttc自动处理重连
        local ret, topic, data, qos = sys.waitUntil("mqtt_pub", 5000)
        if ret then
            if topic == "close" then break end

            log.info("mqtt publish")
            mqttc:publish(topic, data, qos)
        end
    end
    mqttc:close()
    mqttc = nil 
end

function web_start()
    httpsrv.start(80, function(fd, method, uri, headers, body)
        log.info("httpsrv", method, uri, json.encode(headers), body)
        -- meminfo()
        local body_obj = json.decode(body)
        log.info("second", body_obj.second)
        log.info("level", body_obj.level)
        if uri == "/led" then
            do_click(body_obj.second,body_obj.level)
            return 200, {}, "ok"
        end
        return 404, {}, "Not Found" .. uri
    end)
end


function do_click(second,angle)
    sys.taskInit(function()
        log.info("do_click", ">>>>>second:",second,",angle:",angle)
        LEDB(1)
        pwm.open(PWM_ID, 50, transAngle(angle), 0, 1000)
        sys.wait(second * 1000)
        pwm.open(PWM_ID, 50, transAngle(180), 0, 1000)
        LEDB(0)

    end)
end

function light(ioPort, level)
    log.info("light")
    pwm.open(ioPort, 1000, level * 10, 0, 1000)
end

function transAngle(angle)
    -- 0 度的基数
    local angle_0 = 25;
    -- 180 度的基数
    local angle_180 = 125;

    -- 单位个角度的量值
    local angle_single = (angle_180 - angle_0) / 180;

    return angle_0 + angle * angle_single

end


-- 定时相关
TIMER_KEY = "timer_setting"
local last_trigger_time = nil; -- 上次触发时间

function test_timer()
    set_timer_setting({{time="12:05",enable=true,volume=3},{time="12:06",enable=true,volume=3}})
end
function get_timer_setting()
    return json.decode(fskv.get(TIMER_KEY))
end
function set_timer_setting(value)
    return fskv.set(TIMER_KEY,json.encode(value))
end

function timer_trigger()
   local time_str = os.date("%H:%M");
   local timer_setting = get_timer_setting();

   if timer_setting then

        for i = 1, #timer_setting, 1 do
            local time = timer_setting[i].time;           -- 时间
            local enable = timer_setting[i].enable;       -- 启用
            local volume = timer_setting[i].volume;       -- 量

            if (enable == true and time == time_str and last_trigger_time ~= time_str ) then -- 当前时间等于设定时间且启用时触发
                log.info("timer_trigger", ">>>>>time:", time, ",enable:", enable, ",volume:", volume)
                for j = 1, volume, 1 do
                    do_click(0.5, 90)
                    sys.wait(1500)
                end
               
                last_trigger_time = time_str
                break
            end
        end

   end
end


-- test_timer();
-- 用户代码已结束---------------------------------------------
-- 结尾总是这一句
sys.run()
-- sys.run()之后后面不要加任何语句!!!!!
