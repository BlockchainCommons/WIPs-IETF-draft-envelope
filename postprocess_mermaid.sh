#!/bin/zsh

postprocess() {
    echo $1
    FILENAME=$1.svg
    svgcheck -r images/svg/$FILENAME --out images/svg-validated/$FILENAME
    sed -e "s/ x=\"0px\" y=\"0px\"//g" -i .backup images/svg-validated/$FILENAME
    sed -e "s/ id=\"Layer_1\"//g" -i .backup images/svg-validated/$FILENAME
    rm images/svg-validated/$FILENAME.backup
}

postprocess "example"
postprocess "assertion_case"
postprocess "elided_case"
postprocess "encrypted_case"
postprocess "compressed_case"
postprocess "known_value_case"
postprocess "leaf_case"
postprocess "node_case"
postprocess "wrapped_envelope_case"
