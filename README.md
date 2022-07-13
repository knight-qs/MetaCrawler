## 爬虫crawler.py 说明

1.  本地备份文件saved_full_class.csv及saved_used_class.csv，储存之前查询过的数据

2.  若无备份，则不会在开头询问是否删除，将自动新建，并随脚本在MetaCyc上的爬取结果自动更新

3.  爬取前脚本会先在本地备份查询，没有的话再上MetaCyc爬取

4.  爬虫的请求频率可以自己控制，但过高可能对网站正常运行存在影响，同时极大增加ip被封的风险

5.  第2/3条主要目的为“断点续传”，若ip被封或网络不稳定等情况使脚本运行中断，无需再从头爬取或手动调整

6.  第2/3条亦可记录所有历史数据，构建“本地数据库”，节约查询时间，同时减少爬虫对目标站点MetaCyc的负担

7.  请勿对备份数据文本内容手动增减、删改，防止查询本地备份数据结果有误

8.  若违反第7条，脚本自身虽有核查机制，但无法保证排查出本地备份中所有可能的潜在错误

9.  若担心备份数据有误、陈旧，可在脚本运行的开头选择删除本地备份，如此便只会从MetaCyc爬取数据

<br>

使用爬虫脚本时，记得修改开头的本地路径，并把查询文件换成自己的待查询MetaCyc代谢通路
```
path_f = 'D:\\R\\MetaCyc-Crawl-main\\python_file\\full_class.csv'
path_u = 'D:\\R\\MetaCyc-Crawl-main\\python_file\\used_class.csv'
path_sf = 'D:\\R\\MetaCyc-Crawl-main\\python_file\\saved_full_class.csv'
path_su = 'D:\\R\\MetaCyc-Crawl-main\\python_file\\saved_used_class.csv'
path_qp = 'D:\\R\\MetaCyc-Crawl-main\\python_file\\query_ITS_MetaCyc_path_abun_unstrat.tsv'   # 查询文件在这里选择
```

<br>

查询文件格式如下
```
ANAGLYCOLYSIS-PWY
ARGSYN-PWY
CALVIN-PWY
```

<br>

假如本地有备份，会询问下列问题，具体解释见上方说明
```
是否删除本地备份数据(y/n):
```

<br>

爬取的完整层级信息结果full_class.csv，每行最后一位为对应的代谢通路，不同代谢通路层级深度不同
```
Generation of Precursor Metabolites and Energy,Glycolysis,ANAGLYCOLYSIS-PWY

Biosynthesis,Amino Acid Biosynthesis,Proteinogenic Amino Acid Biosynthesis,L-arginine Biosynthesis,ARGSYN-PWY

Superpathways,ARGSYN-PWY

Biosynthesis,Carbohydrate Biosynthesis,Sugar Biosynthesis,CALVIN-PWY

Degradation/Utilization/Assimilation,C1 Compound Utilization and Assimilation,CO2 Fixation,Autotrophic CO2 Fixation,CALVIN-PWY
```

<br>

用于下游分析的层级信息结果used_class.csv
```
Generation of Precursor Metabolites and Energy,Glycolysis,Glycolysis,ANAGLYCOLYSIS-PWY

Biosynthesis,Amino Acid Biosynthesis,L-arginine Biosynthesis,ARGSYN-PWY

Superpathways,ARGSYN-PWY,Superpathways,ARGSYN-PWY

Biosynthesis,Carbohydrate Biosynthesis,Sugar Biosynthesis,CALVIN-PWY

Degradation/Utilization/Assimilation,C1 Compound Utilization and Assimilation,Autotrophic CO2 Fixation,CALVIN-PWY
```

<br>

## 下游分析dif_ana.R说明

下游分析在R中进行
<br><br>
按照原本设计，used_class.csv第一二列为第一二层级，第三四列为倒数第二和倒数第一层级，各有不同目的
<br><br><br>
三四列准备在差异分析后绘制火山图，再使用clusterprofiler富集分析
<br><br>
但结果不好，猜测是因为MetaCyc结果相对KEGG少的多，因此不做展示，相关代码可在dif_ana.R中查看
<br><br><br>
一二列用于绘制桑基图，直出效果如下
<br><br>
![image](https://github.com/knight-qs/MetaCyc-Crawl/blob/main/fig/raw_fig.jpg)
<br><br><br>
使用Adobe Illustrator调整，最终效果如下（右图）
<br><br><br>
![image](https://github.com/knight-qs/MetaCyc-Crawl/blob/main/fig/sankey_T.jpg)


