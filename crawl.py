import os
import requests
import csv
import time
import random

###############################################>>>>>>>>>>>>>>>>>>>>>
#   脚本运行准备工作1：定义文件路径及函数
###############################################>>>>>>>>>>>>>>>>>>>>>

path_f = 'D:\\R\\MetaCyc-Crawl-main\\python_file\\full_class.csv'
path_u = 'D:\\R\\MetaCyc-Crawl-main\\python_file\\used_class.csv'
path_sf = 'D:\\R\\MetaCyc-Crawl-main\\python_file\\saved_full_class.csv'
path_su = 'D:\\R\\MetaCyc-Crawl-main\\python_file\\saved_used_class.csv'
path_qp = 'D:\\R\\MetaCyc-Crawl-main\\python_file\\query_ITS_MetaCyc_path_abun_unstrat.tsv'   # 查询文件在这里选择

# 从本地备份库中查询，写入
def write_full(full_class):
    with open (path_f, 'a') as full_class_csvfile:
        full_class_csvfile.writelines([line+'\n'+'\n' for line in full_class])
def write_used(used_class):
    with open (path_u, 'a') as used_class_csvfile:
        used_class_csvfile.writelines([line+'\n'+'\n' for line in used_class])

# 写入爬取所得数据
def write_full_csv(full_class):
    with open(path_f, 'a') as full_class_csvfile:
        full = csv.writer(full_class_csvfile)
        full.writerow(full_class)
def write_used_csv(used_class):
    with open(path_u, 'a') as used_class_csvfile:
        used = csv.writer(used_class_csvfile)
        used.writerow(used_class)

# 爬取过程中添加本地备份
def write_saved_full_csv(full_class):
    with open(path_sf, 'a') as saved_full_class_csvfile:
        full = csv.writer(saved_full_class_csvfile)
        full.writerow(full_class)
def write_saved_used_csv(used_class):
    with open(path_su, 'a') as saved_used_class_csvfile:
        used = csv.writer(saved_used_class_csvfile)
        used.writerow(used_class)

###############################################>>>>>>>>>>>>>>>>>>>>>
#   脚本运行准备工作2：清洗文件夹
###############################################>>>>>>>>>>>>>>>>>>>>>

# CSV结果文件写入方式为'a'，防止覆盖
# 为避免错误计入之前的结果，每次循环前都要清理文件夹
if os.path.exists(path_f):
    os.remove(path_f)
if os.path.exists(path_u):
    os.remove(path_u)

# 若存在本地备份数据，询问是否删除
if os.path.exists(path_sf) or os.path.exists(path_su):
    while True:
        choice = input('是否删除本地备份数据(y/n):')
        if choice == 'y':
            if os.path.exists(path_sf):
                os.remove(path_sf)
            if os.path.exists(path_su):
                os.remove(path_su)
            break
        elif choice == 'n':
            break
        else:
            print('''删除请输入"y"并敲回车, 不删除请输入"n"并敲回车''')
            print('')
            continue
else: pass

###############################################>>>>>>>>>>>>>>>>>>>>>
#   本地备份数据库查询，力所能及的错误核查
###############################################>>>>>>>>>>>>>>>>>>>>>

sav_f = []
sav_u = []
pa = []

if os.path.exists(path_sf):
    with open(path_sf) as sav_full:
        for f in sav_full.readlines():
            if f != '\n':
                f = f.strip('\n')
                sav_f.append(f)

if os.path.exists(path_su):
    with open(path_su) as sav_used:
        for u in sav_used.readlines():
            if u != '\n':
                u = u.strip('\n')
                sav_u.append(u)

with open(path_qp) as path:
    local_f = []
    local_u = []
    for i in path.readlines():
        i = i.strip('\n')
        i = ',' + i         # 在本地备份中查询，要区分COMPLETE-ARO-PWY与ARO-PWY这类错误，避免重复，因此前面加“逗号”
        sign_f = 0
        for j in sav_f:
            query_f = j[-len(i):]
            if i == query_f:
                local_f.append(j)
                sign_f += 1
        sign_u = 0
        for k in sav_u:
            query_u = k[-len(i):]
            if i == query_u:
                local_u.append(k)
                sign_u += 1
        if sign_f == 0 and sign_u == 0:
            i = i[1:]       # 这里都是本地备份中不存在的代谢通路，需使用爬虫爬取，这里去除前面加的“逗号”
            pa.append(i)
        elif sign_f != sign_u:      # 比较saved_f和saved_u查询结果数量是否一致，做力所能及的错误核查
            print('× 两备份库本地查询结果数量不等，本地备份数据存在错误，请重新运行脚本，并在开始选择删除本地备份数据')
            exit()      # 中断脚本

    write_full(local_f)
    write_used(local_u)
    
# 核查本地备份数据saved_full查询结果是否存在重复，做力所能及的错误核查
if os.path.exists(path_sf) and os.path.exists(path_f):
    saved_f_pa = []
    saved_u_pa = []
    with open(path_sf) as path:
        for i in path.readlines():
            if i == '\n':
                pass
            else: 
                i = i.strip('\n')
                saved_f_pa.append(i)
    query_pa = []
    with open(path_f) as path:
        for i in path.readlines():
            if i == '\n':
                pass
            else: 
                i = i.strip('\n')
                query_pa.append(i)
    a = 0
    for j in saved_f_pa:
        num = query_pa.count(j)
        if num != 1 and num != 0:
            print(j, num)
            a += 1
    if a == 0:
        print('')
        print('√ 本地备份数据查询已完成，经核验，结果无重复')   # 实际只核查了本地备份数据saved_full
        print('')
    elif a >= 1:
        print('')
        print('× 本地备份数据查询已完成，经核验，结果存在重复，请重新运行脚本，并在开始选择删除本地备份数据')
        print('')
        exit()
    
    # saved_u备份库重复可能属于正常，如GLYCOGENSYNTH-PWY
    # 像saved_f备份库一样通过重复核查会得出误判为错误
    # 改变思路，比对saved_u与saved_f个数是否相等，做力所能及的错误核查
    with open(path_su) as path:
        for i in path.readlines():
            if i == '\n':
                pass
            else: 
                i = i.strip('\n')
                saved_u_pa.append(i)
    if len(saved_f_pa) != len(saved_u_pa):
        print('× 两备份库数据量不匹配，本地备份存在错误，请重新运行脚本，并在开始选择删除本地备份数据')
        exit()

###############################################>>>>>>>>>>>>>>>>>>>>>
#   循环爬取所需METACYC代谢通路层级信息   
###############################################>>>>>>>>>>>>>>>>>>>>>

num = len(pa)
m = 0

headers = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.139 Mobile Safari/537.36'
}

for pathway in pa:      # 需注意Picrust2预测出的通路少数在MetaCyc中不存在，如'ARGORNPROST-PWY','PWY-5182'，所以百分数增加不代表爬到的数据一定刷新变多。当然，这种情况极少
    data = {'object': pathway}
    
    try:
        r = requests.post('https://metacyc.org/META/NEW-IMAGE', params=data, headers = headers, timeout=30)
        html = r.text
        from bs4 import BeautifulSoup
        soup =  BeautifulSoup(html, 'lxml')

        # 收集所有METACYC一级代谢通路层级，作为断点，判断是否读完一条完整代谢通路层级
        first_rank = ['Activation/Inactivation/Interconversion','Bioluminescence','Biosynthesis',
        'Degradation/Utilization/Assimilation','Detoxification','Generation of Precursor Metabolites and Energy',
        'Glycan Pathways','Macromolecule Modification','Signal transduction pathways','Superpathways','Transport']

        # full_class为完整的代谢通路层级关系
        # used_class取第1,2层代谢通路层级为第1,2列，取最后一层代谢通路层级和查询pathway为第3,4列
        # used_class第1,2列用于画桑基图，第3,4列用于富集分析
        full_class = []
        used_class = []

        m += 1

        # 循环计数
        n = 0

        # METACYC代谢通路页面html中代谢通路层级信息均在属性class为ECOCYC-CLASS的节点内
        classes = soup.find_all(class_='ECOCYC-CLASS')

        for ECOCYC_CLASS in classes:
            n += 1
            rank = ECOCYC_CLASS.string
            if len(classes) != 1:
                if rank in first_rank and n != 1:
                    full_class.append(pathway)
                    write_full_csv(full_class)
                    write_saved_full_csv(full_class)
                    used_class = [full_class[0], full_class[1], full_class[-2], full_class[-1]]
                    write_used_csv(used_class)
                    write_saved_used_csv(used_class)
                    full_class = []
                    used_class = []
                    full_class.append(rank)
                    if n == len(classes):       # 针对最后一条只有一级代谢通路的情况，如'P441-PWY'
                        full_class.append(pathway)
                        write_full_csv(full_class)
                        write_saved_full_csv(full_class)
                        used_class = [full_class[0], full_class[1],full_class[-2], full_class[-1]]
                        write_used_csv(used_class)
                        write_saved_used_csv(used_class)
                        full_class = []
                        used_class = []
                        break
                    if rank == 'Superpathways':     # 针对 属性class为ECOCYC-CLASS的节点并非都是层次信息,且在最后，不为None，而实际结尾是Superpathways 的情况，如'UBISYN-PWY'
                        full_class.append(pathway)
                        write_full_csv(full_class)
                        write_saved_full_csv(full_class)
                        used_class = [full_class[0], full_class[1],full_class[-2], full_class[-1]]
                        write_used_csv(used_class)
                        write_saved_used_csv(used_class)
                        full_class = []
                        used_class = []
                        break
                elif rank not in first_rank or n == 1:
                    if rank == None:        # 针对属性class为ECOCYC-CLASS的节点并非都是层次信息，且在最后，为None 的情况，如'PWY-6700','PWY-7527','PWY0-1261'
                        full_class.append(pathway)
                        write_full_csv(full_class)
                        write_saved_full_csv(full_class)
                        used_class = [full_class[0], full_class[1],full_class[-2], full_class[-1]]
                        write_used_csv(used_class)
                        write_saved_used_csv(used_class)
                        full_class = []
                        used_class = []
                        break
                    if n == len(classes):       # 针对最后一条为深代谢层级的情况，如'1CMET2-PWY'
                        full_class.append(rank)
                        full_class.append(pathway)
                        write_full_csv(full_class)
                        write_saved_full_csv(full_class)
                        used_class = [full_class[0], full_class[1],full_class[-2], full_class[-1]]
                        write_used_csv(used_class)
                        write_saved_used_csv(used_class)
                        full_class = []
                        used_class = []
                    elif n != len(classes):
                        full_class.append(rank)
            elif len(classes) == 1:     # 针对只有一级代谢通路的情况，如'PWY-7723'
                full_class.append(rank)
                full_class.append(pathway)
                write_full_csv(full_class)
                write_saved_full_csv(full_class)
                used_class = [full_class[0], full_class[1],full_class[-2], full_class[-1]]
                write_used_csv(used_class)
                write_saved_used_csv(used_class)
                full_class = []
                used_class = []

        print('%s%%'%(round(m/num*100,2)))

        r.close()   # 手动关闭连接
        del(r)  # 释放内存
    
    # 通过捕获错误保证程序不间断运行，若遇其它类型错误，中断程序以排查问题
    except requests.exceptions.ConnectionError:
        print('ConnectionError -- 可能由于请求过频繁，或VPN未关闭，或其它因素，爬虫访问网站似乎受到了限制，1min后将尝试重新爬取')
        time.sleep(60)
    except requests.exceptions.Timeout:
        print('Timeout -- 爬虫在30s内仍未连接到网站服务器，10s后将尝试重新爬取')
        time.sleep(10)

    sleep_time = random.randrange(5, 20)
    time.sleep(sleep_time)
