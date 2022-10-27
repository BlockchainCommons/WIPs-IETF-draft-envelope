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

    echo "\n### CBOR Diagnostic Notation\n"
    echo "~~~"
    envelope --diag $ENVELOPE
    echo "~~~"

    echo "\n### Mermaid\n"
    echo "~~~"
    envelope --mermaid $ENVELOPE
    echo "~~~"

    echo "\n### CBOR\n"
    echo "~~~"
    envelope --cbor $ENVELOPE
    echo "~~~"
}

print_variants "Leaf Case" 'envelope subject "Alice"'
