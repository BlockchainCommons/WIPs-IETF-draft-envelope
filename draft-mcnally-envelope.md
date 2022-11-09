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
    RFC6838: MIME
    IANA-CBOR-TAGS:
        title: IANA, Concise Binary Object Representation (CBOR) Tags
        target: https://www.iana.org/assignments/cbor-tags/cbor-tags.xhtml
    BLAKE3:
        title: BLAKE3 Cryptographic Hash Function
        target: https://blake3.io
    CRYPTO-MSG:
        title: UR Type Definition for Secure Messages
        target: https://github.com/BlockchainCommons/Research/blob/master/papers/bcr-2022-001-secure-message.md
    ENVELOPE-REFIMPL:
        title: Envelope Reference Implementation, part of the Blockchain Commons Secure Components Framework
        target: https://github.com/BlockchainCommons/BCSwiftSecureComponents
    ENVELOPE-CLI:
        title: Envelope Command Line Tool
        target: https://github.com/BlockchainCommons/envelope-cli-swift

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
    FOAF:
        title: "Friend of a Friend (FOAF)"
        target: https://en.wikipedia.org/wiki/FOAF
    SSKR:
        title: "Sharded Secret Key Recovery (SSKR)"
        target: https://github.com/BlockchainCommons/Research/blob/master/papers/bcr-2020-011-sskr.md
    OWL:
        title: "Web Ontology Language (OWL)"
        target: https://www.w3.org/OWL/
    ISO639:
        title: "ISO 639 - Standard for representation of names for language and language groups"
        target: https://en.wikipedia.org/wiki/ISO_639

--- abstract

The `envelope` protocol specifies a format for hierarchical binary data built on CBOR. Envelopes are designed with "smart documents" in mind, and have a number of unique features including easy representation of semantic structures like triples, built-in normalization, a built-in Merkle-like digest tree, and the ability for the holder of a document to selectively encrypt or elide specific parts of a document without invalidating the digest tree or cryptographic signatures that rely on it.

--- middle

# Introduction

This document specifies the `envelope` protocol for hierarchical structured binary data. Envelope has a number of features that distinguish it from other forms of structured data formats, for example JSON {{-JSON}} (envelopes are binary, not text), JSON-LD {{JSONLD}} (envelopes require no normalization because they are always constructed in canonical form), and protocol buffers {{PROTOBUF}} (envelopes allow for, but do not require a pre-existing schema.)

## Feature: Digest Tree

One of the key features of envelope is that it structurally provides a tree of digests for all its elements, similar to a Merkle Tree {{MERKLE}}. Additionally, each element in an envelope's hierarchy is itself an envelope, making it a recursive structure. Each element in an envelope MAY be abitrary CBOR, or one of several other types of elements that provide the envelope's structure.

## Feature: Semantic Structure

Envelope is designed to facilitate the encoding of semantic triples {{TRIPLE}}, i.e., "subject-predicate-object", e.g. "Alice knows Bob." At its top structural level, an envelope encodes a single `subject` and a set of zero or more `assertion`s about the subject, which are `predicate-object` pairs:

~~~
subject [
    predicate0: object0
    predicate1: object1
    ...
    predicateN: objectN
]
~~~

The simplest envelope is just a subject with no assertions, e.g., a simple plaintext string (or any other CBOR construct.) But since every element in an envelope is itelf an envelope, every element can therefore hold its own assertions. This allows any element to carry additional context, e.g. an assertion declaring the language in which a human-readable string is written. This mechanism for "assertions with assertions" provides for arbitrarily complex metadata.

## Feature: Cryptography Ready

Because of the strictly invariant nature of the digest tree, envelopes are suitable for use in applications that employ cryptographic signatures. Such signatures in an envelope take the form of `verifiedBy-Signature` assertions on a `subject`, which is the target of the signature. Other cryptographic structures are readily supported.

## Feature: Binary Efficiency, Built on Deterministic CBOR

Envelopes are a binary structure built on CBOR {{-CBOR}}, and MUST adhere to the requirements in section 4.2., "Deterministically Encoded CBOR". This requirement is one of several design factors ensuring that two envelopes that have the same top-level digest, and therefore contain the same digest tree, MUST represent exactly the same information. This holds true even if the two identical envelopes were assembled by different parties, at different times, and particularly in different orders.

## Feature: Digest-Preserving Encryption and Elision

Envelope supports two digest tree-preserving transformations for any of its elements: encryption and elision.

When an element is encrypted, its ciphertext remains in the envelope, and the transformation can be reversed using the symmetric key used to perform the encryption. The encrypted envelope declares the digest of its plaintext content using HMAC authentication. More sophisticated cryptographic constructs such as encryption to a set of public keys are readily supported.

When an element is elided, only its digest remains in the envelope as a placeholder, and the transformation can only be reversed by subsitution with the envelope having the same root digest. Elision has several use cases:

* As a form of redaction, where the holder of a document reveals part of it while deliberately withholding other parts;
* As a form of referencing, where the digest is used as the unique identifier of a digital object that can be found outside the envelope;
* As a form of compression, where many identical sub-elements of an envelope (except one) are elided.

These digest tree-preserving transformations allow the holder of an envelope-based document to selectively reveal parts of it to third parties without invalidating its signatures. It is also possible to produce proofs that one envelope (or even just the root digest of an envelope) necessarily contains another envelope by revealing only a minimum spanning set of digests.

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
* `known-value`
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
    known-value /
    encrypted /
    elided /
    node /
    wrapped-envelope /
    assertion
)
~~~

## Cases Without Children

### Leaf Case Format

A `leaf` case is used when the envelope contains only user-defined CBOR content. It is tagged using #6.24, per {{-CBOR}} section 3.4.5.1, "Encoded CBOR Data Item".

~~~ cddl
leaf = #6.24(bytes)
~~~

### Known Value Case Format

A `known-value` case is used to specify an unsigned integer in a namespace of well-known values. Known values are frequently used as predicates. Any envelope can be used as a predicate in an assertion, but many predicates are commonly used, e.g., `verifiedBy` for signatures, hence it is desirable to keep common predicates short.

~~~ cddl
known-value = #6.223(uint)
~~~

### Encrypted Case Format

An `encrypted` case is used for an envelope that has been encrypted.

~~~ cddl
encrypted = crypto-msg
~~~

For `crypto-msg`, the reference implementation {{ENVELOPE-REFIMPL}} uses the definition in "UR Type Definition for Secure Messages" {{CRYPTO-MSG}} and we repeat the salient specification here. This format specifies the use of "ChaCha20 and Poly1305 for IETF Protocols" as described in {{-CHACHA}}. When used with envelopes, the `crypto-msg` construct `aad` (additional authenticated data) field contains the `digest` of the plaintext, authenticating the declared digest using the Poly1305 HMAC.

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

For `digest`, the reference implementation {{ENVELOPE-REFIMPL}} uses of the BLAKE3 cryptographic hash function {{BLAKE3}} to generate a 32 byte digest.

~~~ cddl
digest = #6.203(blake3-digest)

blake3-digest = bytes .size 32
~~~

## Cases With Children

### Node Case Format

A `node` case is encoded as a CBOR array, and MUST be used when one or more assertions are present on the envelope. It MUST NOT be present when there is not at least one assertion. The first element of the array is the envelope's `subject`, Followed by one or more `assertion-element`s, each of which MUST be an `assertion`, or the `encrypted` or `elided` transformation of that assertion. The assertion elements MUST appear in ascending lexicographic order by their digest. The array MUST NOT contain any assertion elements with identical digests.

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

An `assertion` case is used for each of the assertions in an envelope. It is encoded as a CBOR array with exactly two elements in order:

1. the envelope representing the predicate of the assertion, followed by
2. the envelope representing the object of the assertion.

~~~ cddl
assertion = #6.221([predicate-envelope, object-envelope])
predicate-envelope = envelope
object-envelope = envelope
~~~

# Computing the Digest Tree

This section is normative, and specifies how the digests for each of the envelope cases are computed. The examples in this section may be used as test vectors.

Each of the seven enumerated envelope cases produces an image which is used as input to a cryptographic hash function to produce a digest of its contents.

The overall digest of an envelope is the digest of its specific case.

In this and subsequenct sections:

*  `digest(image)` is the BLAKE3 hash function that produces a 32-byte digest.
*  The `.digest` attribute is the digest of the named element computed as specified herein.
*  The `||` operator represents contactenation of byte sequences.

## Leaf Case Digest Calculation

The `leaf` case consists of any CBOR object. Tagging the leaf CBOR is RECOMMENDED, especially for compound structures with a specified layout. The envelope image is the CBOR serialization of that object:

~~~
digest(cbor)
~~~

### Example

The CBOR serialization of the plaintext string `"Hello"` (not including the quotes) is `6548656C6C6F`. The following command line calculates the BLAKE3 sum of this sequence:

~~~
$ echo "6548656C6C6F" | xxd -r -p | b3sum --no-names
bd6c78899fc1f22c667cfe6893aa2414f8124f25ae6ea80a1a66c2d1d6b455ea
~~~

Using the envelope command line tool {{ENVELOPE-CLI}}, we create an envelope with this string as the subject and display the envelope's digest. The digest below matches the one above.

~~~
$ envelope subject "Hello" | envelope digest --hex
bd6c78899fc1f22c667cfe6893aa2414f8124f25ae6ea80a1a66c2d1d6b455ea
~~~

## Known Value Case Digest Calculation

The envelope image of the `known-value` case is the CBOR serialization of the unsigned integer value of the value tagged with #6.223, as specified in the Known Value Case Format section above.

~~~
digest(#6.223(uint))
~~~

### Example

The known value `verifiedBy` in CBOR diagnostic notation is `223(3)`, which in hex is `D8DF03`. The BLAKE3 sum of this sequence is:

~~~
$ echo "D8DF03" | xxd -r -p | b3sum --no-names
d59f8c0ffd798eac7602d1dfb15c457d8e51c3ce34d499e5d2a4fbd2cfe3773f
~~~

Using the envelope command line tool {{ENVELOPE-CLI}}, we create an envelope with this known value as the subject and display the envelope's digest. The digest below matches the one above.

~~~
$ envelope subject --known verifiedBy | envelope digest --hex
d59f8c0ffd798eac7602d1dfb15c457d8e51c3ce34d499e5d2a4fbd2cfe3773f
~~~

## Encrypted Case Digest Calculation

The `encrypted` case declares its digest to be the digest of plaintext before encryption. The declaration is made using an HMAC, and when decrypting an element the implementation MUST compare the digest of the decrypted element to the declared digest and flag an error if they do not match.

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

Note that in the envelope notation representation above, the assertions are sorted alphabetically, with `"knows": "Edward"` coming last. But internally, the three assertions are ordered by digest in ascending lexicographic order, with "Edward" coming first because its digest starting with `1e0b049b` is the lowest, as in the tree formatted display below:

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
3. assertion
4. predicate
5. object

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

These examples may be used as test vectors. In addition, each subsection starts with the envelope command line {{ENVELOPE-CLI}} needed to generate the envelope being formatted.

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

## Known Value Case

### Envelope CLI Command Line

~~~
envelope subject --known verifiedBy
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

<artwork type="svg" src="images/svg-validated/known_value_case.svg"/>

### CBOR Diagnostic Notation

~~~
200(   ; envelope
   223(3)   ; known-value
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


# Known Values

This section is informative.

Known values are a specific case of envelope that defines a namespace consisting of single unsigned integers. The expectation is that the most common and widely useful predicates will be assigned in this namespace, but known values may be used in any position in an envelope.

Most of the examples in this document use UTF-8 strings as predicates, but in real-world applications the same predicate may be used many times in a document and across a body of knowledge. Since the size of an envelope is proportionate to the size of its content, a predicate made using a string like a human-readable sentence or a URL could take up a great deal of space in a typical envelope. Even emplacing the digest of a known structure takes 32 bytes. Known values provide a way to compactly represent predicates and other common values in as few as three bytes.

Other CBOR tags can be used to define completely separate namespaces if desired, but the reference implementation {{ENVELOPE-REFIMPL}} and its tools {{ENVELOPE-CLI}} recognize specific known values and their human-readable names.

Custom ontologies such as Web Ontology Language {{OWL}} or Friend of a Friend {{FOAF}} may someday be represented as ranges of integers in this known space, or be defined in their own namespaces.

A specification for a standard minimal ontology of known values is TBD.

The following table lists all the known values currently defined in the reference implementation {{ENVELOPE-REFIMPL}}. This list is currently informative, but all these known values have been used in the reference implementation for various examples and test vectors.

Note that a work-in-progress specification for remote procedure calls using envelope has been assigned a namespace starting at 100.

| Value | Name             | Used as   | Description |
|:------|:-----------------|:----------|:------------|
| 1     | `id`             | predicate | A domain-unique identifier of some kind. |
| 2     | `isA`            | predicate | A domain-specific type identifier. |
| 3     | `verifiedBy`     | predicate | A signature on the digest of the subject, verifiable with the signer's public key. |
| 4     | `note`           | predicate | A human-readable informative note. |
| 5     | `hasRecipient`   | predicate | A sealed message encrypting to a specific recipient the ephemeral encryption key that was used to encrypt the subject. |
| 6     | `sskrShare`      | predicate | A single SSKR {{SSKR}} share of the emphemeral encryption key that was used to encrypt the subject. |
| 7     | `controller`     | predicate | A domain-unique identifier of the party that controls the contents of this document. |
| 8     | `publicKeys`     | predicate | A "public key base" consisting of the information needed to encrypt messages to a party or verify messages signed by them. |
| 9     | `dereferenceVia` | predicate | A domain-unique Pointer such as a URL indicating from where the elided envelope subject can be recovered. |
| 10    | `entity`         | predicate | A document representing an entity of interest in the current context. |
| 11    | `hasName`        | predicate | The human-readable name of the subject. |
| 12    | `language`       | predicate | The ISO 639 {{ISO639}} code for the human natural language used to write the subject. |
| 13    | `issuer`         | predicate | A domain-unique identifier of the document's issuing entity. |
| 14    | `holder`         | predicate | A domain-unique identifier of the document's holder, i.e., the entity to which the document pertains. |
| 15    | `salt`           | predicate | A block of random data used to deliberately perturb the digest tree for the purpose of decorrelation. |
| 16    | `date`           | predicate | A timestamp, e.g., the time at which a remote procedure call request was signed. |
| 100   | `body`           | predicate | RPC: The body of a function call. The object is the function identifier and the assertions on the object are the function parameters. |
| 101   | `result`         | predicate | RPC: A result of a successful function call. The object is the returned value. |
| 102   | `error`          | predicate | RPC: A result of an unsuccessful function call. The object is message or other diagnostic state. |
| 103   | `ok`             | object    | RPC: The object of a `result` predicate for a successful remote procedure call that has no other return value. |
| 104   | `processing`     | object    | RPC: The object of a `result` predicate where a function call is accepted for processing and has not yet produced a result or error. |

# Existence Proofs

This section is informative.

Because each element of an envelope provides a unique digest, and because changing an element in an envelope changes the digest of all elements upwards towards its root, the structure of an envelope is comparable to a {{MERKLE}}.

In a Merkle Tree, all semantically significant information is carried by the tree's leaves (for example, the transactions in a block of Bitcoin transactions) while the internal nodes of the tree are nothing but digests computed from combinations of pairs of lower nodes, all the way up to the root of the tree (the "Merkle root".)

In an envelope, every digest references some semantically significant content: it could reference the subject of the envelope, or one of the assertions in the envelope, or at the predicate or object of a given assertion. Of course, those elements are all envelopes themselves, and thus potentiall the root of their own subtree.

In a merkle tree, the minumum subset of hashes necessary to confirm that a specific leaf node (the "target") must be present is called a "Merkle proof." For envelopes, an analogous proof would be a transformation of the envelope that is entirely elided but preserves the structure necesssary to reveal the target.

As an example, we produce an envelope representing a simple FOAF {{FOAF}} style graph:

~~~ sh
$ ALICE_FRIENDS=`envelope subject Alice |
    envelope assertion knows Bob |
    envelope assertion knows Carol |
    envelope assertion knows Dan`

$ envelope $ALICE_FRIENDS
"Alice" [
    "knows": "Bob"
    "knows": "Carol"
    "knows": "Dan"
]
~~~

We then elide the entire envlope, leaving only the root-level digest. This digest is a cryptographic commitment to the envelope's contents.

~~~ sh
$ COMMITMENT=`envelope elide $ALICE_FRIENDS`
$ envelope --tree $COMMITMENT
cd84aa96 ELIDED
~~~

A third party, having received this commitment, can then request proof that the envelope contains a particular assertion, called the *target*.

~~~ sh
$ REQUESTED_ASSERTION=`envelope subject assertion knows Bob`

$ envelope --tree $REQUESTED_ASSERTION
55560bdf ASSERTION
    7092d620 pred "knows"
    9a771715 obj "Bob"
~~~

The holder can then produce a proof, which is an elided form of the original document that contains a minimum spanning set of digests including the target.

~~~ sh
$ KNOWS_BOB_DIGEST=`envelope digest $REQUESTED_ASSERTION`

$ KNOWS_BOB_PROOF=`envelope proof create $ALICE_FRIENDS $KNOWS_BOB_DIGEST`

$ envelope --tree $KNOWS_BOB_PROOF
cd84aa96 NODE
    27840350 subj ELIDED
    55560bdf ELIDED
    71a30690 ELIDED
    907c8857 ELIDED
~~~

Note that the proof:

1. has the same root digest as the commitment,
2. includes the digest of the `knows-Bob` assertion: `55560bdf`,
3. includes only the other digests necessary to calculate the digest tree from the target back to the root, without revealing any additional information about the envelope.

Criteria 3 was met when the proof was produced. Critera 1 and 2 are checked by the command line tool when confirming the proof:

~~~ sh
$ envelope proof confirm --silent $COMMITMENT $KNOWS_BOB_PROOF $KNOWS_BOB_DIGEST && echo "Success"
Success
~~~

# Reference Implementation

This section is informative.

The current reference implementation of envelope is written in Swift and is part of the Blockchain Commons Secure Components Framework {{ENVELOPE-REFIMPL}}.

The envelope command line tool {{ENVELOPE-CLI}} is also written in Swift.


# Future Proofing

This section is informative.

Because envelope is a specification for documents that may persist indefinitely, it is a design goal of this specification that later implementation versions are able to parse envelopes produced by earlier versions. Furthermore, later implementations should be able to compose new envelopes using older envelopes as components.

The authors considered adding a version number to every envelope, but deemed this unnecessary as any code that parses later envelopes can determine what features are required from the CBOR structure alone.

The general migration strategy is that the specific structure of envelopes defined in the first general release of this specification is the baseline, and later specifications may incrementally add structural features such as envelope cases, new tags, or support for new structures or algorithms, but are generally expected to maintain backward compatibility.

An example of addition would be to add an additional supported method of encryption. The `crypto-msg` specification CDDL is a CBOR array with either three or four elements:

~~~ cddl
crypto-msg = #6.201([ ciphertext, nonce, auth, ? aad ])
ciphertext = bytes       ; encrypted using ChaCha20
aad = digest             ; Additional Authenticated Data
nonce = bytes .size 12   ; Random, generated at encryption-time
auth = bytes .size 16    ; Authentication tag created by Poly1305
~~~

For the sake of this example we assume the new method to be supported has all the same fields, but needs to be processed differently. In this case, the first element of the array could become an optional integer:

~~~ cddl
crypto-msg = #6.201([ ? version, ciphertext, nonce, auth, ? aad ])
version = uint           ; absent for old method, 1 for new method
~~~

If present, the first field specifies the later encryption method. If absent, the original encryption method is specified. For low numbered versions, the storage cost of specifying a later version is one byte, and backwards compatibility is preserved.

# Security Considerations

This section is informative unless noted otherwise.

## Cryptographic Considerations

### Inherited Considerations

Generally, this document inherits the security considerations of CBOR {{-CBOR}} and any of the cryptographic constructs it uses such as IETF-ChaCha20-Poly1305 {{-CHACHA}} and BLAKE3 {{BLAKE3}}.

### Choice of Cryptographic Primitives (No Set Curve)

Though envelope recommends the use of certain cryptographic algorithms, most are not required (with the exception of BLAKE3 usage, noted below). In particular, envelope has no required curve. Different choices will obviously result in different security considerations.

## Validation Requirements

Unlike HTML, envelope is intended to be conservative in both what it sends _and_ what it accepts. This means that receivers of envelope-based documents should carefully validate them. Any deviation from the validation requirements of this specification MUST result in the rejection of the entire envelope. Even after validation, envelope contents should be treated with due skepticism.

## Hashing

### Choice of BLAKE3 Hash Primitive

Although BLAKE2 is more widely supported by IETF specifications, envelope instead makes use of BLAKE3. This is to take advantage of advances in the updated protocol: the new BLAKE3 implementation uses a Merkle Tree format that allows for streaming and for incremental updates as well as high levels of parallelism. The fact that BLAKE3 is newer should be taken into consideration, but its foundation in BLAKE2 and its support by experts such as the Zcash Foundation are considered to grant it sufficient maturity.

Whereas, envelope is written to allow for the easy exchange of most of its cryptographic protocols, this is not true for BLAKE3: swapping for another hash protocol would result in incompatible envelopes. Thus, any security considerations related to BLAKE3 should be given careful attention.

### Well-Known Hashes

Because they are short unsigned integers, well-known values produce well-known digests. Elided envelopes may in some cases inadvertently reveal information by transmitting digests that may be correlated to known information. Envelopes can be salted by adding assertions that contain random data to perturb the digest tree, hence decorrelating it from any known values.

### Digest Trees

Existence proofs include the minimal set of digests that are necessary to calculate the digest tree from the target to the root, but may themselves leak information about the contents of the envelope due to the other digests that must be included in the spanning set. Designers of envelope-based formats should anticipate such attacks and use decorrelation mechanisms like salting where necessary.

### Collisions

Hash trees tend to make it harder to create collisions than the use of a raw hash function. If attackers manage to find a collision for a hash, they can only replace one node (and its children), so the impact is limited, especially since finding collisions higher in a hash tree grows increasingly difficult because the collision must be a concatenation of two hashes. This should generally reduce issues with collisions: finding collisions that fit a hash tree tends to be harder than finding regular collisions. But, the issue always should be considered.

### Leaf-Node Attacks

Envelope's hash tree  is proof against the leaf-node weakness of Bitcoin that can affect SPVs because its predicates are an unordered set, serialized in increasing lexicographic order by digest, with no possibility for duplication and thus fully deterministic ordering of the tree.

See https://bitslog.com/2018/06/09/leaf-node-weakness-in-bitcoin-merkle-tree-design/.

### Forgery Attacks on Unbalanced Trees

Envelopes should also be proof against forgery attacks before of their different construction, where all nodes contain both data and hashes. Nonetheless, care must still be taken with trees, especially when also using redaction, which limits visible information.

See https://bitcointalk.org/?topic=102395 for the core attack.

## Elision

### Duplication of Claims

Support for redaction allows for the possibility of contradictory claims where one is kept hidden at any time. So, for example, an evelope could contain contradictory predictions of election results, and only reveal the one that matches the actual results. As a result, revealed material should be carefully assessed for this possibility when redacted material also exists.

## Additional Specification Creation

Creators of specifications for envelope-based documents should give due consideration to security implications that are outside the scope of this specification to anticipate or avert. One example would be the number and type of assertions allowed in a particular document, and whether additional assertions (metadata) are allowed on those assertions.

# IANA Considerations

## CBOR Tags

This section proposes a number of IANA allocated specific CBOR tags {{IANA-CBOR-TAGS}}.

In the table below, tags directly referenced in this specification have "yes" in the "spec" field.

The reference implementation {{ENVELOPE-REFIMPL}} uses tags not used in this specification, and these are marked "no" in the "spec" field.

This document requests that IANA reserve the assigned tags listed below in the range 200-230 for use by envelope and associated specifications.

| data item | spec | semantics |
|:----|:-----|:-----|
| 200 | yes  | envelope |
| 201 | yes  | crypto-message |
| 202 | no   | common-identifier |
| 203 | yes  | digest |
| 204 | no   | symmetric-key |
| 205 | no   | private-key-base |
| 206 | no   | public-key-base |
| 207 | no   | sealed-message |
| 208-221 | no | unassigned
| 221 | yes  | assertion |
| 222 | no   | signature |
| 223 | yes  | known-value |
| 224 | yes  | wrapped-envelope |
| 225-229 | no | unassigned
| 230 | no   | agreement-public-key |

Points of contact:
    * Christopher Allen <christophera@blockchaincommons.com>
    * Wolf McNally <wolf@wolfmcnally.com>

## Media Type

The proposed media type {{-MIME}} for envelope is `application/envelope+cbor`.

* Type name: application
* Subtype name: envelope+cbor
* Required parameters: n/a
* Optional parameters: n/a
* Encoding considerations: binary
* Security considerations: See the previous section of this document
* Interoperability considerations: n/a
* Published specification: This document
* Applications that use this media type:  None yet, but it is expected that this format will be deployed in protocols and applications.
* Additional information:
    * Magic number(s): n/a
    * File extension(s): .envelope
    * Macintosh file type code(s): n/a
* Person & email address to contact for further information:
    * Christopher Allen <christophera@blockchaincommons.com>
    * Wolf McNally <wolf@wolfmcnally.com>
* Intended usage: COMMON
* Restrictions on usage: none
* Author:
    * Wolf McNally <wolf@wolfmcnally.com>
* Change controller:
    * The IESG <iesg@ietf.org>

--- back

# Acknowledgments
{:numbered="false"}

TODO acknowledge.
