#!/bin/bash
# Move notes from Inspiring/DataScienceSpCourseNotes-master to Data Science/
# Modules 4-9 only. Preserves projects/, mtcars_work, _cache/, _files/.
# Rewrites author: "Xing Su" -> "Miguel Rosa" in source Rmds.

set -e

SRC="/Users/miguelrosa/Desktop/Courses/Inspiring/DataScienceSpCourseNotes-master"
DST="/Users/miguelrosa/Desktop/Courses/Data Science"
STASH="$DST/.prestash"
mkdir -p "$STASH"

# Module name mappings: source-dir-name : target-info
# Format: src_dir:target_dir:target_rmd_basename
MODULE_4="$(echo 4.Exploratory-Data-Analysis)"
MODULE_5="$(echo 5.Reproducible Research)"
MODULE_7="$(echo 7. Regression Models)"
MODULE_8="$(echo 8. Practical Machine Learning)"

# Process one module: $1=src_dir, $2=tgt_dir, $3=tgt_rmd_basename, $4=html_basename, $5=pdf_basename
process_module() {
    local SRC_DIR="$1"
    local TGT_DIR="$2"
    local TGT_RMD="$3"
    local TGT_HTML="$4"
    local TGT_PDF="$5"

    echo "===================================================="
    echo "Processing: $SRC_DIR -> $TGT_DIR"
    echo "===================================================="

    cd "$DST"

    # Defensive: stash old generated artifacts so git shows the move properly
    mkdir -p "$STASH/$TGT_DIR"

    # Stash old main Rmd/html/pdf and any _cache/_files siblings if they exist
    for old in "$TGT_RMD" "$TGT_HTML" "$TGT_PDF"; do
        if [ -e "$TGT_DIR/$old" ]; then
            mv "$TGT_DIR/$old" "$STASH/$TGT_DIR/"
        fi
    done
    # Old lowercase .rmd extension variant and any generated cache/files dirs
    for old in "$TGT_RMD.lower" "Reproducible_Research_cache" "Reproducible_Research_files"; do
        if [ -e "$TGT_DIR/$old" ]; then
            mv "$TGT_DIR/$old" "$STASH/$TGT_DIR/"
        fi
    done

    # Move source.Rmd into target dir with author-rename
    local SRC_RMD_FILE
    SRC_RMD_FILE=$(ls "$SRC/$SRC_DIR"/*.Rmd 2>/dev/null | head -1)
    if [ -n "$SRC_RMD_FILE" ]; then
        cp "$SRC_RMD_FILE" "$TGT_DIR/$TGT_RMD"
        # Rewrite author: "Xing Su" -> "Miguel Rosa"  (only the author line)
        sed -i '' 's/^author: ".*"$/author: "Miguel Rosa"/' "$TGT_DIR/$TGT_RMD"
        echo "  Rmd placed: $TGT_DIR/$TGT_RMD"
    fi

    # Merge figures/ from source (additive: don't delete target's figures)
    if [ -d "$SRC/$SRC_DIR/figures" ]; then
        mkdir -p "$TGT_DIR/figures"
        # Copy missing files only (no overwrite of same-name files in target)
        cp -n "$SRC/$SRC_DIR/figures/"* "$TGT_DIR/figures/" 2>/dev/null || true
        echo "  Figures merged"
    fi

    # Copy extras from source root that aren't Rmd/HTML/PDF/figures
    if [ -d "$SRC/$SRC_DIR" ]; then
        for item in "$SRC/$SRC_DIR"/*; do
            local name
            name=$(basename "$item")
            case "$name" in
                *.Rmd|*.rmd|*.Rmarkdown|*.html|*.pdf|*.HTM|figures|images|.DS_Store)
                    ;; # skip
                *)
                    if [ ! -e "$TGT_DIR/$name" ]; then
                        cp -R "$item" "$TGT_DIR/"
                        echo "  Extra copied: $name"
                    fi
                    ;;
            esac
        done
    fi

    echo "  Done staging $TGT_DIR"
}

# Module 4 - Exploratory Data Analysis
process_module "4_EXDATA" "$MODULE_4" \
    "Exploratory Data Analysis.Rmd" \
    "Exploratory-Data-Analysis.html" \
    "Exploratory-Data-Analysis.pdf"

# Module 5 - Reproducible Research
# Note: target uses lowercase .rmd - normalize to .Rmd
process_module "5_REPDATA" "$MODULE_5" \
    "Reproducible_Research.Rmd" \
    "Reproducible_Research.html" \
    "Reproducible_Research.pdf"

# Module 6 - Statistical Inference
process_module "6_STATINFERENCE" "6. Inference" \
    "Statistical Inference Course Notes.Rmd" \
    "Statistical-Inference.html" \
    "Statistical-Inference.pdf"

# Module 7 - Regression Models
process_module "7_REGMODS" "$MODULE_7" \
    "Regression Models Course Notes.Rmd" \
    "Regression-Models.html" \
    "Regression-Models.pdf"

# Module 8 - Practical Machine Learning
process_module "8_PREDMACHLEARN" "$MODULE_8" \
    "Practical Machine Learning Course Notes.Rmd" \
    "Practical-Machine-Learning.html" \
    "Practical-Machine-Learning.pdf"

# Module 9 - Developing Data Products
process_module "9_DEVDATAPROD" "9. Developing Data Products" \
    "Developing Data Products Course Notes.Rmd" \
    "Developing-Data-Products.html" \
    "Developing-Data-Products.pdf"

echo ""
echo "All modules staged. Now rendering Rmd -> HTML+PDF..."
