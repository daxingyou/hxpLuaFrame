-- RAUIDefine

-- const define used in ui part

-- the priority of no touch layer
-- the value in c++ is INT_MIN
INT_MIN = -2147483648
NoTouchLayerPriority_Page = INT_MIN + 3
NoTouchLayerPriority_All = INT_MIN + 2
GuideLayerPriority = -2147483646
CoverLayerPriority = -2147483647

-- the tag of node that need to adjust
CCBNodeNeedAdjustTag = -9

-- game designSize
GameDesignSize = {
	width = 640,
	height = 852
}