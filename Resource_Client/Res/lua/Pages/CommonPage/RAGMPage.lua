--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local RAGMPage = BaseFunctionPage:new(...)
local UIExtend = RARequire("UIExtend")
local common = RARequire("common")
local RARootManager = RARequire("RARootManager")
local mAllScrollview = nil
local common = RARequire("common")
function RAGMPage:Enter(data)
    local ccbfile = UIExtend.loadCCBFile("RASettingMainPage.ccbi",self)
    mAllScrollview = ccbfile:getCCScrollViewFromCCB("mSettingListSV")
    mAllScrollview:setVisible(false)
    assert(mAllScrollview~=nil,"mAllScrollview~=nil")
    self:_initTitle()
    self:CommonRefresh()
end


function RAGMPage:_initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	local backCallBack = function()
		RARootManager.CloseCurrPage()
	end
    local titleName = "GM Page"
	local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAGMPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end

function RAGMPage:CommonRefresh()
    common:createGmItem(self.ccbfile,function(commandData)
        if commandData == nil then
            RARootManager.ShowMsgBox("请输入lua脚本名称");
            return
        end

        local hasPath, fullPath = RAGetPathByFileName(commandData)
        if hasPath == false then
            RARootManager.ShowMsgBox("没找到该lua文件，请输入lua脚本名称");
            return
        end
        RAUnload(commandData)
        RARootManager.ShowMsgBox("成功卸载module,name is "..commandData);
    end,ccp(50,700),"重载lua脚本名称，如RACitySceneConfig")

    common:createGmItem(self.ccbfile,function(commandData)
        if commandData == nil then
            RARootManager.CloseAllPages();
        else
            RARootManager.ClosePage(commandData);
        end
        
    end,ccp(50,500),"输入需要关闭的页面名字,空表示关闭所有页面，如RAConfirmPage")

    common:createGmItem(self.ccbfile,function(commandData)
        local RACityScene_BlackShop = RARequire("RACityScene_BlackShop")
        RACityScene_BlackShop:HandleGuideSpecialReq()
        RARootManager.CloseAllPages();
    end,ccp(50,350),"Fly to Blackshop")
end

function RAGMPage:Exit()
    mAllScrollview:removeAllCell()
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	RACommonTitleHelper:RemoveCommonTitle("RAGMPage")
    UIExtend.unLoadCCBFile(self)
end



return RAGMPage
--endregion
