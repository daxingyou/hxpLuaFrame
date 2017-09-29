local newbie_chapter_conf = {
[1] ={
     chapterId = 1,
     chapterType = 1,
     stepCount = 9,
     stepIdList = '10000001_10000002_10000003_10000004_10000005_10000006_10000007_10000008_10000009',
     previousChapterId = -1,
     nextChapterId = 2
},
[2] ={
     chapterId = 2,
     chapterType = 0,
     stepCount = 6,
     stepIdList = '20000001_20000002_20000003_20000004_20000005_20000006',
     previousChapterId = 1,
     nextChapterId = 3
},
[3] ={
     chapterId = 3,
     chapterType = 0,
     stepCount = 6,
     stepIdList = '30000001_30000002_30000003_30000004_30000005_30000006',
     previousChapterId = 2,
     nextChapterId = 4
},
[4] ={
     chapterId = 4,
     chapterType = -1,
     stepCount = 1,
     stepIdList = 40000001,
     previousChapterId = 3,
     nextChapterId = -1
}
}
return newbie_chapter_conf
