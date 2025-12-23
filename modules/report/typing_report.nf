process TYPING_REPORT_HTML {
    publishDir "${params.outdir}/report", mode: 'copy', overwrite: true

    input:
    path merged_tsv

    output:
    path "typing_report.html"

    script:
    """
    python scripts/generate_report.py \
        --input ${merged_tsv} \
        --output typing_report.html
    """
}
