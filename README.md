# pig-16S

Quarto and R workflows for pig 16S amplicon analysis.

## Large local files

Large sequencing files, reference databases, and full PICRUSt2 outputs are not tracked by Git. Keep them locally or in external storage before rerunning the full workflow.

Required local data locations:

- `raw data/`: paired-end raw reads (`*_R1.fq.gz`, `*_R2.fq.gz`).
- `clean data/`: assembled FASTQ files (`*.assembled.fastq.gz`).
- `data/dada2-filtered/`: DADA2 filtered FASTQ files (`*_F_filt.fq.gz`).
- `data/silva/`: SILVA reference database (`silva_nr99_v138.2_wSpecies_train_set.fa.gz`).
- `data/picrust2-result/picrust2_output/`: full PICRUSt2 output files.

The local manuscript/source document `20260528.docx` is also not tracked because of its size.

