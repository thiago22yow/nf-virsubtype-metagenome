nextflow.enable.dsl = 2

// ------------------------------------------------------------
// Input parameters
// ------------------------------------------------------------
params.samplesheet = params.samplesheet ?: "data/test/samplesheet.csv"
params.outdir      = params.outdir      ?: "results"
params.host_index  = params.host_index  ?: "${projectDir}/data/references/human/bowtie2_index/hg38.fa"

// SARS-CoV-2 typing with Freyja
params.enable_sc2_freyja = params.enable_sc2_freyja ?: true
params.sc2_ref           = params.sc2_ref ?: "${projectDir}/data/references/sc2/NC_045512_Hu-1.fasta"

// ------------------------------------------------------------
// Import modules
// ------------------------------------------------------------
include { FASTQC_RAW     } from './modules/qc/fastqc.nf'
include { FASTQC_TRIMMED } from './modules/qc/fastqc.nf'
include { FASTP_TRIM     } from './modules/preproc/fastp.nf'
include { HOST_DEPLETION } from './modules/preproc/host_depletion_bowtie2.nf'
include { MULTIQC        } from './modules/qc/multiqc.nf'

include { FREYJA_RUN   } from './modules/typing/freyja_run.nf'
include { PARSE_FREYJA } from './modules/typing/parse_freyja.nf'

// ------------------------------------------------------------
// Workflow
// ------------------------------------------------------------
workflow {

    Channel
        .fromPath(params.samplesheet)
        .splitCsv(header:true)
        .set { samples_ch }

    samples_ch.view { "Samples loaded: ${it.sample_id}" }

    raw_reads_ch = samples_ch.map { row ->
        tuple(row.sample_id, file(row.fastq_1), file(row.fastq_2))
    }

    FASTQC_RAW(raw_reads_ch)

    trimmed_ch = FASTP_TRIM(raw_reads_ch)

    FASTQC_TRIMMED(trimmed_ch)

    host_depleted_ch = HOST_DEPLETION(trimmed_ch)

    if (params.enable_sc2_freyja) {

        sc2_freyja_input_ch = host_depleted_ch.map { sample_id, r1, r2 ->
            tuple(sample_id, r1, r2)
        }

        freyja_results_ch = FREYJA_RUN(sc2_freyja_input_ch)

        freyja_summary_ch = PARSE_FREYJA(freyja_results_ch)

        freyja_summary_for_multiqc_ch = COPY_FREYJA_TO_MULTIQC(freyja_summary_ch)
    }

    MULTIQC(freyja_summary_for_multiqc_ch)
}

// ------------------------------------------------------------
// Copy Freyja summary files for MultiQC custom content
// ------------------------------------------------------------
process COPY_FREYJA_TO_MULTIQC {

    tag "$sample_id"

    input:
        tuple val(sample_id), path(summary_file)

    output:
        path("multiqc_custom/${sample_id}.freyja.summary.tsv")

    script:
    """
    mkdir -p multiqc_custom
    cp ${summary_file} multiqc_custom/${sample_id}.freyja.summary.tsv
    """
}
