process PARSE_FREYJA {

  tag "${sample_id}"

  publishDir "${params.outdir}/typing/freyja",
             mode: 'copy',
             overwrite: true

  input:
    tuple val(sample_id), path(freyja_tsv)

  output:
    tuple val(sample_id),
          path("${sample_id}.freyja.summary.tsv")

  script:
  """
  python << 'EOF'
  import csv, os, re

  COV_RE   = re.compile(r"^\\s*coverage\\s+([\\-0-9\\.Ee]+)", re.IGNORECASE)
  RESID_RE = re.compile(r"^\\s*resid\\s+([\\-0-9\\.Ee]+)", re.IGNORECASE)

  sample_id = "${sample_id}"
  infile = "${freyja_tsv}"
  outfile = f"{sample_id}.freyja.summary.tsv"

  major_lineage = "NO_SC2_DETECTED"
  major_abundance = 0.0
  n_lineages = 0
  coverage = float("nan")
  resid = float("nan")
  warnings = []

  def _write(outpath):
      with open(outpath, "w", newline="") as out:
          out.write("sample_id\\tmajor_lineage\\tmajor_abundance\\tn_lineages\\tcoverage\\tresid\\twarning\\n")
          warn_txt = "; ".join(warnings) if warnings else ""
          out.write(f"{sample_id}\\t{major_lineage}\\t{major_abundance}\\t{n_lineages}\\t{coverage}\\t{resid}\\t{warn_txt}\\n")

  if not os.path.exists(infile) or os.path.getsize(infile) == 0:
      warnings.append("Input missing or empty.")
      _write(outfile)
      raise SystemExit(0)

  with open(infile, "r", encoding="utf-8", errors="ignore") as f:
      lines = [ln.rstrip("\\n") for ln in f]

  nonempty = [ln for ln in lines if ln.strip()]
  if not nonempty:
      warnings.append("Input contains only blank lines.")
      _write(outfile)
      raise SystemExit(0)

  lineages_line = None
  abundances_line = None

  for ln in nonempty:
      m = COV_RE.match(ln)
      if m:
          try: coverage = float(m.group(1))
          except: pass
      m = RESID_RE.match(ln)
      if m:
          try: resid = float(m.group(1))
          except: pass

      parts = ln.strip().split(None, 1)
      if len(parts) == 2:
          k, v = parts[0].lower(), parts[1].strip()
          if k.startswith("lineages"):
              lineages_line = v.strip().strip("[]")
          elif k.startswith("abundances"):
              abundances_line = v.strip().strip("'").strip('"')

  # Case A: TSV header
  first = nonempty[0].strip().lower()
  if first.startswith("lineage") and "abundance" in first:
      rows = list(csv.DictReader(nonempty, delimiter="\\t"))
      if rows:
          for r in rows:
              try:
                  r["abundance"] = float(str(r.get("abundance", "0")).replace(",", " ").split()[0])
              except:
                  r["abundance"] = 0.0
          rows.sort(key=lambda r: r["abundance"], reverse=True)
          n_lineages = len(rows)
          major_lineage = rows[0].get("lineage", "NA")
          major_abundance = float(rows[0]["abundance"])
  else:
      # Case B: native freyja demix text
      lineage_list, abundance_list = [], []
      if lineages_line:
          lineage_list = [t for t in lineages_line.split() if t]
      if abundances_line:
          abundances_line = abundances_line.replace(",", " ")
          try:
              abundance_list = [float(x) for x in abundances_line.split() if x]
          except:
              abundance_list = []
      if lineage_list and abundance_list:
          n = min(len(lineage_list), len(abundance_list))
          lineage_list = lineage_list[:n]
          abundance_list = abundance_list[:n]
          n_lineages = n
          max_i = max(range(n), key=lambda i: abundance_list[i])
          major_lineage = lineage_list[max_i]
          major_abundance = abundance_list[max_i]
      else:
          warnings.append("Could not parse lineages/abundances from Freyja output.")

  # Warnings
  if major_lineage == "NO_SC2_DETECTED" or n_lineages == 0:
      warnings.append("No SARS-CoV-2 mixture recovered.")
  if n_lineages > 0 and major_abundance < 0.30:
      warnings.append("Low major lineage abundance (<30%). Interpret with caution.")
  if coverage == coverage:
      if coverage < 10:
          warnings.append("Low coverage (<10%). High risk of overfitting.")
      elif coverage < 30:
          warnings.append("Borderline coverage (10–30%).")
  else:
      warnings.append("No coverage field in input.")
  if resid == resid and resid > 5 and (coverage != coverage or coverage < 30):
      warnings.append("High residual with low/unknown coverage.")

  _write(outfile)
  EOF
  """
}

