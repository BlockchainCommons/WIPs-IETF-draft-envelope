---
title: "The Envelope Structured Data Format"
abbrev: "Envelope"
docname: draft-mcnally-envelope-latest
category: exp
stream: IETF

ipr: trust200902
area: Applications and Real-Time
workgroup: Network Working Group
keyword: Internet-Draft

stand_alone: yes
smart_quotes: no
pi: [toc, sortrefs, symrefs]

author:
 -
    ins: W. McNally
    name: Wolf McNally
    organization: Blockchain Commons
    email: wolf@wolfmcnally.com
 -
    ins: C. Allen
    name: Christopher Allen
    organization: Blockchain Commons
    email: christophera@blockchaincommons.com

normative:
    RFC8949: CBOR
    RFC8610: CDDL
    RFC7539: CHACHA
    IANA-CBOR-TAGS:
        title: IANA, Concise Binary Object Representation (CBOR) Tags
        target: https://www.iana.org/assignments/cbor-tags/cbor-tags.xhtml
    BLAKE3:
        title: BLAKE3 Cryptographic Hash Function
        target: https://blake3.io

informative:
    MERKLE:
        title: "Merkle Tree"
        target: https://en.wikipedia.org/wiki/Merkle_tree
    TRIPLE:
        title: "Semantic Triple"
        target: https://en.wikipedia.org/wiki/Semantic_triple
    RFC8259: JSON
    JSONLD:
        title: "JSON-LD, Latest Specifications"
        target: https://json-ld.org/spec/latest/
    PROTOBUF:
        title: "Protocol Buffers"
        target: https://developers.google.com/protocol-buffers/
    MERMAID:
        title: "Mermaid.js"
        target: https://mermaid-js.github.io/mermaid/#/

--- abstract

The `envelope` protocol specifies a format for hierarchical binary data built on CBOR. Envelopes are designed with "smart documents" in mind, and have a number of unique features including easy representation of semantic structures like triples, built-in normalization, a built-in Merkle-like digest tree, and the ability for the holder of a document to selectively encrypt or elide specific parts of a document *without* invalidating the digest tree or cryptographic signatures that rely on it.

--- middle

# Introduction

This document specifies the `envelope` protocol for hierarchical structured binary data. Envelope has a number of features that distinguish it from other forms of structured data formats, for example JSON {{-JSON}} (envelopes are binary, not text), JSON-LD {{JSONLD}} (envelopes require no normalization because they are always constructed in canonical form), and protocol buffers {{PROTOBUF}} (envelopes allow for, but do not require a pre-existing schema.)

## Feature: Digest Tree

One of the key features of envelope is that it structurally provides a tree of digests for all its elements, similar to a Merkle Tree {{MERKLE}}. Additionally, each element in an envelope's hierarchy is itself an envelope, making it a recursive structure. Each element in an envelope MAY be abitrary CBOR, or one of several other types of elements that provide the envelope's structure.

## Feature: Semantic Structure

Envelope is designed to facilitate the encoding semantic triples {{TRIPLE}}, i.e., "subject-predicate-object", e.g. "Alice knows Bob". At its top structural level, an envelope encodes a single `subject` and a set of zero or more `assertion`s about the subject, which are `predicate-object` pairs:

~~~
subject [
    predicate1: object1
    predicate2: object2
    ...
]
~~~

The simplest envelope is just a subject with no assertions, e.g., a simple plaintext string. But since every element in an envelope is itelf an envelope, every element can therefore hold its own assertions. This allows any element to carry additional context, e.g. an assertion declaring the language in which human-readable string is written. This mechanism for "assertions with assertions" provides for arbitrarily complex metadata.

## Feature: Cryptography Ready

Because of the strictly invariant nature of the digest tree, envelopes are suitable for use in applications that employ cryptographic signatures. Such signatures in an envelope take the form of `verifiedBy-Signature` assertions on a `subject`, which is the target of the signature.

## Feature: Binary Efficiency, Built on Deterministic CBOR

Envelopes are a binary structure built on CBOR {{-CBOR}}, and MUST adhere to the requirements in section 4.2., "Deterministically Encoded CBOR". This requirement is one factor ensuring that two envelopes that have the same top-level digest, and therefore contain the same digest tree, MUST contain exactly the same information. This holds true even if the two identical envelopes were assembled by different parties, at different times, and particularly in different orders.

## Feature: Digest-Preserving Encryption and Elision

Envelope supports two digest-tree preserving transformations for any of its elements: encryption and elision.

When an element is encrypted, its ciphertext remains in the envelope, and the transformation can be reversed using the symmetric key used to perform the encryption. The encrypted envelope declares the digest of its plaintext content using HMAC authentication. More sophisticated cryptographic constructs such as encryption to a set of public keys are easily supported.

When an element is elided, only its digest remains in the envelope as a placeholder, and the transformation can only be reversed by subsitution with the envelope having the same root digest. Elision can be used as a form of redaction, where the holder of a document reveals part of it while deliberately withholding other parts, or as a form of referencing, where the digest is used as the unique identifier of a digital object that can be found outside the envelope, or as a form of compression where many identical sub-elements of an envelope (except one) are elided.

These digest-tree preserving transformations allow the holder of an envelope-based document to selectively reveal parts of it to third parties without invalidating its signatures. It is also possible to produce proofs that one envelope (or even just the root digest of an envelope) contains another envelope by revealing only a minimum spanning set of digests.

## Terminology

{::boilerplate bcp14-tagged}

This specification makes use of the following terminology:

byte
: Used in its now-customary sense as a synonym for "octet".

element
: An envelope is a tree of elements, each of which is itself an envelope.

image
: The source data from which a cryptographic digest is calculated.

# Envelope Format Specification

This section is normative, and specifies the binary format of envelopes in terms of its CBOR components and their sequencing. The formal language used is the Concise Data Definition Language (CDDL) {{-CDDL}}. To be considered a well-formed envelope, a sequence of bytes MUST be well-formed deterministic CBOR {{-CBOR}} and MUST conform to the specifications in this section.

## Top Level

An envelope is a tagged enumerated type with seven cases. Four of these cases have no children:

* `leaf`
* `known-predicate`
* `encrypted`
* `elided`

Two of these cases, `encrypted` and `elided` "declare" their digest, i.e., they actually encode their digest in the envelope serialization. For all other cases, their digest is implicit in the data itself and may be computed and cached by implementations when an envelope is deserialized.

The other three cases have one or more children:

* The `node` case has a child for its `subject` and an additional child for each of its `assertion`s.
* The `wrapped-envelope` case has exactly one child: the envelope that has been wrapped.
* The `assertion` case has exactly two children: the `predicate` and the `object`.

~~~ cddl
envelope = #6.200(
    envelope-content
)

envelope-content = (
    leaf /
    known-predicate /
    encrypted /
    elided /
    node /
    wrapped-envelope /
    assertion
)
~~~

## Cases Without Children

### Leaf Case Format

A `leaf` case is used when the envelope contains user-defined CBOR content. It is tagged using #6.24, per {{-CBOR}} section 3.4.5.1, "Encoded CBOR Data Item".

~~~ cddl
leaf = #6.24(bytes)
~~~

### Known Predicate Case Format

A `known-predicate` case is used to specify an unsigned integer used as a predicate. Any envelope can be used as a predicate in an assertion, but many predicates are commonly used, e.g., `verifiedBy` for signatures, hence it is desirable to keep common predicates short.

~~~ cddl
known-predicate = #6.223(uint)
~~~

### Encrypted Case Format

An `encrypted` case is used for an envelope that has been encrypted.

~~~ cddl
encrypted = crypto-msg
~~~

For `crypto-msg`, this document specifies the use of "ChaCha20 and Poly1305 for IETF Protocols" as described in {{-CHACHA}}. When used with envelopes, the `crypto-message` construct `aad` (additional authenticated data) field is the `digest` of the plaintext.

~~~ cddl
crypto-msg = #6.201([ ciphertext, nonce, auth, ? aad ])

ciphertext = bytes       ; encrypted using ChaCha20
aad = digest             ; Additional Authenticated Data
nonce = bytes .size 12   ; Random, generated at encryption-time
auth = bytes .size 16    ; Authentication tag created by Poly1305
~~~

### Elided Case Format

An `elided` case is used as a placeholder for an element that has been elided.

~~~ cddl
elided = digest
~~~

For `digest`, this document specifies the use of the BLAKE3 cryptographic hash function {{BLAKE3}} to generate a 32 byte digest.

~~~ cddl
digest = #6.203(blake3-digest)

blake3-digest = bytes .size 32
~~~

## Cases With Children

### Node Case Format

A `node` case is encoded as a CBOR array, and used when one or more assertions are present on the envelope. It MUST NOT be present when there is not at least one assertion. The first element of the array is the envelope's `subject`, Followed by one or more `assertion-element`s, each of which MUST be an `assertion`, or the `encrypted` or `elided` transformation of that assertion. The assertion elements MUST appear in ascending lexicographic order by their digest. The array MUST NOT contain any assertion elements with identical digests.

~~~ cddl
node = [envelope-content, + assertion-element]

assertion-element = ( assertion / encrypted / elided )
~~~

### Wrapped Envelope Case Format

A `wrapped-envelope` case is used where an envelope including all its assertions should be treated as a single element, e.g. for the purpose of signing.

~~~ cddl
wrapped-envelope = #6.224(envelope-content)
~~~

### Assertion Case Format

An `assertion` case is used for each of the assertions in an envelope.

~~~ cddl
assertion = #6.221([envelope, envelope])
~~~

# Computing the Digest Tree

This section is normative, and specifies how the digests for each of the envelope cases are computed. The examples in this section may be used as test vectors.

Each of the seven enumerated envelope cases produces an image which is used as input to a cryptographic hash function to produce a digest of its contents.

The overall digest of an envelope is the digest of its specific case.

In this and subsequenct sections:

*  `digest(image)` is the BLAKE3 hash function that produces a 32-byte digest.
*  The `.digest` attribute is the digest of the named element computed as specified herein.
*  The `||` operator represents contactenation of byte strings.

## Leaf Case Digest Calculation

The `leaf` case consists of any CBOR object. The envelope image is the CBOR serialization of that object:

~~~
digest(cbor)
~~~

### Example

The CBOR serialization of the plaintext string `"Hello"` (not including the quotes) is `6548656C6C6F`. The following command line calculates the BLAKE3 sum of this sequence:

~~~
$ echo "6548656C6C6F" | xxd -r -p | b3sum --no-names
bd6c78899fc1f22c667cfe6893aa2414f8124f25ae6ea80a1a66c2d1d6b455ea
~~~

Using the command line tool in the envelope reference implementation, we create an envelope with this string as the subject and display the envelope's digest. The digest below matches the one above.

~~~
$ envelope subject "Hello" | envelope digest --hex
bd6c78899fc1f22c667cfe6893aa2414f8124f25ae6ea80a1a66c2d1d6b455ea
~~~

## Known Predicate Case Digest Calculation

The envelope image of the `known-predicate` case is the CBOR serialization of the unsigned integer value of the predicate tagged with #6.223, as specified in the Known Predicate Case Format section above.

~~~
digest(#6.223(uint))
~~~

### Example

The known predicate `verifiedBy` in CBOR diagnostic notation is `223(3)`, which in hex is `D8DF03`. The BLAKE3 sum of this sequence is:

~~~
$ echo "D8DF03" | xxd -r -p | b3sum --no-names
d59f8c0ffd798eac7602d1dfb15c457d8e51c3ce34d499e5d2a4fbd2cfe3773f
~~~

Using the command line tool in the envelope reference implementation, we create an envelope with this known predicate as the subject and display the envelope's digest. The digest below matches the one above.

~~~
$ envelope subject --known-predicate verifiedBy | envelope digest --hex
d59f8c0ffd798eac7602d1dfb15c457d8e51c3ce34d499e5d2a4fbd2cfe3773f
~~~

## Encrypted Case Digest Calculation

The `encrypted` case declares its digest to be the digest of the encrypted plaintext. The declaration is made using an HMAC, and when decrypting an element the implementation MUST compare the digest of the decrypted element to the declared digest and flag an error if they do not match.

### Example

If we create the envelope from the leaf example above, encrypt it, and then request its digest:

~~~
$ KEY=`envelope generate key`
$ envelope subject "Hello" | envelope encrypt --key $KEY | envelope digest --hex
bd6c78899fc1f22c667cfe6893aa2414f8124f25ae6ea80a1a66c2d1d6b455ea
~~~

...we see that its digest is the same as its plaintext form:

~~~
$ envelope subject "Hello" | envelope digest --hex
bd6c78899fc1f22c667cfe6893aa2414f8124f25ae6ea80a1a66c2d1d6b455ea
~~~

## Elided Case Digest Calculation

The `elided` case declares its digest to be the digest of the envelope for which it is a placeholder.

### Example

If we create the envelope from the leaf example above, elide it, and then request its digest:

~~~
$ envelope subject "Hello" | envelope elide | envelope digest --hex
bd6c78899fc1f22c667cfe6893aa2414f8124f25ae6ea80a1a66c2d1d6b455ea
~~~

...we see that its digest is the same as its unelided form:

~~~
$ envelope subject "Hello" | envelope digest --hex
bd6c78899fc1f22c667cfe6893aa2414f8124f25ae6ea80a1a66c2d1d6b455ea
~~~

## Node Case Digest Calculation

The envelope image of the `node` case is the concatenation of the digest of its `subject` and the digests of its assertions sorted in ascending lexicographic order.

With a `node` case, there MUST always be at least one assertion.

~~~
digest(subject.digest || assertion-0.digest || assertion-1.digest || ... || assertion-n.digest)
~~~

### Example

We create four separate envelopes and display their digests:

~~~
$ SUBJECT=`envelope subject "Alice"`
$ envelope digest --hex $SUBJECT
278403504ad3a9a9c24c1b35a3673eee165a5d523f8d2a5cf5ce6dd25a37f110

$ ASSERTION_0=`envelope subject assertion "knows" "Bob"`
$ envelope digest --hex $ASSERTION_0
55560bdf060f1220199c87e84e29cecef96ef811de4f399dab2fde9425d0d418

$ ASSERTION_1=`envelope subject assertion "knows" "Carol"`
$ envelope digest --hex $ASSERTION_1
71a3069088c61c928f54ec50859f3f09b9318e9ca6734e6a3b5f77aa3159a711

$ ASSERTION_2=`envelope subject assertion "knows" "Edward"`
$ envelope digest --hex $ASSERTION_2
1e0b049b8d2b21d4bb32f90b4a9e6b5031526f868da303268a9c1c75c0082446
~~~

We combine the envelopes into a single envelope with three assertions:

~~~
$ ENVELOPE=`envelope assertion add envelope $ASSERTION_0 $SUBJECT | \
    envelope assertion add envelope $ASSERTION_1 | \
    envelope assertion add envelope $ASSERTION_2`

$ envelope $ENVELOPE
"Alice" [
    "knows": "Bob"
    "knows": "Carol"
    "knows": "Edward"
]

$ envelope digest --hex $ENVELOPE
0abac60ae3a45a8a7b448b309cca30bdd747f42f508a9a97ea64d657d1f7ea81
~~~

Note that in the envelope notation representation above, the assertions are sorted alphabetically, with `"knows": "Edward"` coming last. But internally, the three assertions are ordered by digest in ascending lexicographic order, with "Edward" coming first because it's digest starting with `1e0b049b` is the lowest, as in the tree formatted display below:

~~~
$ envelope --tree $ENVELOPE
0abac60a NODE
    27840350 subj "Alice"
    1e0b049b ASSERTION
        7092d620 pred "knows"
        d5a375ff obj "Edward"
    55560bdf ASSERTION
        7092d620 pred "knows"
        9a771715 obj "Bob"
    71a30690 ASSERTION
        7092d620 pred "knows"
        ad2c454b obj "Carol"
~~~

To replicate this, we make a list of digests, starting with the subject, and then each assertion's digest in ascending lexicographic order:

~~~
278403504ad3a9a9c24c1b35a3673eee165a5d523f8d2a5cf5ce6dd25a37f110
1e0b049b8d2b21d4bb32f90b4a9e6b5031526f868da303268a9c1c75c0082446
55560bdf060f1220199c87e84e29cecef96ef811de4f399dab2fde9425d0d418
71a3069088c61c928f54ec50859f3f09b9318e9ca6734e6a3b5f77aa3159a711
~~~

We then calculate the BLAKE3 hash of the concatenation of these four digests, and note that this is the same digest as the composite envelope's digest:

~~~
echo "278403504ad3a9a9c24c1b35a3673eee165a5d523f8d2a5cf5ce6dd25a37f1101e0b049b8d2b21d4bb32f90b4a9e6b5031526f868da303268a9c1c75c008244655560bdf060f1220199c87e84e29cecef96ef811de4f399dab2fde9425d0d41871a3069088c61c928f54ec50859f3f09b9318e9ca6734e6a3b5f77aa3159a711" | xxd -r -p | b3sum --no-names
0abac60ae3a45a8a7b448b309cca30bdd747f42f508a9a97ea64d657d1f7ea81

$ envelope digest --hex $ENVELOPE
0abac60ae3a45a8a7b448b309cca30bdd747f42f508a9a97ea64d657d1f7ea81
~~~

## Wrapped Envelope Case Digest Calculation

The envelope image of the `wrapped-envelope` case is the digest of the wrapped envelope:

~~~
digest(envelope.digest)
~~~

### Example

As above, we note the digest of a leaf envelope is the digest of its CBOR:

~~~
$ envelope subject "Hello" | envelope digest --hex
bd6c78899fc1f22c667cfe6893aa2414f8124f25ae6ea80a1a66c2d1d6b455ea

$ echo "6548656C6C6F" | xxd -r -p | b3sum --no-names
bd6c78899fc1f22c667cfe6893aa2414f8124f25ae6ea80a1a66c2d1d6b455ea
~~~

Now we note that the digest of a wrapped envelope is the digest of the wrapped envelope's digest:

~~~
$ envelope subject "Hello" | envelope subject --wrapped | envelope digest --hex
55d4e04399c54bec23346ebf612bf237e659a72e34df14420e18e0290f28c31b

$ echo "bd6c78899fc1f22c667cfe6893aa2414f8124f25ae6ea80a1a66c2d1d6b455ea" | xxd -r -p | b3sum --no-names
55d4e04399c54bec23346ebf612bf237e659a72e34df14420e18e0290f28c31b
~~~

## Assertion Case Digest Calculation

The envelope image of the `assertion` case is the concatenation of the digests of the assertion's predicate and object in that order:

~~~
digest(predicate.digest || object.digest)
~~~

### Example

We create an assertion from two separate envelopes and display their digests:

~~~
$ PREDICATE=`envelope subject "knows"`
$ envelope digest --hex $PREDICATE
7092d62002c3d0f3c889058092e6915bad908f03263c2dc91bfea6fd8ee62fab

$ OBJECT=`envelope subject "Bob"`
$ envelope digest --hex $OBJECT
9a7717153d7a31b0390011413bdf9500ff4d8870ccf102ae31eaa165ab25df1a

$ ASSERTION=`envelope subject assertion "knows" "Bob"`
$ envelope digest --hex $ASSERTION
55560bdf060f1220199c87e84e29cecef96ef811de4f399dab2fde9425d0d418
~~~

To replicate this, we make a list of the predicate digest and the object digest, in that order:

~~~
7092d62002c3d0f3c889058092e6915bad908f03263c2dc91bfea6fd8ee62fab
9a7717153d7a31b0390011413bdf9500ff4d8870ccf102ae31eaa165ab25df1a
~~~

We then calculate the BLAKE3 hash of the concatenation of these two digests, and note that this is the same digest as the composite envelope's digest:

~~~
echo "7092d62002c3d0f3c889058092e6915bad908f03263c2dc91bfea6fd8ee62fab9a7717153d7a31b0390011413bdf9500ff4d8870ccf102ae31eaa165ab25df1a" | xxd -r -p | b3sum --no-names
55560bdf060f1220199c87e84e29cecef96ef811de4f399dab2fde9425d0d418

$ envelope digest --hex $ASSERTION
55560bdf060f1220199c87e84e29cecef96ef811de4f399dab2fde9425d0d418
~~~

# Envelope Hierarchy

This section is informative, and describes envelopes from the perspective of their hierachical structure and the various ways they can be formatted.

An envelope consists of a `subject` and one or more `predicate-object` pairs called `assertions`:

~~~
subject [
    predicate0: object0
    predicate1: object1
    ...
    predicateN: objectN
]
~~~

A concrete example of this might be:

~~~
"Alice" [
    "knows": "Bob"
    "knows": "Carol"
    "knows": "Edward"
]
~~~

In the diagram above, there are five distinct "positions" of elements, each of which is itself an envelope and which therefore produces its own digest:

1. envelope
2. subject
3. predicate
4. object
5. assertion

The examples above are printed in "envelope notation," which is designed to make the semantic content of envelopes human-readable, but it doesn't show the actual digests associated with each of the positions. To see the structure more completely, we can display every element of the envelope in Tree Notation:

~~~
0abac60a NODE
    27840350 subj "Alice"
    1e0b049b ASSERTION
        7092d620 pred "knows"
        d5a375ff obj "Edward"
    55560bdf ASSERTION
        7092d620 pred "knows"
        9a771715 obj "Bob"
    71a30690 ASSERTION
        7092d620 pred "knows"
        ad2c454b obj "Carol"
~~~

We can also show the digest tree graphically using Mermaid {{MERMAID}}:

<artwork type="svg" src="images/svg-validated/example.svg"/>

For easy recognition, envelope trees and Mermaid diagrams only show the first four bytes of each digest, but internally all digests are 32 bytes.

From the above envelope and its tree, we make the following observations:

* The envelope is a `node` case, which holds the overall envelope digest.
* The subject "Alice" has its own digest.
* Each of the three assertions have their own digests
* The predicate and object of each assertion each have their own digests.
* The assertions appear in the structure in ascending lexicographic order by digest, which is distinct from envelope notation where they appear sorted alphabeticaly.

The following subsections present each of the seven enumerated envelope cases in five different output formats:

* Envelope Notation
* Envelope Tree
* Mermaid
* CBOR Diagnostic Notation
* CBOR hex

These examples may be used as test vectors. In addition, each subsection starts with the reference implementation envelope CLI command line needed to generate the envelope being formatted.

## Leaf Case

### Envelope CLI Command Line

~~~
envelope subject "Alice"
~~~

### Envelope Notation

~~~
"Alice"
~~~

### Tree

~~~
27840350 "Alice"
~~~

### Mermaid

<artwork type="svg" src="images/svg-validated/leaf_case.svg"/>

### CBOR Diagnostic Notation

~~~
200(   ; envelope
   24("Alice")   ; leaf
)
~~~

### CBOR Hex

~~~
d8c8d81865416c696365
~~~

## Known Predicate Case

### Envelope CLI Command Line

~~~
envelope subject --known-predicate verifiedBy
~~~

### Envelope Notation

~~~
verifiedBy
~~~

### Tree

~~~
d59f8c0f verifiedBy
~~~

### Mermaid

<artwork type="svg" src="images/svg-validated/known_predicate_case.svg"/>

### CBOR Diagnostic Notation

~~~
200(   ; envelope
   223(3)   ; known-predicate
)
~~~

### CBOR Hex

~~~
d8c8d8df03
~~~

## Encrypted Case

### Envelope CLI Command Line

~~~
envelope subject "Alice" | envelope encrypt --key `envelope generate key`
~~~

### Envelope Notation

~~~
ENCRYPTED
~~~

### Tree

~~~
27840350 ENCRYPTED
~~~

### Mermaid

<artwork type="svg" src="images/svg-validated/encrypted_case.svg"/>

### CBOR Diagnostic Notation

~~~
200(   ; envelope
   201(   ; crypto-msg
      [
         h'6bfa027df241def0',
         h'5520ca6d9d798ffd32d075c4',
         h'd4b43d97a37eb280fdd89cf152ccf57d',
         h'd8cb5820278403504ad3a9a9c24c1b35a3673eee165a5d523f8d2a5cf5ce6dd25a37f110'
      ]
   )
)
~~~

### CBOR Hex

~~~
d8c8d8c984486bfa027df241def04c5520ca6d9d798ffd32d075c450d4b43d97a37eb280fdd89cf152ccf57d5824d8cb5820278403504ad3a9a9c24c1b35a3673eee165a5d523f8d2a5cf5ce6dd25a37f110
~~~

## Elided Case

### Envelope CLI Command Line

~~~
envelope subject "Alice" | envelope elide
~~~

### Envelope Notation

~~~
ELIDED
~~~

### Tree

~~~
27840350 ELIDED
~~~

### Mermaid

<artwork type="svg" src="images/svg-validated/elided_case.svg"/>

### CBOR Diagnostic Notation

~~~
200(   ; envelope
   203(   ; crypto-digest
      h'278403504ad3a9a9c24c1b35a3673eee165a5d523f8d2a5cf5ce6dd25a37f110'
   )
)
~~~

### CBOR Hex

~~~
d8c8d8cb5820278403504ad3a9a9c24c1b35a3673eee165a5d523f8d2a5cf5ce6dd25a37f110
~~~

## Node Case

### Envelope CLI Command Line

~~~
envelope subject "Alice" | envelope assertion "knows" "Bob"
~~~

### Envelope Notation

~~~
"Alice" [
    "knows": "Bob"
]
~~~

### Tree

~~~
e54d6fd3 NODE
    27840350 subj "Alice"
    55560bdf ASSERTION
        7092d620 pred "knows"
        9a771715 obj "Bob"
~~~

### Mermaid

<artwork type="svg" src="images/svg-validated/node_case.svg"/>

### CBOR Diagnostic Notation

~~~
200(   ; envelope
   [
      200(   ; envelope
         24("Alice")   ; leaf
      ),
      200(   ; envelope
         221(   ; assertion
            [
               200(   ; envelope
                  24("knows")   ; leaf
               ),
               200(   ; envelope
                  24("Bob")   ; leaf
               )
            ]
         )
      )
   ]
)
~~~

### CBOR Hex

~~~
d8c882d8c8d81865416c696365d8c8d8dd82d8c8d818656b6e6f7773d8c8d81863426f62
~~~

## Wrapped Envelope Case

### Envelope CLI Command Line

~~~
envelope subject "Alice" | envelope subject --wrapped
~~~

### Envelope Notation

~~~
{
    "Alice"
}
~~~

### Tree

~~~
aaed47e8 WRAPPED
    27840350 subj "Alice"
~~~

### Mermaid

<artwork type="svg" src="images/svg-validated/wrapped_envelope_case.svg"/>

### CBOR Diagnostic Notation

~~~
200(   ; envelope
   224(   ; wrapped-envelope
      24("Alice")   ; leaf
   )
)
~~~

### CBOR Hex

~~~
d8c8d8e0d81865416c696365
~~~

## Assertion Case

### Envelope CLI Command Line

~~~
envelope subject assertion "knows" "Bob"
~~~

### Envelope Notation

~~~
"knows": "Bob"
~~~

### Tree

~~~
55560bdf ASSERTION
    7092d620 pred "knows"
    9a771715 obj "Bob"
~~~

### Mermaid

<artwork type="svg" src="images/svg-validated/assertion_case.svg"/>

### CBOR Diagnostic Notation

~~~
200(   ; envelope
   221(   ; assertion
      [
         200(   ; envelope
            24("knows")   ; leaf
         ),
         200(   ; envelope
            24("Bob")   ; leaf
         )
      ]
   )
)
~~~

### CBOR Hex

~~~
d8c8d8dd82d8c8d818656b6e6f7773d8c8d81863426f62
~~~


# Known Predicates

TODO


# Reference Implementation

TODO This section describes the current reference implementations.


# Security Considerations

TODO Security


# IANA Considerations

TODO

* This section will request that IANA allocated specific CBOR tags in its CBOR tag registry {{IANA-CBOR-TAGS}} to the purpose of encoding the envelope type.
* This section will also request that IANA reserve the MIME type `application/envelope+cbor` for media conforming to this specification.

--- back

# Acknowledgments
{:numbered="false"}

TODO acknowledge.
