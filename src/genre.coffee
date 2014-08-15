'use strict'

_ = require 'underscore'
###
GenreId3 =
    "Blues": 0
    "Classic Rock": 1
    "Country": 2
    "Dance": 3
    "Disco": 4
    "Funk": 5
    "Grunge": 6
    "Hip-Hop": 7
    "Jazz": 8
    "Metal": 9
    "New Age": 10
    "Oldies": 11
    "Other": 12
    "Pop": 13
    "R&B": 14
    "Rap": 15
    "Reggae": 16
    "Rock": 17
    "Techno": 18
    "Industrial": 19
    "Alternative": 20
    "Ska": 21
    "Death Metal": 22
    "Pranks": 23
    "Soundtrack": 24
    "Euro-Techno": 25
    "Ambient": 26
    "Trip-Hop": 27
    "Vocal": 28
    "Jazz+Funk": 29
    "Fusion": 30
    "Trance": 31
    "Classical": 32
    "Instrumental": 33
    "Acid": 34
    "House": 35
    "Game": 36
    "Sound Clip": 37
    "Gospel": 38
    "Noise": 39
    "AlternRock": 40
    "Bass": 41
    "Soul": 42
    "Punk": 43
    "Space": 44
    "Meditative": 45
    "Instrumental Pop": 46
    "Instrumental Rock": 47
    "Ethnic": 48
    "Gothic": 49
    "Darkwave": 50
    "Techno-Industrial": 51
    "Electronic": 52
    "Pop-Folk": 53
    "Eurodance": 54
    "Dream": 55
    "Southern Rock": 56
    "Comedy": 57
    "Cult": 58
    "Gangsta Rap": 59
    "Top 40": 60
    "Christian Rap": 61
    "Pop / Funk": 62
    "Jungle": 63
    "Native American": 64
    "Cabaret": 65
    "New Wave": 66
    "Psychedelic": 67
    "Rave": 68
    "Showtunes": 69
    "Trailer": 70
    "Lo-Fi": 71
    "Tribal": 72
    "Acid Punk": 73
    "Acid Jazz": 74
    "Polka": 75
    "Retro": 76
    "Musical": 77
    "Rock & Roll": 78
    "Hard Rock": 79
    "Folk": 80
    "Folk-Rock": 81
    "National Folk": 82
    "Swing": 83
    "FastFusion": 84
    "Bebob": 85
    "Latin": 86
    "Revival": 87
    "Celtic": 88
    "Bluegrass": 89
    "Avantgarde": 90
    "Gothic Rock": 91
    "Progressive Rock": 92
    "Psychedelic Rock": 93
    "Symphonic Rock": 94
    "Slow Rock": 95
    "Big Band": 96
    "Chorus": 97
    "Easy Listening": 98
    "Acoustic": 99
    "Humour": 100
    "Speech": 101
    "Chanson": 102
    "Opera": 103
    "Chamber Music": 104
    "Sonata": 105
    "Symphony": 106
    "Booty Bass": 107
    "Primus": 108
    "Porn Groove": 109
    "Satire": 110
    "Slow Jam": 111
    "Club": 112
    "Tango": 113
    "Samba": 114
    "Folklore": 115
    "Ballad": 116
    "Power Ballad": 117
    "Rhythmic Soul": 118
    "Freestyle": 119
    "Duet": 120
    "Punk Rock": 121
    "Drum Solo": 122
    "A Cappella": 123
    "Euro-House": 124
    "Dance Hall": 125
    "Goa": 126
    "Drum & Bass": 127
    "Club-House": 128
    "Hardcore": 129
    "Terror": 130
    "Indie": 131
    "BritPop": 132
    "Negerpunk": 133
    "Polsk Punk": 134
    "Beat": 135
    "Christian Gangsta Rap": 136
    "Heavy Metal": 137
    "Black Metal": 138
    "Crossover": 139
    "Contemporary Christian": 140
    "Christian Rock": 141
    "Merengue": 142
    "Salsa": 143
    "Thrash Metal": 144
    "Anime": 145
    "JPop": 146
    "Synthpop": 147
    "Rock/Pop": 148
###
GenreXiami = 
    "流行 Pop": "Pop"
    "摇滚 Rock": "Rock"
    "民谣 Folk": "Folk"
    "电子 Electronic": "Electronic"
    "节奏布鲁斯 R&B": "R&B"
    "爵士 Jazz": "Jazz"
    "布鲁斯 Blues": "Blues"
    "说唱 Hip Hop": "Hip-Hop"
    "金属 Metal": "Metal"
    "古典 Classical": "Classical"
    "世界音乐 World Music": "Pop" # doubt
    "轻音乐 Easy Listening": "Easy Listening"
    "新世纪 New Age": "New Age"
    "实验 Experimental": "Other" # doubt
    "中国特色 Chinese Characteristic": null # unknown
    "乡村 Country": "Country"
    "雷鬼 Reggae": "Reggae"
    "拉丁 Latin": "Latin"
    "唱作人 Singer-Songwriter": "Folk" # doubt
    "舞台 / 银幕 / 娱乐 Stage & Screen & Entertainment": null # unknown
    "儿童 Children": null # unknown

List = 
    "流行 Pop": [
        "国语流行 Mandarin Pop"
        "粤语流行 Cantopop"
        "欧美流行 Western Pop"
        "日本流行 J-Pop"
        "韩国流行 K-Pop"
        "流行舞曲 Dance-Pop"
        "成人时代 Adult Contemporary"
        "独立流行 Indie Pop"
        "艺术流行 Art Pop"
        "青少年流行 Teen Pop"
        "梦幻流行 Dream Pop"
        "迷幻流行 Psychedelic Pop"
        "氛围流行 Ambient Pop"
        "阳光流行 Sunshine Pop"
        "噪音流行 Noise Pop"
        "噪响流行 Jangle Pop"
        "前卫流行 Progressive Pop"
        "传统流行 Traditional Pop"
        "标准歌曲 Standards"
        "童稚流行 Twee Pop"
        "C86 C86"
        "女子团体 Girl Group"
        "巴洛克流行 Baroque Pop"
        "室内流行 Chamber Pop"
        "男孩团体 Boy Band"
        "泡泡糖摇滚舞曲 Bubblegum"
        "布瑞尔大厦流行 Brill Building Pop"
        "当代基督 CCM / Contemporary Christian Music"
        "文雅流行 Sophisti Pop"
        "韩国抒情曲 Korean Ballad"
        "闽南语流行 Taiwanese Pop"
        "凯尔特流行 Celtic Pop"
        "致幻流行 Hypnagogic Pop"
        "法国流行 French Pop"
        "意大利流行 Italian Pop"
        "非洲流行 Afro-Pop"
        "阿拉伯流行 Arabic Pop"
        "弗拉明戈流行 Flamenco Pop"
        "印度流行 Indian Pop"
        "土耳其流行 Turkish Pop"
        "人声合唱团 Vocal Group"
    ]
    "摇滚 Rock": [
        "摇滚 Rock & Roll"
        "流行摇滚 Pop Rock"
        "流行朋克 Pop Punk"
        "独立摇滚 Indie Rock"
        "英式摇滚 Britpop"
        "另类摇滚 Alternative Rock"
        "迷幻摇滚 Psychedelic Rock"
        "朋克 Punk Rock"
        "后摇 Post-Rock"
        "硬摇滚 Hard Rock"
        "新迷幻 Neo-Psychedelia"
        "噪音摇滚 Noise Rock"
        "自赏 Shoegaze"
        "后朋克 Post-Punk"
        "垃圾摇滚 Grunge"
        "新浪潮 New Wave"
        "低保真 Lo-Fi"
        "后朋复兴 Post-Punk Revival"
        "前卫摇滚 Progressive Rock"
        "华丽摇滚 Glam Rock"
        "慢核 Slowcore"
        "哥特摇滚 Gothic Rock"
        "工业摇滚 Industrial Rock"
        "数学摇滚 Math Rock"
        "后垃圾摇滚 Post-Grunge"
        "说唱摇滚 Rap Rock"
        "艺术摇滚 Art Rock"
        "基督摇滚 Christian Rock"
        "默西之声 Merseybeat"
        "喜剧摇滚 Comedy Rock"
        "情绪硬核 Emo"
        "实验摇滚 Experimental Rock"
        "先锋前卫摇滚 Avant-Prog"
        "民谣摇滚 Folk Rock"
        "酸性摇滚 Acid Rock"
        "成人另类 Adult Alternative"
        "美国传统摇滚 American Trad Rock"
        "舞台摇滚 Arena Rock"
        "澳洲摇滚 Aussie Rock"
        "布鲁斯摇滚 Blues Rock"
        "英国民谣摇滚 British Folk Rock"
        "英国传统摇滚 British Trad Rock"
        "凯尔特摇滚 Celtic Rock"
        "冷潮 Coldwave"
        "学院摇滚 College Rock"
        "舞曲朋克 Dance-Punk"
        "暗潮 Dark Wave"
        "仙音 Ethereal Wave"
        "法国摇滚 French Rock"
        "车库朋克 Garage Punk"
        "车库摇滚 Garage Rock"
        "车库摇滚复兴 Garage Rock Revival"
        "硬核朋克 Hardcore Punk"
        "中心地带摇滚 Heartland Rock"
        "工业 Industrial"
        "爵士摇滚 Jazz Rock"
        "德国前卫摇滚 Krautrock"
        "现代主义 Mod"
        "新浪漫 New Romantic"
        "无浪潮 No Wave"
        "钢琴摇滚 Piano Rock"
        "后硬核 Post-Hardcore"
        "电力流行 Power Pop"
        "原型朋克 Proto-Punk"
        "酒吧摇滚 Pub Rock"
        "山区乡村摇滚 Rockabilly"
        "根源摇滚 Roots Rock"
        "斯卡朋克 Ska Punk"
        "滑雪朋克 Skate Punk"
        "轻摇滚 Soft Rock"
        "美国南方摇滚 Southern Rock"
        "冲浪摇滚 Surf Rock"
        "沼泽摇滚 Swamp Pop"
        "美式墨西哥摇滚 Tex-Mex"
        "视觉摇滚 Visual Rock"
    ]
    "民谣 Folk": [
        "当代民谣 Contemporary Folk"
        "传统民谣 Traditional Folk"
        "独立民谣 Indie Folk"
        "民谣流行 Folk Pop"
        "新民谣 Neofolk"
        "迷幻民谣 Psychedelic Folk"
        "前卫民谣 Progressive Folk"
        "奇幻民谣 Freak Folk"
        "室内民谣 Chamber Folk"
        "先锋民谣 Avant-Folk"
        "反民谣 Anti-Folk"
        "自由民谣 Free Folk"
        "美国原始主义 American Primitivism"
        "美国传统民谣 American Folk"
        "英国传统民谣 English Folk"
        "凯尔特民谣 Celtic Folk"
        "法国民谣 French Folk"
        "爱尔兰民谣 Irish Folk"
        "苏格兰民谣 Scottish Folk"
        "阿拉伯民谣 Arabic Folk"
        "加勒比民谣 Caribbean Folk"
        "匈牙利民谣 Hungarian Folk"
        "非洲民谣 African Folk"
        "曼德民谣 Mande Folk"
        "新传统主义民谣 Neo-Traditional Folk"
        "异教民谣 Pagan Folk"
        "政治民谣 Political Folk"
        "城市民谣 Urban Folk"
    ]
    "电子 Electronic": [
        "电音流行 Electropop"
        "独立电子乐 Indietronica"
        "电子民谣 Folktronica"
        "缓拍 Downtempo"
        "回响重拍 Dubstep"
        "神游舞曲 Trip Hop"
        "氛围音乐 Ambient"
        "浩室舞曲 House"
        "科技舞曲 Techno"
        "迷幻舞曲 Trance"
        "迪斯科 Disco"
        "智能舞曲 Idm"
        "氛围科技舞曲 Ambient Techno"
        "合成器流行 Synth Pop"
        "二步舞曲 2-Step"
        "酸性浩室舞曲 Acid House"
        "另类舞曲 Alternative Dance"
        "氛围回响 Ambient Dub"
        "氛围浩室舞曲 Ambient House"
        "大节拍 Big Beat"
        "碎拍 Breakbeat"
        "芝加哥浩室舞曲 Chicago House"
        "寒潮 Chillwave"
        "黑暗氛围 Dark Ambient"
        "深浩室舞曲 Deep House"
        "鼓打贝斯 Drum & Bass"
        "电子乐 Electro"
        "电子迪斯科 Electro-Disco"
        "实验回响重拍 Experimental Dub"
        "未来车库舞曲 Future Garage"
        "脉冲 Glitch"
        "脉冲流行 Glitch Pop"
        "高能量迪斯科 Hi-Nrg"
        "微浩室舞曲 Microhouse"
        "微声 Microsound"
        "极简科技舞曲 Minimal Techno"
        "极简潮 Minimal Wave"
        "合成器朋克 Synth Punk"
        "科技浩室舞曲 Tech House"
        "英国车库舞曲 Uk Garage"
        "女巫浩室 Witch House"
        "恍惚嘻哈舞曲 Wonky"
    ]
    "节奏布鲁斯 R&B": [
        "当代节奏布鲁斯 Contemporary R&B"
        "放克 Funk"
        "灵魂乐 Soul"
        "流行灵魂乐 Pop Soul"
        "新灵魂乐 Neo-Soul"
        "白人灵魂乐 Blue Eyed Soul"
        "芝加哥灵魂乐 Chicago Soul"
        "乡村灵魂乐 Country Soul"
        "深度放克 Deep Funk"
        "深度灵魂乐 Deep Soul"
        "嘟喔普 Doo Wop"
        "爵士放克 Jazz Funk"
        "另类嘻哈 Left-Field Hip-Hop"
        "摩城 Motown"
        "新杰克摇摆乐 New Jack Swing"
        "北方灵魂乐 Northern Soul"
        "迷幻灵魂乐 Psychedelic Soul"
        "节奏布鲁斯 Rhythm & Blues"
        "柔顺灵魂乐 Smooth Soul"
        "南方灵魂乐 Southern Soul"
    ]
    "爵士 Jazz": [
        "巴萨诺瓦 Bossa Nova"
        "爵士流行 Jazz Pop"
        "酸性爵士 Acid Jazz"
        "非洲爵士 African Jazz"
        "古巴爵士 Afro-Cuban Jazz"
        "先锋爵士 Avant-Garde Jazz"
        "大乐队 Big Band"
        "波普 Bop"
        "室内爵士 Chamber Jazz"
        "冷爵士 Cool Jazz"
        "迪克西兰爵士 Dixieland"
        "实验大乐队 Experimental Big Band"
        "自由爵士 Free Jazz"
        "硬波普 Hard Bop"
        "融合爵士 Jazz Fusion"
        "调式爵士 Modal Jazz"
        "新奥尔良爵士 New Orleans Jazz"
        "后波普 Post-Bop"
        "拉格泰姆 Ragtime"
        "柔顺爵士 Smooth Jazz"
        "灵魂爵士 Soul Jazz"
        "摇摆乐 Swing"
        "第三流派 Third Stream"
        "人声爵士 Vocal Jazz"
    ]
    "布鲁斯 Blues": [
        "电声布鲁斯 Electric Blues"
        "三角洲布鲁斯 Delta Blues"
        "钢琴布鲁斯 Piano Blues"
        "原声布鲁斯 Acoustic Blues"
        "爵士布鲁斯 Jazz Blues"
        "灵魂布鲁斯 Soul Blues"
        "芝加哥布鲁斯 Chicago Blues"
        "乡村布鲁斯 Country Blues"
        "跳跃布鲁斯 Jump Blues"
        "布基伍基 Boogie Woogie"
        "英国布鲁斯 British Blues"
        "民谣布鲁斯 Folk Blues"
        "新奥尔良布鲁斯 New Orleans Blues"
        "纽约布鲁斯 New York Blues"
        "城市布鲁斯 Urban Blues"
    ]
    "说唱 Hip Hop": [
        "抽象说唱 Abstract Hip Hop"
        "另类说唱 Alternative Hip Hop"
        "英伦说唱 British Hip Hop"
        "基督教说唱 Christian Hip Hop"
        "喜剧说唱 Comedy Hip Hop"
        "意识说唱 Conscious Hip Hop"
        "南方脏口 Dirty South"
        "不良说唱 Dirty Hip Hop"
        "东岸说唱 East Coast Hip Hop"
        "实验说唱 Experimental Hip Hop"
        "匪帮放克 G-Funk"
        "匪帮说唱 Gangsta Rap"
        "硬核说唱 Hardcore Hip Hop"
        "器乐说唱 Instrumental Hip Hop"
        "爵士说唱 Jazz Hip Hop"
        "中西部说唱 Midwest Hip Hop"
        "老派说唱 Old-School Hip Hop"
        "政治说唱 Political Hip Hop"
        "流行说唱 Pop Rap"
        "南方说唱 Southern Hip Hop"
        "唱盘主义 Turntablism"
        "地下说唱 Underground Hip Hop"
        "西岸说唱 West Coast Hip Hop"
    ]
    "金属 Metal": [
        "重金属 Heavy Metal"
        "激流金属 Thrash Metal"
        "另类金属 Alternative Metal"
        "死亡金属 Death Metal"
        "前卫金属 Progressive Metal"
        "黑金属 Black Metal"
        "民谣金属 Folk Metal"
        "厄运金属 Doom Metal"
        "新金属 Nu Metal"
        "氛围黑金属 Atmospheric Black Metal"
        "氛围泥浆金属 Atmospheric Sludge Metal"
        "自赏黑 Blackgaze"
        "凯尔特金属 Celtic Metal"
        "电子金属 Cyber Metal"
        "电子碾 Cybergrind"
        "华丽金属 Glam Metal"
        "哥特金属 Gothic Metal"
        "碾核 Grindcore"
        "工业金属 Industrial Metal"
        "数学核 Mathcore"
        "中世纪民谣金属 Medieval Folk Metal"
        "金属核 Metalcore"
        "新古典金属 Neo-Classical Metal"
        "能量金属 Power Metal"
        "朋克金属 Punk Metal"
        "泥浆金属 Sludge Metal"
        "速度金属 Speed Metal"
        "交响金属 Symphonic Metal"
        "技术死亡金属 Technical Death Metal"
    ]
    "古典 Classical": [
        "西方古典 Western Classical Music"
        "当代古典 Modern Classical"
        "声乐 Vocal Music"
        "管弦乐 Orchestral"
        "歌剧 Opera"
        "教堂音乐 Church Music"
        "艺术歌曲 Lied"
        "合唱 Choral"
        "交响乐 Symphonic Music"
        "交响曲 Symphony"
        "协奏曲 Concerto"
        "芭蕾 / 舞曲 Ballet / Dance"
        "独奏 Recital"
        "室内乐 / 重奏 Chamber Music"
        "古典跨界 Classical Crossover"
        "军乐 Band Music"
        "康塔塔 Cantata"
        "键盘音乐 Keyboard"
        "进行曲 Marches"
        "极简主义 Minimalism"
        "新古典主义音乐 Neoclassicism Music"
        "清唱剧 Oratorio"
        "序曲 Overture"
        "后极简主义 Post-Minimalism"
        "前奏曲 Prelude"
        "奏鸣曲 Sonata"
    ]
    "世界音乐 World Music": [
        "韩国 | 演歌 Korea Trot"
        "韩国传统音乐 Korean Traditional Music"
        "日本 | 岛呗 Shima Uta"
        "日本 | 演歌 Enka"
        "日本 | 邦乐 Japanese Traditional Music"
        "同人音乐 Doujin"
        "无伴奏合唱 A Cappella"
        "非洲打击乐 Afrobeat"
        "阿拉伯 | 肚皮舞 Belly Dancing"
        "印度 | 邦拉 Bhangra"
        "美国 | 凯金 Cajun"
        "加勒比 | 卡吕普索 Calypso"
        "法国 | 香颂 Chanson"
        "葡萄牙 | 法朵 Fado"
        "西班牙 | 弗拉门戈 Flamenco"
        "日本 | 雅乐 Gagaku"
        "印尼 | 甘美兰 Gamelan"
        "福音 Gospel"
        "格里高利圣咏 Gregorian Chant"
        "加纳 | 快活之音 Highlife"
        "犹太音乐 Jewish Music"
        "挪威 | 哼唱 Joik"
        "犹太 | 克莱兹梅尔 Klezmer"
        "古巴 | 曼波 Mambo"
        "墨西哥 | 马里亚奇 Mariachi"
        "塞内加尔 | 姆巴拉 Mbalax"
        "南非 | 姆巴堪噶 Mbaqanga"
        "南非 | 姆布贝 Mbube"
        "多米尼加 | 默朗格 Merengue"
        "巴西 | 全域音乐 Mpb"
        "日本 | 能乐 Noh"
        "墨西哥 | 诺特诺 NorteñO"
        "捷克 | 波尔卡 Polka"
        "巴基斯坦 | 卡瓦里 Qawwali"
        "印度 | 拉格 Raga"
        "阿尔及利亚 | 籁乐 Rai"
        "古巴 | 伦巴 Rumba"
        "巴西 | 桑巴 Samba"
        "古巴 | 颂乐 Son"
        "刚果 | 索克斯 Soukous"
        "蒙古 | 呼麦 Throat Singing"
        "华尔兹 Waltz"
        "世界融合 World Fusion"
        "世界节拍 Worldbeat"
        "法国 | 祖克 Zouk"
        "美国 | 柴迪科舞曲 Zydeco"
    ]
    "轻音乐 Easy Listening": [
        "轻音乐 Easy Listening"
        "沙发音乐 Lounge"
        "异域 Exotica"
        "器乐独奏 Solo Instrumental"
    ]
    "新世纪 New Age": [
        "新世纪音乐 New Age"
        "自然新世纪 Nature New Age"
        "精神新世纪 Spiritual New Age"
        "民族融合新世纪 Ethnic Fusion New Age"
        "宗教新世纪 Religionary New Age"
        "太空新世纪 Space New Age"
        "放松新世纪 Relaxation New Age"
        "凯尔特新世纪 Celtic New Age"
        "日本新世纪 Japanese New Age"
        "部落新世纪 Techno-Tribal New Age"
        "新古典新世纪 Neoclassical New Age"
    ]
    "实验 Experimental": [
        "实验音乐 Experimental"
        "电子原声 Electroacoustic"
        "自由即兴 Free Improvisation"
        "噪音 Noise"
        "自然采样 Field Recordings"
        "声效拼贴 Sound Collage"
        "蜂鸣 Drone"
        "磁带音乐 Tape Music"
        "诵读音乐 Spoken Word"
        "实验电子 Experimental Electronic"
        "边缘音乐人 Obscuro"
    ]
    "中国特色 Chinese Characteristic": [
        "中国戏曲 Chinese Opera"
        "京剧 Beijing Opera"
        "昆曲 Kunqu Opera"
        "越剧 Shaoxing Opera"
        "黄梅戏 Huangmei Opera"
        "粤剧 Cantonese Opera"
        "评剧 Pingju Opera"
        "豫剧 Yu Opera"
        "中国曲艺 Chinese Quyi"
        "中国民乐 Chinese Folk Music"
        "中国传统民歌 Chinese Traditional Folk"
        "中国风 China-Wave"
        "红歌 Red Song"
        "军旅歌曲 Military Songs"
        "校园民谣 Campus Folk"
        "台湾民歌运动 Taiwan Folk Scene"
        "台湾原住民音乐 Taiwan Aboriginal"
        "时代曲 Shidaiqu"
    ]
    "乡村 Country": [
        "当代乡村 Contemporary Country"
        "乡村流行 Country Pop"
        "蓝草 Bluegrass"
        "另类乡村 Alt-Country"
        "乡村摇滚 Country Rock"
        "乡村民谣 Country Folk"
        "前卫乡村 Progressive Country"
        "美式乡村 Americana"
        "牛仔 Cowboy"
        "约德尔 Yodeling"
        "传统乡村 Traditional Country"
        "传统蓝草 Traditional Bluegrass"
        "乡村福音 Country Gospel"
        "纳什维尔之声 Nashville Sound"
        "当代蓝草 Contemporary Bluegrass"
        "乡村布吉 Country Boogie"
        "器乐乡村 Instrumental Country"
        "新原音 New Acoustic"
        "叛道乡村 Outlaw Country"
        "前卫蓝草 Progressive Bluegrass"
        "弦乐团 String Band"
        "都市牛仔 Urban Cowboy"
        "西部摇摆 Western Swing"
    ]
    "雷鬼 Reggae": [
        "雷鬼 Reggae"
        "回响 Dub"
        "斯卡 Ska"
        "雷鬼流行 Reggae Pop"
        "雷嘎 Ragga"
        "舞厅 Dancehall"
        "根源雷鬼 Roots Reggae"
        "迪杰 Deejay / Toasting"
        "当代雷鬼 Contemporary Reggae"
        "洛克斯代迪 Rocksteady"
        "政治雷鬼 Political Reggae"
    ]
    "拉丁 Latin": [
        "拉美音乐 Latin American Music"
        "拉丁流行 Latin Pop"
        "拉丁爵士 Latin Jazz"
        "拉丁灵魂乐 Latin Soul"
        "拉丁摇滚 Latin Rock"
        "拉丁说唱 Latin Hip Hop"
        "巴恰塔 Bachata"
        "恰朗加 Charanga"
        "康巴斯 Compas"
        "坤比亚 Cumbia"
        "拉丁大乐队 Latin Big Band"
        "萨尔萨 Salsa"
        "探戈 Tango"
        "热带 Tropical"
    ]
    "唱作人 Singer-Songwriter": [
        "根源唱作人 Singer/Songwriter"
        "当代唱作人 Contemporary Singer/Songwriter"
        "另类唱作人 Alternative Singer/ Songwriter"
        "华语唱作人 Chinese Singer-Songwriter"
    ]
    "舞台 / 银幕 / 娱乐 Stage & Screen & Entertainment": [
        "原声 Soundtrack"
        "电影配乐 Film Score"
        "电视配乐 Television Music"
        "卡通配乐 Cartoon Music"
        "游戏配乐 Video Game Music"
        "音乐剧 Musical Theatre"
        "歌舞剧 Cabaret"
        "罐头音乐 Production Music"
        "商业配乐 Jingles"
        "演出金曲 Show Tunes"
        "体育音乐 Sports Music"
        "综艺剧院 Music Hall"
        "圣诞歌曲 Christmas Music"
        "有声读物 Audio Book"
        "诗歌 Poetry"
        "广播剧 Radio Drama"
    ]
    "儿童 Children": [
        "儿歌 Nursery Rhyme"
        "儿童音乐 Children'S Music"
        "童声合唱团 Children'S Chorus"
        "胎教音乐 Prenatal Music"
    ]

module.exports = (args...)->
    args = _.flatten args
    type = []
    for i in args
        for key, value of List
            if _.contains value, i
                type.push key
                break
    type = _.pairs _.countBy(type, (obj)->obj)
    type = _.sortBy type, (obj)->obj[1]
    for [i] in type
        #result = GenreId3[GenreXiami[i]]
        result = GenreXiami[i]
        return result if result