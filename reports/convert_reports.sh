#!/bin/bash
###############################################################################
# ATLAS Report Converter — Markdown → DOCX + PDF
# Uses Pandoc for professional document generation
#
# Prerequisites:
#   sudo apt install pandoc texlive-latex-recommended texlive-latex-extra
#   sudo apt install texlive-fonts-recommended texlive-xetex
#
# Usage:
#   chmod +x convert_reports.sh
#   ./convert_reports.sh
###############################################################################

set -e

echo "=============================================="
echo " ATLAS Report Document Generator"
echo "=============================================="
echo ""

# Check for pandoc
if ! command -v pandoc &> /dev/null; then
    echo "ERROR: pandoc not found."
    echo "Install with: sudo apt install pandoc"
    echo ""
    echo "For PDF generation also install:"
    echo "  sudo apt install texlive-latex-recommended texlive-latex-extra"
    echo "  sudo apt install texlive-fonts-recommended texlive-xetex"
    exit 1
fi

echo "Pandoc version: $(pandoc --version | head -1)"
echo ""

# Get script directory
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPORT1="$DIR/ATLAS_AGV_SIMULATION_TO_PHYSICAL_CONVERSION_REPORT"
REPORT2="$DIR/ATLAS_WAREHOUSE_AGV_COMPLETE_ENGINEERING_DISSERTATION"

# ─── Report 1: DOCX ──────────────────────────────────────
echo "[1/4] Generating Report 1 DOCX..."
pandoc "${REPORT1}.md" \
    -o "${REPORT1}.docx" \
    --from markdown \
    --to docx \
    --toc \
    --toc-depth=3 \
    --number-sections \
    --highlight-style=tango \
    --metadata title="ATLAS AGV — Simulation to Physical Robot Conversion Report" \
    2>&1 && echo "  ✓ ${REPORT1}.docx" || echo "  ✗ DOCX generation failed"

# ─── Report 1: PDF ────────────────────────────────────────
echo "[2/4] Generating Report 1 PDF..."
pandoc "${REPORT1}.md" \
    -o "${REPORT1}.pdf" \
    --from markdown \
    --to pdf \
    --pdf-engine=xelatex \
    --toc \
    --toc-depth=3 \
    --number-sections \
    --highlight-style=tango \
    -V geometry:margin=2.5cm \
    -V fontsize=12pt \
    -V linestretch=1.5 \
    -V documentclass=report \
    2>&1 && echo "  ✓ ${REPORT1}.pdf" || echo "  ✗ PDF failed (install texlive-xetex)"

# ─── Report 2: DOCX ──────────────────────────────────────
echo "[3/4] Generating Report 2 DOCX..."
pandoc "${REPORT2}.md" \
    -o "${REPORT2}.docx" \
    --from markdown \
    --to docx \
    --toc \
    --toc-depth=3 \
    --number-sections \
    --highlight-style=tango \
    --metadata title="ATLAS Warehouse AGV — Complete Engineering Dissertation" \
    2>&1 && echo "  ✓ ${REPORT2}.docx" || echo "  ✗ DOCX generation failed"

# ─── Report 2: PDF ────────────────────────────────────────
echo "[4/4] Generating Report 2 PDF..."
pandoc "${REPORT2}.md" \
    -o "${REPORT2}.pdf" \
    --from markdown \
    --to pdf \
    --pdf-engine=xelatex \
    --toc \
    --toc-depth=3 \
    --number-sections \
    --highlight-style=tango \
    -V geometry:margin=2.5cm \
    -V fontsize=12pt \
    -V linestretch=1.5 \
    -V documentclass=report \
    2>&1 && echo "  ✓ ${REPORT2}.pdf" || echo "  ✗ PDF failed (install texlive-xetex)"

echo ""
echo "=============================================="
echo " GENERATION COMPLETE"
echo "=============================================="
echo ""
echo " Output files:"
ls -lh "$DIR"/*.docx "$DIR"/*.pdf 2>/dev/null || echo "  (check above for errors)"
echo ""
echo " If PDF failed, DOCX still works. Open DOCX in:"
echo "   - Microsoft Word"
echo "   - Google Docs (upload)"
echo "   - LibreOffice Writer"
echo "   Then export to PDF from there."
echo ""
echo " Alternative PDF generation (if xelatex unavailable):"
echo "   pandoc report.md -o report.pdf --pdf-engine=pdflatex"
echo "   pandoc report.md -o report.pdf --pdf-engine=wkhtmltopdf"
echo "=============================================="
