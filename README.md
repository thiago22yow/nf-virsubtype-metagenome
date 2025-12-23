# nf-virsubtype-metagenome

**Nextflow pipeline for metagenomic SARS-CoV-2 subtyping from wastewater sequencing data**

---

## Overview

`nf-virsubtype-metagenome` is a **Nextflow DSL2 pipeline** designed for the analysis of **paired-end metagenomic sequencing data**, with a focus on **SARS-CoV-2** and **wastewater surveillance**.

The pipeline performs:

- Quality control of raw and trimmed reads  
- Adapter and quality trimming  
- Host (human) read depletion  
- SARS-CoV-2 lineage deconvolution using **Freyja**  
- Aggregated quality and lineage reporting with **MultiQC** (including Freyja results)  

---

## Intended use

This pipeline is optimized for:

- Wastewater-based epidemiology (WBE)  
- Environmental surveillance  
- Mixed viral populations  
- SARS-CoV-2 lineage tracking in metagenomic samples  

It assumes **human host depletion (hg38)** for all samples.

---

## Pipeline structure

```
nf-virsubtype-metagenome/
├── assets/
├── bin/
├── configs/
├── containers/
├── data/
│   ├── references/
│   └── test/
├── docs/
├── envs/
├── modules/
├── scripts/
├── main.nf
├── nextflow.config
└── samplesheet.csv
```

---

## Requirements

### Software

- Nextflow ≥ 23  
- Conda (Miniconda or Mambaforge recommended)

### Reference data

Reference human genome and index are **not versioned** due to size constraints.

---

## Reference setup

### Human reference (host depletion)

Build a Bowtie2 index for hg38:

```bash
bowtie2-build hg38.fa hg38
```

Expected directory structure:

```
data/references/human/bowtie2_index/
├── hg38.fa
├── hg38.1.bt2
├── hg38.2.bt2
├── hg38.3.bt2
├── hg38.4.bt2
├── hg38.rev.1.bt2
└── hg38.rev.2.bt2
```

Run the pipeline with:

```bash
--host_index data/references/human/bowtie2_index/hg38
```

---

### SARS-CoV-2 reference

The SARS-CoV-2 reference genome is included:

```
data/references/sc2/NC_045512_Hu-1.fasta
```

---

## 🧾 Input samplesheet

Example `samplesheet.csv`:

```csv
sample_id,fastq_1,fastq_2
sample_1,data/test/sample_1.fastq.gz,data/test/sample_2.fastq.gz
```

---

## Running the pipeline

Basic execution:

```bash
nextflow run main.nf -profile conda
```

### Optional parameters

Disable SARS-CoV-2 lineage typing (Freyja):

```bash
--enable_sc2_freyja false

Resume:

```bash
nextflow run main.nf -profile conda -resume
```

---

## SARS-CoV-2 lineage typing (Freyja)

1. Maps reads to SARS-CoV-2 reference  
2. Calls variants and depths  
3. Performs lineage deconvolution  
4. Generates per-sample summaries  
5. Integrates results into MultiQC  

Outputs:

```
results/typing/freyja/
```

---

## Outputs

```
results/
├── qc/
├── typing/
│   └── freyja/
└── multiqc/
```

