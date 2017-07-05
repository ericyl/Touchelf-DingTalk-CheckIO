-- 脚本描述
DESCRIPTION="触摸精灵-钉钉签到签退脚本 v1.2.0";
--CHANGELOG
-- v1.2.0
--      新增时令签退日期修改, (默认签退时间17:30)
--      修改 Log 输出逻辑
-- v1.1.2
--      新增工作小红点图标位置判断
-- v1.1.1
--      修复若干BUG
-- v1.1.0
--      新增签到签退延时功能
-- v1.0.1
--      修改为使用图片识别方式判断位置
-- v1.0
--      完成脚本编写

-- 适用屏幕参数
SCREEN_RESOLUTION="720x1080";
SCREEN_COLOR_BITS=32;

--默认签退时间17:30
checkOutTime = 1050;
-- 主入口
function main()
    --防黑屏，请将黑屏时间间隔调到最大：例如：30分钟
    clickBackBtn();
    
    --使用网络时间【有问题】
    --time = getNetTime();
    --if time ~= -1 then
        --tt = os.date("*t", time);
        --localTime=(tt.hour * 60 + tt.min);
    --else
        --logDebug("请连接网络");
        --return;
    --end
    
    --时令修改标记
    flag = true;
    
    --使用本地时间
    --时间判断是否为夏时令
    localDate=((tonumber(os.date("%m")) or 1) * 100 + (tonumber(os.date("%d")) or 1));
    --判断 7月1日-9月15日 且 时令修改标记为 true 时修改 签退时间+30分钟
    if flag and localDate > 700 and localDate < 916 then
        checkOutTime = checkOutTime + 30;
    end
    localTime=(os.date("%H") * 60 + os.date("%M"));
    --判断签到/签退时间
    if localTime >= 485 and localTime <= 510 then
        logDebug(string.format("当前时间: %s", localTime));
        --签到
        checkIn = doCheckIn(localTime);
        --log输出
        checkInMsg = "失败";
        if checkIn then 
            checkInMsg = "成功";
        end
        logDebug("--------------------------------");
        logDebug(string.format("签到: %s !", checkInMsg));
        logDebug("--------------------------------");
    elseif localTime >= checkOutTime and localTime <= checkOutTime + 60 then
        logDebug(string.format("当前时间: %s", localTime));
        --签退
        checkOut = doCheckOut(localTime);
        --log输出
        checkOutMsg = "失败";
        if checkOut then 
            checkOutMsg = "成功";
        end
        logDebug("--------------------------------");
        logDebug(string.format("签退: %s !", checkOutMsg));
        logDebug("--------------------------------");
    end
end

--签到
function doCheckIn(localTime)
    --关闭钉钉
    --killDingTalkFlag  = killDingTalk();
    if killDingTalk() == false then
        return false;
    end
    mSleep(10 * 1000);
    logDebug("准备上班打卡");
    --获取8:25以前随机打卡时间，可自行调整
    local randomTime = 0;
    if localTime < 500 then
        randomTime = math.random(500 - localTime);
        logDebug(string.format("上班打卡延迟 %s 分钟。", randomTime));
        mSleep(randomTime * 60 * 1000);
    end
    logDebug("开始上班打卡");
    --打开钉钉，使用急速打卡
    openDingTalkFlag = openDingTalk();
    mSleep(60 * 1000);
    if openDingTalkFlag then
        logDebug("上班急速打卡完成");
    end
    return openDingTalkFlag;
end

--签退
function doCheckOut(localTime)
    --关闭钉钉
    --killDingTalkFlag  = killDingTalk();
    if killDingTalk() == false then
        return false;
    end
    mSleep(10 * 1000);
    --获取17:45以前随机打卡时间，可自行调整
    if localTime < checkOutTime + 15 then
        randomTime = math.random(checkOutTime + 15 - localTime);
        logDebug(string.format("下班打卡延迟 %s 分钟。", randomTime));
        mSleep(randomTime * 60 * 1000);
    end
    logDebug("准备下班打卡");
    --打开钉钉
    --openDingTalkFlag = openDingTalk();
    if openDingTalk() == false then
        return false;
    end
    mSleep(20 * 1000);
    logDebug("打开工作");
    --判断并打开工作。分两种图标，一种纯图标，一种带提示红点的图标。【根据手机分辨率大小，自行修改0, 1623, 1080, 1920参数】
    workX, workY = findImageInRegionFuzzy("ic_work.bmp", 90, 0, 1080, 720, 1280, 0xF7F7F7);
    workOtherX, workOtherY = findImageInRegionFuzzy("ic_work_other.bmp", 90, 0, 1080, 720, 1280, 0xF7F7F7);         
    if workX ~= -1 and workY ~= -1 then  
        logDebug(string.format("匹配工作位置 %s, %s", workX, workY));
        touchDown(0, workX, workY);
        mSleep(100);
        touchUp(0);
    elseif workOtherX ~= -1 and workOtherY ~= -1 then 
        logDebug(string.format("匹配工作位置 %s, %s", workOtherX, workOtherY));
        touchDown(0, workOtherX, workOtherY);
        mSleep(100);
        touchUp(0);
    else
        return false;
    end
    mSleep(20 * 1000);
    logDebug("进入考勤打卡页面");
    --判断并打开考勤打卡。【根据手机分辨率大小，自行修改0, 1086, 1080, 1616参数】
    attendanceX, attendanceY = findImageInRegionFuzzy("ic_attendance.bmp", 90, 0, 100, 720, 1080, 0xFFFFFF);     
    if attendanceX ~= -1 and attendanceY ~= -1 then  
        logDebug(string.format("匹配考勤打卡位置 %s, %s", attendanceX, attendanceY));
        touchDown(0, attendanceX, attendanceY);
        mSleep(100);
        touchUp(0);
    else 
        return false;
    end
    mSleep(20 * 1000);
    logDebug("开始下班打卡");
    --循环多次判断签退图片位置。循环次数可自行修改
    local i = 1;
    while (i < 6)  do
        logDebug(string.format("尝试第 %d 次匹配图片位置", i));
        --【根据手机分辨率大小，自行修改0, 960, 1080, 1920参数】
        checkOutX, checkOutY = findImageInRegionFuzzy("ic_check_out.bmp", 80, 0, 600, 720, 1080);         
        if checkOutX ~= -1 and checkOutY ~= -1 then  
            logDebug(string.format("匹配签退位置 %s, %s", checkOutX, checkOutY));
            touchDown(0, checkOutX + 150, checkOutY + 150);--【根据手机分辨率大小，自行修改150数值】
            mSleep(100);
            touchUp(0);
            logDebug("下班打卡完成!");
            return true;
        else
            logDebug("匹配失败, 或已下班打卡成功!");
            mSleep(500);
            i = i + 1;
        end
    end
    return false;
end

--关闭钉钉
function killDingTalk()
    logDebug("开始关闭钉钉!");
    killAppFlag = killApp("com.alibaba.android.rimet");
    killAppMsg = "失败";
    if killAppFlag then 
        killAppMsg = "成功";
    end
    logDebug(string.format("关闭钉钉 %s !", killAppMsg));
    return killAppFlag;
end

--关闭App
function killApp(appPackage)
    local i = 1;
    while i < 20 do 
        if appRunning(appPackage) then 
            appKill(appPackage);
            mSleep(1000);
        else
            return true;
        end
        i = i + 1;
    end
    return false;
end

--打开钉钉
function openDingTalk()
    logDebug("开始打开钉钉!");
    openAppFlag = openApp("com.alibaba.android.rimet");
    openAppMsg = "失败";
    if openAppFlag then 
        openAppMsg = "成功";
    end
    logDebug(string.format("打开钉钉 %s !", openAppMsg));
    return openAppFlag;
end

--打开App
function openApp(appPackage)
    appRun(appPackage);
    mSleep(10 * 1000);
    local i = 1;
    while i < 20 do 
        if appRunning(appPackage) then 
            return true;
        else
            appRun(appPackage);
            mSleep(5 * 1000);
        end
        i = i + 1;
    end
    return false;
end

--返回
function clickBackBtn()
    mSleep(500);
    os.execute("input keyevent 4"); -- back
end

--Home
function clickHomeBtn()
    mSleep(500);
    os.execute("input keyevent 3"); -- home
end

--App选择界面
function clickAppSwitchBtn()
    mSleep(500);
    os.execute("input keyevent 187"); --app switch      
end
