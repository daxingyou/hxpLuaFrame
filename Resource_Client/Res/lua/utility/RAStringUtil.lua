

local tostring = tostring
local tonumber = tonumber
local LanguageChooseTag = "RA_Language_Tag"
local RAStringUtil = {
	-- _curlanguage="cn",  --当前语言
    -- _preLanguage = "",  --前一种语言
    -- _langFileName= "", -- 语言配置文件
    -- _errorFileName="", -- 错误码配置文件
    -- _htmlFileName="", -- html配置文件
    -- 限制词是否初始化过
    mRestrictWordInited = false
}

function RAStringUtil:reset()
    self._curlanguage = nil
    self._preLanguage = nil
end

--filter lang code in both android and ios
function RAStringUtil:filterLangCode(lang)
    if lang:find("zh_TW") ~=nil or lang:find("zh-Hant")~=nil then
        return "zh_TW";
    elseif lang:find("zh_CN") ~=nil or lang:find("zh-Hans")~=nil then
        return "zh_CN";
    elseif lang:find("en") ~=nil then
        return   "en";
    elseif lang:find("pt") ~=nil then
        return   "pt";
    elseif lang:find("tr") ~=nil then
        return   "tr";
    elseif lang:find("fr") ~=nil then
        return   "fr";
    elseif lang:find("no") ~=nil then
        return   "no";
    elseif lang:find("ko") ~=nil then
        return   "ko";
    elseif lang:find("ja") ~=nil then
        return   "ja";
     elseif lang:find("nl") ~=nil then
        return   "nl";
     elseif lang:find("it") ~=nil then
        return   "it";
     elseif lang:find("de") ~=nil then
        return   "de";
     elseif lang:find("es") ~=nil then
        return   "es";
     elseif lang:find("th") ~=nil then
        return   "th";
     elseif lang:find("ru") ~=nil then
        return   "ru";
     elseif lang:find("pl") ~=nil then
        return   "pl";
    else
        return "zh_CN"
    end
end

--get the device raw currrent lang
function RAStringUtil:getDeviceCurLang()
    local lang_default_type = CCApplication:sharedApplication():getCurrentLanguageStr()
    return self:filterLangCode(lang_default_type)
end

--get the game's current language, if didn't has the stored language, use the system language
--if config not exist, use chinese instead
function RAStringUtil:getCurrentLang()
    local lang_default_type = self:getDeviceCurLang()
    local i18nconfig_conf = dynamic_require("i18nconfig_conf")
    local lang_type= CCUserDefault:sharedUserDefault():getStringForKey(LanguageChooseTag,lang_default_type)

    local curLanguageInfo = i18nconfig_conf[lang_type]
    --if do not has the config, use cn
    if curLanguageInfo==nil then
        lang_type = "zh_CN"
        curLanguageInfo = i18nconfig_conf[lang_type]
    end 
    local _langFileName = curLanguageInfo.langSrcPath
    local _errorFileName = curLanguageInfo.errorSrcPath
    local _htmlFileName = curLanguageInfo.htmlSrcPath

    local isExistLangFile = RAGetPathByFileName(_langFileName)
    local isExistErrorFile = RAGetPathByFileName(_errorFileName)
    local isExistHtmlFile = RAGetPathByFileName(_errorFileName)
    --if do not has the file, use cn instead
    if not isExistLangFile or not isExistErrorFile or not isExistHtmlFile then
        lang_type = "zh_CN"
    end
    CCUserDefault:sharedUserDefault():setStringForKey(LanguageChooseTag,lang_type)
    return lang_type
        
end

function RAStringUtil:initLanguage(languageInfo)
    local i18nconfig_conf = dynamic_require("i18nconfig_conf")
    self._curlanguage = languageInfo.languageName
    self._preLanguage = self._curlanguage

    RAUnload(self._langFileName)
    RAUnload(self._errorFileName)
    RAUnload(self._htmlFileName)
    

    self._langFileName = languageInfo.langSrcPath
    self._errorFileName = languageInfo.errorSrcPath
    self._htmlFileName = languageInfo.htmlSrcPath

    local isExistLangFile = RAGetPathByFileName(self._langFileName)
    local isExistErrorFile = RAGetPathByFileName(self._errorFileName)
    local isExistHtmlFile = RAGetPathByFileName(self._errorFileName)
    if not isExistLangFile or not isExistErrorFile or not isExistHtmlFile then
        
         self._langFileName = "lang_zh_cn"
         self._errorFileName = "error_zh_cn"
         self._htmlFileName = "html_zh_cn"
         self._txtTab = RARequire(self._langFileName)
         self._errorTab = RARequire(self._errorFileName)
         self._htmlTab = RARequire(self._htmlFileName)
         languageInfo = i18nconfig_conf[lang_default_type]
         self._curlanguage = languageInfo.id
         
    else
         self._txtTab = RARequire(self._langFileName)
         self._errorTab = RARequire(self._errorFileName)
         self._htmlTab = RARequire(self._htmlFileName)
    end

    CCUserDefault:sharedUserDefault():setStringForKey(LanguageChooseTag, languageInfo.id)
   
end

--切换，选择语言
function RAStringUtil:chooseLanguage(lang_type)
    local i18nconfig_conf = dynamic_require("i18nconfig_conf")
    local chooseLanguageInfo = i18nconfig_conf[lang_type]
    if self._curlanguage == chooseLanguageInfo.id then
        return 
    else
        self:initLanguage(chooseLanguageInfo)
    end
end

--系统默认的设置语言
function RAStringUtil:setLanguage()
    local i18nconfig_conf = dynamic_require("i18nconfig_conf")
    local lang_type= self:getCurrentLang()
    local curLanguageInfo = i18nconfig_conf[lang_type]
    self:initLanguage(curLanguageInfo)

end
function RAStringUtil:trim(s)
	return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

function _RALangFill(key,...)
   return RAStringUtil:fill(RAStringUtil._txtTab[key],...)
end
function _RAHtmlFill(key,...)
   return RAStringUtil:fill(RAStringUtil._htmlTab[key],...)
end
function RAStringUtil:fill(s, ...)
	if s == nil then
		return ""
	end
	local o = tostring(s)
	for i = 1, select("#", ...) do
		o = o:gsub("{"..(i-1).."}", tostring((select(i, ...))))
	end
	return o
end

function _RALang( key, ... )
    -- return RAStringUtil:getLanguageString(key, ...)
    return RAStringUtil:getLanguageStringByKey(key, ...)
end
--example:
--RAStringUtil:getLanguageString("101000")
--RAStringUtil:getLanguageString("102502",30)
--RAStringUtil:getLanguageString("101385",30,100)

function _RAHtmlLang(key,...)
    return RAStringUtil:getHTMLString(key, ...)
end
function RAStringUtil:getLanguageString(key, ...)
    if not string.find(tostring(key),"@") then return key end
    if RAStringUtil._txtTab[key] == nil then return key end 
    return self:fill(RAStringUtil._txtTab[key], ...)
end


function RAStringUtil:getLanguageStringByKey(key, ...)
    if not string.find(tostring(key),"@") then return key end

    local txt=RAStringUtil._txtTab[key]
    if txt == nil then return key end 
    
    txt=self:getLanguageString(key,...)
    local tmpTxt=txt
    local index=1
    local startSplit="%["
    local endSplit="]"
    while string.find(tmpTxt,startSplit,index) do

        --找到第一次出现的位置和结束位置
        local startIndex=string.find(tmpTxt,startSplit,index)  
        local endIndex=string.find(tmpTxt,endSplit,index)
        local subTxt=string.sub(tmpTxt,startIndex+1,endIndex-1)
        local tsubTxt=subTxt

        --存在逗号表示有参数填入
        local paraIndex=1
        local paramTab={}
        if string.find(subTxt,",",paraIndex) then
            paramTab=self:split(subTxt,",")
            table.remove(paramTab,1)
            paraIndex=string.find(subTxt,",",paraIndex)
            subTxt=string.sub(tmpTxt,startIndex+1,startIndex+paraIndex-1) 
            local count=#paramTab
            if count==1 then
                 txt=string.gsub(txt,startSplit..tsubTxt..endSplit,self:getLanguageString(subTxt,paramTab[1]))
            elseif count==2 then
                 txt=string.gsub(txt,startSplit..tsubTxt..endSplit,self:getLanguageString(subTxt,paramTab[1],paramTab[2]))
            elseif count==3 then
                 txt=string.gsub(txt,startSplit..tsubTxt..endSplit,self:getLanguageString(subTxt,paramTab[1],paramTab[2],paramTab[3]))
            end 
           
        else

            txt=string.gsub(txt,startSplit..subTxt..endSplit,self:getLanguageString(subTxt))
        end
    
        index=endIndex+1
    end

    return txt 
end

--example:
--RAStringUtil:getHTMLString("101000")
--RAStringUtil:getHTMLString("102502",30)
--RAStringUtil:getHTMLString("101385",30,100)
function RAStringUtil:getHTMLString(key, ...)
    -- if not string.find(tostring(key),"@") then return key end
    if RAStringUtil._htmlTab[key] == nil then return key end 
    return self:fill(RAStringUtil._htmlTab[key], ...)
end


function RAStringUtil:getErrorString(key, ...)
    if RAStringUtil._errorTab[key] == nil then return key end 
    return self:fill(RAStringUtil._errorTab[key], ...)
end

function RAStringUtil:split(str, delim, maxNb)
    if string.find(str, delim) == nil then
        return {str}
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

--获取一串字符所占的行数
--fontSize:字号
--width:文字框宽度
function RAStringUtil:getStringLineNumber( str, fontSize, width )
    -- body
    local length = RAStringUtil:getStringUTF8Len(str)
    local lineNumber = length * fontSize / width
    return math.ceil(lineNumber)
end

--重置html文本，宽度，超过的末尾 ... 
function RAStringUtil:resetHTMLStringWidth(htmlLabel, width)
    -- body
    local content = htmlLabel:getString()
    local chtml   = htmlLabel:getHTMLContentSize()
    local cw, ch  = chtml.width, chtml.height
    if width >= cw then
        --todo
        return
    end

    local lenInByte = #content
    local index = lenInByte
    while (index > 0) do
        --todo
        local curByte = string.byte(content, index)
        local char
        if curByte >= 0 and curByte <= 127 then
            --todo
            index = index - 1
        else
            --todo
            index = index - 3
        end

        char = string.sub(content, 1, index)

        htmlLabel:setString(char)
        chtml = htmlLabel:getHTMLContentSize()
        cw    = chtml.width
        if width >= cw then
            --todo
            char = char.."..."
            htmlLabel:setString(char)
            return
        end
    end
end

--获取带utf8格式汉字的字符串长度
function RAStringUtil:getStringUTF8Len(str)
    --todo
    local len = #str
    local left = len
    local cnt = 0
    local arr = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        --todo
        local tmp = string.byte(str, -left)
        local i = #arr
        while arr[i] do
            if tmp >= arr[i] then
                --todo
                left = left - i
                break
            end
            i = i-1
        end
        cnt = cnt + 1
    end
    return cnt
end

--added by phan for parse "10000_1007_750,10000_1009_50" wiht "," and "_"
function RAStringUtil:parseWithComma(str, keyList)
    local items = {}
    keyList = keyList or {"type", "id", "count", "additional"}
    local valueList, tmp
    if str ~= nil then
        for _, item in ipairs(self:split(str,",")) do
            valueList = self:split(item,"_")
            tmp = {}
            for i,v in ipairs(keyList) do
                tmp[v] = tonumber(valueList[i])
            end
            table.insert(items,tmp)
        end
    end
    return items
end

function RAStringUtil:_initRestrictWord()
    if not self.mRestrictWordInited then
        local fileName = "txt/block_word.txt"
        local filePath = CCFileUtils:sharedFileUtils():fullPathForFilename(fileName)
        RestrictedWord:getInstance():init(filePath)
        self.mRestrictWordInited = true
    end
end

function RAStringUtil:replaceToStarForChat(str)
    self:_initRestrictWord()
    return RestrictedWord:getInstance():replaceToStarForChat(str)
end

function RAStringUtil:isStringOKForChat(str)
    self:_initRestrictWord()
    return RestrictedWord:getInstance():isStringOKForChat(str)
end

return RAStringUtil