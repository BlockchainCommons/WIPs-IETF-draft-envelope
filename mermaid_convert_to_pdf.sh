#!/bin/zsh

to_pdf() {
    echo $1
    FILENAME=$1
    mmdc --input images/mermaid/$FILENAME.mermaid \
        --output images/pdf/$FILENAME.pdf \
        --outputFormat pdf \
        --configFile mermaid_config.json
}

to_pdf "example"
to_pdf "assertion_case"
to_pdf "elided_case"
to_pdf "encrypted_case"
to_pdf "known_value_case"
to_pdf "leaf_case"
to_pdf "node_case"
to_pdf "wrapped_envelope_case"
