---
title: "The Gordian Envelope Structured Data Format"
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
    email: christophera@lifewithalacrity.com

normative:
    RFC8949: CBOR
    RFC8610: CDDL
    RFC6838: MIME
    DCBOR:
        title: "Gordian dCBOR: A Deterministic CBOR Application Profile"
        target: https://datatracker.ietf.org/doc/draft-mcnally-deterministic-cbor/
    IANA-CBOR-TAGS:
        title: IANA, Concise Binary Object Representation (CBOR) Tags
        target: https://www.iana.org/assignments/cbor-tags/cbor-tags.xhtml
    RFC6234: SHA-256
    ENVELOPE-SWIFT:
        title: Blockchain Commons Gordian Envelope for Swift
        target: https://github.com/blockchaincommons/BCSwiftEnvelope
    ENVELOPE-RUST:
        title: Blockchain Commons Gordian Envelope for Rust
        target: https://github.com/blockchaincommons/bc-envelope-rust
    ENVELOPE-CLI:
        title: Envelope Command Line Tool
        target: https://github.com/BlockchainCommons/envelope-cli-swift

informative:
    MERKLE:
        title: "Merkle Tree"
        target: https://en.wikipedia.org/wiki/Merkle_tree

--- abstract

Gordian Envelope specifies a structured format for hierarchical binary data focused on the ability to transmit it in a privacy-focused way. Envelopes are designed to facilitate "smart documents" and have a number of unique features including: easy representation of a variety of semantic structures, a built-in Merkle-like digest tree, deterministic representation using CBOR, and the ability for the holder of a document to selectively elide specific parts of a document without invalidating the digest tree structure. This document specifies the base Envelope format, which is designed to be extensible.

--- middle

# Introduction

Gordian Envelope was designed with two key goals in mind: to be *Structure-Ready*, allowing for the reliable and interoperable encoding and storage of information; and to be *Privacy-Ready*, ensuring that transmission of that data can occur in a privacy-protecting manner.

- **Structure-Ready.** Gordian Envelope is designed as a "smart document": a set of information about a subject. More than that, it's a meta-document that can contain or refer to other documents. It can support multiple data structures, from single data items, to simple hierarchies, to labeled property graphs, semantic triples, and other forms of structured graphs. Though its fundamental structure is a tree, it can be used to create Directed Acyclic Graphs (DAGs) through references within or between Envelopes.
- **Privacy-Ready.** Gordian Envelope protects privacy by affording progressive trust, allowing for holders to minimally disclose information by using elision, and then to optionally increase that disclosure over time. The fact that a holder can control data revelation, not just an issuer, creates a new level of privacy for all stakeholders. The progressive trust in Gordian Envelopes is accomplished through hashing of all elements, which also creates foundational support for signing and encryption.

The following architectural decisions support these goals:

- **Structured Merkle Tree.** A variant of the Merkle Tree {{MERKLE}} structure is created by hashing the elements in the Envelope into a tree of digests. (In this "structured Merkle Tree", all nodes contain both semantic content and digests, rather than semantic content being limited to leaves.)
- **Deterministic Representation.** There is only one way to encode any semantic representation within a Gordian Envelope. This is accomplished through the use of Deterministic CBOR {{DCBOR}} and the sorting of the Envelope's assertions into a lexicographic order (not to be confused with sorting a CBOR encoding's map keys). Any Envelope that doesn't follow these strict rules will be rejected; as a result, separate actors assembling envelopes from the same information will converge on the same encoded structure.

## Elision Support

- **Holder-initiated Elision.** Elision can be performed by the Holder of a Gordian Envelope, not just the Issuer.
- **Granular Elision.** Elision can be performed on any data within an Envelope including subjects, predicates and objects of assertions, assertions as a whole, and envelopes as a whole. This allows each entity to elide data as is appropriate for the management of their personal (or business) risk.
- **Progressive Trust.** The elision mechanics in Gordian Envelopes allow for progressive trust, where increasing amounts of data may be revealed over time.
- **Consistent Hashing.** Even when elided, digests for those parts of the Gordian Envelope remain the same. So constructs such as signatures remain verifiable even for elided documents.
- **Reversible Elision.** Elision can be reversed by the Holder of a Gordian Envelope, which means removed information can be selectively replaced without changing the digest tree.

## Extensions

This document is the base specification for Gordian Envelope, which is designed to support extension specifications to support constructs like encryption, compression, decorrelation, and inclusion proofs. These extensions will be specified in separate documents.

# Terminology

{::boilerplate bcp14-tagged}

This specification makes use of the following terminology:

byte
: Used in its now-customary sense as a synonym for "octet".

element
: An envelope is a tree of elements, each of which is itself an envelope.

image
: The source data from which a cryptographic digest is calculated.

# Envelope Format Specification

This section is normative, and specifies the Gordian Envelope binary format in terms of its CBOR components and their sequencing. The formal language used is the Concise Data Definition Language (CDDL) {{-CDDL}}. To be considered a well-formed Envelope, a sequence of bytes MUST conform to the Gordian dCBOR deterministic CBOR profile {{DCBOR}} and MUST conform to the specifications in this section.

An Envelope is a tagged enumerated type with five cases. Here is the entire CDDL specification for the base Envelope format. Each case is discussed in detail below:

~~~ cddl
envelope = #6.200(
    leaf /
    elided /
    node /
    assertion /
    wrapped
)

leaf = #6.24(bytes)  ; MUST be dCBOR

elided = sha256-digest
sha256-digest = bytes .size 32

node = [subject, + assertion-element]
subject = envelope
assertion-element = ( assertion / elided-assertion )
elided-assertion = elided           ; MUST represent an assertion.

assertion = { predicate-envelope: object-envelope }
predicate-envelope = envelope
object-envelope = envelope

wrapped = envelope
~~~

Some of these cases create a hierarchical, recursive structure by including children that are themselves Envelopes. Two of these cases (`leaf` and `elided`) have no children. The `node` case adds one or more assertions to the envelope, each of which is a child. The `assertion` case is a predicate/object pair, both of which are children. The `wrapped` case is used to wrap an entire Envelope including its assertions (its child) so assertions can be made about the wrapped Envelope as a whole.

## Leaf Case Format

A `leaf` case is used when the Envelope contains only user-defined CBOR content. It is tagged using #6.24, per {{-CBOR}} §3.4.5.1, "Encoded CBOR Data Item".

~~~ cddl
leaf = #6.24(bytes)  ; MUST be dCBOR
~~~

To preserve deterministic encoding, authors of application-level data formats based on Envelope MUST only encode CBOR in the `leaf` case that conforms to dCBOR {{DCBOR}}. Care must be taken to ensure that leaf CBOR follows best practices for deterministic encoding, such as clearly specifying when tags for nested structures MUST or MUST NOT be used.

## Elided Case Format

An `elided` case is used as a placeholder for an element that has been elided. It consists solely of the elided envelope's digest.

~~~ cddl
elided = sha256-digest
sha256-digest = bytes .size 32
~~~

## Node Case Format

A `node` case is encoded as a CBOR array. A `node` case MUST be used when one or more assertions are present on the Envelope. A `node` case MUST NOT be present when there is not at least one assertion.

The first element of the array is the Envelope's `subject`, followed by one or more `assertion-element`s, each of which MUST either be an `assertion` or an `elided-assertion`.

The `assertion-element`s MUST appear in ascending lexicographic order by their digest (not to be confused with sorting a CBOR map's keys).

The array MUST NOT contain any `assertion-element`s with identical digests.

For an Envelope to be valid, any `elided-assertion` Envelopes in the `node` assertions MUST, if and when unelided, be found to be actual `assertion` case Envelopes having the same digest.

~~~ cddl
node = [subject, + assertion-element]
subject = envelope
assertion-element = ( assertion / elided-assertion )
elided-assertion = elided           ; MUST represent an assertion.
~~~

## Assertion Case Format

An `assertion` case is used for each of the assertions on the subject of an Envelope. It is encoded as a CBOR map with exactly one map element:

* The key of the map element is the Envelope representing the predicate of the assertion.
* The value of the map element is the Envelope representing the object of the assertion.

~~~ cddl
assertion = { predicate-envelope: object-envelope }
predicate-envelope = envelope
object-envelope = envelope
~~~

## Wrapped Case Format

Assertions make semantic statements about an Envelope's subject. A `wrapped` case is used where an Envelope, including all its assertions, should be treated as a single element, e.g. for the purpose of adding assertions to an Envelope as a whole, including its assertions.

~~~ cddl
wrapped = envelope
~~~

# Computing the Digest Tree

This section specifies how the digests for each of the Envelope cases are computed, and is normative. The examples in this section may be used as test vectors.

Each of the five enumerated Envelope cases produces an image which is used as input to a cryptographic hash function to produce the digest of its contents.

The overall digest of an Envelope is the digest of its specific case.

In this section:

*  `digest(image)` is the 32-byte hash produced by running the SHA-256 hash function on the input image.
*  The `.digest` attribute is the digest of the named element computed as specified herein.
*  The `||` operator represents the concatenation of byte sequences.

## Leaf Digest Calculation

The `leaf` case consists of any CBOR object conforming to dCBOR {{DCBOR}}. The Envelope image is the CBOR serialization of that object:

~~~
digest(cbor)
~~~

**Example**

The CBOR serialization of the plaintext string `"Hello"` (not including the quotes) is `6548656C6C6F`. The following command line calculates the SHA-256 sum of this sequence:

~~~
$ echo "6548656C6C6F" | xxd -r -p | shasum --binary --algorithm 256 | \
    awk '{ print $1 }'
4d303dac9eed63573f6190e9c4191be619e03a7b3c21e9bb3d27ac1a55971e6b
~~~

Using the `envelope` command line tool {{ENVELOPE-CLI}}, we create an Envelope with this string as the subject and display the Envelope's digest. The digest below matches the one above.

~~~
$ envelope subject "Hello" | envelope digest --hex
4d303dac9eed63573f6190e9c4191be619e03a7b3c21e9bb3d27ac1a55971e6b
~~~

## Elided Digest Calculation

The `elided` case declares its digest to be the digest of the Envelope for which it is a placeholder.

**Example**

If we create the Envelope from the leaf example above, elide it, and then request its digest:

~~~
$ envelope subject "Hello" | envelope elide | envelope digest --hex
4d303dac9eed63573f6190e9c4191be619e03a7b3c21e9bb3d27ac1a55971e6b
~~~

...we see that its digest is the same as its unelided form:

~~~
$ envelope subject "Hello" | envelope digest --hex
4d303dac9eed63573f6190e9c4191be619e03a7b3c21e9bb3d27ac1a55971e6b
~~~

## Node Digest Calculation

The Envelope image of the `node` case is the concatenation of the digest of its `subject` and the digests of its assertions sorted in ascending lexicographic order.

With a `node` case, there MUST always be at least one assertion.

~~~
digest(subject.digest || assertion-0.digest ||
    assertion-1.digest || ... || assertion-n.digest)
~~~

**Example**

We create four separate Envelopes and display their digests:

~~~
$ SUBJECT=`envelope subject "Alice"`
$ envelope digest --hex $SUBJECT
13941b487c1ddebce827b6ec3f46d982938acdc7e3b6a140db36062d9519dd2f

$ ASSERTION_0=`envelope subject assertion "knows" "Bob"`
$ envelope digest --hex $ASSERTION_0
78d666eb8f4c0977a0425ab6aa21ea16934a6bc97c6f0c3abaefac951c1714a2

$ ASSERTION_1=`envelope subject assertion "knows" "Carol"`
$ envelope digest --hex $ASSERTION_1
4012caf2d96bf3962514bcfdcf8dd70c351735dec72c856ec5cdcf2ee35d6a91

$ ASSERTION_2=`envelope subject assertion "knows" "Edward"`
$ envelope digest --hex $ASSERTION_2
65c3ebc3f056151a6091e738563dab4af8da1778da5a02afcd104560b612ca17
~~~

We combine the Envelopes into a single Envelope with three assertions:

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
6255e3b67ad935caf07b5dce5105d913dcfb82f0392d4d302f6d406e85ab4769
~~~

Note that in the Envelope notation representation above, the assertions are sorted alphabetically, with `"knows": "Edward"` coming last. But internally, the three assertions are ordered by digest in ascending lexicographic order, with "Carol" coming first because its digest starting with `4012caf2` is the lowest, as in the tree formatted display below:

~~~
$ envelope --tree $ENVELOPE
6255e3b6 NODE
    13941b48 subj "Alice"
    4012caf2 ASSERTION
        db7dd21c pred "knows"
        afb8122e obj "Carol"
    65c3ebc3 ASSERTION
        db7dd21c pred "knows"
        e9af7883 obj "Edward"
    78d666eb ASSERTION
        db7dd21c pred "knows"
        13b74194 obj "Bob"
~~~

To replicate this, we make a list of digests, starting with the subject, and then each assertion's digest in ascending lexicographic order:

~~~
13941b487c1ddebce827b6ec3f46d982938acdc7e3b6a140db36062d9519dd2f
4012caf2d96bf3962514bcfdcf8dd70c351735dec72c856ec5cdcf2ee35d6a91
65c3ebc3f056151a6091e738563dab4af8da1778da5a02afcd104560b612ca17
78d666eb8f4c0977a0425ab6aa21ea16934a6bc97c6f0c3abaefac951c1714a2
~~~

We then calculate the SHA-256 digest of the concatenation of these four digests. Note that this is the same digest as the composite Envelope's digest:

~~~
echo "13941b487c1ddebce827b6ec3f46d982938acdc7e3b6a140db36062d9519dd2f\
4012caf2d96bf3962514bcfdcf8dd70c351735dec72c856ec5cdcf2ee35d6a91\
65c3ebc3f056151a6091e738563dab4af8da1778da5a02afcd104560b612ca17\
78d666eb8f4c0977a0425ab6aa21ea16934a6bc97c6f0c3abaefac951c1714a2" | \
    xxd -r -p | shasum --binary --algorithm 256 | awk '{ print $1 }'
6255e3b67ad935caf07b5dce5105d913dcfb82f0392d4d302f6d406e85ab4769

$ envelope digest --hex $ENVELOPE
6255e3b67ad935caf07b5dce5105d913dcfb82f0392d4d302f6d406e85ab4769
~~~

## Assertion Digest Calculation

The Envelope image of the `assertion` case is the concatenation of the digests of the assertion's predicate and object, in that order:

~~~
digest(predicate.digest || object.digest)
~~~

**Example**

We create an assertion from two separate Envelopes and display their digests:

~~~
$ PREDICATE=`envelope subject "knows"`
$ envelope digest --hex $PREDICATE
db7dd21c5169b4848d2a1bcb0a651c9617cdd90bae29156baaefbb2a8abef5ba

$ OBJECT=`envelope subject "Bob"`
$ envelope digest --hex $OBJECT
13b741949c37b8e09cc3daa3194c58e4fd6b2f14d4b1d0f035a46d6d5a1d3f11

$ ASSERTION=`envelope subject assertion "knows" "Bob"`
$ envelope digest --hex $ASSERTION
78d666eb8f4c0977a0425ab6aa21ea16934a6bc97c6f0c3abaefac951c1714a2
~~~

To replicate this, we make a list of the predicate digest and the object digest, in that order:

~~~
db7dd21c5169b4848d2a1bcb0a651c9617cdd90bae29156baaefbb2a8abef5ba
13b741949c37b8e09cc3daa3194c58e4fd6b2f14d4b1d0f035a46d6d5a1d3f11
~~~

We then calculate the SHA-256 digest of the concatenation of these two digests. Note that this is the same digest as the composite Envelope's digest:

~~~
echo "db7dd21c5169b4848d2a1bcb0a651c9617cdd90bae29156baaefbb2a8abef5ba\
13b741949c37b8e09cc3daa3194c58e4fd6b2f14d4b1d0f035a46d6d5a1d3f11" | \
    xxd -r -p | shasum --binary --algorithm 256 | awk '{ print $1 }'
78d666eb8f4c0977a0425ab6aa21ea16934a6bc97c6f0c3abaefac951c1714a2

$ envelope digest --hex $ASSERTION
78d666eb8f4c0977a0425ab6aa21ea16934a6bc97c6f0c3abaefac951c1714a2
~~~

## Wrapped Digest Calculation

The Envelope image of the `wrapped` case is the digest of the wrapped Envelope:

~~~
digest(envelope.digest)
~~~

**Example**

As above, we note the digest of a leaf Envelope is the digest of its CBOR:

~~~
$ envelope subject "Hello" | envelope digest --hex
4d303dac9eed63573f6190e9c4191be619e03a7b3c21e9bb3d27ac1a55971e6b

$ echo "6548656C6C6F" | xxd -r -p | shasum --binary --algorithm 256 | \
    awk '{ print $1 }'
4d303dac9eed63573f6190e9c4191be619e03a7b3c21e9bb3d27ac1a55971e6b
~~~

Now we note that the digest of a wrapped Envelope is the digest of the wrapped Envelope's digest:

~~~
$ envelope subject "Hello" | \
    envelope subject --wrapped | \
    envelope digest --hex
743a86a9f411b1441215fbbd3ece3de5206810e8a3dd8239182e123802677bd7

$ echo "4d303dac9eed63573f6190e9c4191be619e03a7b3c21e9bb\
3d27ac1a55971e6b" \
    | xxd -r -p | shasum --binary --algorithm 256 | awk '{ print $1 }'
743a86a9f411b1441215fbbd3ece3de5206810e8a3dd8239182e123802677bd7
~~~

# Envelope Hierarchy

This section is informative, and describes Envelopes from the perspective of their hierarchical structure and the various ways they can be formatted.

Notionally an Envelope can be thought of as a `subject` and one or more `predicate-object` pairs called `assertions`.

Note that the following example is *not* CDDL or CBOR diagnostic notation, but "Envelope notation," which is a convenient way to describe the structure of an Envelope:

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

The notional concept of Envelope is helpful, but not technically accurate because Envelope is implemented structurally as an enumerated type consisting of five cases. This allows actual Envelope instances to be more flexible, for example a "bare assertion" consisting of a predicate-object pair with no subject, which is useful in some situations:

~~~
"knows": "Bob"
~~~

More common is the opposite case: a subject with no assertions:

~~~
"Alice"
~~~

In Envelopes, there are five distinct "positions" of elements, each of which is itself an Envelope and which therefore produces its own digest:

1. envelope
2. subject
3. assertion
4. predicate
5. object

The examples above are printed in Envelope notation, which is designed to make the semantic content of Envelopes human-readable, but it doesn't show the actual digests associated with each of the positions. To see the structure more completely, we can display every element of the Envelope in "Tree Format":

~~~
6255e3b6 NODE
    13941b48 subj "Alice"
    4012caf2 ASSERTION
        db7dd21c pred "knows"
        afb8122e obj "Carol"
    65c3ebc3 ASSERTION
        db7dd21c pred "knows"
        e9af7883 obj "Edward"
    78d666eb ASSERTION
        db7dd21c pred "knows"
        13b74194 obj "Bob"
~~~

For easy recognition, Envelope trees only show the first four bytes of each digest, but internally all digests are 32 bytes.

From the above Envelope and its tree, we make the following observations:

* The Envelope is a `node` case, which has the overall Envelope digest.
* The subject "Alice" has its own digest.
* Each of the three assertions have their own digests
* The predicate and object of each assertion each have their own digests.
* The assertions appear in the structure in ascending lexicographic order by digest, which is the actual order in which they are serialized, and which is distinct from Envelope notation, where they appear sorted alphabetically.

The following subsections present each of the five enumerated Envelope cases in four different output formats:

* Envelope Notation
* Envelope Tree
* CBOR Diagnostic Notation
* CBOR hex

These examples may be used as test vectors. In addition, each subsection starts with the `envelope` command line {{ENVELOPE-CLI}} needed to generate the Envelope being formatted.

## Leaf Case

**Envelope CLI Command Line**

~~~
envelope subject "Alice"
~~~

**Envelope Notation**

~~~
"Alice"
~~~

**Tree**

~~~
13941b48 "Alice"
~~~

**CBOR Diagnostic Notation**

~~~
200(   ; envelope
   24("Alice")   ; leaf
)
~~~

**CBOR Hex**

~~~
d8c8d81865416c696365
~~~

## Elided Case

**Envelope CLI Command Line**

~~~
envelope subject "Alice" | envelope elide
~~~

**Envelope Notation**

~~~
ELIDED
~~~

**Tree**

~~~
13941b48 ELIDED
~~~

**CBOR Diagnostic Notation**

~~~
200(   ; envelope
   h'13941b487c1ddebce827b6ec3f46d982938acdc7e3b6a140db36062d9519dd2f'
)
~~~

**CBOR Hex**

~~~
d8c8582013941b487c1ddebce827b6ec3f46d982938acdc7e3b6a140db36062d9519dd2f
~~~

## Node Case

**Envelope CLI Command Line**

~~~
envelope subject "Alice" | envelope assertion "knows" "Bob"
~~~

**Envelope Notation**

~~~
"Alice" [
    "knows": "Bob"
]
~~~

**Tree**

~~~
8955db5e NODE
    13941b48 subj "Alice"
    78d666eb ASSERTION
        db7dd21c pred "knows"
        13b74194 obj "Bob"
~~~

**CBOR Diagnostic Notation**

~~~
200(   ; envelope
   [
      200(   ; envelope
         24("Alice")   ; leaf
      ),
      200(   ; envelope
         {
            200(   ; envelope
               24("knows")   ; leaf
            ):
            200(   ; envelope
               24("Bob")   ; leaf
            )
         }
      )
   ]
)
~~~

**CBOR Hex**

~~~
d8c882d8c8d81865416c696365d8c8a1d8c8d818656b6e6f7773d8c8d81863426f62
~~~

## Assertion Case

**Envelope CLI Command Line**

~~~
envelope subject assertion "knows" "Bob"
~~~

**Envelope Notation**

~~~
"knows": "Bob"
~~~

**Tree**

~~~
78d666eb ASSERTION
    db7dd21c pred "knows"
    13b74194 obj "Bob"
~~~

**CBOR Diagnostic Notation**

~~~
200(   ; envelope
   {
      200(   ; envelope
         24("knows")   ; leaf
      ):
      200(   ; envelope
         24("Bob")   ; leaf
      )
   }
)
~~~

**CBOR Hex**

~~~
d8c8a1d8c8d818656b6e6f7773d8c8d81863426f62
~~~

## Wrapped Case

**Envelope CLI Command Line**

~~~
envelope subject "Alice" | envelope subject --wrapped
~~~

**Envelope Notation**

~~~
{
    "Alice"
}
~~~

**Tree**

~~~
2bc17c65 WRAPPED
    13941b48 subj "Alice"
~~~

**CBOR Diagnostic Notation**

~~~
200(   ; envelope
   200(   ; envelope
      24("Alice")   ; leaf
   )
)
~~~

**CBOR Hex**

~~~
d8c8d8c8d81865416c696365
~~~

# Reference Implementations

This section is informative.

The current reference implementations of Envelope are written in Swift {{ENVELOPE-SWIFT}} and Rust {{ENVELOPE-RUST}}.

The `envelope` command line tool {{ENVELOPE-CLI}} is also written in Swift.

# Security Considerations

This section is informative unless noted otherwise.

## CBOR Considerations

Generally, this document inherits the security considerations of CBOR {{-CBOR}}. Though CBOR has limited web usage, it has received strong usage in hardware, resulting in a mature specification. It also inherits the security considerations of Gordian dCBOR {{DCBOR}}.

## Validation Requirements

Unlike HTML, Envelope is intended to be conservative in both what it encodes _and_ what it accepts as valid. This means that receivers of Envelope-based documents should carefully validate them. Any deviation from the validation requirements of this specification MUST result in the rejection of the entire Envelope. Even after validation, Envelope contents should be treated with due skepticism at the application level.

## Choice of SHA-256 Hash Primitive

Envelope uses the SHA-256 digest algorithm {{-SHA-256}}, which is regarded as reliable and widely supported by many implementations in both software and hardware.

## Correlated Digests

Elided Envelopes may in some cases inadvertently reveal information by transmitting digests that may be correlated to known information. In many cases this is of no consequence, but when necessary Envelopes can (when constructed) be "salted" by adding assertions that contain random data. This results in perturbing the digest tree, hence decorrelating it (after elision) from digests whose unelided contents are known.

# IANA Considerations

## CBOR Tags

This document requests that IANA {{IANA-CBOR-TAGS}} reserve the tag #6.200 for use by Envelope.

| Tag | Data Item | Semantics |
|:----|:-----|:-----|
| 200 | multiple | Gordian Envelope |

Points of contact:

* Christopher Allen <christophera@blockchaincommons.com>
* Wolf McNally <wolf@wolfmcnally.com>

## Media Type

The proposed media type {{-MIME}} for Envelope is `application/envelope+cbor`. The authors understand that this will require this document to become an RFC before the media type can be registered.

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
