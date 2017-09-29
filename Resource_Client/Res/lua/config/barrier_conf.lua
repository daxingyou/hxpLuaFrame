local barrier_conf = {
    [1] = {
        id = 1,
        name = "xxx",
        startStepId = 1,
        forcusNode = "mMarchRouteStart1",
        armyRes = "RAMissionMap1_March1.ccbi",
        [1] = {
            startActionId = "2000,2005",
            nextStepId = 2
        },
        [2] = {
            startActionId = "2060,2070,2080",
            nextStepId = 3
        },
        [3] = {
            startActionId = "2100,2105",
            nextStepId = 4
        },
        [4] = {
            startActionId = "2140,2145,2150",
            nextStepId = 5
        },
        [5] = {
            startActionId = "2160,2165,2170",
            nextStepId = 6
        },
        [6] = {
            startActionId = "2180,2185,2190",
            nextStepId = 7
        },
        [7] = {
            startActionId = "2200,2203,2205",
            nextStepId = 8
        },
        [8] = {
            startActionId = "2230,2235,2238",
            nextStepId = 9
        },
        [9] = {
            startActionId = "2250,2255,2260",
            nextStepId = 10
        },
        [10] = {
            startActionId = "2270,2280",
            nextStepId = 11
        },
        [11] = {
            startActionId = "2310",
            nextStepId = 15
        },
--        [12] = {
--            startActionId = "2350",
--            nextStepId = 13
--        },
--        [13] = {
--            startActionId = "2370",
--            nextStepId = 14
--        },
--        [14] = {
--            startActionId = "2390",
--            nextStepId = 15
--        },
        [15] = {
            startActionId = "2440,2445,2450",
            nextStepId = 16
        },
        [16] = {
            startActionId = "2460,2470,2475,2480",
            nextStepId = 17
        },
        [17] = {
            startActionId = "2490,2495,2500",
            nextStepId = 18
        },
        [18] = {
            startActionId = "2510,2515,2520",
            nextStepId = 19
        },
        [19] = {
            startActionId = "2530,2540,2550",
            nextStepId = 20
        },
        [20] = {
            startActionId = "2560,2570,2575,2580",
            nextStepId = 21
        },
        [21] = {
            startActionId = "2596,2597,2598,2599",
            nextStepId = nil
        },
    },
    [2] = {
        id = 1,
        name = "xxx",
        startStepId = 1,
        forcusNode = "mMarchRouteStart2",
        armyRes = "RAMissionMap1_March2.ccbi",
        [1] = {
            startActionId = "3000,3005,3010",
            nextStepId = 2
        },
        [2] = {
            startActionId = "3070,3080,3090",
            nextStepId = 3
        },
        [3] = {
            startActionId = "3110,3120,3130,3140",
            nextStepId = 4
        },
        [4] = {
            startActionId = "3160,3170,3180,3190",
            nextStepId = 5
        },
        [5] = {
            startActionId = "3210,3220,3225",
            nextStepId = 6
        },
        [6] = {
            startActionId = "3280,3290,3300,3310",
            nextStepId = 7
        },
        [7] = {
            startActionId = "3330,3340,3350,3360,3370",
            nextStepId = 8
        },
        [8] = {
            startActionId = "3410,3415,3420",
            nextStepId = nil
        }
    },
    [3] = {
        id = 3,
        name = "xxx",
        startStepId = 1,
        forcusNode = "mMarchRouteStart3",
        armyRes = "RAMissionMap1_March3.ccbi",
        [1] = {
            startActionId = "4000,4005,4008",
            nextStepId = 2
        },
        [2] = {
            startActionId = "4060,4070,4080",
            nextStepId = 3
        },
        [3] = {
            startActionId = "4100,4110,4120,4130,4135,4138",
            nextStepId = 4
        },
        [4] = {
            startActionId = "4150,4160,4170",
            nextStepId = 5
        },
        [5] = {
            startActionId = "4190,4200,4210",
            nextStepId = 6
        },
        [6] = {
            startActionId = "4230,4240,4250,4260",
            nextStepId = 7
        },
        [7] = {
            startActionId = "4280,4290,4300,4310",
            nextStepId = 8
        },
        [8] = {
            startActionId = "4320,4330,4340,4350",
            nextStepId = nil
        },
    },
    [4] = {
        id = 4,
        name = "xxx",
        startStepId = 1,
        forcusNode = "mMarchRouteStart4",
        armyRes = "RAMissionMap1_March4.ccbi",
        [1] = {
            startActionId = "5000,5005,5010",
            nextStepId = 2
        },
        [2] = {
            startActionId = "5070,5080,5090,5095",
            nextStepId = 3
        },
        [3] = {
            startActionId = "5110,5120,5130",
            nextStepId = 4
        },
        [4] = {
            startActionId = "5150,5160,5170,5180",
            nextStepId = 5
        },
        [5] = {
            startActionId = "5200,5210,5220,5230",
            nextStepId = 6
        },
        [6] = {
            startActionId = "5250,5260",
            nextStepId = 7
        },
        [7] = {
            startActionId = "5270,5280",
            nextStepId = nil
        },
    },
    [5] = {
        id = 5,
        name = "xxx",
        startStepId = 1,
        forcusNode = "mMarchRouteEndStart4",
        armyRes = "RAMissionMap1_MarchEnd4.ccbi",
        [1] = {
            startActionId = "6000,6005,6008",
            nextStepId = 2
        },
        [2] = {
            startActionId = "6060,6070,6080,6090",
            nextStepId = 3
        },
        [3] = {
            startActionId = "6110,6120,6130",
            nextStepId = 4
        },
        [4] = {
            startActionId = "6150,6160,6170",
            nextStepId = 5
        },
        [5] = {
            startActionId = "6190,6200,6210,6220",
            nextStepId = 6
        },
        [6] = {
            startActionId = "6240,6250,6260",
            nextStepId = 7
        },
        [7] = {
            startActionId = "6280,6290,6300,6310",
            nextStepId = 8
        },
        [8] = {
            startActionId = "6330,6340,6350,6360,6370,6380",
            nextStepId = 9
        },
        [9] = {
            startActionId = "6400,6410",
            nextStepId = 10
        },
        [10] = {
            startActionId = "6470,6480,6490",
            nextStepId = 11
        },
        [11] = {
            startActionId = "6510,6520,6530,6540",
            nextStepId = 12
        },
        [12] = {
            startActionId = "6560,6570,6580,6590",
            nextStepId = 13
        },
        [13] = {
            startActionId = "6610,6620,6630,6640",
            nextStepId = 14
        },
        [14] = {
            startActionId = "6660,6670",
            nextStepId = 15
        },
        [15] = {
            startActionId = "6680,6690",
        },
    },
    --新手起始专用
    [10000001] = {
        id = 10000001,
        name = "xxx",
        startStepId = 1,
        forcusNode = "mMarchRouteStart1",
        armyRes = "RAMissionMap2_March1.ccbi",
        [1] = {
            startActionId = "10000002",
            nextStepId = 2
        },
        [2] = {
            startActionId = "10000090,10000100",
            nextStepId = 3
        },
        [3] = {
            startActionId = "10000130,10000140",
            nextStepId = 4
        },
        [4] = {
            startActionId = "10000170,10000180,10000190,10000200",
            nextStepId = 5
        },
        [5] = {
            startActionId = "10000280,10000290",
            nextStepId = 6
        },
        [6] = {
            startActionId = "10000330,10000340,10000350,10000320",
            nextStepId = 7
        },
        [7] = {
            startActionId = "10000360",
            nextStepId = 8
        },
        [8] = {
            startActionId = "10000430,10000440,10000450,10000460",
            nextStepId = 9
        },
        [9] = {
            startActionId = "10000530,10000540,10000550,10000560",
            nextStepId = 10
        },
        [10] = {
            startActionId = "10000570,10000580",
            nextStepId = 11
        },
        [11] = {
            startActionId = "10000620,10000630,10000640,10000650",
            nextStepId = 12
        },
        [12] = {
            startActionId = "10000720,10000730,10000740,10000750",
            nextStepId = 13
        },
        [13] = {
            startActionId = "10000820,10000830,10000840,10000850",
            nextStepId = nil
        },
    },
    [10000002] = {
        id = 10000002,
        name = "xxx",
        startStepId = 1,
        forcusNode = "mMarchRouteStart1",
        armyRes = "RAMissionMap2_March1.ccbi",
        [1] = {
            startActionId = "10001010,10001013",
            nextStepId = 2
        },
        [2] = {
            startActionId = "10001070,10001080,10001090",
            nextStepId = 3
        },
        [3] = {
            startActionId = "10001140,10001150,10001160",
            nextStepId = 4
        },
        [4] = {
            startActionId = "10001240,10001250",
            nextStepId = 5
        },
        [5] = {
            startActionId = "10001280,10001290",
            nextStepId = 6
        },
        [6] = {
            startActionId = "10001320,10001330,10001340",
            nextStepId = 7
        },
        [7] = {
            startActionId = "10003120,10003130",
            nextStepId = 8
        },
        [8] = {
            startActionId = "10003160,10003170",
            nextStepId = 9
        },
        [9] = {
            startActionId = "10003200,10003210,10003220",
            nextStepId = 10
        },
        [10] = {
            startActionId = "10003270,10003280,10003290",
            nextStepId = 11
        },
        [11] = {
            startActionId = "10003340,10003350,10003360",
            nextStepId = 12
        },
        [12] = {
            startActionId = "10003410,10003412,10003414,10003420",
            nextStepId = nil
        },
    },
    --新手专用
    [20000001] = {
        id = 20000001,
        name = "xxx",
        startStepId = 1,
        forcusNode = "mMarch1Point1",
        armyRes = "RAMissionMap3_March1.ccbi",
        [1] = {
            startActionId = "20000010",
            nextStepId = 2
        },
        [2] = {
            startActionId = "20000140,20000143,20000146,20000150",
            nextStepId = 3
        },
        [3] = {
            startActionId = "20000180,20000185,20000190",
            nextStepId = 4
        },
        [4] = {
            startActionId = "20000210,20000220,20000225,20000230",
            nextStepId = nil
        },
    },
    --新手专用
    [30000001] = {
        id = 30000001,
        name = "xxx",
        startStepId = 1,
        forcusNode = "xxxxxx",
        armyRes = "xxxxxx.ccbi",
        [1] = {
            startActionId = "30000010",
            nextStepId = nil
        },
    },
}

return barrier_conf