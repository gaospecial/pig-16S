# pig-16S

本仓库保存猪粪便 16S 扩增子数据分析的 Quarto + R 工作流。项目以 Quarto book 的形式组织，主要内容包括 DADA2 预处理、`microeco` 数据对象构建、Alpha/Beta 多样性、分类组成、差异分析、共现网络、ASV Venn 图，以及 PICRUSt2/KEGG 功能预测结果整理。

## 仓库内容

主要文件：

- `_quarto.yml`：Quarto book 配置和章节顺序。
- `index.qmd`、`summary.qmd`：项目首页和结果概要。
- `Preprocess/amplicon-dada2.qmd`：DADA2 预处理流程。
- `amplicon-data.qmd`：从 DADA2 输出和样本信息构建 `microeco` 分析表。
- `amplicon-sample-*.qmd`：各分析章节。
- `renv.lock`、`renv/`、`.Rprofile`：R 依赖复现环境。
- `data/amplicon-sequencing/`、`data/dada2-result/`、`data/picrust2-result/derived/`：已纳入 Git 的轻量结果表。
- `raw data/README.md`、`clean data/README.md`、`data/*/README.md`：未入库大文件说明。

## 复现方式概览

本项目有两种复现层级：

1. **快速复现报告**：使用仓库中已跟踪的小型结果表，直接恢复 R 环境并运行 `quarto render`。适合检查图表、章节和统计结果。
2. **完整重跑分析**：额外准备原始测序 reads、拼接 reads、SILVA 数据库和完整 PICRUSt2 输出，再重新运行 DADA2 和 PICRUSt2 相关步骤。适合从原始数据审计整个流程。

默认推荐先做快速复现，确认环境无误后再重跑耗时步骤。

## 环境要求

需要安装：

- R，建议使用当前项目创建 `renv.lock` 时的 R 版本或更新的兼容版本。
- Quarto。
- Git。
- 系统编译工具链。macOS 上建议安装 Xcode Command Line Tools。

进入项目目录后，R 会通过 `.Rprofile` 自动启用 `renv`：

```bash
cd pig-16S
```

恢复 R 包环境：

```bash
Rscript -e 'renv::restore(prompt = FALSE)'
```

检查依赖状态：

```bash
Rscript -e 'renv::status()'
```

如果输出 `No issues found -- the project is in a consistent state.`，说明 R 依赖与 `renv.lock` 一致。

## 快速复现报告

快速复现不需要原始 FASTQ，也不需要重新运行 DADA2。仓库已经跟踪了报告渲染所需的关键轻量结果：

- `data/dada2-result/asv-table.csv`
- `data/dada2-result/tax-table.csv`
- `data/dada2-result/asv.fasta`
- `data/amplicon-sequencing/otu_table_mt.csv`
- `data/amplicon-sequencing/sample_table_mt.csv`
- `data/amplicon-sequencing/taxon_table_mt.csv`
- `data/picrust2-result/derived/kegg_class_by_genotype.csv`
- `data/picrust2-result/derived/ko00001.keg`
- `info.xlsx`

渲染整本报告：

```bash
quarto render
```

渲染完成后打开：

```bash
open _book/index.html
```

如果只想渲染某一章，例如 Alpha 多样性：

```bash
quarto render amplicon-sample-alpha.qmd
```

## 大文件准备

以下文件不纳入 Git，需要从本地备份、测序交付目录或外部存储恢复。目录中保留了 README 说明。

### 原始 reads

目录：`raw data/`

需要放置 paired-end 原始 reads，命名类似：

```text
NovABWGB16SAB27963-10-5_R1.fq.gz
NovABWGB16SAB27963-10-5_R2.fq.gz
```

当前本地完整数据约 326 个 `.fq.gz` 文件，约 1.1 GB。

### 拼接 reads

目录：`clean data/`

DADA2 主流程当前使用已经拼接好的 FASTQ，命名类似：

```text
NovABWGB16SAB27963-10-5.assembled.fastq.gz
```

当前本地完整数据约 163 个 `.assembled.fastq.gz` 文件，约 516 MB。

### DADA2 过滤 reads

目录：`data/dada2-filtered/`

重新运行过滤步骤后会生成：

```text
NovABWGB16SAB27963-10-5_F_filt.fq.gz
```

这些中间 FASTQ 不入库；`filter-stats.csv` 是轻量统计表，会纳入 Git。

### SILVA 数据库

目录：`data/silva/`

需要准备：

```text
silva_nr99_v138.2_wSpecies_train_set.fa.gz
```

也可以通过环境变量 `SILVA_DB_FILE` 指向其它路径。

### PICRUSt2 完整输出

目录：`data/picrust2-result/picrust2_output/`

完整 PICRUSt2 输出体积较大，当前本地约 2.5 GB，不纳入 Git。常见文件包括：

```text
KO_metagenome_out/pred_metagenome_contrib.tsv.gz
EC_metagenome_out/pred_metagenome_contrib.tsv.gz
pathways_out/path_abun_contrib.tsv.gz
combined_KO_predicted.tsv.gz
combined_EC_predicted.tsv.gz
```

仓库只跟踪了绘图和解释所需的轻量派生结果。

## 完整重跑 DADA2

`Preprocess/amplicon-dada2.qmd` 默认会检测 `data/dada2-result/` 中是否已有结果。如果已有结果且没有显式要求重跑，会跳过耗时 DADA2 主流程。

如需从 `clean data/` 中的拼接 FASTQ 重新运行 DADA2，请先确认：

- `clean data/*.assembled.fastq.gz` 已放置完整。
- SILVA 数据库文件已准备好。
- `data/dada2-filtered/` 和 `data/dada2-result/` 可写。

设置环境变量并渲染预处理章节：

```bash
export RUN_DADA2=TRUE
export DADA2_MULTITHREAD=TRUE
export DADA2_NBASES=1e8
export SILVA_DB_FILE="data/silva/silva_nr99_v138.2_wSpecies_train_set.fa.gz"

quarto render Preprocess/amplicon-dada2.qmd
```

说明：

- `RUN_DADA2=TRUE` 表示强制重跑 DADA2 主流程。
- `DADA2_MULTITHREAD=TRUE` 会启用多线程；在资源受限机器上可以设为 `FALSE`。
- `DADA2_NBASES` 控制学习错误率时使用的碱基数。
- 如果 SILVA 数据库放在共享目录或绝对路径，修改 `SILVA_DB_FILE` 即可。

预处理完成后，关键输出应位于：

```text
data/dada2-result/asv-table.csv
data/dada2-result/tax-table.csv
data/dada2-result/asv.fasta
data/dada2-filtered/filter-stats.csv
```

## 重新构建 microeco 输入表

DADA2 结果更新后，需要重新生成 `microeco` 使用的标准表：

```bash
quarto render amplicon-data.qmd
```

该步骤会读取：

- `data/dada2-result/asv-table.csv`
- `data/dada2-result/tax-table.csv`
- `info.xlsx`

并写出：

- `data/amplicon-sequencing/otu_table_mt.csv`
- `data/amplicon-sequencing/sample_table_mt.csv`
- `data/amplicon-sequencing/taxon_table_mt.csv`

后续 Alpha/Beta 多样性、分类组成、差异分析、网络分析等章节都依赖这些表。

## PICRUSt2 复现说明

PICRUSt2 流程记录在 `amplicon-sample-picrust.qmd` 中。该章节包含服务器运行命令示例，核心输入是：

- `data/dada2-result/asv.fasta`
- `data/dada2-result/asv-table.csv`

在服务器运行前，会将 ASV 表从“样本 x ASV”转置为 PICRUSt2/BIOM 所需的“ASV x 样本”格式，并生成：

```text
data/picrust2-result/work/asv-table.tsv
data/picrust2-result/work/feature-table.biom
```

完整 PICRUSt2 输出较大，不纳入 Git。重跑后如果要更新报告中的 KEGG 热图，需要确保以下派生文件可用或重新生成：

```text
data/picrust2-result/derived/kegg_class_by_genotype.csv
data/picrust2-result/derived/ko00001.keg
```

然后渲染功能预测章节：

```bash
quarto render amplicon-sample-picrust.qmd
```

## 推荐复现顺序

从空环境复现已有报告：

```bash
git clone https://github.com/gaospecial/pig-16S.git
cd pig-16S
Rscript -e 'renv::restore(prompt = FALSE)'
quarto render
```

从本地大文件完整重跑：

```bash
git clone https://github.com/gaospecial/pig-16S.git
cd pig-16S
Rscript -e 'renv::restore(prompt = FALSE)'

# 放置 raw data/、clean data/、data/silva/ 等大文件后：
export RUN_DADA2=TRUE
export DADA2_MULTITHREAD=TRUE
export SILVA_DB_FILE="data/silva/silva_nr99_v138.2_wSpecies_train_set.fa.gz"

quarto render Preprocess/amplicon-dada2.qmd
quarto render amplicon-data.qmd
quarto render
```

如果还要重新生成 PICRUSt2 结果，请按 `amplicon-sample-picrust.qmd` 中的服务器流程运行 PICRUSt2，再更新 `data/picrust2-result/derived/` 下的轻量结果。

## 常见问题

### 渲染时提示 `renv` out-of-sync

先运行：

```bash
Rscript -e 'renv::status()'
```

如果缺包，执行：

```bash
Rscript -e 'renv::restore(prompt = FALSE)'
```

如果代码确实新增了包，应在确认后更新 lockfile：

```bash
Rscript -e 'renv::snapshot(prompt = FALSE)'
```

如果 snapshot 在 Bioconductor 联网校验阶段很慢，可临时跳过校验：

```bash
RENV_CONFIG_SNAPSHOT_VALIDATE=FALSE Rscript -e 'renv::snapshot(prompt = FALSE)'
```

### 找不到拼接 FASTQ

检查 `clean data/` 目录中是否存在：

```text
*.assembled.fastq.gz
```

`Preprocess/amplicon-dada2.qmd` 的 DADA2 流程默认读取该目录，而不是直接读取 `raw data/` 中的 paired-end reads。

### 找不到 SILVA 数据库

设置 `SILVA_DB_FILE`：

```bash
export SILVA_DB_FILE="/path/to/silva_nr99_v138.2_wSpecies_train_set.fa.gz"
```

### 不想重跑耗时步骤

不要设置 `RUN_DADA2=TRUE`。只要 `data/dada2-result/` 中的结果文件存在，预处理章节会跳过 DADA2 主流程。

## Git 跟踪策略

本仓库跟踪：

- 分析源码和 Quarto 章节。
- `renv.lock` 和项目配置。
- 小型结果表、轻量派生结果和最终图形。
- 大文件目录中的 README 占位说明。

本仓库不跟踪：

- 原始 FASTQ。
- 拼接/过滤后的 FASTQ。
- SILVA 数据库压缩包。
- 完整 PICRUSt2 大型输出。
- Quarto 渲染目录 `_book/`、`_freeze/`。
- 本地手稿文件 `20260528.docx`。

