#!/bin/bash
# Render each module's Rmd to HTML + PDF
# Uses system pdflatex (TeX Live 2026 already installed)

set -e

DST="/Users/miguelrosa/Desktop/Courses/Data Science"
cd "$DST"

# Install rmarkdown if needed (already done)
# We'll call Rscript -e "rmarkdown::render(...)" per file

render_one() {
    local DIR="$1"
    local RMD_FILE="$2"
    local HTML_FILE="$3"
    local PDF_FILE="$4"

    echo "----------------------------------------------------"
    echo "Rendering: $DIR/$RMD_FILE"
    echo "----------------------------------------------------"

    # Change into the directory so relative paths (figures/, data/) work
    cd "$DIR"

    # Render HTML
    Rscript -e "rmarkdown::render('$RMD_FILE', output_format='html_document', output_file='$HTML_FILE')" 2>&1 | tail -30

    # Render PDF (using the already-present pdflatex via TeX Live)
    Rscript -e "rmarkdown::render('$RMD_FILE', output_format='pdf_document', output_file='$PDF_FILE')" 2>&1 | tail -30

    # Back to repo root
    cd "$DST"
}

# Module 4
render_one "4.Exploratory-Data-Analysis" "Exploratory Data Analysis.Rmd" "Exploratory-Data-Analysis.html" "Exploratory-Data-Analysis.pdf"

# Module 5
render_one "5.Reproducible Research" "Reproducible_Research.Rmd" "Reproducible_Research.html" "Reproducible_Research.pdf"

# Module 6
render_one "6. Inference" "Statistical Inference Course Notes.Rmd" "Statistical-Inference.html" "Statistical-Inference.pdf"

# Module 7
render_one "7. Regression Models" "Regression Models Course Notes.Rmd" "Regression-Models.html" "Regression-Models.pdf"

# Module 8
render_one "8. Practical Machine Learning" "Practical Machine Learning Course Notes.Rmd" "Practical-Machine-Learning.html" "Practical-Machine-Learning.pdf"

# Module 9
render_one "9. Developing Data Products" "Developing Data Products Course Notes.Rmd" "Developing-Data-Products.html" "Developing-Data-Products.pdf"

echo ""
echo "All renders complete."