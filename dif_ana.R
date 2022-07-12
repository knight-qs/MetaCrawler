# 导入代谢通路丰度数据并清洗
path_abun <- read.table('ITS_MetaCyc_path_abun_unstrat.tsv',
                        sep = '\t', header = T)
row.names(path_abun) <- path_abun[,1]
path_abun <- path_abun[,-1]
colnames(path_abun) <- c('0g','125g','250g','500g')

# 检验差异基因

one_t_cutoff <- 0.05  # 检验出的差异代谢通路极少，因此降低阈值
fdr_cutoff <- 0.05
log2FC_cutoff <- 1

# 单样本T检验（差异极少）

p.value <- vector()
estimate <- vector()

for (a in 1:dim(path_abun)[1]) {
  test <- t.test(as.numeric(path_abun[a,2:4]),mu=as.numeric(path_abun[a,1]))
  p.value[a] <- test$p.value
  estimate[a] <- test$estimate
}

path_abun1 <- data.frame(path_abun,p.value,estimate)
colnames(path_abun1)[1:4] <- c('0g','125g','250g','500g')
path_abun1$log2FC <- round(log(path_abun1$estimate/(path_abun1$`0g`+1),2), 2)

dif_path <- subset(path_abun1, 
                   p.value <= one_t_cutoff & abs(log2FC >= log2FC_cutoff))

# 矫正P值FDR（FDR最小0.379，都不显著，因此后续分析都基于T检验结果）

path_abun2 <- path_abun1[order(path_abun1$p.value),]
(FDR <- round(p.adjust(path_abun2$p.value, 'BH'), 3))
path_abun3 <- data.frame(path_abun2, FDR)
colnames(path_abun3)[1:4] <- c('0g','125g','250g','500g')

# 火山图（基于单样本T和FDR）

path_abun3.1 <- path_abun3
trend_T <- rep(NA, dim(path_abun3.1)[1])

for (j in 1:dim(path_abun3.1)[1]) {
  ifelse(path_abun3.1[j,5] <= one_t_cutoff & abs(path_abun3.1[j,7]) >= log2FC_cutoff,
         ifelse(path_abun3.1[j,7] >= log2FC_cutoff, trend_T[j] <- 'UP', trend_T[j] <- 'DOWN'),
         trend_T[j] <- 'STABLE')
}

path_abun3.2 <- data.frame(path_abun3.1, trend_T)
title_T <- paste0('Cutoff for logFC is ',round(log2FC_cutoff,3),
                  '\nThe number of up pathway is ',nrow(path_abun3.2[path_abun3.2$trend_T =='UP',]) ,
                  '\nThe number of down pathway is ',nrow(path_abun3.2[path_abun3.2$trend_T =='DOWN',]))


library(ggplot2)

(VO_T <- ggplot(data = path_abun3.2,
                aes(x = log2FC, y = -log10(p.value), color = trend_T)) +
    geom_point(alpha=0.4, size=1.75) + 
    theme_set(theme_set(theme_bw(base_size=20))) + 
    xlab("log2 fold change") + 
    ylab("-log10 p-value") +
    ggtitle(title_T) + 
    theme(plot.title = element_text(size=15,hjust = 0.5)) + 
    scale_colour_manual(values = c('black','blue')))

#######################################>>>>>>>>>>>>>>>>>
# 超几何检验，富集分析（基于单样本T）（无显著结果）
#######################################>>>>>>>>>>>>>>>>>

library(clusterProfiler)

# 准备背景文件(基于0g处理组)

path_abun4 <- path_abun
colnames(path_abun4)[1] <- 'zero'
path_abun5 <- subset(path_abun4, zero !=0)

bg_id <- row.names(path_abun5)
clo_dif_id <- row.names(dif_path)

path_rank <- read.csv('used_class.csv', head = F, sep = ',')

colnames(path_rank) <- c('first', 'second', 'last', 'pathway')

last_rank <- unique(path_rank$last)
last_id <- rep(NA, dim(path_rank)[1])

for (i in 1:length(last_rank)) {
  last_id[which(path_rank$last %in% last_rank[i])] <- i
}

path_rank1 <- data.frame(path_rank[,1:2], last_id, path_rank[,3:4])


term_path <- path_rank1[,c('last_id', 'pathway')]
term_name <- path_rank1[,c('last_id', 'last')]

enricher_T <- enricher(gene = clo_dif_id, universe = bg_id,
                       TERM2GENE = term_path, TERM2NAME = term_name,
                       pvalueCutoff = 0.99,
                       pAdjustMethod = 'BH',
                       qvalueCutoff = 0.99)

enricher_T1 <- as.data.frame(enricher_T)   # 什么都富集不到

#######################################>>>>>>>>>>>>>>>>>
# 桑基图
#######################################>>>>>>>>>>>>>>>>>

path_rank2 <- path_rank1[,-3:-4]
path_rank3 <- path_rank2[order(path_rank2$first),]   # 方便AI中补充第一层级信息
path_rank4 <- path_rank3

pathway <- path_rank3$pathway

for (m in 1:length(pathway)) {
  path <- pathway[m]
  for (n in 1:dim(path_abun3.2)[1]) {
    if(path == rownames(path_abun3.2)[n]){
      path_rank4$trend_T[m] <- path_abun3.2$trend_T[n]
    }
  }
}

# 统计第二层级所含代谢通路增减信息总和
len <- length(unique(path_rank4$second))
sankey_flow <- data.frame(source = unique(path_rank4$second),
                          UP_T = rep(0, len),
                          DOWN_T = rep(0, len),
                          STABLE_T = rep(0, len))

for (o in 1:dim(sankey_flow)[1]) {
  pa <- sankey_flow$source[o]
  for (p in 1:dim(path_rank4)[1]) {
    if(pa == path_rank4$second[p]){
      if(path_rank4$trend_T[p] == 'UP'){
        sankey_flow$UP_T[o] = sankey_flow$UP_T[o] + 1
      }else if(path_rank4$trend_T[p] == 'DOWN'){
        sankey_flow$DOWN_T[o] = sankey_flow$DOWN_T[o] + 1
      }else if(path_rank4$trend_T[p] == 'STABLE'){
        sankey_flow$STABLE_T[o] = sankey_flow$STABLE_T[o] + 1
      }
    }
  }
}

# 标注对应第一层级信息
sankey_flow1 <- sankey_flow

for (q in 1:length(sankey_flow1$source)) {
  second <- sankey_flow1$source[q]
  r <- 1
  while (second != path_rank4$second[r]) {
    r = r + 1
  }
  sankey_flow1$first[q] <- path_rank4$first[r]
}

sankey_flow2 <- sankey_flow1[,c(5,1:4)]

# 合并others
first <- unique(sankey_flow2$first)
# 合并大others
sankey_flow3 <- data.frame(first = character(), source = character(),
                           UP_T = numeric(), DOWN_T = numeric(),
                           STABLE_T = numeric())
others <- c('Others', 'Others', rep(0, 3))
for (s in 1:length(first)) {
  fir <- first[s]
  t <- which(sankey_flow2$first %in% fir)
  sum_UP_T <- sum(sankey_flow2$UP_T[t])
  sum_DOWN_T <- sum(sankey_flow2$DOWN_T[t])
  sum_STABLE_T <- sum(sankey_flow2$STABLE_T[t])
  if (sum(sum_UP_T, sum_DOWN_T, sum_STABLE_T) <= 10) {   # 为保留GoPMaE，设为10
    others[3:5] <- c(as.numeric(others[3]) + sum_UP_T,
                     as.numeric(others[4]) + sum_DOWN_T,
                     as.numeric(others[5]) + sum_STABLE_T)
  }else {
    sankey_flow3 <- rbind(sankey_flow3, sankey_flow2[t,])
  }
}

# 合并Superpathways
sankey_flow4 <- sankey_flow3[-which(sankey_flow3$first %in% 'Superpathways'),]

u <- which(sankey_flow2$first %in% 'Superpathways')
sum_UP_T <- sum(sankey_flow2$UP_T[t])
sum_DOWN_T <- sum(sankey_flow2$DOWN_T[t])
sum_STABLE_T <- sum(sankey_flow2$STABLE_T[t])
Superpathways <- c('Superpathways', 'Superpathways',
                   sum_UP_T, sum_DOWN_T, sum_STABLE_T)

sankey_flow4 <- rbind(sankey_flow4, Superpathways, others)

# 合并小others
Biosynthesis <- sankey_flow4[which(sankey_flow4$first %in% 'Biosynthesis'),]
D_U_A <- sankey_flow4[which(sankey_flow4$first %in% 'Degradation/Utilization/Assimilation'),]
GoPMaE <- sankey_flow4[which(sankey_flow4$first %in% 'Generation of Precursor Metabolites and Energy'),]

Biosyn <- c('Biosynthesis', 'Other Biosyntheses', rep(0, 3))
combine_Bio <- vector()
for (v in 1:dim(Biosynthesis)[1]) {
  if (sum(as.numeric(Biosynthesis[v, 3:5])) <= 2) {   # 为显示更多，降低为2
    Biosyn[3] <- as.numeric(Biosyn[3]) + as.numeric(Biosynthesis[v, 3])
    Biosyn[4] <- as.numeric(Biosyn[4]) + as.numeric(Biosynthesis[v, 4])
    Biosyn[5] <- as.numeric(Biosyn[5]) + as.numeric(Biosynthesis[v, 5])
    combine_Bio <- append(combine_Bio, v)
  }
}
Biosynthesis1 <- rbind(Biosynthesis[-combine_Bio,], Biosyn)

DUA <- c('Degradation/Utilization/Assimilation', 'Other D_U_A', rep(0, 3))
combine_DUA <- vector()
for (w in 1:dim(D_U_A)[1]) {
  if (sum(as.numeric(D_U_A[w, 3:5])) <= 2) {   # 为显示更多，降低为2
    DUA[3] <- as.numeric(DUA[3]) + as.numeric(D_U_A[w, 3])
    DUA[4] <- as.numeric(DUA[4]) + as.numeric(D_U_A[w, 4])
    DUA[5] <- as.numeric(DUA[5]) + as.numeric(D_U_A[w, 5])
    combine_DUA <- append(combine_DUA, w)
  }
}
D_U_A1 <- rbind(D_U_A[-combine_DUA,], DUA)

GoP <- c('Generation of Precursor Metabolites and Energy',
         'Other GoPMaE', rep(0, 3))
combine_GoPMaE <- vector()
for (x in 1:dim(GoPMaE)[1]) {
  if (sum(as.numeric(GoPMaE[x, 3:5])) <= 2) {   # 为显示更多，降低为2
    GoP[3] <- as.numeric(GoP[3]) + as.numeric(GoPMaE[x, 3])
    GoP[4] <- as.numeric(GoP[4]) + as.numeric(GoPMaE[x, 4])
    GoP[5] <- as.numeric(GoP[5]) + as.numeric(GoPMaE[x, 5])
    combine_GoPMaE <- append(combine_GoPMaE, x)
  }
}
GoPMaE1 <- rbind(GoPMaE[-combine_GoPMaE,], GoP)

# 整理完毕，合并
sankey_flow5 <- rbind(Biosynthesis1, D_U_A1, GoPMaE1, Superpathways, others)

#########################################
# 使用T-test结果绘制桑基图
#########################################
sankey_flow6_T <- sankey_flow5
sankey_flow7_T <- cbind(sankey_flow6_T,
                        UP = rep('UP', dim(sankey_flow6_T)[1]),
                        DOWN = rep('DOWN', dim(sankey_flow6_T)[1]),
                        STABLE = rep('STABLE', dim(sankey_flow6_T)[1]))
sankey_flow8_T <- rbind(data.frame(source = sankey_flow7_T$source,
                                   target = sankey_flow7_T$UP,
                                   value = sankey_flow7_T$UP_T),
                        data.frame(source = sankey_flow7_T$source,
                                   target = sankey_flow7_T$STABLE,
                                   value = sankey_flow7_T$STABLE_T),
                        data.frame(source = sankey_flow7_T$source,
                                   target = sankey_flow7_T$DOWN,
                                   value = sankey_flow7_T$DOWN_T))

library(magrittr)  # %>%来自这个R包
nodes_T <- data.frame(name=c(as.character(sankey_flow8_T$source),
                             as.character(sankey_flow8_T$target)) %>% unique())
sankey_flow9_T <- sankey_flow8_T
sankey_flow9_T$IDsource <- match(sankey_flow9_T$source, nodes_T$name)-1 
sankey_flow9_T$IDtarget <- match(sankey_flow9_T$target, nodes_T$name)-1

sankey_flow10_T <- sankey_flow9_T
sankey_flow10_T$Link_Grp <- as.factor(sankey_flow9_T$target)

# 剔除value为0的行，否则即便为0，也会绘制出极细的流
aba_T <- c()
sankey_flow11_T <- sankey_flow10_T
for (z in 1:dim(sankey_flow11_T)[1]) {
  last_slice <- sankey_flow11_T[z,]
  if (last_slice$value == '0') {
    aba_T <- append(aba_T, z)
  }
}
if (!is.null(aba_T)) {
  sankey_flow11_T <- sankey_flow11_T[-aba_T,]
}

library(networkD3)

ColourScal_T='d3.scaleOrdinal().range(["#f99292", "#c6c8c9", "#85d3fd", 
"#fb8072" ,"#80b1d3", "#fdb462" ,"#b3de69" ,"#fccde5", "#d9d9d9", "#bc80bd", 
"#ccebc5", "#ffed6f"])'

(sankey_T <- sankeyNetwork(Links = sankey_flow11_T, Nodes = nodes_T,
                           Source = 'IDsource', Target = 'IDtarget',
                           Value = 'value', NodeID = 'name', 
                           sinksRight= T, colourScale = ColourScal_T, 
                           nodeWidth= 40, fontSize = 11, nodePadding = 3,
                           LinkGroup = 'Link_Grp',iterations = 0))

# html转化为PDF
library(webshot)
if(!is_phantomjs_installed()){
  install_phantomjs()
}
is_phantomjs_installed()

saveNetwork(sankey_T,"sankey_T.html")
webshot("sankey_T.html" , "sankey_T_ITS.pdf")
