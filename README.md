# MetaCyc爬虫脚本（crawl.py）说明

1.  本地备份文件saved_full_class.csv及saved_used_class.csv，储存之前查询过的数据

2.  若无备份，则不会在开头询问是否删除，将自动新建，并随脚本在MetaCyc上的爬取结果自动更新

3.  爬取前脚本会先在本地备份查询，没有的话再上MetaCyc爬取

4.  爬虫的请求频率可以自己控制，但过高可能对网站正常运行存在影响，同时极大增加ip被封的风险

5.  第2/3条主要目的为“断点续传”，若ip被封或网络不稳定等情况使脚本运行中断，无需再从头爬取或手动调整

6.  第2/3条亦可记录所有历史数据，构建“本地数据库”，节约查询时间，同时减少爬虫对目标站点MetaCyc的负担

7.  请勿对备份数据文本内容手动增减、删改，防止查询本地备份数据结果有误

8.  若违反第7条，脚本自身虽有核查机制，但无法保证排查出本地备份中所有可能的潜在错误

9.  若担心备份数据有误、陈旧，可在脚本运行的开头选择删除本地备份，如此便只会从MetaCyc爬取数据

10. 使用爬虫脚本时，记得修改开头的本地路径，并把查询文件换成自己的待查询MetaCyc代谢通路

下图爬取的完整层级信息结果full_class.csv，每行最后一位为对应的代谢通路，不同代谢通路层级深度不同
![image](https://github.com/knight-qs/MetaCyc-Crawl/blob/main/fig/crawl_result_example.jpg)

# 下游分析示例(dif_ana.R)

下游分析在R中进行，按照原本设计，used_class.csv第一二列为第一二层级，第三四列为倒数第二和倒数第一层级

其中三四列准备在差异分析后绘制火山图，再使用clusterprofiler富集分析，但结果不好，猜测是因为MetaCyc结果相对KEGG少的多，因此没有放图，相关代码在dif_ana.R中有

而第一二列用于绘制桑基图，直出结果见下图
![image](https://github.com/knight-qs/MetaCyc-Crawl/blob/main/fig/raw_fig.jpg)

使用Adobe Illustrator修饰，最终结果见下方右图
![image](https://github.com/knight-qs/MetaCyc-Crawl/blob/main/fig/sankey_T.jpg)


