#!/bin/zsh

print_variants() {
    echo "\n## $1"
    ENVELOPE=`eval $2`

    echo "\n### Envelope CLI Command Line\n"
    echo "~~~"
    echo $2
    echo "~~~"

    echo "\n### Envelope Notation\n"
    echo "~~~"
    envelope --envelope $ENVELOPE
    echo "~~~"

    echo "\n### Tree\n"
    echo "~~~"
    envelope --tree $ENVELOPE
    echo "~~~"

    echo "\n### Mermaid\n"
    MERMAID=`envelope --mermaid --theme monochrome $ENVELOPE`
    FILENAME=${1:l}
    FILENAME=${FILENAME// /_}
    MERMAID_FILENAME=images/mermaid/$FILENAME.mermaid
    echo ${MERMAID} > ${MERMAID_FILENAME}
    PDF_FILENAME=images/pdf/$FILENAME.pdf
    mmdc --input ${MERMAID_FILENAME} \
        --output ${PDF_FILENAME} \
        --outputFormat pdf \
        --configFile mermaid_config.json \
        > /dev/null

    # echo "~~~"
    # echo $MERMAID
    # echo "~~~"
    echo "<artwork type=\"svg\" src=\"images/svg-validated/$FILENAME.svg\"/>"

    echo "\n### CBOR Diagnostic Notation\n"
    echo "~~~"
    envelope --diag $ENVELOPE
    echo "~~~"

    echo "\n### CBOR Hex\n"
    echo "~~~"
    envelope --cbor $ENVELOPE
    echo "~~~"
}

print_variants "Example" 'envelope subject "Alice" | envelope assertion "knows" "Bob" | envelope assertion "knows" "Carol" | envelope assertion "knows" "Edward"'
print_variants "Leaf Case" 'envelope subject "Alice"'
print_variants "Known Predicate Case" 'envelope subject --known-predicate verifiedBy'
print_variants "Encrypted Case" 'envelope subject "Alice" | envelope encrypt --key `envelope generate key`'
print_variants "Elided Case" 'envelope subject "Alice" | envelope elide'
print_variants "Node Case" 'envelope subject "Alice" | envelope assertion "knows" "Bob"'
print_variants "Wrapped Envelope Case" 'envelope subject "Alice" | envelope subject --wrapped'
print_variants "Assertion Case" 'envelope subject assertion "knows" "Bob"'

# The next steps to prepare the Mermaid files need to be performed in Illustrator.
# See `preparing_mermaid.md`.
# After that's done, run `postprocess_mermaid.sh`
