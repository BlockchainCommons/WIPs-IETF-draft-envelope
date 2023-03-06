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
    email: christophera@lifewithalacrity.com

normative:
    RFC8949: CBOR
    RFC8610: CDDL
    RFC8439: CHACHA
    RFC6838: MIME
    IANA-CBOR-TAGS:
        title: IANA, Concise Binary Object Representation (CBOR) Tags
        target: https://www.iana.org/assignments/cbor-tags/cbor-tags.xhtml
    RFC6234: SHA-256
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
    BC-UR-TAGS:
        title: "Registry of Uniform Resource (UR) Types"
        target: https://github.com/BlockchainCommons/Research/blob/master/papers/bcr-2020-006-urtypes.md
    CBOR-IMPLS:
        title: "CBOR Implementations"
        target: http://cbor.io/impls.html
    UR-QA:
        title: "UR (Uniform Resources) Q&A"
        target: https://github.com/BlockchainCommons/Research/blob/master/papers/bcr-2020-005-ur.md#qa
    CBOR-FLATBUFFERS:
        title: "Flatbuffers vs CBOR"
        target: https://stackoverflow.com/questions/47799396/flatbuffers-vs-cbor
    CBOR-FORMAT-COMPARISON:
        title: "Comparison of Other Binary Formats to CBOR's Design Objectives"
        target: https://www.rfc-editor.org/rfc/rfc8949#name-comparison-of-other-binary-
    ASN-1:
        title: "X.680 : Information technology - Abstract Syntax Notation One (ASN.1): Specification of basic notation"
        target: https://www.itu.int/rec/T-REC-X.680/
    LEAF-MERKLE:
        title: "Leaf-Node weakness in Bitcoin Merkle Tree Design"
        target: https://bitslog.com/2018/06/09/leaf-node-weakness-in-bitcoin-merkle-tree-design/
    BLOCK-EXPLOIT:
        title: "CVE-2012-2459 (block merkle calculation exploit)"
        target: https://bitcointalk.org/?topic=102395

--- abstract

The `envelope` protocol specifies a structured format for hierarchical binary data focused on the ability to transmit it in a privacy-focused way. Envelopes are designed to facilitate "smart documents" and have a number of unique features including: easy representation of a variety of semantic structures, a built-in Merkle-like digest tree, deterministic representation using CBOR, and the ability for the holder of a document to selectively encrypt or elide specific parts of a document without invalidating the document structure including the digest tree, or any cryptographic signatures that rely on it.

--- middle

# Introduction

Gordian Envelope was designed with two key goals in mind: to be *Structure-Ready*, allowing for the reliable and interoperable storage of information; and to be *Privacy-Ready*, ensuring that transmission of that data can occur in a privacy-protecting manner.

- **Structure-Ready.** Gordian Envelope is designed as a Smart Document, meant to store information about a subject. More than that, it's a meta-document that can contain or refer to other documents. It can support multiple data formats, from simple hierarchical structures to labeled property graphs, semantic triples, and other forms of structured graphs. Though its fundamental structure is a tree, it can be used to create Directed Acyclic Graphs (DAGs) through references between Envelopes.
- **Privacy-Ready.** Gordian Envelope protects the privacy of its data through progressive trust, allowing for holders to minimally disclose information by using elision or encryption, and then to optionally increase that disclosure over time. The fact that a holder can control data revelation, not just an issuer, creates a new level of privacy for all stakeholders. The progressive trust in Gordian Envelopes is accomplished through hashing of all elements, which creates foundational support for cryptographic functions such as signing and encryption, without actually defining which cryptographic functions must be used.

The following architectural decisions support these goals:

- **Structured Merkle Tree.** A variant of the Merkle Tree structure is created by forming the hashing of the elements in the Envelope into a tree of digests. (In this "structured Merkle Tree", all nodes contain both semantic content and digests, rather than semantic content being limited to leaves.)
- **Deterministic Representation.** There is only one way to encode any semantic representation within a Gordian Envelope. This is accomplished through the use of Deterministic CBOR and the sorting of the Envelope by hashes to create a lexicographic order. Any Envelope that doesn't follow these strict rules can be rejected; as a result, there's no need to worry about different people adding the assertions in a different order or at different times: if two Envelopes contain the same data, they will be encoded the same way.

## Elision Support

- **Elision of All Elements.** Gordian Envelopes innately support elision for any part of its data, including subjects, predicates, and objects.
- **Elision, Compression, and Encryption.** Elision can be used for a variety of purposes including redaction (removing information), compression (removing duplicate information), and encryption (enciphering information).
- **Holder-initiated Elision.** Elision can be performed by the Holder of a Gordian Envelope, not just the Issuer.
- **Granular Holder Control.** Elision can not only be performed by any Holder, but also for any data, allowing each entity to elide data as is appropriate for the management of their personal (or business) risk.
- **Progressive Trust.** The elision mechanics in Gordian Envelopes allow for progressive trust, where increasing amounts of data are revealed over time, and can be combined with encryption to escrow data to later be revealed.
- **Consistent Hashing.** Even when elided or encrypted, hashes for those parts of the Gordian Envelope remain the same.

## Privacy Support

- **Proof of Inclusion.** As an alternative to presenting elided structures, proofs of inclusion can be included in top-level hashes.
- **Herd Privacy.** Proofs of inclusion allow for herd privacy where all members of a class can share data such as a VC or DID without revealing individual information.
- **Non-Correlation.** Encrypted Gordian Envelope data can optionally be made less correlatable with the addition of salt.

## Authentication Support

- **Symmetric Key Permits.** Gordian Envelopes can be locked ("closed") using a symmetric key.
- **SSKR Permits.** Gordian Envelopes can alternatively be locked ("closed") using a symmetric key sharded with Shamir's Secret Sharing, with the shares stored with copies of the Envelope, and the whole enveloped thus openable if copies of the Envelope with a quorum of different shares are gathered.
- **Public Key Permits.** Gordian Envelopes can alternatively be locked ("closed") with a public key and then be opened with the associated private key, or vice versa.
- **Multiple Permits.** Gordian Envelopes can simultaneously be locked ("closed") via a variety of means and then openable by any appropriate individual method, with different methods likely held by different people.

## Future Looking

- **Data Storage.** The initial inspiration for Gordian Envelopes was for secure data storage.
- **Credentials & Presentations.** The usage of Gordian Envelope signing techniques allows for the creation of credentials and the ability to present them to different verifiers in different ways.
- **Distributed or Decentralized Identifiers.** Self-Certifying Identifiers (SCIDs) can be created and shared with peers, certified by a trust authority, or registered on blockchain.
- **Future Techniques.** Beyond its technical specifics, Gordian Envelopes still allows for cl-sigs, bbs+, and other privacy-preserving techniques such as zk-proofs, differential privacy, etc.
- **Cryptography Agnostic.** Generally, the Gordian Envelope architecture is cryptography agnostic, allowing it to work with everything from older algorithms with silicon support through more modern algorithms suited to blockchains and to future zk-proof or quantum-attack resistant cryptographic choices. These choices are made in sets via ciphersuites.

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

This section is normative, and specifies the binary format of envelopes in terms of its CBOR components and their sequencing. The formal language used is the Concise Data Definition Language (CDDL) {{-CDDL}}. To be considered a well-formed envelope, a sequence of bytes MUST be well-formed deterministic CBOR {{-CBOR}} and MUST conform to the specifications in this section.

## Top Level

An envelope is a tagged enumerated type with seven cases. Four of these cases have no children:

* `leaf`
* `known-value`
* `encrypted`
* `elided`

Two of these cases, `encrypted` and `elided`, "declare" their digest, i.e., they actually encode their digest in the envelope serialization. For all other cases, their digest is implicit in the data itself and may be computed and cached by implementations when an envelope is deserialized.

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

To preserve deterministic encoding, developers using the envelope format MUST specify where tags MUST or MUST NOT be used to identify the type of CBOR within `leaf` elements. In cases where simple CBOR values like integers or UTF-8 strings are encoded, no additional tagging may be necessary because positionality within the envelope is sufficient to imply the type without ambiguity.

For example, if a structure representing a person specifies that it MAY have a `firstName` predicate with a `string` object, there is no need for an additional tag within the object `leaf` element: it would be a coding error to place anything but a `string` in that position. But where developers are specifying a compound CBOR structure with a specified layout for inclusion in an envelope, especially one that may be used in a plurality of positions (for example a CBOR array of alias first names), they SHOULD specify a tag, and specify where it MUST or MUST NOT be used.

~~~ cddl
leaf = #6.24(bytes)
~~~

### Known Value Case Format

A `known-value` case is used to specify an unsigned integer in a namespace of well-known values. Known values are frequently used as predicates. For example, any envelope can be used as a predicate in an assertion, but many predicates are commonly used, e.g., `verifiedBy` for signatures; hence it is desirable to keep common predicates short.

~~~ cddl
known-value = #6.223(uint)
~~~

### Encrypted Case Format

An `encrypted` case is used for an envelope that has been encrypted using an Authenticated Encryption with Associated Data (AEAD), and where the digest of the plaintext is declared by the encrypted structure's Additional Authenticated Data (AAD) field. This subsection specifies the construct used in the current reference implementation and is informative.

~~~ cddl
encrypted = crypto-msg
~~~

For `crypto-msg`, the reference implementation {{ENVELOPE-REFIMPL}} uses the definition in "UR Type Definition for Secure Messages" {{CRYPTO-MSG}} and we repeat the salient specification here. This format specifies the use of "ChaCha20 and Poly1305 for IETF Protocols" as described in {{-CHACHA}}. When used with envelopes, the `crypto-msg` construct `aad` (additional authenticated data) field contains the `digest` of the plaintext, authenticating the declared digest using the Poly1305 MAC.

~~~ cddl
crypto-msg = #6.201([ ciphertext, nonce, auth, ? aad ])

ciphertext = bytes       ; encrypted using ChaCha20
aad = digest             ; Additional Authenticated Data
nonce = bytes .size 12   ; Random, generated at encryption-time
auth = bytes .size 16    ; Authentication tag created by Poly1305
~~~

### Elided Case Format

An `elided` case is used as a placeholder for an element that has been elided and its digest, produced by a cryptographic hash algorithm, is left as a placeholder. This subsection specifies the construct used in the current reference implementation and is informative.

~~~ cddl
elided = digest
~~~

For `digest`, the reference implementation {{ENVELOPE-REFIMPL}} uses of the SHA-256 cryptographic hash function {{-SHA-256}} to generate a 32 byte digest.

~~~ cddl
digest = #6.203(sha256-digest)

sha256-digest = bytes .size 32
~~~

## Cases With Children

### Node Case Format

A `node` case is encoded as a CBOR array, and MUST be used when one or more assertions are present on the envelope. It MUST NOT be present when there is not at least one assertion. The first element of the array is the envelope's `subject`, Followed by one or more `assertion-element`s, each of which MUST be an `assertion`, or the `encrypted` or `elided` transformation of that assertion. The assertion elements MUST appear in ascending lexicographic order by their digest. The array MUST NOT contain any assertion elements with identical digests.

Note that `assertion-elements` as defined here here explicitly include assertions that have been elided or encrypted, as specified in the CDDL below. The envelopes in the `node` case array MUST, when unelided/unencrypted be found to be actual `assertion` case envelopes, or it is a coding error.

~~~ cddl
node = [envelope-content, + assertion-element]

assertion-element = ( assertion / encrypted / elided )
~~~

### Wrapped Envelope Case Format

A `wrapped-envelope` case is used where an envelope, including all its assertions, should be treated as a single element, e.g. for the purpose of signing.

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

This section specifies how the digests for each of the envelope cases are computed, and is normative. The examples in this section may be used as test vectors.

Each of the seven enumerated envelope cases produces an image which is used as input to a cryptographic hash function to produce a digest of its contents.

The overall digest of an envelope is the digest of its specific case.

In this and subsequent sections:

*  `digest(image)` is the SHA-256 hash function that produces a 32-byte digest.
*  The `.digest` attribute is the digest of the named element computed as specified herein.
*  The `||` operator represents the concatenation of byte sequences.

## Leaf Case Digest Calculation

The `leaf` case consists of any CBOR object. The envelope image is the CBOR serialization of that object:

~~~
digest(cbor)
~~~

### Example

The CBOR serialization of the plaintext string `"Hello"` (not including the quotes) is `6548656C6C6F`. The following command line calculates the SHA-256 sum of this sequence:

~~~
$ echo "6548656C6C6F" | xxd -r -p | shasum --binary --algorithm 256 | \
    awk '{ print $1 }'
4d303dac9eed63573f6190e9c4191be619e03a7b3c21e9bb3d27ac1a55971e6b
~~~

Using the envelope command line tool {{ENVELOPE-CLI}}, we create an envelope with this string as the subject and display the envelope's digest. The digest below matches the one above.

~~~
$ envelope subject "Hello" | envelope digest --hex
4d303dac9eed63573f6190e9c4191be619e03a7b3c21e9bb3d27ac1a55971e6b
~~~

## Known Value Case Digest Calculation

The envelope image of the `known-value` case is the CBOR serialization of the unsigned integer value of the value tagged with #6.223, as specified in the Known Value Case Format section above.

~~~
digest(#6.223(uint))
~~~

### Example

The known value `verifiedBy` in CBOR diagnostic notation is `223(3)`, which in hex is `D8DF03`. The SHA-256 sum of this sequence is:

~~~
$ echo "D8DF03" | xxd -r -p | shasum --binary --algorithm 256 | \
    awk '{ print $1 }'
d933fc069551eae6c34b663e1c64dc8e62bfc43c1d43b3d22dbe57a3c4b84359
~~~

Using the envelope command line tool {{ENVELOPE-CLI}}, we create an envelope with this known value as the subject and display the envelope's digest. The digest below matches the one above.

~~~
$ envelope subject --known verifiedBy | envelope digest --hex
d933fc069551eae6c34b663e1c64dc8e62bfc43c1d43b3d22dbe57a3c4b84359
~~~

## Encrypted Case Digest Calculation

The `encrypted` case declares its digest to be the digest of plaintext before encryption. The declaration is made using a MAC, and when decrypting an element, the implementation MUST compare the digest of the decrypted element to the declared digest and flag an error if they do not match.

### Example

If we create the envelope from the leaf example above, encrypt it, and then request its digest:

~~~
$ KEY=`envelope generate key`
$ envelope subject "Hello" | \
    envelope encrypt --key $KEY | \
    envelope digest --hex
4d303dac9eed63573f6190e9c4191be619e03a7b3c21e9bb3d27ac1a55971e6b
~~~

...we see that its digest is the same as its plaintext form:

~~~
$ envelope subject "Hello" | envelope digest --hex
4d303dac9eed63573f6190e9c4191be619e03a7b3c21e9bb3d27ac1a55971e6b
~~~

## Elided Case Digest Calculation

The `elided` case declares its digest to be the digest of the envelope for which it is a placeholder.

### Example

If we create the envelope from the leaf example above, elide it, and then request its digest:

~~~
$ envelope subject "Hello" | envelope elide | envelope digest --hex
4d303dac9eed63573f6190e9c4191be619e03a7b3c21e9bb3d27ac1a55971e6b
~~~

...we see that its digest is the same as its unelided form:

~~~
$ envelope subject "Hello" | envelope digest --hex
4d303dac9eed63573f6190e9c4191be619e03a7b3c21e9bb3d27ac1a55971e6b
~~~

## Node Case Digest Calculation

The envelope image of the `node` case is the concatenation of the digest of its `subject` and the digests of its assertions sorted in ascending lexicographic order.

With a `node` case, there MUST always be at least one assertion.

~~~
digest(subject.digest || assertion-0.digest ||
    assertion-1.digest || ... || assertion-n.digest)
~~~

### Example

We create four separate envelopes and display their digests:

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
6255e3b67ad935caf07b5dce5105d913dcfb82f0392d4d302f6d406e85ab4769
~~~

Note that in the envelope notation representation above, the assertions are sorted alphabetically, with `"knows": "Edward"` coming last. But internally, the three assertions are ordered by digest in ascending lexicographic order, with "Carol" coming first because its digest starting with `4012caf2` is the lowest, as in the tree formatted display below:

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

We then calculate the SHA-256 hash of the concatenation of these four digests. Note that this is the same digest as the composite envelope's digest:

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

## Wrapped Envelope Case Digest Calculation

The envelope image of the `wrapped-envelope` case is the digest of the wrapped envelope:

~~~
digest(envelope.digest)
~~~

### Example

As above, we note the digest of a leaf envelope is the digest of its CBOR:

~~~
$ envelope subject "Hello" | envelope digest --hex
4d303dac9eed63573f6190e9c4191be619e03a7b3c21e9bb3d27ac1a55971e6b

$ echo "6548656C6C6F" | xxd -r -p | shasum --binary --algorithm 256 | \
    awk '{ print $1 }'
4d303dac9eed63573f6190e9c4191be619e03a7b3c21e9bb3d27ac1a55971e6b
~~~

Now we note that the digest of a wrapped envelope is the digest of the wrapped envelope's digest:

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

We then calculate the SHA-256 hash of the concatenation of these two digests. Note that this is the same digest as the composite envelope's digest:

~~~
echo "db7dd21c5169b4848d2a1bcb0a651c9617cdd90bae29156baaefbb2a8abef5ba\
13b741949c37b8e09cc3daa3194c58e4fd6b2f14d4b1d0f035a46d6d5a1d3f11" | \
    xxd -r -p | shasum --binary --algorithm 256 | awk '{ print $1 }'
78d666eb8f4c0977a0425ab6aa21ea16934a6bc97c6f0c3abaefac951c1714a2

$ envelope digest --hex $ASSERTION
78d666eb8f4c0977a0425ab6aa21ea16934a6bc97c6f0c3abaefac951c1714a2
~~~

# Envelope Hierarchy

This section is informative, and describes envelopes from the perspective of their hierarchical structure and the various ways they can be formatted.

Notionally an envelope can be thought of as a `subject` and one or more `predicate-object` pairs called `assertions`:

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

The notional concept of envelope is useful but not technically accurate because envelope is structurally implemented as an enumerated type consisting of seven cases. This allows actual envelope instances to be more flexible, for example a "bare assertion" consisting of a predicate-object pair with no subject, which is useful in some situations:

~~~
"knows": "Bob"
~~~

More common is the opposite case: a subject with no assertions:

~~~
"Alice"
~~~

In the diagrams above, there are five distinct "positions" of elements, each of which is itself an envelope and which therefore produces its own digest:

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

<artwork type="svg"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.2" baseProfile="tiny" width="539.8px" height="541.2px" viewBox="0 0 539.8 541.2" xml:space="preserve">
<path fill="none" stroke="#000000" stroke-width="1.4998" d="M77.9,179.3l8.5-21.2c8.5-21.2,25.6-63.6,39.1-84.8  C139,52,149,52,153.9,52h5"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="489.8" height="491.2"/>
<polygon fill="black" points="150.8,47.5 159.8,52 150.8,56.5 "/>
<rect x="149.3" y="47.5" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.4998" d="M86.6,184.4l7.1-8.8c7.1-8.8,21.3-26.4,36.8-35.2  c15.6-8.8,32.5-8.8,41-8.8h8.5"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="489.8" height="491.2"/>
<polygon fill="black" points="171.9,127 180.9,131.5 171.9,136 "/>
<rect x="170.4" y="127" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.4998" d="M274.6,112.5l8.6-3.5c8.6-3.5,25.9-10.4,40.3-13.9  c14.3-3.5,25.7-3.5,31.4-3.5h5.7"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="489.8" height="491.2"/>
<polygon fill="black" points="352.5,87.2 361.5,91.8 352.5,96.2 "/>
<rect x="351" y="87.2" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.4998" d="M274.6,150.5l8.6,3.5c8.6,3.5,25.9,10.4,40.7,13.9  c14.8,3.5,27,3.5,33.2,3.5h6.1"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="489.8" height="491.2"/>
<polygon fill="black" points="355.1,166.8 364.1,171.2 355.1,175.8 "/>
<rect x="353.6" y="166.8" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.4998" d="M86.6,237.6l7.1,8.8c7.1,8.8,21.3,26.4,36.8,35.2  c15.6,8.8,32.5,8.8,41,8.8h8.5"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="489.8" height="491.2"/>
<polygon fill="black" points="171.9,286 180.9,290.5 171.9,295 "/>
<rect x="170.4" y="286" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.4998" d="M274.6,271.5l8.6-3.5c8.6-3.5,25.9-10.4,40.3-13.9  c14.3-3.5,25.7-3.5,31.4-3.5h5.7"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="489.8" height="491.2"/>
<polygon fill="black" points="352.5,246.2 361.5,250.8 352.5,255.2 "/>
<rect x="351" y="246.2" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.4998" d="M274.6,309.5l8.6,3.5c8.6,3.5,25.9,10.4,39.7,13.9  c13.8,3.5,24,3.5,29.1,3.5h5.1"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="489.8" height="491.2"/>
<polygon fill="black" points="349.1,325.8 358.1,330.2 349.1,334.8 "/>
<rect x="347.6" y="325.8" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.4998" d="M74,244l9.2,34.2c9.2,34.2,27.5,102.7,45.2,137  c17.7,34.2,34.6,34.2,43.1,34.2h8.5"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="489.8" height="491.2"/>
<polygon fill="black" points="171.9,445 180.9,449.5 171.9,454 "/>
<rect x="170.4" y="445" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.4998" d="M274.6,430.5l8.6-3.5c8.6-3.5,25.9-10.4,40.3-13.9  c14.3-3.5,25.7-3.5,31.4-3.5h5.7"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="489.8" height="491.2"/>
<polygon fill="black" points="352.5,405.2 361.5,409.8 352.5,414.2 "/>
<rect x="351" y="405.2" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.4998" d="M274.6,468.5l8.6,3.5c8.6,3.5,25.9,10.4,41.3,13.9  c15.4,3.5,28.9,3.5,35.6,3.5h6.7"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="489.8" height="491.2"/>
<polygon fill="black" points="358.8,484.8 367.8,489.2 358.8,493.8 "/>
<rect x="357.3" y="484.8" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path d="M118.5,53.9l1-0.2c0.1,0.4,0.2,0.7,0.5,1s0.6,0.3,1.1,0.3c0.5,0,0.8-0.1,1.1-0.3s0.4-0.4,0.4-0.7c0-0.2-0.1-0.4-0.3-0.6  c-0.1-0.1-0.5-0.2-1.1-0.4c-0.8-0.2-1.3-0.4-1.6-0.5s-0.5-0.3-0.7-0.6s-0.2-0.5-0.2-0.8c0-0.3,0.1-0.5,0.2-0.8  c0.1-0.2,0.3-0.4,0.5-0.6c0.2-0.1,0.4-0.2,0.7-0.3s0.6-0.1,0.9-0.1c0.5,0,0.9,0.1,1.3,0.2s0.6,0.3,0.8,0.6s0.3,0.6,0.4,1l-1,0.1  c0-0.3-0.2-0.6-0.4-0.8s-0.5-0.3-1-0.3c-0.5,0-0.8,0.1-1,0.2s-0.3,0.3-0.3,0.6c0,0.1,0,0.3,0.1,0.4c0.1,0.1,0.2,0.2,0.4,0.3  c0.1,0,0.4,0.1,0.9,0.3c0.7,0.2,1.3,0.4,1.6,0.5s0.5,0.3,0.7,0.6c0.2,0.2,0.3,0.5,0.3,0.9c0,0.4-0.1,0.7-0.3,1s-0.5,0.6-0.9,0.7  s-0.8,0.3-1.3,0.3c-0.8,0-1.4-0.2-1.8-0.5C118.9,55.1,118.6,54.6,118.5,53.9z"/>
<path d="M129,55.8v-0.9c-0.5,0.7-1.1,1.1-2,1.1c-0.4,0-0.7-0.1-1-0.2s-0.6-0.3-0.7-0.5s-0.3-0.5-0.3-0.8c0-0.2-0.1-0.5-0.1-1v-3.9  h1.1V53c0,0.6,0,0.9,0.1,1.1c0.1,0.3,0.2,0.5,0.4,0.7s0.5,0.2,0.8,0.2c0.3,0,0.6-0.1,0.9-0.2s0.5-0.4,0.6-0.7s0.2-0.7,0.2-1.2v-3.3  h1.1v6.2H129z"/>
<path d="M132.6,55.8h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5c-0.5,0.6-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V55.8z M132.5,52.6c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  S132.5,51.8,132.5,52.6z"/>
<path d="M136.9,58.2l0.2-0.9c0.2,0.1,0.4,0.1,0.5,0.1c0.2,0,0.4-0.1,0.5-0.2s0.2-0.5,0.2-1.1v-6.5h1.1v6.6c0,0.8-0.1,1.3-0.3,1.6  c-0.3,0.4-0.7,0.6-1.3,0.6C137.5,58.3,137.2,58.2,136.9,58.2z M138.2,48.4v-1.2h1.1v1.2H138.2z"/>
<rect x="118.1" y="45.2" fill-rule="evenodd" fill="none" width="21.7" height="13.5"/>
<path d="M315.3,97.9v-8.6h1v0.8c0.2-0.3,0.5-0.6,0.8-0.7s0.6-0.2,1-0.2c0.5,0,1,0.1,1.4,0.4s0.7,0.7,0.9,1.2s0.3,1,0.3,1.6  c0,0.6-0.1,1.2-0.3,1.7c-0.2,0.5-0.6,0.9-1,1.2s-0.9,0.4-1.4,0.4c-0.4,0-0.7-0.1-0.9-0.2s-0.5-0.3-0.7-0.6v3H315.3z M316.2,92.4  c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6  c-0.4,0-0.8,0.2-1.2,0.6S316.2,91.6,316.2,92.4z"/>
<path d="M321.9,95.5v-6.2h0.9v0.9c0.2-0.4,0.5-0.7,0.7-0.9s0.4-0.2,0.7-0.2c0.4,0,0.7,0.1,1.1,0.3l-0.4,1c-0.3-0.2-0.5-0.2-0.8-0.2  c-0.2,0-0.4,0.1-0.6,0.2s-0.3,0.3-0.4,0.6c-0.1,0.4-0.2,0.8-0.2,1.2v3.3H321.9z"/>
<path d="M330.2,93.5l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5s-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8s-0.8-1.3-0.8-2.4c0-1,0.3-1.9,0.8-2.4  s1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8s0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6c0,0.7,0.2,1.2,0.6,1.6c0.3,0.4,0.8,0.5,1.3,0.5  c0.4,0,0.7-0.1,1-0.3S330,93.9,330.2,93.5z M326.7,91.8h3.5c0-0.5-0.2-0.9-0.4-1.2c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5  C326.9,90.8,326.8,91.2,326.7,91.8z"/>
<path d="M336.6,95.5v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2c0.4-0.3,0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6v-3.1h1v8.6H336.6z M333.3,92.4  c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9S335.4,90,335,90  c-0.5,0-0.9,0.2-1.2,0.6C333.5,91,333.3,91.6,333.3,92.4z"/>
<rect x="314.5" y="85" fill-rule="evenodd" fill="none" width="24" height="13.5"/>
<path d="M318.9,171.9c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8c0.5,0.6,0.8,1.3,0.8,2.3  c0,0.8-0.1,1.4-0.4,1.9c-0.2,0.5-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8C319.1,173.7,318.9,172.9,318.9,171.9z   M320,171.9c0,0.8,0.2,1.4,0.5,1.8s0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7s-0.8-0.6-1.3-0.6  c-0.5,0-1,0.2-1.3,0.6S320,171.1,320,171.9z"/>
<path d="M326.9,175h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1s0.2,0.8,0.2,1.3  c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V175z M326.9,171.8c0,0.7,0.1,1.3,0.3,1.6c0.3,0.5,0.8,0.8,1.3,0.8  c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  C327.1,170.5,326.9,171.1,326.9,171.8z"/>
<path d="M331.3,177.4l0.2-0.9c0.2,0.1,0.4,0.1,0.5,0.1c0.2,0,0.4-0.1,0.5-0.2s0.2-0.5,0.2-1.1v-6.5h1.1v6.6c0,0.8-0.1,1.3-0.3,1.6  c-0.3,0.4-0.7,0.6-1.3,0.6C331.8,177.5,331.5,177.5,331.3,177.4z M332.6,167.6v-1.2h1.1v1.2H332.6z"/>
<rect x="318.5" y="164.5" fill-rule="evenodd" fill="none" width="15.7" height="13.5"/>
<path d="M315.3,256.9v-8.6h1v0.8c0.2-0.3,0.5-0.6,0.8-0.7s0.6-0.2,1-0.2c0.5,0,1,0.1,1.4,0.4s0.7,0.7,0.9,1.2s0.3,1,0.3,1.6  c0,0.6-0.1,1.2-0.3,1.7c-0.2,0.5-0.6,0.9-1,1.2s-0.9,0.4-1.4,0.4c-0.4,0-0.7-0.1-0.9-0.2s-0.5-0.3-0.7-0.6v3H315.3z M316.2,251.4  c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6  c-0.4,0-0.8,0.2-1.2,0.6S316.2,250.6,316.2,251.4z"/>
<path d="M321.9,254.5v-6.2h0.9v0.9c0.2-0.4,0.5-0.7,0.7-0.9s0.4-0.2,0.7-0.2c0.4,0,0.7,0.1,1.1,0.3l-0.4,1c-0.3-0.2-0.5-0.2-0.8-0.2  c-0.2,0-0.4,0.1-0.6,0.2s-0.3,0.3-0.4,0.6c-0.1,0.4-0.2,0.8-0.2,1.2v3.3H321.9z"/>
<path d="M330.2,252.5l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5s-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8s-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4s1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8s0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6c0,0.7,0.2,1.2,0.6,1.6  c0.3,0.4,0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3S330,252.9,330.2,252.5z M326.7,250.8h3.5c0-0.5-0.2-0.9-0.4-1.2  c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5C326.9,249.8,326.8,250.2,326.7,250.8z"/>
<path d="M336.6,254.5v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2c0.4-0.3,0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6v-3.1h1v8.6H336.6z M333.3,251.4  c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C333.5,250,333.3,250.6,333.3,251.4z"/>
<rect x="314.5" y="244" fill-rule="evenodd" fill="none" width="24" height="13.5"/>
<path d="M318.9,330.9c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8c0.5,0.6,0.8,1.3,0.8,2.3  c0,0.8-0.1,1.4-0.4,1.9c-0.2,0.5-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8C319.1,332.7,318.9,331.9,318.9,330.9z   M320,330.9c0,0.8,0.2,1.4,0.5,1.8s0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7s-0.8-0.6-1.3-0.6  c-0.5,0-1,0.2-1.3,0.6S320,330.1,320,330.9z"/>
<path d="M326.9,334h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1s0.2,0.8,0.2,1.3  c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V334z M326.9,330.8c0,0.7,0.1,1.3,0.3,1.6c0.3,0.5,0.8,0.8,1.3,0.8  c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  C327.1,329.5,326.9,330.1,326.9,330.8z"/>
<path d="M331.3,336.4l0.2-0.9c0.2,0.1,0.4,0.1,0.5,0.1c0.2,0,0.4-0.1,0.5-0.2s0.2-0.5,0.2-1.1v-6.5h1.1v6.6c0,0.8-0.1,1.3-0.3,1.6  c-0.3,0.4-0.7,0.6-1.3,0.6C331.8,336.5,331.5,336.5,331.3,336.4z M332.6,326.6v-1.2h1.1v1.2H332.6z"/>
<rect x="318.5" y="323.5" fill-rule="evenodd" fill="none" width="15.7" height="13.5"/>
<path d="M315.3,415.9v-8.6h1v0.8c0.2-0.3,0.5-0.6,0.8-0.7s0.6-0.2,1-0.2c0.5,0,1,0.1,1.4,0.4s0.7,0.7,0.9,1.2s0.3,1,0.3,1.6  c0,0.6-0.1,1.2-0.3,1.7c-0.2,0.5-0.6,0.9-1,1.2s-0.9,0.4-1.4,0.4c-0.4,0-0.7-0.1-0.9-0.2s-0.5-0.3-0.7-0.6v3H315.3z M316.2,410.4  c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6  c-0.4,0-0.8,0.2-1.2,0.6S316.2,409.6,316.2,410.4z"/>
<path d="M321.9,413.5v-6.2h0.9v0.9c0.2-0.4,0.5-0.7,0.7-0.9s0.4-0.2,0.7-0.2c0.4,0,0.7,0.1,1.1,0.3l-0.4,1c-0.3-0.2-0.5-0.2-0.8-0.2  c-0.2,0-0.4,0.1-0.6,0.2s-0.3,0.3-0.4,0.6c-0.1,0.4-0.2,0.8-0.2,1.2v3.3H321.9z"/>
<path d="M330.2,411.5l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5s-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8s-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4s1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8s0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6c0,0.7,0.2,1.2,0.6,1.6  c0.3,0.4,0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3S330,411.9,330.2,411.5z M326.7,409.8h3.5c0-0.5-0.2-0.9-0.4-1.2  c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5C326.9,408.8,326.8,409.2,326.7,409.8z"/>
<path d="M336.6,413.5v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2c0.4-0.3,0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6v-3.1h1v8.6H336.6z M333.3,410.4  c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C333.5,409,333.3,409.6,333.3,410.4z"/>
<rect x="314.5" y="403" fill-rule="evenodd" fill="none" width="24" height="13.5"/>
<path d="M318.9,489.9c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8c0.5,0.6,0.8,1.3,0.8,2.3  c0,0.8-0.1,1.4-0.4,1.9c-0.2,0.5-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8C319.1,491.7,318.9,490.9,318.9,489.9z   M320,489.9c0,0.8,0.2,1.4,0.5,1.8s0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7s-0.8-0.6-1.3-0.6  c-0.5,0-1,0.2-1.3,0.6S320,489.1,320,489.9z"/>
<path d="M326.9,493h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1s0.2,0.8,0.2,1.3  c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V493z M326.9,489.8c0,0.7,0.1,1.3,0.3,1.6c0.3,0.5,0.8,0.8,1.3,0.8  c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  C327.1,488.5,326.9,489.1,326.9,489.8z"/>
<path d="M331.3,495.4l0.2-0.9c0.2,0.1,0.4,0.1,0.5,0.1c0.2,0,0.4-0.1,0.5-0.2s0.2-0.5,0.2-1.1v-6.5h1.1v6.6c0,0.8-0.1,1.3-0.3,1.6  c-0.3,0.4-0.7,0.6-1.3,0.6C331.8,495.5,331.5,495.5,331.3,495.4z M332.6,485.6v-1.2h1.1v1.2H332.6z"/>
<rect x="318.5" y="482.5" fill-rule="evenodd" fill="none" width="15.7" height="13.5"/>
<path fill="none" stroke="#000000" stroke-width="2.2498" d="M99.4,211c0,1.1-0.1,2.2-0.2,3.4c-0.1,1.1-0.3,2.2-0.5,3.3  c-0.2,1.1-0.5,2.2-0.8,3.3c-0.3,1.1-0.7,2.1-1.1,3.2c-0.4,1-0.9,2-1.4,3c-0.5,1-1.1,1.9-1.7,2.9c-0.6,0.9-1.3,1.8-2,2.7  s-1.5,1.7-2.3,2.5c-0.8,0.8-1.6,1.5-2.5,2.3c-0.9,0.7-1.8,1.4-2.7,2c-0.9,0.6-1.9,1.2-2.9,1.7c-1,0.5-2,1-3,1.4  c-1,0.4-2.1,0.8-3.2,1.1c-1.1,0.3-2.2,0.6-3.3,0.8c-1.1,0.2-2.2,0.4-3.3,0.5c-1.1,0.1-2.2,0.2-3.4,0.2c-1.1,0-2.2-0.1-3.4-0.2  c-1.1-0.1-2.2-0.3-3.3-0.5s-2.2-0.5-3.3-0.8c-1.1-0.3-2.1-0.7-3.2-1.1s-2-0.9-3-1.4c-1-0.5-1.9-1.1-2.9-1.7s-1.8-1.3-2.7-2  c-0.9-0.7-1.7-1.5-2.5-2.3s-1.5-1.6-2.3-2.5s-1.4-1.8-2-2.7c-0.6-0.9-1.2-1.9-1.7-2.9c-0.5-1-1-2-1.4-3c-0.4-1-0.8-2.1-1.1-3.2  s-0.6-2.2-0.8-3.3c-0.2-1.1-0.4-2.2-0.5-3.3c-0.1-1.1-0.2-2.2-0.2-3.4c0-1.1,0.1-2.2,0.2-3.4c0.1-1.1,0.3-2.2,0.5-3.3  c0.2-1.1,0.5-2.2,0.8-3.3c0.3-1.1,0.7-2.1,1.1-3.2c0.4-1,0.9-2,1.4-3c0.5-1,1.1-1.9,1.7-2.9c0.6-0.9,1.3-1.8,2-2.7s1.5-1.7,2.3-2.5  s1.6-1.5,2.5-2.3c0.9-0.7,1.8-1.4,2.7-2s1.9-1.2,2.9-1.7c1-0.5,2-1,3-1.4s2.1-0.8,3.2-1.1c1.1-0.3,2.2-0.6,3.3-0.8s2.2-0.4,3.3-0.5  c1.1-0.1,2.2-0.2,3.4-0.2c1.1,0,2.2,0.1,3.4,0.2c1.1,0.1,2.2,0.3,3.3,0.5c1.1,0.2,2.2,0.5,3.3,0.8c1.1,0.3,2.1,0.7,3.2,1.1  c1,0.4,2,0.9,3,1.4c1,0.5,1.9,1.1,2.9,1.7c0.9,0.6,1.8,1.3,2.7,2c0.9,0.7,1.7,1.5,2.5,2.3c0.8,0.8,1.5,1.6,2.3,2.5s1.4,1.8,2,2.7  c0.6,0.9,1.2,1.9,1.7,2.9c0.5,1,1,2,1.4,3c0.4,1,0.8,2.1,1.1,3.2s0.6,2.2,0.8,3.3c0.2,1.1,0.4,2.2,0.5,3.3  C99.3,208.8,99.4,209.9,99.4,211z"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="489.8" height="491.2"/>
<path d="M44.5,201.5l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  s-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9s0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8c0.5,0.5,0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5  s-0.6,0.8-1,1.1s-0.9,0.4-1.4,0.4c-0.9,0-1.6-0.3-2.1-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6c0.5-0.7,1.3-1,2.2-1  c0.7,0,1.2,0.2,1.7,0.6C44.1,200.3,44.4,200.8,44.5,201.5z M40.2,205.2c0,0.4,0.1,0.7,0.2,1s0.4,0.6,0.6,0.8s0.6,0.3,0.9,0.3  c0.4,0,0.8-0.2,1.1-0.5s0.5-0.8,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.5S40.2,204.7,40.2,205.2z"/>
<path d="M51.2,207v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1s0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8s0.5-0.9,0.5-1.3  c0-0.4-0.1-0.8-0.4-1.1s-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5s-0.5,0.7-0.5,1.3l-1.1-0.1c0.1-0.8,0.4-1.4,0.8-1.8  c0.5-0.4,1.1-0.6,2-0.6c0.8,0,1.5,0.2,2,0.7c0.5,0.5,0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1s-0.4,0.7-0.7,1c-0.3,0.4-0.9,0.9-1.6,1.5  c-0.6,0.5-1,0.9-1.2,1.1s-0.3,0.4-0.4,0.6H51.2z"/>
<path d="M52.3,205.8l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2s0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6s0.5-0.9,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4  s-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2s-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4l-0.5,2.3c0.5-0.4,1.1-0.5,1.6-0.5  c0.8,0,1.4,0.3,1.9,0.8c0.5,0.5,0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1c-0.8,0-1.4-0.2-1.9-0.7  C52.7,207.1,52.4,206.5,52.3,205.8z"/>
<path d="M59,205.8l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2s0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6s0.5-0.9,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4  s-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2s-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4l-0.5,2.3c0.5-0.4,1.1-0.5,1.6-0.5  c0.8,0,1.4,0.3,1.9,0.8c0.5,0.5,0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1c-0.8,0-1.4-0.2-1.9-0.7  C59.4,207.1,59.1,206.5,59,205.8z"/>
<path d="M70.2,206l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5c-0.5,0.4-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8c-0.5-0.6-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4c0.5-0.6,1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8c0.5,0.6,0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6  c0,0.7,0.2,1.2,0.6,1.6s0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3S70.1,206.4,70.2,206z M66.8,204.3h3.5c0-0.5-0.2-0.9-0.4-1.2  c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5S66.8,203.7,66.8,204.3z"/>
<path d="M72.4,205.7l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3s0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5s0.5-0.8,0.5-1.3c0-0.5-0.2-0.9-0.5-1.2  s-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1l0.1-0.9c0.1,0,0.1,0,0.2,0c0.4,0,0.9-0.1,1.2-0.4s0.5-0.6,0.5-1.1c0-0.4-0.1-0.7-0.4-1  s-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4s-0.4,0.6-0.5,1.2l-1.1-0.2c0.1-0.7,0.4-1.3,0.9-1.6c0.5-0.4,1-0.6,1.7-0.6  c0.5,0,0.9,0.1,1.3,0.3s0.7,0.5,0.9,0.8c0.2,0.3,0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-0.9,0.7c0.5,0.1,0.9,0.4,1.2,0.7  c0.3,0.4,0.4,0.8,0.4,1.4c0,0.8-0.3,1.4-0.8,1.9c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7C72.7,207,72.4,206.4,72.4,205.7z"/>
<path d="M80.3,208h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5c-0.5,0.6-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V208z M80.3,204.8c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  S80.3,204.1,80.3,204.8z"/>
<path d="M91.2,201.5l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  s-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9s0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8c0.5,0.5,0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5  s-0.6,0.8-1,1.1s-0.9,0.4-1.4,0.4c-0.9,0-1.6-0.3-2.1-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6c0.5-0.7,1.3-1,2.2-1  c0.7,0,1.2,0.2,1.7,0.6C90.8,200.3,91.1,200.8,91.2,201.5z M86.9,205.2c0,0.4,0.1,0.7,0.2,1s0.4,0.6,0.6,0.8s0.6,0.3,0.9,0.3  c0.4,0,0.8-0.2,1.1-0.5s0.5-0.8,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.5S86.9,204.7,86.9,205.2z"/>
<path d="M48.8,221.5v-8.6h1.2l4.5,6.7v-6.7h1.1v8.6h-1.2l-4.5-6.8v6.8H48.8z"/>
<path d="M57.1,217.3c0-1.4,0.4-2.5,1.1-3.3c0.8-0.8,1.8-1.2,3-1.2c0.8,0,1.5,0.2,2.1,0.6s1.1,0.9,1.5,1.6s0.5,1.4,0.5,2.3  c0,0.9-0.2,1.7-0.5,2.3c-0.4,0.7-0.8,1.2-1.5,1.6s-1.3,0.5-2.1,0.5c-0.8,0-1.5-0.2-2.2-0.6c-0.6-0.4-1.1-0.9-1.4-1.6  C57.3,218.8,57.1,218.1,57.1,217.3z M58.3,217.3c0,1,0.3,1.9,0.8,2.4s1.3,0.9,2.1,0.9c0.9,0,1.6-0.3,2.1-0.9s0.8-1.5,0.8-2.6  c0-0.7-0.1-1.3-0.4-1.8s-0.6-0.9-1-1.2s-1-0.4-1.5-0.4c-0.8,0-1.5,0.3-2.1,0.8S58.3,216,58.3,217.3z"/>
<path d="M66.8,221.5v-8.6h3c0.7,0,1.2,0,1.5,0.1c0.5,0.1,0.9,0.3,1.3,0.6c0.5,0.4,0.8,0.9,1,1.5c0.2,0.6,0.3,1.3,0.3,2  c0,0.7-0.1,1.2-0.2,1.7c-0.2,0.5-0.3,0.9-0.6,1.3s-0.5,0.6-0.8,0.8s-0.6,0.3-1,0.4c-0.4,0.1-0.9,0.1-1.4,0.1H66.8z M67.9,220.5h1.8  c0.6,0,1-0.1,1.3-0.2s0.6-0.3,0.8-0.4c0.3-0.3,0.5-0.6,0.6-1.1s0.2-1,0.2-1.7c0-0.9-0.1-1.6-0.4-2.1s-0.7-0.8-1.1-1  c-0.3-0.1-0.8-0.2-1.5-0.2h-1.8V220.5z"/>
<path d="M75.5,221.5v-8.6h6.2v1h-5.1v2.6h4.8v1h-4.8v2.9h5.3v1H75.5z"/>
<rect x="38.5" y="197.5" fill-rule="evenodd" fill="none" width="53.2" height="27"/>
<rect x="158.9" y="31" fill="none" stroke="#000000" stroke-width="2.2498" width="136.8" height="42"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="489.8" height="491.2"/>
<path d="M205.1,49H204v-6.7c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1c0.4-0.4,0.8-0.8,0.9-1.1h0.7V49z"/>
<path d="M207.8,46.7l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3s0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5s0.5-0.8,0.5-1.3c0-0.5-0.2-0.9-0.5-1.2  s-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1L210,44c0.1,0,0.1,0,0.2,0c0.4,0,0.9-0.1,1.2-0.4s0.5-0.6,0.5-1.1c0-0.4-0.1-0.7-0.4-1  s-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4s-0.4,0.6-0.5,1.2l-1.1-0.2c0.1-0.7,0.4-1.3,0.9-1.6c0.5-0.4,1-0.6,1.7-0.6  c0.5,0,0.9,0.1,1.3,0.3s0.7,0.5,0.9,0.8c0.2,0.3,0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-0.9,0.7c0.5,0.1,0.9,0.4,1.2,0.7  c0.3,0.4,0.4,0.8,0.4,1.4c0,0.8-0.3,1.4-0.8,1.9c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7C208.1,48,207.9,47.4,207.8,46.7z"/>
<path d="M214.6,47l1-0.1c0.1,0.5,0.2,0.8,0.5,1s0.6,0.3,0.9,0.3c0.3,0,0.6-0.1,0.9-0.2s0.4-0.3,0.6-0.6s0.3-0.6,0.4-1  s0.2-0.9,0.2-1.3c0,0,0-0.1,0-0.2c-0.2,0.3-0.5,0.6-0.9,0.8s-0.8,0.3-1.2,0.3c-0.7,0-1.3-0.3-1.8-0.8c-0.5-0.5-0.7-1.2-0.7-2  c0-0.9,0.3-1.6,0.8-2.1c0.5-0.5,1.2-0.8,1.9-0.8c0.6,0,1.1,0.2,1.5,0.5s0.8,0.7,1.1,1.3c0.2,0.6,0.4,1.4,0.4,2.4  c0,1.1-0.1,2-0.4,2.6s-0.6,1.1-1.1,1.5s-1,0.5-1.7,0.5c-0.7,0-1.2-0.2-1.6-0.6S214.7,47.7,214.6,47z M218.9,43.2  c0-0.6-0.2-1.1-0.5-1.4s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.6s-0.5,0.9-0.5,1.5c0,0.5,0.2,1,0.5,1.3s0.7,0.5,1.2,0.5  c0.5,0,0.9-0.2,1.2-0.5S218.9,43.8,218.9,43.2z"/>
<path d="M224.5,49v-2.1h-3.7v-1l3.9-5.6h0.9V46h1.2v1h-1.2V49H224.5z M224.5,46v-3.9l-2.7,3.9H224.5z"/>
<path d="M231.8,49h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1c0.4-0.4,0.8-0.8,0.9-1.1h0.7V49z"/>
<path d="M235.7,49h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5c-0.5,0.6-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V49z M235.7,45.8c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  S235.7,45.1,235.7,45.8z"/>
<path d="M244.5,49v-2.1h-3.7v-1l3.9-5.6h0.9V46h1.2v1h-1.2V49H244.5z M244.5,46v-3.9l-2.7,3.9H244.5z"/>
<path d="M249.4,44.3c-0.4-0.2-0.8-0.4-1-0.7c-0.2-0.3-0.3-0.7-0.3-1.1c0-0.6,0.2-1.2,0.7-1.6s1-0.6,1.8-0.6c0.7,0,1.4,0.2,1.8,0.7  s0.7,1,0.7,1.6c0,0.4-0.1,0.7-0.3,1c-0.2,0.3-0.5,0.5-1,0.7c0.5,0.2,0.9,0.4,1.2,0.8c0.3,0.4,0.4,0.8,0.4,1.4c0,0.7-0.3,1.4-0.8,1.9  c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.5-0.3-2.1-0.8c-0.5-0.5-0.8-1.1-0.8-1.9c0-0.6,0.1-1,0.4-1.4C248.5,44.7,248.9,44.5,249.4,44.3z   M248.9,46.5c0,0.3,0.1,0.6,0.2,0.9s0.4,0.5,0.6,0.7s0.6,0.2,0.9,0.2c0.5,0,0.9-0.2,1.2-0.5s0.5-0.7,0.5-1.2c0-0.5-0.2-0.9-0.5-1.3  s-0.8-0.5-1.3-0.5c-0.5,0-0.9,0.2-1.2,0.5S248.9,46,248.9,46.5z M249.2,42.6c0,0.4,0.1,0.7,0.4,1s0.6,0.4,1,0.4c0.4,0,0.7-0.1,1-0.4  s0.4-0.6,0.4-0.9c0-0.4-0.1-0.7-0.4-1s-0.6-0.4-1-0.4c-0.4,0-0.7,0.1-1,0.4S249.2,42.2,249.2,42.6z"/>
<path d="M210.9,57l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H210.9z M212.8,57l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H212.8z"/>
<path d="M214.3,62.5l3.3-8.6h1.2l3.5,8.6H221l-1-2.6h-3.6l-0.9,2.6H214.3z M216.8,59h2.9l-0.9-2.4c-0.3-0.7-0.5-1.3-0.6-1.8  c-0.1,0.6-0.3,1.1-0.5,1.6L216.8,59z"/>
<path d="M223.1,62.5v-8.6h1.1v8.6H223.1z"/>
<path d="M225.8,55.1v-1.2h1.1v1.2H225.8z M225.8,62.5v-6.2h1.1v6.2H225.8z"/>
<path d="M232.5,60.2l1,0.1c-0.1,0.7-0.4,1.3-0.9,1.7c-0.5,0.4-1,0.6-1.7,0.6c-0.9,0-1.5-0.3-2.1-0.8c-0.5-0.6-0.8-1.4-0.8-2.4  c0-0.7,0.1-1.3,0.3-1.8s0.6-0.9,1-1.1s1-0.4,1.5-0.4c0.7,0,1.2,0.2,1.7,0.5s0.7,0.8,0.8,1.5l-1,0.2c-0.1-0.4-0.3-0.7-0.5-0.9  S231.3,57,231,57c-0.5,0-1,0.2-1.3,0.6s-0.5,1-0.5,1.8c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.3,0.6c0.4,0,0.8-0.1,1-0.4  S232.4,60.7,232.5,60.2z"/>
<path d="M238.7,60.5l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5c-0.5,0.4-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8c-0.5-0.6-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4c0.5-0.6,1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8c0.5,0.6,0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6  c0,0.7,0.2,1.2,0.6,1.6s0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3S238.5,60.9,238.7,60.5z M235.2,58.8h3.5c0-0.5-0.2-0.9-0.4-1.2  c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5S235.3,58.2,235.2,58.8z"/>
<path d="M241.2,57l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H241.2z M243.1,57l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H243.1z"/>
<rect x="166.4" y="38.5" fill-rule="evenodd" fill="none" width="122.2" height="27"/>
<path fill="none" stroke="#000000" stroke-width="2.2498" d="M201,110.5h52.6c0.7,0,1.4,0,2.1,0.1c0.7,0.1,1.4,0.2,2,0.3  c0.7,0.1,1.3,0.3,2,0.5c0.7,0.2,1.3,0.4,1.9,0.7c0.6,0.3,1.3,0.6,1.9,0.9c0.6,0.3,1.2,0.7,1.8,1.1c0.6,0.4,1.1,0.8,1.7,1.2  s1,0.9,1.5,1.4c0.5,0.5,0.9,1,1.4,1.5c0.4,0.5,0.8,1.1,1.2,1.7c0.4,0.6,0.7,1.2,1.1,1.8c0.3,0.6,0.6,1.2,0.9,1.9  c0.3,0.6,0.5,1.3,0.7,1.9c0.2,0.7,0.4,1.3,0.5,2s0.2,1.4,0.3,2c0.1,0.7,0.1,1.4,0.1,2.1s0,1.4-0.1,2.1c-0.1,0.7-0.2,1.4-0.3,2  s-0.3,1.3-0.5,2c-0.2,0.7-0.4,1.3-0.7,1.9c-0.3,0.6-0.6,1.3-0.9,1.9c-0.3,0.6-0.7,1.2-1.1,1.8c-0.4,0.6-0.8,1.1-1.2,1.7  c-0.4,0.5-0.9,1-1.4,1.5c-0.5,0.5-1,0.9-1.5,1.4s-1.1,0.8-1.7,1.2c-0.6,0.4-1.2,0.7-1.8,1.1c-0.6,0.3-1.2,0.6-1.9,0.9  c-0.6,0.3-1.3,0.5-1.9,0.7c-0.7,0.2-1.3,0.4-2,0.5c-0.7,0.1-1.4,0.2-2,0.3c-0.7,0.1-1.4,0.1-2.1,0.1H201c-0.7,0-1.4,0-2.1-0.1  c-0.7-0.1-1.4-0.2-2-0.3c-0.7-0.1-1.3-0.3-2-0.5c-0.7-0.2-1.3-0.4-1.9-0.7c-0.6-0.3-1.3-0.6-1.9-0.9s-1.2-0.7-1.8-1.1  c-0.6-0.4-1.1-0.8-1.7-1.2s-1-0.9-1.5-1.4s-0.9-1-1.4-1.5c-0.4-0.5-0.8-1.1-1.2-1.7c-0.4-0.6-0.7-1.2-1.1-1.8  c-0.3-0.6-0.6-1.2-0.9-1.9c-0.3-0.6-0.5-1.3-0.7-1.9c-0.2-0.7-0.4-1.3-0.5-2c-0.1-0.7-0.2-1.4-0.3-2s-0.1-1.4-0.1-2.1s0-1.4,0.1-2.1  c0.1-0.7,0.2-1.4,0.3-2c0.1-0.7,0.3-1.3,0.5-2c0.2-0.7,0.4-1.3,0.7-1.9c0.3-0.6,0.6-1.3,0.9-1.9c0.3-0.6,0.7-1.2,1.1-1.8  c0.4-0.6,0.8-1.1,1.2-1.7c0.4-0.5,0.9-1,1.4-1.5s1-0.9,1.5-1.4s1.1-0.8,1.7-1.2c0.6-0.4,1.2-0.7,1.8-1.1s1.2-0.6,1.9-0.9  c0.6-0.3,1.3-0.5,1.9-0.7c0.7-0.2,1.3-0.4,2-0.5c0.7-0.1,1.4-0.2,2-0.3C199.6,110.5,200.3,110.5,201,110.5z"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="489.8" height="491.2"/>
<path d="M206.5,128.5v-2.1h-3.7v-1l3.9-5.6h0.9v5.6h1.2v1h-1.2v2.1H206.5z M206.5,125.5v-3.9l-2.7,3.9H206.5z"/>
<path d="M209.8,124.3c0-1,0.1-1.8,0.3-2.5c0.2-0.6,0.5-1.1,0.9-1.4s0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3s0.6,0.5,0.9,0.8  c0.2,0.3,0.4,0.8,0.5,1.3s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9  C210.1,127,209.8,125.9,209.8,124.3z M210.9,124.3c0,1.4,0.2,2.3,0.5,2.8s0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7s0.5-1.4,0.5-2.8  c0-1.4-0.2-2.4-0.5-2.8s-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C211.1,121.9,210.9,122.9,210.9,124.3z"/>
<path d="M220.4,128.5h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1c0.4-0.4,0.8-0.8,0.9-1.1h0.7  V128.5z"/>
<path d="M228.7,127.5v1H223c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1s0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8s0.5-0.9,0.5-1.3  c0-0.4-0.1-0.8-0.4-1.1s-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5s-0.5,0.7-0.5,1.3l-1.1-0.1c0.1-0.8,0.4-1.4,0.8-1.8  c0.5-0.4,1.1-0.6,2-0.6c0.8,0,1.5,0.2,2,0.7c0.5,0.5,0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1s-0.4,0.7-0.7,1c-0.3,0.4-0.9,0.9-1.6,1.5  c-0.6,0.5-1,0.9-1.2,1.1s-0.3,0.4-0.4,0.6H228.7z"/>
<path d="M234.2,126.2l1,0.1c-0.1,0.7-0.4,1.3-0.9,1.7c-0.5,0.4-1,0.6-1.7,0.6c-0.9,0-1.5-0.3-2.1-0.8c-0.5-0.6-0.8-1.4-0.8-2.4  c0-0.7,0.1-1.3,0.3-1.8s0.6-0.9,1-1.1s1-0.4,1.5-0.4c0.7,0,1.2,0.2,1.7,0.5s0.7,0.8,0.8,1.5l-1,0.2c-0.1-0.4-0.3-0.7-0.5-0.9  s-0.5-0.3-0.9-0.3c-0.5,0-1,0.2-1.3,0.6s-0.5,1-0.5,1.8c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.3,0.6c0.4,0,0.8-0.1,1-0.4  S234.1,126.7,234.2,126.2z"/>
<path d="M240.2,127.7c-0.4,0.3-0.8,0.6-1.1,0.7s-0.7,0.2-1.2,0.2c-0.7,0-1.2-0.2-1.6-0.5c-0.4-0.3-0.6-0.8-0.6-1.3  c0-0.3,0.1-0.6,0.2-0.8s0.3-0.5,0.5-0.6s0.5-0.3,0.8-0.3c0.2-0.1,0.5-0.1,0.9-0.2c0.9-0.1,1.5-0.2,1.9-0.4c0-0.1,0-0.2,0-0.3  c0-0.4-0.1-0.7-0.3-0.9c-0.3-0.2-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.1-1.1,0.3s-0.4,0.5-0.5,0.9l-1-0.1c0.1-0.4,0.2-0.8,0.5-1.1  c0.2-0.3,0.5-0.5,0.9-0.6s0.9-0.2,1.4-0.2c0.5,0,1,0.1,1.3,0.2s0.6,0.3,0.7,0.5c0.2,0.2,0.3,0.4,0.3,0.7c0,0.2,0.1,0.5,0.1,1v1.4  c0,1,0,1.6,0.1,1.9s0.1,0.5,0.3,0.7h-1.1C240.3,128.3,240.2,128,240.2,127.7z M240.1,125.4c-0.4,0.2-1,0.3-1.7,0.4  c-0.4,0.1-0.7,0.1-0.9,0.2s-0.3,0.2-0.4,0.3s-0.1,0.3-0.1,0.5c0,0.3,0.1,0.5,0.3,0.7s0.5,0.3,0.9,0.3c0.4,0,0.8-0.1,1.1-0.3  s0.5-0.4,0.7-0.7c0.1-0.2,0.2-0.6,0.2-1.1V125.4z"/>
<path d="M243,128.5v-5.4h-0.9v-0.8h0.9v-0.7c0-0.4,0-0.7,0.1-0.9c0.1-0.3,0.3-0.5,0.5-0.7s0.6-0.3,1.1-0.3c0.3,0,0.6,0,1,0.1  l-0.2,0.9c-0.2,0-0.4-0.1-0.6-0.1c-0.3,0-0.5,0.1-0.7,0.2s-0.2,0.4-0.2,0.8v0.6h1.2v0.8h-1.2v5.4H243z"/>
<path d="M251.4,127.5v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1s0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8s0.5-0.9,0.5-1.3  c0-0.4-0.1-0.8-0.4-1.1s-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5s-0.5,0.7-0.5,1.3l-1.1-0.1c0.1-0.8,0.4-1.4,0.8-1.8  c0.5-0.4,1.1-0.6,2-0.6c0.8,0,1.5,0.2,2,0.7c0.5,0.5,0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1s-0.4,0.7-0.7,1c-0.3,0.4-0.9,0.9-1.6,1.5  c-0.6,0.5-1,0.9-1.2,1.1s-0.3,0.4-0.4,0.6H251.4z"/>
<path d="M192.7,142l3.3-8.6h1.2l3.5,8.6h-1.3l-1-2.6h-3.6l-0.9,2.6H192.7z M195.2,138.5h2.9l-0.9-2.4c-0.3-0.7-0.5-1.3-0.6-1.8  c-0.1,0.6-0.3,1.1-0.5,1.6L195.2,138.5z"/>
<path d="M201.3,139.2l1.1-0.1c0.1,0.4,0.2,0.8,0.4,1.1s0.5,0.5,0.9,0.7c0.4,0.2,0.8,0.3,1.3,0.3c0.4,0,0.8-0.1,1.1-0.2  c0.3-0.1,0.6-0.3,0.7-0.5s0.2-0.5,0.2-0.7c0-0.3-0.1-0.5-0.2-0.7s-0.4-0.4-0.8-0.5c-0.2-0.1-0.7-0.2-1.5-0.4  c-0.8-0.2-1.3-0.4-1.7-0.5c-0.4-0.2-0.7-0.5-0.9-0.8s-0.3-0.7-0.3-1.1c0-0.4,0.1-0.8,0.4-1.2c0.2-0.4,0.6-0.7,1.1-0.9s1-0.3,1.6-0.3  c0.6,0,1.2,0.1,1.7,0.3c0.5,0.2,0.9,0.5,1.1,0.9s0.4,0.8,0.4,1.4l-1.1,0.1c-0.1-0.5-0.3-1-0.6-1.2c-0.3-0.3-0.8-0.4-1.5-0.4  c-0.7,0-1.2,0.1-1.5,0.4s-0.5,0.6-0.5,0.9c0,0.3,0.1,0.6,0.3,0.8c0.2,0.2,0.8,0.4,1.7,0.6c0.9,0.2,1.6,0.4,1.9,0.5  c0.5,0.2,0.9,0.5,1.1,0.9s0.4,0.8,0.4,1.2c0,0.5-0.1,0.9-0.4,1.3s-0.6,0.7-1.1,0.9c-0.5,0.2-1,0.3-1.7,0.3c-0.8,0-1.4-0.1-2-0.3  s-0.9-0.6-1.2-1C201.5,140.3,201.3,139.8,201.3,139.2z"/>
<path d="M209.3,139.2l1.1-0.1c0.1,0.4,0.2,0.8,0.4,1.1s0.5,0.5,0.9,0.7c0.4,0.2,0.8,0.3,1.3,0.3c0.4,0,0.8-0.1,1.1-0.2  c0.3-0.1,0.6-0.3,0.7-0.5s0.2-0.5,0.2-0.7c0-0.3-0.1-0.5-0.2-0.7s-0.4-0.4-0.8-0.5c-0.2-0.1-0.7-0.2-1.5-0.4  c-0.8-0.2-1.3-0.4-1.7-0.5c-0.4-0.2-0.7-0.5-0.9-0.8s-0.3-0.7-0.3-1.1c0-0.4,0.1-0.8,0.4-1.2c0.2-0.4,0.6-0.7,1.1-0.9s1-0.3,1.6-0.3  c0.6,0,1.2,0.1,1.7,0.3c0.5,0.2,0.9,0.5,1.1,0.9s0.4,0.8,0.4,1.4l-1.1,0.1c-0.1-0.5-0.3-1-0.6-1.2c-0.3-0.3-0.8-0.4-1.5-0.4  c-0.7,0-1.2,0.1-1.5,0.4s-0.5,0.6-0.5,0.9c0,0.3,0.1,0.6,0.3,0.8c0.2,0.2,0.8,0.4,1.7,0.6c0.9,0.2,1.6,0.4,1.9,0.5  c0.5,0.2,0.9,0.5,1.1,0.9s0.4,0.8,0.4,1.2c0,0.5-0.1,0.9-0.4,1.3s-0.6,0.7-1.1,0.9c-0.5,0.2-1,0.3-1.7,0.3c-0.8,0-1.4-0.1-2-0.3  s-0.9-0.6-1.2-1C209.5,140.3,209.3,139.8,209.3,139.2z"/>
<path d="M217.7,142v-8.6h6.2v1h-5.1v2.6h4.8v1h-4.8v2.9h5.3v1H217.7z"/>
<path d="M225.7,142v-8.6h3.8c0.8,0,1.3,0.1,1.7,0.2s0.7,0.4,1,0.8c0.2,0.4,0.4,0.8,0.4,1.3c0,0.6-0.2,1.1-0.6,1.5s-1,0.7-1.8,0.8  c0.3,0.1,0.5,0.3,0.7,0.4c0.3,0.3,0.6,0.7,0.9,1.1l1.5,2.3h-1.4l-1.1-1.8c-0.3-0.5-0.6-0.9-0.8-1.2s-0.4-0.5-0.6-0.6  s-0.3-0.2-0.5-0.2c-0.1,0-0.3,0-0.6,0h-1.3v3.8H225.7z M226.8,137.2h2.4c0.5,0,0.9-0.1,1.2-0.2c0.3-0.1,0.5-0.3,0.7-0.5  s0.2-0.5,0.2-0.8c0-0.4-0.1-0.7-0.4-1s-0.8-0.4-1.4-0.4h-2.7V137.2z"/>
<path d="M236.3,142v-7.6h-2.8v-1h6.8v1h-2.8v7.6H236.3z"/>
<path d="M241.7,142v-8.6h1.1v8.6H241.7z"/>
<path d="M244.4,137.8c0-1.4,0.4-2.5,1.1-3.3c0.8-0.8,1.8-1.2,3-1.2c0.8,0,1.5,0.2,2.1,0.6s1.1,0.9,1.5,1.6s0.5,1.4,0.5,2.3  c0,0.9-0.2,1.7-0.5,2.3c-0.4,0.7-0.8,1.2-1.5,1.6s-1.3,0.5-2.1,0.5c-0.8,0-1.5-0.2-2.2-0.6c-0.6-0.4-1.1-0.9-1.4-1.6  C244.6,139.3,244.4,138.6,244.4,137.8z M245.6,137.8c0,1,0.3,1.9,0.8,2.4s1.3,0.9,2.1,0.9c0.9,0,1.6-0.3,2.1-0.9s0.8-1.5,0.8-2.6  c0-0.7-0.1-1.3-0.4-1.8s-0.6-0.9-1-1.2s-1-0.4-1.5-0.4c-0.8,0-1.5,0.3-2.1,0.8S245.6,136.5,245.6,137.8z"/>
<path d="M254.1,142v-8.6h1.2l4.5,6.7v-6.7h1.1v8.6h-1.2l-4.5-6.8v6.8H254.1z"/>
<rect x="192.7" y="118" fill-rule="evenodd" fill="none" width="69" height="27"/>
<rect x="360.6" y="70.8" fill="none" stroke="#000000" stroke-width="2.2498" width="144.8" height="42"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="489.8" height="491.2"/>
<path d="M411.5,88.8V88c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2c0.4-0.3,0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6v-3.1h1v8.6H411.5z M408.1,85.6  c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C408.3,84.2,408.1,84.8,408.1,85.6z"/>
<path d="M415.1,88.8h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1s0.2,0.8,0.2,1.3  c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V88.8z M415.1,85.6c0,0.7,0.1,1.3,0.3,1.6c0.3,0.5,0.8,0.8,1.3,0.8  c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  C415.2,84.3,415.1,84.8,415.1,85.6z"/>
<path d="M420.6,81.3v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  c0.3-1,0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H420.6z"/>
<path d="M431.5,88.8V88c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2c0.4-0.3,0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6v-3.1h1v8.6H431.5z M428.2,85.6  c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C428.3,84.2,428.2,84.8,428.2,85.6z"/>
<path d="M438.2,88.8V88c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2c0.4-0.3,0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6v-3.1h1v8.6H438.2z M434.8,85.6  c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C435,84.2,434.8,84.8,434.8,85.6z"/>
<path d="M446,87.7v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1s0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8s0.5-0.9,0.5-1.3  c0-0.4-0.1-0.8-0.4-1.1s-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5c-0.3,0.3-0.5,0.7-0.5,1.3l-1.1-0.1c0.1-0.8,0.4-1.4,0.8-1.8  s1.1-0.6,2-0.6c0.8,0,1.5,0.2,2,0.7s0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1s-0.4,0.7-0.7,1s-0.9,0.9-1.6,1.5c-0.6,0.5-1,0.9-1.2,1.1  c-0.2,0.2-0.3,0.4-0.4,0.6H446z"/>
<path d="M451.1,88.8h-1.1V82c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1s0.8-0.8,0.9-1.1h0.7V88.8z"/>
<path d="M458.2,86.5l1,0.1c-0.1,0.7-0.4,1.3-0.9,1.7s-1,0.6-1.7,0.6c-0.9,0-1.5-0.3-2.1-0.8s-0.8-1.4-0.8-2.4c0-0.7,0.1-1.3,0.3-1.8  s0.6-0.9,1-1.1c0.5-0.3,0.9-0.4,1.5-0.4c0.7,0,1.2,0.2,1.7,0.5s0.7,0.8,0.8,1.5l-1,0.2c-0.1-0.4-0.3-0.7-0.5-0.9s-0.5-0.3-0.9-0.3  c-0.5,0-1,0.2-1.3,0.6c-0.3,0.4-0.5,1-0.5,1.8c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.3,0.6c0.4,0,0.8-0.1,1-0.4  S458.1,87,458.2,86.5z"/>
<path d="M412.6,96.7l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H412.6z M414.5,96.7l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H414.5z"/>
<path d="M416.8,102.2v-8.6h1.1v4.9l2.5-2.5h1.4l-2.4,2.3l2.6,3.9h-1.3l-2.1-3.2l-0.7,0.7v2.5H416.8z"/>
<path d="M422.8,102.2V96h0.9v0.9c0.5-0.7,1.1-1,2-1c0.4,0,0.7,0.1,1,0.2s0.5,0.3,0.7,0.5s0.3,0.5,0.3,0.8c0,0.2,0.1,0.5,0.1,1v3.8  h-1.1v-3.8c0-0.4,0-0.8-0.1-1s-0.2-0.4-0.4-0.5s-0.5-0.2-0.7-0.2c-0.4,0-0.8,0.1-1.2,0.4c-0.3,0.3-0.5,0.8-0.5,1.6v3.4H422.8z"/>
<path d="M429.1,99.1c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8s0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  s-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8S429.1,100.2,429.1,99.1z M430.1,99.1c0,0.8,0.2,1.4,0.5,1.8  c0.3,0.4,0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7s-0.8-0.6-1.3-0.6c-0.5,0-1,0.2-1.3,0.6  C430.3,97.7,430.1,98.3,430.1,99.1z"/>
<path d="M437.3,102.2l-1.9-6.2h1.1l1,3.6l0.4,1.3c0-0.1,0.1-0.5,0.3-1.3l1-3.6h1.1l0.9,3.6l0.3,1.2l0.4-1.2l1.1-3.6h1l-1.9,6.2h-1.1  l-1-3.7l-0.2-1.1l-1.3,4.8H437.3z"/>
<path d="M444.4,100.4l1-0.2c0.1,0.4,0.2,0.7,0.5,1c0.3,0.2,0.6,0.3,1.1,0.3c0.5,0,0.8-0.1,1.1-0.3s0.4-0.4,0.4-0.7  c0-0.2-0.1-0.4-0.3-0.6c-0.1-0.1-0.5-0.2-1.1-0.4c-0.8-0.2-1.3-0.4-1.6-0.5s-0.5-0.3-0.7-0.6s-0.2-0.5-0.2-0.8  c0-0.3,0.1-0.5,0.2-0.8s0.3-0.4,0.5-0.6c0.2-0.1,0.4-0.2,0.7-0.3c0.3-0.1,0.6-0.1,0.9-0.1c0.5,0,0.9,0.1,1.3,0.2s0.6,0.3,0.8,0.6  s0.3,0.6,0.4,1l-1,0.1c0-0.3-0.2-0.6-0.4-0.8s-0.5-0.3-1-0.3c-0.5,0-0.8,0.1-1,0.2s-0.3,0.3-0.3,0.6c0,0.1,0,0.3,0.1,0.4  c0.1,0.1,0.2,0.2,0.4,0.3c0.1,0,0.4,0.1,0.9,0.3c0.7,0.2,1.3,0.4,1.6,0.5s0.5,0.3,0.7,0.6s0.3,0.5,0.3,0.9c0,0.4-0.1,0.7-0.3,1  s-0.5,0.6-0.9,0.7s-0.8,0.3-1.3,0.3c-0.8,0-1.4-0.2-1.8-0.5S444.5,101.1,444.4,100.4z"/>
<path d="M450.8,96.7l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H450.8z M452.8,96.7l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H452.8z"/>
<rect x="368.1" y="78.2" fill-rule="evenodd" fill="none" width="129.7" height="27"/>
<rect x="363.2" y="150.2" fill="none" stroke="#000000" stroke-width="2.2498" width="139.5" height="42"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="489.8" height="491.2"/>
<path d="M412.8,167.5c-0.4,0.3-0.8,0.6-1.1,0.7s-0.7,0.2-1.2,0.2c-0.7,0-1.2-0.2-1.6-0.5s-0.6-0.8-0.6-1.3c0-0.3,0.1-0.6,0.2-0.8  s0.3-0.5,0.5-0.6s0.5-0.3,0.8-0.3c0.2-0.1,0.5-0.1,0.9-0.2c0.9-0.1,1.5-0.2,1.9-0.4c0-0.1,0-0.2,0-0.3c0-0.4-0.1-0.7-0.3-0.9  c-0.3-0.2-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.1-1.1,0.3c-0.2,0.2-0.4,0.5-0.5,0.9l-1-0.1c0.1-0.4,0.2-0.8,0.5-1.1s0.5-0.5,0.9-0.6  c0.4-0.1,0.9-0.2,1.4-0.2c0.5,0,1,0.1,1.3,0.2s0.6,0.3,0.7,0.5s0.3,0.4,0.3,0.7c0,0.2,0.1,0.5,0.1,1v1.4c0,1,0,1.6,0.1,1.9  s0.1,0.5,0.3,0.7H413C412.9,168,412.9,167.8,412.8,167.5z M412.7,165.1c-0.4,0.2-1,0.3-1.7,0.4c-0.4,0.1-0.7,0.1-0.9,0.2  c-0.2,0.1-0.3,0.2-0.4,0.3s-0.1,0.3-0.1,0.5c0,0.3,0.1,0.5,0.3,0.7s0.5,0.3,0.9,0.3c0.4,0,0.8-0.1,1.1-0.3s0.5-0.4,0.7-0.7  c0.1-0.2,0.2-0.6,0.2-1.1V165.1z"/>
<path d="M415.7,168.2v-5.4h-0.9V162h0.9v-0.7c0-0.4,0-0.7,0.1-0.9c0.1-0.3,0.3-0.5,0.5-0.7s0.6-0.3,1.1-0.3c0.3,0,0.6,0,1,0.1  l-0.2,0.9c-0.2,0-0.4-0.1-0.6-0.1c-0.3,0-0.5,0.1-0.7,0.2s-0.2,0.4-0.2,0.8v0.6h1.2v0.8h-1.2v5.4H415.7z"/>
<path d="M419.7,168.2h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1s0.2,0.8,0.2,1.3  c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V168.2z M419.7,165.1c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  C419.9,163.8,419.7,164.3,419.7,165.1z"/>
<path d="M426.8,163.6c-0.4-0.2-0.8-0.4-1-0.7s-0.3-0.7-0.3-1.1c0-0.6,0.2-1.2,0.7-1.6s1-0.6,1.8-0.6c0.8,0,1.4,0.2,1.8,0.7  s0.7,1,0.7,1.6c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-1,0.7c0.5,0.2,0.9,0.4,1.2,0.8s0.4,0.8,0.4,1.4c0,0.7-0.3,1.4-0.8,1.9  s-1.2,0.8-2.1,0.8s-1.5-0.3-2-0.8s-0.8-1.1-0.8-1.9c0-0.6,0.1-1,0.4-1.4S426.2,163.7,426.8,163.6z M426.2,165.8  c0,0.3,0.1,0.6,0.2,0.9s0.4,0.5,0.6,0.7c0.3,0.2,0.6,0.2,0.9,0.2c0.5,0,0.9-0.2,1.2-0.5s0.5-0.7,0.5-1.2c0-0.5-0.2-0.9-0.5-1.3  s-0.8-0.5-1.3-0.5c-0.5,0-0.9,0.2-1.2,0.5C426.4,164.9,426.2,165.3,426.2,165.8z M426.6,161.8c0,0.4,0.1,0.7,0.4,1  c0.3,0.3,0.6,0.4,1,0.4c0.4,0,0.7-0.1,1-0.4s0.4-0.6,0.4-0.9c0-0.4-0.1-0.7-0.4-1s-0.6-0.4-1-0.4c-0.4,0-0.7,0.1-1,0.4  S426.6,161.4,426.6,161.8z"/>
<path d="M435.8,168.2h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1s0.8-0.8,0.9-1.1h0.7V168.2z"/>
<path d="M444,167.2v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1s0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8s0.5-0.9,0.5-1.3  c0-0.4-0.1-0.8-0.4-1.1s-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5c-0.3,0.3-0.5,0.7-0.5,1.3l-1.1-0.1c0.1-0.8,0.4-1.4,0.8-1.8  s1.1-0.6,2-0.6c0.8,0,1.5,0.2,2,0.7s0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1s-0.4,0.7-0.7,1s-0.9,0.9-1.6,1.5c-0.6,0.5-1,0.9-1.2,1.1  c-0.2,0.2-0.3,0.4-0.4,0.6H444z"/>
<path d="M450.7,167.2v1H445c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1s0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8s0.5-0.9,0.5-1.3  c0-0.4-0.1-0.8-0.4-1.1s-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5c-0.3,0.3-0.5,0.7-0.5,1.3l-1.1-0.1c0.1-0.8,0.4-1.4,0.8-1.8  s1.1-0.6,2-0.6c0.8,0,1.5,0.2,2,0.7s0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1s-0.4,0.7-0.7,1s-0.9,0.9-1.6,1.5c-0.6,0.5-1,0.9-1.2,1.1  c-0.2,0.2-0.3,0.4-0.4,0.6H450.7z"/>
<path d="M456.4,166.2l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5s-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8s-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4s1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8s0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6c0,0.7,0.2,1.2,0.6,1.6  c0.3,0.4,0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3S456.2,166.7,456.4,166.2z M452.9,164.5h3.5c0-0.5-0.2-0.9-0.4-1.2  c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5C453.1,163.6,453,164,452.9,164.5z"/>
<path d="M415.2,176.2l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H415.2z M417.2,176.2l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H417.2z"/>
<path d="M425.7,178.7l1.1,0.3c-0.2,0.9-0.7,1.6-1.3,2.1c-0.6,0.5-1.4,0.7-2.3,0.7c-0.9,0-1.7-0.2-2.3-0.6c-0.6-0.4-1-0.9-1.3-1.6  s-0.5-1.5-0.5-2.3c0-0.9,0.2-1.7,0.5-2.3s0.8-1.2,1.5-1.5c0.6-0.3,1.3-0.5,2.1-0.5c0.9,0,1.6,0.2,2.2,0.7c0.6,0.4,1,1.1,1.2,1.8  l-1.1,0.3c-0.2-0.6-0.5-1.1-0.9-1.4s-0.9-0.4-1.4-0.4c-0.7,0-1.2,0.2-1.7,0.5s-0.8,0.7-0.9,1.3c-0.2,0.5-0.3,1.1-0.3,1.6  c0,0.7,0.1,1.4,0.3,1.9c0.2,0.5,0.5,1,1,1.2s0.9,0.4,1.5,0.4c0.6,0,1.2-0.2,1.6-0.6S425.5,179.5,425.7,178.7z"/>
<path d="M432.2,181c-0.4,0.3-0.8,0.6-1.1,0.7s-0.7,0.2-1.2,0.2c-0.7,0-1.2-0.2-1.6-0.5s-0.6-0.8-0.6-1.3c0-0.3,0.1-0.6,0.2-0.8  s0.3-0.5,0.5-0.6s0.5-0.3,0.8-0.3c0.2-0.1,0.5-0.1,0.9-0.2c0.9-0.1,1.5-0.2,1.9-0.4c0-0.1,0-0.2,0-0.3c0-0.4-0.1-0.7-0.3-0.9  c-0.3-0.2-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.1-1.1,0.3c-0.2,0.2-0.4,0.5-0.5,0.9l-1-0.1c0.1-0.4,0.2-0.8,0.5-1.1s0.5-0.5,0.9-0.6  c0.4-0.1,0.9-0.2,1.4-0.2c0.5,0,1,0.1,1.3,0.2s0.6,0.3,0.7,0.5s0.3,0.4,0.3,0.7c0,0.2,0.1,0.5,0.1,1v1.4c0,1,0,1.6,0.1,1.9  s0.1,0.5,0.3,0.7h-1.1C432.3,181.5,432.2,181.3,432.2,181z M432.1,178.6c-0.4,0.2-1,0.3-1.7,0.4c-0.4,0.1-0.7,0.1-0.9,0.2  c-0.2,0.1-0.3,0.2-0.4,0.3s-0.1,0.3-0.1,0.5c0,0.3,0.1,0.5,0.3,0.7s0.5,0.3,0.9,0.3c0.4,0,0.8-0.1,1.1-0.3s0.5-0.4,0.7-0.7  c0.1-0.2,0.2-0.6,0.2-1.1V178.6z"/>
<path d="M434.8,181.8v-6.2h0.9v0.9c0.2-0.4,0.5-0.7,0.7-0.9c0.2-0.1,0.4-0.2,0.7-0.2c0.4,0,0.7,0.1,1.1,0.3l-0.4,1  c-0.3-0.2-0.5-0.2-0.8-0.2c-0.2,0-0.4,0.1-0.6,0.2s-0.3,0.3-0.4,0.6c-0.1,0.4-0.2,0.8-0.2,1.2v3.3H434.8z"/>
<path d="M438.4,178.6c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8s0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  s-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8S438.4,179.7,438.4,178.6z M439.5,178.6c0,0.8,0.2,1.4,0.5,1.8  c0.3,0.4,0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7s-0.8-0.6-1.3-0.6c-0.5,0-1,0.2-1.3,0.6  C439.6,177.2,439.5,177.8,439.5,178.6z"/>
<path d="M445.4,181.8v-8.6h1.1v8.6H445.4z"/>
<path d="M448.2,176.2l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H448.2z M450.1,176.2l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H450.1z"/>
<rect x="370.7" y="157.8" fill-rule="evenodd" fill="none" width="124.5" height="27"/>
<path fill="none" stroke="#000000" stroke-width="2.2498" d="M201,269.5h52.6c0.7,0,1.4,0,2.1,0.1c0.7,0.1,1.4,0.2,2,0.3  c0.7,0.1,1.3,0.3,2,0.5c0.7,0.2,1.3,0.4,1.9,0.7c0.6,0.3,1.3,0.6,1.9,0.9c0.6,0.3,1.2,0.7,1.8,1.1c0.6,0.4,1.1,0.8,1.7,1.2  s1,0.9,1.5,1.4c0.5,0.5,0.9,1,1.4,1.5c0.4,0.5,0.8,1.1,1.2,1.7c0.4,0.6,0.7,1.2,1.1,1.8c0.3,0.6,0.6,1.2,0.9,1.9  c0.3,0.6,0.5,1.3,0.7,1.9c0.2,0.7,0.4,1.3,0.5,2s0.2,1.4,0.3,2c0.1,0.7,0.1,1.4,0.1,2.1s0,1.4-0.1,2.1c-0.1,0.7-0.2,1.4-0.3,2  s-0.3,1.3-0.5,2c-0.2,0.7-0.4,1.3-0.7,1.9c-0.3,0.6-0.6,1.3-0.9,1.9c-0.3,0.6-0.7,1.2-1.1,1.8c-0.4,0.6-0.8,1.1-1.2,1.7  c-0.4,0.5-0.9,1-1.4,1.5c-0.5,0.5-1,0.9-1.5,1.4s-1.1,0.8-1.7,1.2c-0.6,0.4-1.2,0.7-1.8,1.1c-0.6,0.3-1.2,0.6-1.9,0.9  c-0.6,0.3-1.3,0.5-1.9,0.7c-0.7,0.2-1.3,0.4-2,0.5c-0.7,0.1-1.4,0.2-2,0.3c-0.7,0.1-1.4,0.1-2.1,0.1H201c-0.7,0-1.4,0-2.1-0.1  c-0.7-0.1-1.4-0.2-2-0.3c-0.7-0.1-1.3-0.3-2-0.5c-0.7-0.2-1.3-0.4-1.9-0.7c-0.6-0.3-1.3-0.6-1.9-0.9s-1.2-0.7-1.8-1.1  c-0.6-0.4-1.1-0.8-1.7-1.2s-1-0.9-1.5-1.4s-0.9-1-1.4-1.5c-0.4-0.5-0.8-1.1-1.2-1.7c-0.4-0.6-0.7-1.2-1.1-1.8  c-0.3-0.6-0.6-1.2-0.9-1.9c-0.3-0.6-0.5-1.3-0.7-1.9c-0.2-0.7-0.4-1.3-0.5-2c-0.1-0.7-0.2-1.4-0.3-2s-0.1-1.4-0.1-2.1s0-1.4,0.1-2.1  c0.1-0.7,0.2-1.4,0.3-2c0.1-0.7,0.3-1.3,0.5-2c0.2-0.7,0.4-1.3,0.7-1.9c0.3-0.6,0.6-1.3,0.9-1.9c0.3-0.6,0.7-1.2,1.1-1.8  c0.4-0.6,0.8-1.1,1.2-1.7c0.4-0.5,0.9-1,1.4-1.5s1-0.9,1.5-1.4s1.1-0.8,1.7-1.2c0.6-0.4,1.2-0.7,1.8-1.1s1.2-0.6,1.9-0.9  c0.6-0.3,1.3-0.5,1.9-0.7c0.7-0.2,1.3-0.4,2-0.5c0.7-0.1,1.4-0.2,2-0.3C199.6,269.5,200.3,269.5,201,269.5z"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="489.8" height="491.2"/>
<path d="M207.3,281l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  s-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9s0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8c0.5,0.5,0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5  s-0.6,0.8-1,1.1s-0.9,0.4-1.4,0.4c-0.9,0-1.6-0.3-2.1-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6c0.5-0.7,1.3-1,2.2-1  c0.7,0,1.2,0.2,1.7,0.6C206.9,279.8,207.2,280.3,207.3,281z M203,284.7c0,0.4,0.1,0.7,0.2,1s0.4,0.6,0.6,0.8s0.6,0.3,0.9,0.3  c0.4,0,0.8-0.2,1.1-0.5s0.5-0.8,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.5S203,284.2,203,284.7z"/>
<path d="M208.5,285.2l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2s0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6s0.5-0.9,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4s-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2s-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4l-0.5,2.3  c0.5-0.4,1.1-0.5,1.6-0.5c0.8,0,1.4,0.3,1.9,0.8c0.5,0.5,0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1  c-0.8,0-1.4-0.2-1.9-0.7C208.8,286.6,208.5,286,208.5,285.2z"/>
<path d="M219.5,285.2l1,0.1c-0.1,0.7-0.4,1.3-0.9,1.7c-0.5,0.4-1,0.6-1.7,0.6c-0.9,0-1.5-0.3-2.1-0.8c-0.5-0.6-0.8-1.4-0.8-2.4  c0-0.7,0.1-1.3,0.3-1.8s0.6-0.9,1-1.1s1-0.4,1.5-0.4c0.7,0,1.2,0.2,1.7,0.5s0.7,0.8,0.8,1.5l-1,0.2c-0.1-0.4-0.3-0.7-0.5-0.9  s-0.5-0.3-0.9-0.3c-0.5,0-1,0.2-1.3,0.6s-0.5,1-0.5,1.8c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.3,0.6c0.4,0,0.8-0.1,1-0.4  S219.4,285.7,219.5,285.2z"/>
<path d="M221.1,285.2l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3s0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5s0.5-0.8,0.5-1.3c0-0.5-0.2-0.9-0.5-1.2  s-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1l0.1-0.9c0.1,0,0.1,0,0.2,0c0.4,0,0.9-0.1,1.2-0.4s0.5-0.6,0.5-1.1c0-0.4-0.1-0.7-0.4-1  s-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4s-0.4,0.6-0.5,1.2l-1.1-0.2c0.1-0.7,0.4-1.3,0.9-1.6c0.5-0.4,1-0.6,1.7-0.6  c0.5,0,0.9,0.1,1.3,0.3s0.7,0.5,0.9,0.8c0.2,0.3,0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-0.9,0.7c0.5,0.1,0.9,0.4,1.2,0.7  c0.3,0.4,0.4,0.8,0.4,1.4c0,0.8-0.3,1.4-0.8,1.9c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7  C221.5,286.5,221.2,285.9,221.1,285.2z"/>
<path d="M232.4,285.5l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5c-0.5,0.4-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8c-0.5-0.6-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4c0.5-0.6,1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8c0.5,0.6,0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6  c0,0.7,0.2,1.2,0.6,1.6s0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3S232.2,285.9,232.4,285.5z M228.9,283.8h3.5c0-0.5-0.2-0.9-0.4-1.2  c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5S228.9,283.2,228.9,283.8z"/>
<path d="M235.7,287.5h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5c-0.5,0.6-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V287.5z M235.7,284.3  c0,0.7,0.1,1.3,0.3,1.6c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6S235.7,283.6,235.7,284.3z"/>
<path d="M245.5,285.2l1,0.1c-0.1,0.7-0.4,1.3-0.9,1.7c-0.5,0.4-1,0.6-1.7,0.6c-0.9,0-1.5-0.3-2.1-0.8c-0.5-0.6-0.8-1.4-0.8-2.4  c0-0.7,0.1-1.3,0.3-1.8s0.6-0.9,1-1.1s1-0.4,1.5-0.4c0.7,0,1.2,0.2,1.7,0.5s0.7,0.8,0.8,1.5l-1,0.2c-0.1-0.4-0.3-0.7-0.5-0.9  s-0.5-0.3-0.9-0.3c-0.5,0-1,0.2-1.3,0.6s-0.5,1-0.5,1.8c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.3,0.6c0.4,0,0.8-0.1,1-0.4  S245.4,285.7,245.5,285.2z"/>
<path d="M247.2,285.2l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3s0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5s0.5-0.8,0.5-1.3c0-0.5-0.2-0.9-0.5-1.2  s-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1l0.1-0.9c0.1,0,0.1,0,0.2,0c0.4,0,0.9-0.1,1.2-0.4s0.5-0.6,0.5-1.1c0-0.4-0.1-0.7-0.4-1  s-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4s-0.4,0.6-0.5,1.2l-1.1-0.2c0.1-0.7,0.4-1.3,0.9-1.6c0.5-0.4,1-0.6,1.7-0.6  c0.5,0,0.9,0.1,1.3,0.3s0.7,0.5,0.9,0.8c0.2,0.3,0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-0.9,0.7c0.5,0.1,0.9,0.4,1.2,0.7  c0.3,0.4,0.4,0.8,0.4,1.4c0,0.8-0.3,1.4-0.8,1.9c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7  C247.5,286.5,247.2,285.9,247.2,285.2z"/>
<path d="M192.7,301l3.3-8.6h1.2l3.5,8.6h-1.3l-1-2.6h-3.6l-0.9,2.6H192.7z M195.2,297.5h2.9l-0.9-2.4c-0.3-0.7-0.5-1.3-0.6-1.8  c-0.1,0.6-0.3,1.1-0.5,1.6L195.2,297.5z"/>
<path d="M201.3,298.2l1.1-0.1c0.1,0.4,0.2,0.8,0.4,1.1s0.5,0.5,0.9,0.7c0.4,0.2,0.8,0.3,1.3,0.3c0.4,0,0.8-0.1,1.1-0.2  c0.3-0.1,0.6-0.3,0.7-0.5s0.2-0.5,0.2-0.7c0-0.3-0.1-0.5-0.2-0.7s-0.4-0.4-0.8-0.5c-0.2-0.1-0.7-0.2-1.5-0.4  c-0.8-0.2-1.3-0.4-1.7-0.5c-0.4-0.2-0.7-0.5-0.9-0.8s-0.3-0.7-0.3-1.1c0-0.4,0.1-0.8,0.4-1.2c0.2-0.4,0.6-0.7,1.1-0.9s1-0.3,1.6-0.3  c0.6,0,1.2,0.1,1.7,0.3c0.5,0.2,0.9,0.5,1.1,0.9s0.4,0.8,0.4,1.4l-1.1,0.1c-0.1-0.5-0.3-1-0.6-1.2c-0.3-0.3-0.8-0.4-1.5-0.4  c-0.7,0-1.2,0.1-1.5,0.4s-0.5,0.6-0.5,0.9c0,0.3,0.1,0.6,0.3,0.8c0.2,0.2,0.8,0.4,1.7,0.6c0.9,0.2,1.6,0.4,1.9,0.5  c0.5,0.2,0.9,0.5,1.1,0.9s0.4,0.8,0.4,1.2c0,0.5-0.1,0.9-0.4,1.3s-0.6,0.7-1.1,0.9c-0.5,0.2-1,0.3-1.7,0.3c-0.8,0-1.4-0.1-2-0.3  s-0.9-0.6-1.2-1C201.5,299.3,201.3,298.8,201.3,298.2z"/>
<path d="M209.3,298.2l1.1-0.1c0.1,0.4,0.2,0.8,0.4,1.1s0.5,0.5,0.9,0.7c0.4,0.2,0.8,0.3,1.3,0.3c0.4,0,0.8-0.1,1.1-0.2  c0.3-0.1,0.6-0.3,0.7-0.5s0.2-0.5,0.2-0.7c0-0.3-0.1-0.5-0.2-0.7s-0.4-0.4-0.8-0.5c-0.2-0.1-0.7-0.2-1.5-0.4  c-0.8-0.2-1.3-0.4-1.7-0.5c-0.4-0.2-0.7-0.5-0.9-0.8s-0.3-0.7-0.3-1.1c0-0.4,0.1-0.8,0.4-1.2c0.2-0.4,0.6-0.7,1.1-0.9s1-0.3,1.6-0.3  c0.6,0,1.2,0.1,1.7,0.3c0.5,0.2,0.9,0.5,1.1,0.9s0.4,0.8,0.4,1.4l-1.1,0.1c-0.1-0.5-0.3-1-0.6-1.2c-0.3-0.3-0.8-0.4-1.5-0.4  c-0.7,0-1.2,0.1-1.5,0.4s-0.5,0.6-0.5,0.9c0,0.3,0.1,0.6,0.3,0.8c0.2,0.2,0.8,0.4,1.7,0.6c0.9,0.2,1.6,0.4,1.9,0.5  c0.5,0.2,0.9,0.5,1.1,0.9s0.4,0.8,0.4,1.2c0,0.5-0.1,0.9-0.4,1.3s-0.6,0.7-1.1,0.9c-0.5,0.2-1,0.3-1.7,0.3c-0.8,0-1.4-0.1-2-0.3  s-0.9-0.6-1.2-1C209.5,299.3,209.3,298.8,209.3,298.2z"/>
<path d="M217.7,301v-8.6h6.2v1h-5.1v2.6h4.8v1h-4.8v2.9h5.3v1H217.7z"/>
<path d="M225.7,301v-8.6h3.8c0.8,0,1.3,0.1,1.7,0.2s0.7,0.4,1,0.8c0.2,0.4,0.4,0.8,0.4,1.3c0,0.6-0.2,1.1-0.6,1.5s-1,0.7-1.8,0.8  c0.3,0.1,0.5,0.3,0.7,0.4c0.3,0.3,0.6,0.7,0.9,1.1l1.5,2.3h-1.4l-1.1-1.8c-0.3-0.5-0.6-0.9-0.8-1.2s-0.4-0.5-0.6-0.6  s-0.3-0.2-0.5-0.2c-0.1,0-0.3,0-0.6,0h-1.3v3.8H225.7z M226.8,296.2h2.4c0.5,0,0.9-0.1,1.2-0.2c0.3-0.1,0.5-0.3,0.7-0.5  s0.2-0.5,0.2-0.8c0-0.4-0.1-0.7-0.4-1s-0.8-0.4-1.4-0.4h-2.7V296.2z"/>
<path d="M236.3,301v-7.6h-2.8v-1h6.8v1h-2.8v7.6H236.3z"/>
<path d="M241.7,301v-8.6h1.1v8.6H241.7z"/>
<path d="M244.4,296.8c0-1.4,0.4-2.5,1.1-3.3c0.8-0.8,1.8-1.2,3-1.2c0.8,0,1.5,0.2,2.1,0.6s1.1,0.9,1.5,1.6s0.5,1.4,0.5,2.3  c0,0.9-0.2,1.7-0.5,2.3c-0.4,0.7-0.8,1.2-1.5,1.6s-1.3,0.5-2.1,0.5c-0.8,0-1.5-0.2-2.2-0.6c-0.6-0.4-1.1-0.9-1.4-1.6  C244.6,298.3,244.4,297.6,244.4,296.8z M245.6,296.8c0,1,0.3,1.9,0.8,2.4s1.3,0.9,2.1,0.9c0.9,0,1.6-0.3,2.1-0.9s0.8-1.5,0.8-2.6  c0-0.7-0.1-1.3-0.4-1.8s-0.6-0.9-1-1.2s-1-0.4-1.5-0.4c-0.8,0-1.5,0.3-2.1,0.8S245.6,295.5,245.6,296.8z"/>
<path d="M254.1,301v-8.6h1.2l4.5,6.7v-6.7h1.1v8.6h-1.2l-4.5-6.8v6.8H254.1z"/>
<rect x="192.7" y="277" fill-rule="evenodd" fill="none" width="69" height="27"/>
<rect x="360.6" y="229.8" fill="none" stroke="#000000" stroke-width="2.2498" width="144.8" height="42"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="489.8" height="491.2"/>
<path d="M411.5,247.8V247c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2c0.4-0.3,0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6v-3.1h1v8.6H411.5z M408.1,244.6  c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C408.3,243.2,408.1,243.8,408.1,244.6z"/>
<path d="M415.1,247.8h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1s0.2,0.8,0.2,1.3  c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V247.8z M415.1,244.6c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  C415.2,243.3,415.1,243.8,415.1,244.6z"/>
<path d="M420.6,240.3v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  c0.3-1,0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H420.6z"/>
<path d="M431.5,247.8V247c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2c0.4-0.3,0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6v-3.1h1v8.6H431.5z M428.2,244.6  c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C428.3,243.2,428.2,243.8,428.2,244.6z"/>
<path d="M438.2,247.8V247c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2c0.4-0.3,0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6v-3.1h1v8.6H438.2z M434.8,244.6  c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C435,243.2,434.8,243.8,434.8,244.6z"/>
<path d="M446,246.7v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1s0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8s0.5-0.9,0.5-1.3  c0-0.4-0.1-0.8-0.4-1.1s-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5c-0.3,0.3-0.5,0.7-0.5,1.3l-1.1-0.1c0.1-0.8,0.4-1.4,0.8-1.8  s1.1-0.6,2-0.6c0.8,0,1.5,0.2,2,0.7s0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1s-0.4,0.7-0.7,1s-0.9,0.9-1.6,1.5c-0.6,0.5-1,0.9-1.2,1.1  c-0.2,0.2-0.3,0.4-0.4,0.6H446z"/>
<path d="M451.1,247.8h-1.1V241c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1s0.8-0.8,0.9-1.1h0.7V247.8z"/>
<path d="M458.2,245.5l1,0.1c-0.1,0.7-0.4,1.3-0.9,1.7s-1,0.6-1.7,0.6c-0.9,0-1.5-0.3-2.1-0.8s-0.8-1.4-0.8-2.4  c0-0.7,0.1-1.3,0.3-1.8s0.6-0.9,1-1.1c0.5-0.3,0.9-0.4,1.5-0.4c0.7,0,1.2,0.2,1.7,0.5s0.7,0.8,0.8,1.5l-1,0.2  c-0.1-0.4-0.3-0.7-0.5-0.9s-0.5-0.3-0.9-0.3c-0.5,0-1,0.2-1.3,0.6c-0.3,0.4-0.5,1-0.5,1.8c0,0.8,0.2,1.4,0.5,1.8  c0.3,0.4,0.7,0.6,1.3,0.6c0.4,0,0.8-0.1,1-0.4S458.1,246,458.2,245.5z"/>
<path d="M412.6,255.7l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H412.6z M414.5,255.7l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H414.5z"/>
<path d="M416.8,261.2v-8.6h1.1v4.9l2.5-2.5h1.4l-2.4,2.3l2.6,3.9h-1.3l-2.1-3.2l-0.7,0.7v2.5H416.8z"/>
<path d="M422.8,261.2V255h0.9v0.9c0.5-0.7,1.1-1,2-1c0.4,0,0.7,0.1,1,0.2s0.5,0.3,0.7,0.5s0.3,0.5,0.3,0.8c0,0.2,0.1,0.5,0.1,1v3.8  h-1.1v-3.8c0-0.4,0-0.8-0.1-1s-0.2-0.4-0.4-0.5s-0.5-0.2-0.7-0.2c-0.4,0-0.8,0.1-1.2,0.4c-0.3,0.3-0.5,0.8-0.5,1.6v3.4H422.8z"/>
<path d="M429.1,258.1c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8s0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  s-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8S429.1,259.2,429.1,258.1z M430.1,258.1c0,0.8,0.2,1.4,0.5,1.8  c0.3,0.4,0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7s-0.8-0.6-1.3-0.6c-0.5,0-1,0.2-1.3,0.6  C430.3,256.7,430.1,257.3,430.1,258.1z"/>
<path d="M437.3,261.2l-1.9-6.2h1.1l1,3.6l0.4,1.3c0-0.1,0.1-0.5,0.3-1.3l1-3.6h1.1l0.9,3.6l0.3,1.2l0.4-1.2l1.1-3.6h1l-1.9,6.2h-1.1  l-1-3.7l-0.2-1.1l-1.3,4.8H437.3z"/>
<path d="M444.4,259.4l1-0.2c0.1,0.4,0.2,0.7,0.5,1c0.3,0.2,0.6,0.3,1.1,0.3c0.5,0,0.8-0.1,1.1-0.3s0.4-0.4,0.4-0.7  c0-0.2-0.1-0.4-0.3-0.6c-0.1-0.1-0.5-0.2-1.1-0.4c-0.8-0.2-1.3-0.4-1.6-0.5s-0.5-0.3-0.7-0.6s-0.2-0.5-0.2-0.8  c0-0.3,0.1-0.5,0.2-0.8s0.3-0.4,0.5-0.6c0.2-0.1,0.4-0.2,0.7-0.3c0.3-0.1,0.6-0.1,0.9-0.1c0.5,0,0.9,0.1,1.3,0.2s0.6,0.3,0.8,0.6  s0.3,0.6,0.4,1l-1,0.1c0-0.3-0.2-0.6-0.4-0.8s-0.5-0.3-1-0.3c-0.5,0-0.8,0.1-1,0.2s-0.3,0.3-0.3,0.6c0,0.1,0,0.3,0.1,0.4  c0.1,0.1,0.2,0.2,0.4,0.3c0.1,0,0.4,0.1,0.9,0.3c0.7,0.2,1.3,0.4,1.6,0.5s0.5,0.3,0.7,0.6s0.3,0.5,0.3,0.9c0,0.4-0.1,0.7-0.3,1  s-0.5,0.6-0.9,0.7s-0.8,0.3-1.3,0.3c-0.8,0-1.4-0.2-1.8-0.5S444.5,260.1,444.4,259.4z"/>
<path d="M450.8,255.7l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H450.8z M452.8,255.7l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H452.8z"/>
<rect x="368.1" y="237.2" fill-rule="evenodd" fill="none" width="129.7" height="27"/>
<rect x="357.2" y="309.2" fill="none" stroke="#000000" stroke-width="2.2498" width="151.5" height="42"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="489.8" height="491.2"/>
<path d="M413,325.2l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5s-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8s-0.8-1.3-0.8-2.4c0-1,0.3-1.9,0.8-2.4  s1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8s0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6c0,0.7,0.2,1.2,0.6,1.6c0.3,0.4,0.8,0.5,1.3,0.5  c0.4,0,0.7-0.1,1-0.3S412.9,325.7,413,325.2z M409.6,323.5h3.5c0-0.5-0.2-0.9-0.4-1.2c-0.3-0.4-0.8-0.6-1.3-0.6  c-0.5,0-0.9,0.2-1.2,0.5C409.8,322.6,409.6,323,409.6,323.5z"/>
<path d="M415.3,325.3l1-0.1c0.1,0.5,0.2,0.8,0.5,1c0.2,0.2,0.6,0.3,0.9,0.3c0.3,0,0.6-0.1,0.9-0.2s0.4-0.3,0.6-0.6s0.3-0.6,0.4-1  s0.2-0.9,0.2-1.3c0,0,0-0.1,0-0.2c-0.2,0.3-0.5,0.6-0.9,0.8s-0.8,0.3-1.2,0.3c-0.7,0-1.3-0.3-1.8-0.8s-0.7-1.2-0.7-2  c0-0.9,0.3-1.6,0.8-2.1s1.2-0.8,1.9-0.8c0.6,0,1.1,0.2,1.5,0.5s0.8,0.7,1.1,1.3s0.4,1.4,0.4,2.4c0,1.1-0.1,2-0.4,2.6  s-0.6,1.1-1.1,1.5s-1,0.5-1.7,0.5c-0.7,0-1.2-0.2-1.6-0.6S415.4,325.9,415.3,325.3z M419.6,321.5c0-0.6-0.2-1.1-0.5-1.4  s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.6c-0.3,0.4-0.5,0.9-0.5,1.5c0,0.5,0.2,1,0.5,1.3c0.3,0.3,0.7,0.5,1.2,0.5  c0.5,0,0.9-0.2,1.2-0.5S419.6,322.1,419.6,321.5z"/>
<path d="M426.2,326.5c-0.4,0.3-0.8,0.6-1.1,0.7s-0.7,0.2-1.2,0.2c-0.7,0-1.2-0.2-1.6-0.5s-0.6-0.8-0.6-1.3c0-0.3,0.1-0.6,0.2-0.8  s0.3-0.5,0.5-0.6s0.5-0.3,0.8-0.3c0.2-0.1,0.5-0.1,0.9-0.2c0.9-0.1,1.5-0.2,1.9-0.4c0-0.1,0-0.2,0-0.3c0-0.4-0.1-0.7-0.3-0.9  c-0.3-0.2-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.1-1.1,0.3c-0.2,0.2-0.4,0.5-0.5,0.9l-1-0.1c0.1-0.4,0.2-0.8,0.5-1.1s0.5-0.5,0.9-0.6  c0.4-0.1,0.9-0.2,1.4-0.2c0.5,0,1,0.1,1.3,0.2s0.6,0.3,0.7,0.5s0.3,0.4,0.3,0.7c0,0.2,0.1,0.5,0.1,1v1.4c0,1,0,1.6,0.1,1.9  s0.1,0.5,0.3,0.7h-1.1C426.3,327,426.2,326.8,426.2,326.5z M426.1,324.1c-0.4,0.2-1,0.3-1.7,0.4c-0.4,0.1-0.7,0.1-0.9,0.2  c-0.2,0.1-0.3,0.2-0.4,0.3s-0.1,0.3-0.1,0.5c0,0.3,0.1,0.5,0.3,0.7s0.5,0.3,0.9,0.3c0.4,0,0.8-0.1,1.1-0.3s0.5-0.4,0.7-0.7  c0.1-0.2,0.2-0.6,0.2-1.1V324.1z"/>
<path d="M429,327.2v-5.4h-0.9V321h0.9v-0.7c0-0.4,0-0.7,0.1-0.9c0.1-0.3,0.3-0.5,0.5-0.7s0.6-0.3,1.1-0.3c0.3,0,0.6,0,1,0.1  l-0.2,0.9c-0.2,0-0.4-0.1-0.6-0.1c-0.3,0-0.5,0.1-0.7,0.2s-0.2,0.4-0.2,0.8v0.6h1.2v0.8h-1.2v5.4H429z"/>
<path d="M431.9,319.8v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  c0.3-1,0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H431.9z"/>
<path d="M440.1,322.6c-0.4-0.2-0.8-0.4-1-0.7s-0.3-0.7-0.3-1.1c0-0.6,0.2-1.2,0.7-1.6s1-0.6,1.8-0.6c0.8,0,1.4,0.2,1.8,0.7  s0.7,1,0.7,1.6c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-1,0.7c0.5,0.2,0.9,0.4,1.2,0.8s0.4,0.8,0.4,1.4c0,0.7-0.3,1.4-0.8,1.9  s-1.2,0.8-2.1,0.8s-1.5-0.3-2-0.8s-0.8-1.1-0.8-1.9c0-0.6,0.1-1,0.4-1.4S439.6,322.7,440.1,322.6z M439.6,324.8  c0,0.3,0.1,0.6,0.2,0.9s0.4,0.5,0.6,0.7c0.3,0.2,0.6,0.2,0.9,0.2c0.5,0,0.9-0.2,1.2-0.5s0.5-0.7,0.5-1.2c0-0.5-0.2-0.9-0.5-1.3  s-0.8-0.5-1.3-0.5c-0.5,0-0.9,0.2-1.2,0.5C439.7,323.9,439.6,324.3,439.6,324.8z M439.9,320.8c0,0.4,0.1,0.7,0.4,1  c0.3,0.3,0.6,0.4,1,0.4c0.4,0,0.7-0.1,1-0.4s0.4-0.6,0.4-0.9c0-0.4-0.1-0.7-0.4-1s-0.6-0.4-1-0.4c-0.4,0-0.7,0.1-1,0.4  S439.9,320.4,439.9,320.8z"/>
<path d="M446.8,322.6c-0.4-0.2-0.8-0.4-1-0.7s-0.3-0.7-0.3-1.1c0-0.6,0.2-1.2,0.7-1.6s1-0.6,1.8-0.6c0.8,0,1.4,0.2,1.8,0.7  s0.7,1,0.7,1.6c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-1,0.7c0.5,0.2,0.9,0.4,1.2,0.8s0.4,0.8,0.4,1.4c0,0.7-0.3,1.4-0.8,1.9  s-1.2,0.8-2.1,0.8s-1.5-0.3-2-0.8s-0.8-1.1-0.8-1.9c0-0.6,0.1-1,0.4-1.4S446.3,322.7,446.8,322.6z M446.2,324.8  c0,0.3,0.1,0.6,0.2,0.9s0.4,0.5,0.6,0.7c0.3,0.2,0.6,0.2,0.9,0.2c0.5,0,0.9-0.2,1.2-0.5s0.5-0.7,0.5-1.2c0-0.5-0.2-0.9-0.5-1.3  s-0.8-0.5-1.3-0.5c-0.5,0-0.9,0.2-1.2,0.5C446.4,323.9,446.2,324.3,446.2,324.8z M446.6,320.8c0,0.4,0.1,0.7,0.4,1  c0.3,0.3,0.6,0.4,1,0.4c0.4,0,0.7-0.1,1-0.4s0.4-0.6,0.4-0.9c0-0.4-0.1-0.7-0.4-1s-0.6-0.4-1-0.4c-0.4,0-0.7,0.1-1,0.4  S446.6,320.4,446.6,320.8z"/>
<path d="M451.8,325l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3c0.3,0.3,0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5s0.5-0.8,0.5-1.3  c0-0.5-0.2-0.9-0.5-1.2s-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1l0.1-0.9c0.1,0,0.1,0,0.2,0c0.4,0,0.9-0.1,1.2-0.4s0.5-0.6,0.5-1.1  c0-0.4-0.1-0.7-0.4-1s-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4c-0.3,0.3-0.4,0.6-0.5,1.2l-1.1-0.2c0.1-0.7,0.4-1.3,0.9-1.6  s1-0.6,1.7-0.6c0.5,0,0.9,0.1,1.3,0.3s0.7,0.5,0.9,0.8s0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-0.9,0.7  c0.5,0.1,0.9,0.4,1.2,0.7s0.4,0.8,0.4,1.4c0,0.8-0.3,1.4-0.8,1.9s-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7S451.9,325.7,451.8,325z"/>
<path d="M409.2,335.2l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H409.2z M411.2,335.2l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H411.2z"/>
<path d="M413.6,340.8v-8.6h6.2v1h-5.1v2.6h4.8v1h-4.8v2.9h5.3v1H413.6z"/>
<path d="M425.5,340.8V340c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2c0.4-0.3,0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6v-3.1h1v8.6H425.5z M422.1,337.6  c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C422.3,336.2,422.1,336.8,422.1,337.6z"/>
<path d="M429.3,340.8l-1.9-6.2h1.1l1,3.6l0.4,1.3c0-0.1,0.1-0.5,0.3-1.3l1-3.6h1.1l0.9,3.6l0.3,1.2l0.4-1.2l1.1-3.6h1l-1.9,6.2h-1.1  l-1-3.7l-0.2-1.1l-1.3,4.8H429.3z"/>
<path d="M440.8,340c-0.4,0.3-0.8,0.6-1.1,0.7s-0.7,0.2-1.2,0.2c-0.7,0-1.2-0.2-1.6-0.5s-0.6-0.8-0.6-1.3c0-0.3,0.1-0.6,0.2-0.8  s0.3-0.5,0.5-0.6s0.5-0.3,0.8-0.3c0.2-0.1,0.5-0.1,0.9-0.2c0.9-0.1,1.5-0.2,1.9-0.4c0-0.1,0-0.2,0-0.3c0-0.4-0.1-0.7-0.3-0.9  c-0.3-0.2-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.1-1.1,0.3c-0.2,0.2-0.4,0.5-0.5,0.9l-1-0.1c0.1-0.4,0.2-0.8,0.5-1.1s0.5-0.5,0.9-0.6  c0.4-0.1,0.9-0.2,1.4-0.2c0.5,0,1,0.1,1.3,0.2s0.6,0.3,0.7,0.5s0.3,0.4,0.3,0.7c0,0.2,0.1,0.5,0.1,1v1.4c0,1,0,1.6,0.1,1.9  s0.1,0.5,0.3,0.7H441C440.9,340.5,440.9,340.3,440.8,340z M440.8,337.6c-0.4,0.2-1,0.3-1.7,0.4c-0.4,0.1-0.7,0.1-0.9,0.2  c-0.2,0.1-0.3,0.2-0.4,0.3s-0.1,0.3-0.1,0.5c0,0.3,0.1,0.5,0.3,0.7s0.5,0.3,0.9,0.3c0.4,0,0.8-0.1,1.1-0.3s0.5-0.4,0.7-0.7  c0.1-0.2,0.2-0.6,0.2-1.1V337.6z"/>
<path d="M443.4,340.8v-6.2h0.9v0.9c0.2-0.4,0.5-0.7,0.7-0.9c0.2-0.1,0.4-0.2,0.7-0.2c0.4,0,0.7,0.1,1.1,0.3l-0.4,1  c-0.3-0.2-0.5-0.2-0.8-0.2c-0.2,0-0.4,0.1-0.6,0.2s-0.3,0.3-0.4,0.6c-0.1,0.4-0.2,0.8-0.2,1.2v3.3H443.4z"/>
<path d="M451.5,340.8V340c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2c0.4-0.3,0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6v-3.1h1v8.6H451.5z M448.2,337.6  c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C448.3,336.2,448.2,336.8,448.2,337.6z"/>
<path d="M454.2,335.2l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H454.2z M456.1,335.2l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H456.1z"/>
<rect x="364.7" y="316.8" fill-rule="evenodd" fill="none" width="136.5" height="27"/>
<path fill="none" stroke="#000000" stroke-width="2.2498" d="M201,428.5h52.6c0.7,0,1.4,0,2.1,0.1c0.7,0.1,1.4,0.2,2,0.3  c0.7,0.1,1.3,0.3,2,0.5c0.7,0.2,1.3,0.4,1.9,0.7c0.6,0.3,1.3,0.6,1.9,0.9c0.6,0.3,1.2,0.7,1.8,1.1c0.6,0.4,1.1,0.8,1.7,1.2  s1,0.9,1.5,1.4c0.5,0.5,0.9,1,1.4,1.5c0.4,0.5,0.8,1.1,1.2,1.7c0.4,0.6,0.7,1.2,1.1,1.8c0.3,0.6,0.6,1.2,0.9,1.9  c0.3,0.6,0.5,1.3,0.7,1.9s0.4,1.3,0.5,2s0.2,1.4,0.3,2c0.1,0.7,0.1,1.4,0.1,2.1s0,1.4-0.1,2.1c-0.1,0.7-0.2,1.4-0.3,2  s-0.3,1.3-0.5,2s-0.4,1.3-0.7,1.9c-0.3,0.6-0.6,1.3-0.9,1.9c-0.3,0.6-0.7,1.2-1.1,1.8c-0.4,0.6-0.8,1.1-1.2,1.7  c-0.4,0.5-0.9,1-1.4,1.5c-0.5,0.5-1,0.9-1.5,1.4s-1.1,0.8-1.7,1.2c-0.6,0.4-1.2,0.7-1.8,1.1c-0.6,0.3-1.2,0.6-1.9,0.9  c-0.6,0.3-1.3,0.5-1.9,0.7c-0.7,0.2-1.3,0.4-2,0.5c-0.7,0.1-1.4,0.2-2,0.3c-0.7,0.1-1.4,0.1-2.1,0.1H201c-0.7,0-1.4,0-2.1-0.1  c-0.7-0.1-1.4-0.2-2-0.3c-0.7-0.1-1.3-0.3-2-0.5c-0.7-0.2-1.3-0.4-1.9-0.7c-0.6-0.3-1.3-0.6-1.9-0.9s-1.2-0.7-1.8-1.1  c-0.6-0.4-1.1-0.8-1.7-1.2s-1-0.9-1.5-1.4s-0.9-1-1.4-1.5c-0.4-0.5-0.8-1.1-1.2-1.7c-0.4-0.6-0.7-1.2-1.1-1.8  c-0.3-0.6-0.6-1.2-0.9-1.9c-0.3-0.6-0.5-1.3-0.7-1.9c-0.2-0.7-0.4-1.3-0.5-2c-0.1-0.7-0.2-1.4-0.3-2c-0.1-0.7-0.1-1.4-0.1-2.1  s0-1.4,0.1-2.1c0.1-0.7,0.2-1.4,0.3-2c0.1-0.7,0.3-1.3,0.5-2c0.2-0.7,0.4-1.3,0.7-1.9c0.3-0.6,0.6-1.3,0.9-1.9  c0.3-0.6,0.7-1.2,1.1-1.8c0.4-0.6,0.8-1.1,1.2-1.7c0.4-0.5,0.9-1,1.4-1.5s1-0.9,1.5-1.4s1.1-0.8,1.7-1.2c0.6-0.4,1.2-0.7,1.8-1.1  s1.2-0.6,1.9-0.9c0.6-0.3,1.3-0.5,1.9-0.7c0.7-0.2,1.3-0.4,2-0.5c0.7-0.1,1.4-0.2,2-0.3C199.6,428.5,200.3,428.5,201,428.5z"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="489.8" height="491.2"/>
<path d="M201.2,439v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  s0.6-1.9,1.1-2.8c0.5-0.9,1-1.6,1.5-2.2H201.2z"/>
<path d="M209.4,441.8c-0.4-0.2-0.8-0.4-1-0.7c-0.2-0.3-0.3-0.7-0.3-1.1c0-0.6,0.2-1.2,0.7-1.6s1-0.6,1.8-0.6c0.7,0,1.4,0.2,1.8,0.7  s0.7,1,0.7,1.6c0,0.4-0.1,0.7-0.3,1c-0.2,0.3-0.5,0.5-1,0.7c0.5,0.2,0.9,0.4,1.2,0.8c0.3,0.4,0.4,0.8,0.4,1.4c0,0.7-0.3,1.4-0.8,1.9  c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.5-0.3-2.1-0.8c-0.5-0.5-0.8-1.1-0.8-1.9c0-0.6,0.1-1,0.4-1.4C208.5,442.2,208.9,442,209.4,441.8  z M208.9,444c0,0.3,0.1,0.6,0.2,0.9s0.4,0.5,0.6,0.7s0.6,0.2,0.9,0.2c0.5,0,0.9-0.2,1.2-0.5s0.5-0.7,0.5-1.2c0-0.5-0.2-0.9-0.5-1.3  s-0.8-0.5-1.3-0.5c-0.5,0-0.9,0.2-1.2,0.5S208.9,443.5,208.9,444z M209.2,440.1c0,0.4,0.1,0.7,0.4,1s0.6,0.4,1,0.4  c0.4,0,0.7-0.1,1-0.4s0.4-0.6,0.4-0.9c0-0.4-0.1-0.7-0.4-1s-0.6-0.4-1-0.4c-0.4,0-0.7,0.1-1,0.4S209.2,439.7,209.2,440.1z"/>
<path d="M218.8,446.5v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6v-3.1h1v8.6H218.8z M215.4,443.4c0,0.8,0.2,1.4,0.5,1.8  s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  S215.4,442.6,215.4,443.4z"/>
<path d="M226.6,440l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  s-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9s0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8c0.5,0.5,0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5  s-0.6,0.8-1,1.1s-0.9,0.4-1.4,0.4c-0.9,0-1.6-0.3-2.1-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6c0.5-0.7,1.3-1,2.2-1  c0.7,0,1.2,0.2,1.7,0.6C226.3,438.8,226.5,439.3,226.6,440z M222.3,443.7c0,0.4,0.1,0.7,0.2,1s0.4,0.6,0.6,0.8s0.6,0.3,0.9,0.3  c0.4,0,0.8-0.2,1.1-0.5s0.5-0.8,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.5S222.3,443.2,222.3,443.7z"/>
<path d="M233.3,440l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  s-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9s0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8c0.5,0.5,0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5  s-0.6,0.8-1,1.1s-0.9,0.4-1.4,0.4c-0.9,0-1.6-0.3-2.1-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6c0.5-0.7,1.3-1,2.2-1  c0.7,0,1.2,0.2,1.7,0.6C232.9,438.8,233.2,439.3,233.3,440z M229,443.7c0,0.4,0.1,0.7,0.2,1s0.4,0.6,0.6,0.8s0.6,0.3,0.9,0.3  c0.4,0,0.8-0.2,1.1-0.5s0.5-0.8,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.5S229,443.2,229,443.7z"/>
<path d="M239.9,440l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  s-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9s0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8c0.5,0.5,0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5  s-0.6,0.8-1,1.1s-0.9,0.4-1.4,0.4c-0.9,0-1.6-0.3-2.1-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6c0.5-0.7,1.3-1,2.2-1  c0.7,0,1.2,0.2,1.7,0.6C239.6,438.8,239.9,439.3,239.9,440z M235.6,443.7c0,0.4,0.1,0.7,0.2,1s0.4,0.6,0.6,0.8s0.6,0.3,0.9,0.3  c0.4,0,0.8-0.2,1.1-0.5s0.5-0.8,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.5S235.6,443.2,235.6,443.7z"/>
<path d="M245.7,444.5l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5c-0.5,0.4-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8c-0.5-0.6-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4c0.5-0.6,1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8c0.5,0.6,0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6  c0,0.7,0.2,1.2,0.6,1.6s0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3S245.5,444.9,245.7,444.5z M242.2,442.8h3.5c0-0.5-0.2-0.9-0.4-1.2  c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5S242.3,442.2,242.2,442.8z"/>
<path d="M249.1,446.5h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5c-0.5,0.6-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V446.5z M249.1,443.3  c0,0.7,0.1,1.3,0.3,1.6c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6S249.1,442.6,249.1,443.3z"/>
<path d="M192.7,460l3.3-8.6h1.2l3.5,8.6h-1.3l-1-2.6h-3.6l-0.9,2.6H192.7z M195.2,456.5h2.9l-0.9-2.4c-0.3-0.7-0.5-1.3-0.6-1.8  c-0.1,0.6-0.3,1.1-0.5,1.6L195.2,456.5z"/>
<path d="M201.3,457.2l1.1-0.1c0.1,0.4,0.2,0.8,0.4,1.1s0.5,0.5,0.9,0.7c0.4,0.2,0.8,0.3,1.3,0.3c0.4,0,0.8-0.1,1.1-0.2  c0.3-0.1,0.6-0.3,0.7-0.5s0.2-0.5,0.2-0.7c0-0.3-0.1-0.5-0.2-0.7s-0.4-0.4-0.8-0.5c-0.2-0.1-0.7-0.2-1.5-0.4  c-0.8-0.2-1.3-0.4-1.7-0.5c-0.4-0.2-0.7-0.5-0.9-0.8s-0.3-0.7-0.3-1.1c0-0.4,0.1-0.8,0.4-1.2c0.2-0.4,0.6-0.7,1.1-0.9s1-0.3,1.6-0.3  c0.6,0,1.2,0.1,1.7,0.3c0.5,0.2,0.9,0.5,1.1,0.9s0.4,0.8,0.4,1.4l-1.1,0.1c-0.1-0.5-0.3-1-0.6-1.2c-0.3-0.3-0.8-0.4-1.5-0.4  c-0.7,0-1.2,0.1-1.5,0.4s-0.5,0.6-0.5,0.9c0,0.3,0.1,0.6,0.3,0.8c0.2,0.2,0.8,0.4,1.7,0.6c0.9,0.2,1.6,0.4,1.9,0.5  c0.5,0.2,0.9,0.5,1.1,0.9s0.4,0.8,0.4,1.2c0,0.5-0.1,0.9-0.4,1.3s-0.6,0.7-1.1,0.9c-0.5,0.2-1,0.3-1.7,0.3c-0.8,0-1.4-0.1-2-0.3  s-0.9-0.6-1.2-1C201.5,458.3,201.3,457.8,201.3,457.2z"/>
<path d="M209.3,457.2l1.1-0.1c0.1,0.4,0.2,0.8,0.4,1.1s0.5,0.5,0.9,0.7c0.4,0.2,0.8,0.3,1.3,0.3c0.4,0,0.8-0.1,1.1-0.2  c0.3-0.1,0.6-0.3,0.7-0.5s0.2-0.5,0.2-0.7c0-0.3-0.1-0.5-0.2-0.7s-0.4-0.4-0.8-0.5c-0.2-0.1-0.7-0.2-1.5-0.4  c-0.8-0.2-1.3-0.4-1.7-0.5c-0.4-0.2-0.7-0.5-0.9-0.8s-0.3-0.7-0.3-1.1c0-0.4,0.1-0.8,0.4-1.2c0.2-0.4,0.6-0.7,1.1-0.9s1-0.3,1.6-0.3  c0.6,0,1.2,0.1,1.7,0.3c0.5,0.2,0.9,0.5,1.1,0.9s0.4,0.8,0.4,1.4l-1.1,0.1c-0.1-0.5-0.3-1-0.6-1.2c-0.3-0.3-0.8-0.4-1.5-0.4  c-0.7,0-1.2,0.1-1.5,0.4s-0.5,0.6-0.5,0.9c0,0.3,0.1,0.6,0.3,0.8c0.2,0.2,0.8,0.4,1.7,0.6c0.9,0.2,1.6,0.4,1.9,0.5  c0.5,0.2,0.9,0.5,1.1,0.9s0.4,0.8,0.4,1.2c0,0.5-0.1,0.9-0.4,1.3s-0.6,0.7-1.1,0.9c-0.5,0.2-1,0.3-1.7,0.3c-0.8,0-1.4-0.1-2-0.3  s-0.9-0.6-1.2-1C209.5,458.3,209.3,457.8,209.3,457.2z"/>
<path d="M217.7,460v-8.6h6.2v1h-5.1v2.6h4.8v1h-4.8v2.9h5.3v1H217.7z"/>
<path d="M225.7,460v-8.6h3.8c0.8,0,1.3,0.1,1.7,0.2s0.7,0.4,1,0.8c0.2,0.4,0.4,0.8,0.4,1.3c0,0.6-0.2,1.1-0.6,1.5s-1,0.7-1.8,0.8  c0.3,0.1,0.5,0.3,0.7,0.4c0.3,0.3,0.6,0.7,0.9,1.1l1.5,2.3h-1.4l-1.1-1.8c-0.3-0.5-0.6-0.9-0.8-1.2s-0.4-0.5-0.6-0.6  s-0.3-0.2-0.5-0.2c-0.1,0-0.3,0-0.6,0h-1.3v3.8H225.7z M226.8,455.2h2.4c0.5,0,0.9-0.1,1.2-0.2c0.3-0.1,0.5-0.3,0.7-0.5  s0.2-0.5,0.2-0.8c0-0.4-0.1-0.7-0.4-1s-0.8-0.4-1.4-0.4h-2.7V455.2z"/>
<path d="M236.3,460v-7.6h-2.8v-1h6.8v1h-2.8v7.6H236.3z"/>
<path d="M241.7,460v-8.6h1.1v8.6H241.7z"/>
<path d="M244.4,455.8c0-1.4,0.4-2.5,1.1-3.3c0.8-0.8,1.8-1.2,3-1.2c0.8,0,1.5,0.2,2.1,0.6s1.1,0.9,1.5,1.6s0.5,1.4,0.5,2.3  c0,0.9-0.2,1.7-0.5,2.3c-0.4,0.7-0.8,1.2-1.5,1.6s-1.3,0.5-2.1,0.5c-0.8,0-1.5-0.2-2.2-0.6c-0.6-0.4-1.1-0.9-1.4-1.6  C244.6,457.3,244.4,456.6,244.4,455.8z M245.6,455.8c0,1,0.3,1.9,0.8,2.4s1.3,0.9,2.1,0.9c0.9,0,1.6-0.3,2.1-0.9s0.8-1.5,0.8-2.6  c0-0.7-0.1-1.3-0.4-1.8s-0.6-0.9-1-1.2s-1-0.4-1.5-0.4c-0.8,0-1.5,0.3-2.1,0.8S245.6,454.5,245.6,455.8z"/>
<path d="M254.1,460v-8.6h1.2l4.5,6.7v-6.7h1.1v8.6h-1.2l-4.5-6.8v6.8H254.1z"/>
<rect x="192.7" y="436" fill-rule="evenodd" fill="none" width="69" height="27"/>
<rect x="360.6" y="388.8" fill="none" stroke="#000000" stroke-width="2.2498" width="144.8" height="42"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="489.8" height="491.2"/>
<path d="M411.5,406.8V406c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2c0.4-0.3,0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6v-3.1h1v8.6H411.5z M408.1,403.6  c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C408.3,402.2,408.1,402.8,408.1,403.6z"/>
<path d="M415.1,406.8h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1s0.2,0.8,0.2,1.3  c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V406.8z M415.1,403.6c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  C415.2,402.3,415.1,402.8,415.1,403.6z"/>
<path d="M420.6,399.3v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  c0.3-1,0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H420.6z"/>
<path d="M431.5,406.8V406c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2c0.4-0.3,0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6v-3.1h1v8.6H431.5z M428.2,403.6  c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C428.3,402.2,428.2,402.8,428.2,403.6z"/>
<path d="M438.2,406.8V406c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2c0.4-0.3,0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6v-3.1h1v8.6H438.2z M434.8,403.6  c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C435,402.2,434.8,402.8,434.8,403.6z"/>
<path d="M446,405.7v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1s0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8s0.5-0.9,0.5-1.3  c0-0.4-0.1-0.8-0.4-1.1s-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5c-0.3,0.3-0.5,0.7-0.5,1.3l-1.1-0.1c0.1-0.8,0.4-1.4,0.8-1.8  s1.1-0.6,2-0.6c0.8,0,1.5,0.2,2,0.7s0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1s-0.4,0.7-0.7,1s-0.9,0.9-1.6,1.5c-0.6,0.5-1,0.9-1.2,1.1  c-0.2,0.2-0.3,0.4-0.4,0.6H446z"/>
<path d="M451.1,406.8h-1.1V400c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1s0.8-0.8,0.9-1.1h0.7V406.8z"/>
<path d="M458.2,404.5l1,0.1c-0.1,0.7-0.4,1.3-0.9,1.7s-1,0.6-1.7,0.6c-0.9,0-1.5-0.3-2.1-0.8s-0.8-1.4-0.8-2.4  c0-0.7,0.1-1.3,0.3-1.8s0.6-0.9,1-1.1c0.5-0.3,0.9-0.4,1.5-0.4c0.7,0,1.2,0.2,1.7,0.5s0.7,0.8,0.8,1.5l-1,0.2  c-0.1-0.4-0.3-0.7-0.5-0.9s-0.5-0.3-0.9-0.3c-0.5,0-1,0.2-1.3,0.6c-0.3,0.4-0.5,1-0.5,1.8c0,0.8,0.2,1.4,0.5,1.8  c0.3,0.4,0.7,0.6,1.3,0.6c0.4,0,0.8-0.1,1-0.4S458.1,405,458.2,404.5z"/>
<path d="M412.6,414.7l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H412.6z M414.5,414.7l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H414.5z"/>
<path d="M416.8,420.2v-8.6h1.1v4.9l2.5-2.5h1.4l-2.4,2.3l2.6,3.9h-1.3l-2.1-3.2l-0.7,0.7v2.5H416.8z"/>
<path d="M422.8,420.2V414h0.9v0.9c0.5-0.7,1.1-1,2-1c0.4,0,0.7,0.1,1,0.2s0.5,0.3,0.7,0.5s0.3,0.5,0.3,0.8c0,0.2,0.1,0.5,0.1,1v3.8  h-1.1v-3.8c0-0.4,0-0.8-0.1-1s-0.2-0.4-0.4-0.5s-0.5-0.2-0.7-0.2c-0.4,0-0.8,0.1-1.2,0.4c-0.3,0.3-0.5,0.8-0.5,1.6v3.4H422.8z"/>
<path d="M429.1,417.1c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8s0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  s-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8S429.1,418.2,429.1,417.1z M430.1,417.1c0,0.8,0.2,1.4,0.5,1.8  c0.3,0.4,0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7s-0.8-0.6-1.3-0.6c-0.5,0-1,0.2-1.3,0.6  C430.3,415.7,430.1,416.3,430.1,417.1z"/>
<path d="M437.3,420.2l-1.9-6.2h1.1l1,3.6l0.4,1.3c0-0.1,0.1-0.5,0.3-1.3l1-3.6h1.1l0.9,3.6l0.3,1.2l0.4-1.2l1.1-3.6h1l-1.9,6.2h-1.1  l-1-3.7l-0.2-1.1l-1.3,4.8H437.3z"/>
<path d="M444.4,418.4l1-0.2c0.1,0.4,0.2,0.7,0.5,1c0.3,0.2,0.6,0.3,1.1,0.3c0.5,0,0.8-0.1,1.1-0.3s0.4-0.4,0.4-0.7  c0-0.2-0.1-0.4-0.3-0.6c-0.1-0.1-0.5-0.2-1.1-0.4c-0.8-0.2-1.3-0.4-1.6-0.5s-0.5-0.3-0.7-0.6s-0.2-0.5-0.2-0.8  c0-0.3,0.1-0.5,0.2-0.8s0.3-0.4,0.5-0.6c0.2-0.1,0.4-0.2,0.7-0.3c0.3-0.1,0.6-0.1,0.9-0.1c0.5,0,0.9,0.1,1.3,0.2s0.6,0.3,0.8,0.6  s0.3,0.6,0.4,1l-1,0.1c0-0.3-0.2-0.6-0.4-0.8s-0.5-0.3-1-0.3c-0.5,0-0.8,0.1-1,0.2s-0.3,0.3-0.3,0.6c0,0.1,0,0.3,0.1,0.4  c0.1,0.1,0.2,0.2,0.4,0.3c0.1,0,0.4,0.1,0.9,0.3c0.7,0.2,1.3,0.4,1.6,0.5s0.5,0.3,0.7,0.6s0.3,0.5,0.3,0.9c0,0.4-0.1,0.7-0.3,1  s-0.5,0.6-0.9,0.7s-0.8,0.3-1.3,0.3c-0.8,0-1.4-0.2-1.8-0.5S444.5,419.1,444.4,418.4z"/>
<path d="M450.8,414.7l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H450.8z M452.8,414.7l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H452.8z"/>
<rect x="368.1" y="396.2" fill-rule="evenodd" fill="none" width="129.7" height="27"/>
<rect x="366.9" y="468.2" fill="none" stroke="#000000" stroke-width="2.2498" width="132.2" height="42"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="489.8" height="491.2"/>
<path d="M410.8,486.2h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1s0.8-0.8,0.9-1.1h0.7V486.2z"/>
<path d="M413.5,484l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3c0.3,0.3,0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5s0.5-0.8,0.5-1.3  c0-0.5-0.2-0.9-0.5-1.2s-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1l0.1-0.9c0.1,0,0.1,0,0.2,0c0.4,0,0.9-0.1,1.2-0.4s0.5-0.6,0.5-1.1  c0-0.4-0.1-0.7-0.4-1s-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4c-0.3,0.3-0.4,0.6-0.5,1.2l-1.1-0.2c0.1-0.7,0.4-1.3,0.9-1.6  s1-0.6,1.7-0.6c0.5,0,0.9,0.1,1.3,0.3s0.7,0.5,0.9,0.8s0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-0.9,0.7  c0.5,0.1,0.9,0.4,1.2,0.7s0.4,0.8,0.4,1.4c0,0.8-0.3,1.4-0.8,1.9s-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7S413.6,484.7,413.5,484z"/>
<path d="M421.4,486.2h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1s0.2,0.8,0.2,1.3  c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V486.2z M421.4,483.1c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  C421.6,481.8,421.4,482.3,421.4,483.1z"/>
<path d="M426.9,478.8v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  c0.3-1,0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H426.9z"/>
<path d="M436.9,486.2v-2.1h-3.7v-1l3.9-5.6h0.9v5.6h1.2v1h-1.2v2.1H436.9z M436.9,483.2v-3.9l-2.7,3.9H436.9z"/>
<path d="M444.1,486.2h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1s0.8-0.8,0.9-1.1h0.7V486.2z"/>
<path d="M447,484.3l1-0.1c0.1,0.5,0.2,0.8,0.5,1c0.2,0.2,0.6,0.3,0.9,0.3c0.3,0,0.6-0.1,0.9-0.2s0.4-0.3,0.6-0.6s0.3-0.6,0.4-1  s0.2-0.9,0.2-1.3c0,0,0-0.1,0-0.2c-0.2,0.3-0.5,0.6-0.9,0.8s-0.8,0.3-1.2,0.3c-0.7,0-1.3-0.3-1.8-0.8s-0.7-1.2-0.7-2  c0-0.9,0.3-1.6,0.8-2.1s1.2-0.8,1.9-0.8c0.6,0,1.1,0.2,1.5,0.5s0.8,0.7,1.1,1.3s0.4,1.4,0.4,2.4c0,1.1-0.1,2-0.4,2.6  s-0.6,1.1-1.1,1.5s-1,0.5-1.7,0.5c-0.7,0-1.2-0.2-1.6-0.6S447.1,484.9,447,484.3z M451.3,480.5c0-0.6-0.2-1.1-0.5-1.4  s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.6c-0.3,0.4-0.5,0.9-0.5,1.5c0,0.5,0.2,1,0.5,1.3c0.3,0.3,0.7,0.5,1.2,0.5  c0.5,0,0.9-0.2,1.2-0.5S451.3,481.1,451.3,480.5z"/>
<path d="M456.9,486.2v-2.1h-3.7v-1l3.9-5.6h0.9v5.6h1.2v1h-1.2v2.1H456.9z M456.9,483.2v-3.9l-2.7,3.9H456.9z"/>
<path d="M418.9,494.2l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H418.9z M420.8,494.2l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H420.8z"/>
<path d="M423.2,499.8v-8.6h3.2c0.7,0,1.2,0.1,1.6,0.3s0.7,0.4,0.9,0.8c0.2,0.4,0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1  c-0.2,0.3-0.5,0.6-0.9,0.8c0.5,0.2,0.9,0.4,1.2,0.8s0.4,0.8,0.4,1.3c0,0.4-0.1,0.8-0.3,1.1s-0.4,0.6-0.6,0.8  c-0.2,0.2-0.6,0.3-0.9,0.4s-0.8,0.1-1.4,0.1H423.2z M424.3,494.8h1.9c0.5,0,0.9,0,1.1-0.1c0.3-0.1,0.5-0.2,0.7-0.4s0.2-0.4,0.2-0.8  c0-0.3-0.1-0.5-0.2-0.8s-0.3-0.4-0.6-0.4s-0.7-0.1-1.3-0.1h-1.7V494.8z M424.3,498.7h2.1c0.4,0,0.6,0,0.8,0c0.3,0,0.5-0.1,0.7-0.2  s0.3-0.3,0.4-0.5s0.2-0.5,0.2-0.7c0-0.3-0.1-0.6-0.2-0.8s-0.4-0.4-0.7-0.5s-0.7-0.1-1.3-0.1h-2V498.7z"/>
<path d="M430.7,496.6c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8s0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  s-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8S430.7,497.7,430.7,496.6z M431.8,496.6c0,0.8,0.2,1.4,0.5,1.8  c0.3,0.4,0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7s-0.8-0.6-1.3-0.6c-0.5,0-1,0.2-1.3,0.6  C432,495.2,431.8,495.8,431.8,496.6z"/>
<path d="M438.8,499.8h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1s0.2,0.8,0.2,1.3  c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V499.8z M438.7,496.6c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  C438.9,495.3,438.7,495.8,438.7,496.6z"/>
<path d="M444.5,494.2l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H444.5z M446.4,494.2l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H446.4z"/>
<rect x="374.4" y="475.8" fill-rule="evenodd" fill="none" width="117" height="27"/>
</svg>
</artwork>
`
For easy recognition, envelope trees and Mermaid diagrams only show the first four bytes of each digest, but internally all digests are 32 bytes.

From the above envelope and its tree, we make the following observations:

* The envelope is a `node` case, which holds the overall envelope digest.
* The subject "Alice" has its own digest.
* Each of the three assertions has their own digests
* The predicate and object of each assertion each have their own digests.
* The assertions appear in the structure in ascending lexicographic order by digest, which is distinct from envelope notation, where they appear sorted alphabeticaly.

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
13941b48 "Alice"
~~~

### Mermaid

<artwork type="svg"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.2" baseProfile="tiny" width="199.2px" height="104px" viewBox="0 0 199.2 104" xml:space="preserve">
<rect x="31" y="31" fill="none" stroke="#000000" stroke-width="2.2528" width="137.2" height="42"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="149.2" height="54"/>
<path d="M77.3,49h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7c-0.4,0.2-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.6-1c0.4-0.4,0.8-0.8,0.9-1.1h0.7  V49z"/>
<path d="M80.1,46.7l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3c0.3,0.3,0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5s0.5-0.8,0.5-1.3  c0-0.5-0.2-0.9-0.5-1.2c-0.3-0.3-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1l0.1-0.9c0.1,0,0.1,0,0.2,0c0.5,0,0.9-0.1,1.2-0.4  s0.5-0.6,0.5-1.1c0-0.4-0.1-0.7-0.4-1c-0.3-0.3-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4c-0.3,0.3-0.5,0.6-0.5,1.2l-1.1-0.2  c0.1-0.7,0.4-1.3,0.9-1.6c0.5-0.4,1-0.6,1.7-0.6c0.5,0,0.9,0.1,1.3,0.3s0.7,0.5,0.9,0.8s0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1  s-0.5,0.5-0.9,0.7c0.5,0.1,0.9,0.4,1.2,0.7c0.3,0.4,0.4,0.8,0.4,1.4c0,0.8-0.3,1.4-0.8,1.9s-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7  S80.1,47.4,80.1,46.7z"/>
<path d="M86.9,47l1-0.1c0.1,0.5,0.3,0.8,0.5,1s0.6,0.3,0.9,0.3c0.3,0,0.6-0.1,0.9-0.2s0.4-0.3,0.6-0.6c0.2-0.2,0.3-0.6,0.4-1  c0.1-0.4,0.2-0.9,0.2-1.3c0,0,0-0.1,0-0.2c-0.2,0.3-0.5,0.6-0.9,0.8s-0.8,0.3-1.2,0.3c-0.7,0-1.3-0.3-1.8-0.8  c-0.5-0.5-0.7-1.2-0.7-2c0-0.9,0.3-1.6,0.8-2.1c0.5-0.5,1.2-0.8,1.9-0.8c0.6,0,1.1,0.2,1.5,0.5c0.5,0.3,0.8,0.7,1.1,1.3  s0.4,1.4,0.4,2.4c0,1.1-0.1,2-0.4,2.6s-0.6,1.1-1.1,1.5c-0.5,0.3-1,0.5-1.7,0.5c-0.7,0-1.2-0.2-1.7-0.6S87,47.7,86.9,47z M91.2,43.2  c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.4-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.6s-0.5,0.9-0.5,1.5c0,0.5,0.2,1,0.5,1.3  c0.3,0.3,0.7,0.5,1.2,0.5c0.5,0,0.9-0.2,1.2-0.5C91.1,44.3,91.2,43.8,91.2,43.2z"/>
<path d="M96.8,49v-2.1h-3.7v-1l3.9-5.6h0.9V46H99v1h-1.2V49H96.8z M96.8,46v-3.9L94.1,46H96.8z"/>
<path d="M104.1,49H103v-6.7c-0.3,0.2-0.6,0.5-1,0.7c-0.4,0.2-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.6-1c0.4-0.4,0.8-0.8,0.9-1.1h0.7  V49z"/>
<path d="M108.1,49h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1s0.2,0.8,0.2,1.3  c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V49z M108.1,45.8c0,0.7,0.1,1.3,0.3,1.6c0.3,0.5,0.8,0.8,1.4,0.8  c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8c-0.3-0.4-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  C108.2,44.5,108.1,45.1,108.1,45.8z"/>
<path d="M116.9,49v-2.1h-3.7v-1l3.9-5.6h0.9V46h1.2v1H118V49H116.9z M116.9,46v-3.9l-2.7,3.9H116.9z"/>
<path d="M121.8,44.3c-0.4-0.2-0.8-0.4-1-0.7s-0.3-0.7-0.3-1.1c0-0.6,0.2-1.2,0.7-1.6c0.5-0.4,1-0.6,1.8-0.6c0.8,0,1.4,0.2,1.8,0.7  c0.5,0.4,0.7,1,0.7,1.6c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-1,0.7c0.5,0.2,0.9,0.4,1.2,0.8c0.3,0.4,0.4,0.8,0.4,1.4c0,0.7-0.3,1.4-0.8,1.9  c-0.5,0.5-1.2,0.8-2.1,0.8s-1.5-0.3-2.1-0.8c-0.5-0.5-0.8-1.1-0.8-1.9c0-0.6,0.1-1,0.4-1.4C120.9,44.7,121.3,44.5,121.8,44.3z   M121.3,46.5c0,0.3,0.1,0.6,0.2,0.9s0.4,0.5,0.6,0.7c0.3,0.2,0.6,0.2,0.9,0.2c0.5,0,0.9-0.2,1.3-0.5c0.3-0.3,0.5-0.7,0.5-1.2  c0-0.5-0.2-0.9-0.5-1.3c-0.3-0.3-0.8-0.5-1.3-0.5c-0.5,0-0.9,0.2-1.2,0.5C121.4,45.6,121.3,46,121.3,46.5z M121.6,42.6  c0,0.4,0.1,0.7,0.4,1c0.3,0.3,0.6,0.4,1,0.4c0.4,0,0.7-0.1,1-0.4c0.3-0.3,0.4-0.6,0.4-0.9c0-0.4-0.1-0.7-0.4-1s-0.6-0.4-1-0.4  c-0.4,0-0.7,0.1-1,0.4C121.7,41.9,121.6,42.2,121.6,42.6z"/>
<path d="M83.2,57l-0.3-1.6v-1.4h1.2v1.4L83.8,57H83.2z M85.1,57l-0.3-1.6v-1.4H86v1.4L85.7,57H85.1z"/>
<path d="M86.6,62.5l3.3-8.6h1.2l3.5,8.6h-1.3l-1-2.6h-3.6l-0.9,2.6H86.6z M89.1,59H92l-0.9-2.4c-0.3-0.7-0.5-1.3-0.6-1.8  c-0.1,0.6-0.3,1.1-0.5,1.6L89.1,59z"/>
<path d="M95.4,62.5v-8.6h1.1v8.6H95.4z"/>
<path d="M98.1,55.1v-1.2h1.1v1.2H98.1z M98.1,62.5v-6.2h1.1v6.2H98.1z"/>
<path d="M104.8,60.2l1,0.1c-0.1,0.7-0.4,1.3-0.9,1.7c-0.5,0.4-1,0.6-1.7,0.6c-0.9,0-1.5-0.3-2.1-0.8c-0.5-0.6-0.8-1.4-0.8-2.4  c0-0.7,0.1-1.3,0.3-1.8s0.6-0.9,1-1.1c0.5-0.3,1-0.4,1.5-0.4c0.7,0,1.2,0.2,1.7,0.5c0.4,0.3,0.7,0.8,0.8,1.5l-1,0.2  c-0.1-0.4-0.3-0.7-0.5-0.9c-0.2-0.2-0.5-0.3-0.9-0.3c-0.5,0-1,0.2-1.3,0.6c-0.3,0.4-0.5,1-0.5,1.8c0,0.8,0.2,1.4,0.5,1.8  c0.3,0.4,0.7,0.6,1.3,0.6c0.4,0,0.8-0.1,1-0.4C104.6,61.1,104.7,60.7,104.8,60.2z"/>
<path d="M111,60.5l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5c-0.5,0.4-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8c-0.5-0.6-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4c0.5-0.6,1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8c0.5,0.6,0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.7  c0,0.7,0.2,1.2,0.6,1.6s0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3C110.7,61.3,110.9,60.9,111,60.5z M107.6,58.8h3.5  c0-0.5-0.2-0.9-0.4-1.2c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5S107.6,58.2,107.6,58.8z"/>
<path d="M113.5,57l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H113.5z M115.5,57l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H115.5z"/>
<rect x="38.5" y="38.5" fill-rule="evenodd" fill="none" width="122.6" height="27"/>
</svg></artwork>

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
d933fc06 verifiedBy
~~~

### Mermaid

<artwork type="svg"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.2" baseProfile="tiny" width="158px" height="104px" viewBox="0 0 158 104" xml:space="preserve">
<polygon fill="none" stroke="#000000" stroke-width="2.2532" points="31,73 105.9,73 127,31 52.1,31 "/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="108" height="54"/>
<path d="M59.1,49v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4c-0.4-0.3-0.7-0.7-1-1.1c-0.2-0.5-0.3-1.1-0.3-1.7  c0-0.6,0.1-1.2,0.3-1.7s0.5-0.9,0.9-1.2c0.4-0.3,0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6v-3.1h1.1V49H59.1z M55.7,45.9  c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C55.9,44.5,55.7,45.1,55.7,45.9z"/>
<path d="M61.6,47l1-0.1c0.1,0.5,0.3,0.8,0.5,1c0.2,0.2,0.6,0.3,0.9,0.3c0.3,0,0.6-0.1,0.9-0.2c0.2-0.1,0.4-0.3,0.6-0.6  s0.3-0.6,0.4-1C66,46,66,45.6,66,45.2c0,0,0-0.1,0-0.2c-0.2,0.3-0.5,0.6-0.9,0.8s-0.8,0.3-1.2,0.3c-0.7,0-1.3-0.3-1.8-0.8  s-0.7-1.2-0.7-2c0-0.9,0.3-1.6,0.8-2.1c0.5-0.5,1.2-0.8,1.9-0.8c0.6,0,1.1,0.2,1.5,0.5s0.8,0.7,1.1,1.3c0.2,0.6,0.4,1.4,0.4,2.4  c0,1.1-0.1,2-0.4,2.6c-0.2,0.7-0.6,1.1-1.1,1.5s-1,0.5-1.7,0.5c-0.7,0-1.2-0.2-1.7-0.6C61.9,48.2,61.7,47.7,61.6,47z M65.9,43.2  c0-0.6-0.2-1.1-0.5-1.4s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.6c-0.3,0.4-0.5,0.9-0.5,1.5c0,0.5,0.2,1,0.5,1.3s0.7,0.5,1.2,0.5  c0.5,0,0.9-0.2,1.2-0.5S65.9,43.8,65.9,43.2z"/>
<path d="M68.1,46.7l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3s0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5s0.5-0.8,0.5-1.3c0-0.5-0.2-0.9-0.5-1.2  s-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1l0.1-0.9c0.1,0,0.1,0,0.2,0c0.5,0,0.9-0.1,1.2-0.4s0.5-0.6,0.5-1.1c0-0.4-0.1-0.7-0.4-1  c-0.3-0.3-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4s-0.5,0.6-0.5,1.2l-1.1-0.2c0.1-0.7,0.4-1.3,0.9-1.6s1-0.6,1.7-0.6  c0.5,0,0.9,0.1,1.3,0.3c0.4,0.2,0.7,0.5,0.9,0.8s0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-0.9,0.7c0.5,0.1,0.9,0.4,1.2,0.7  s0.4,0.8,0.4,1.4c0,0.8-0.3,1.4-0.8,1.9c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7S68.2,47.4,68.1,46.7z"/>
<path d="M74.8,46.7l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3s0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5s0.5-0.8,0.5-1.3c0-0.5-0.2-0.9-0.5-1.2  s-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1L77,44c0.1,0,0.1,0,0.2,0c0.5,0,0.9-0.1,1.2-0.4s0.5-0.6,0.5-1.1c0-0.4-0.1-0.7-0.4-1  c-0.3-0.3-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4s-0.5,0.6-0.5,1.2l-1.1-0.2c0.1-0.7,0.4-1.3,0.9-1.6s1-0.6,1.7-0.6  c0.5,0,0.9,0.1,1.3,0.3c0.4,0.2,0.7,0.5,0.9,0.8s0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-0.9,0.7c0.5,0.1,0.9,0.4,1.2,0.7  s0.4,0.8,0.4,1.4c0,0.8-0.3,1.4-0.8,1.9c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7S74.9,47.4,74.8,46.7z"/>
<path d="M82.1,49v-5.4h-0.9v-0.8h0.9v-0.7c0-0.4,0-0.7,0.1-0.9c0.1-0.3,0.3-0.5,0.5-0.7c0.3-0.2,0.6-0.3,1.1-0.3c0.3,0,0.6,0,1,0.1  l-0.2,0.9c-0.2,0-0.4-0.1-0.6-0.1c-0.3,0-0.5,0.1-0.7,0.2c-0.1,0.1-0.2,0.4-0.2,0.8v0.6h1.2v0.8h-1.2V49H82.1z"/>
<path d="M89.2,46.7l1,0.1c-0.1,0.7-0.4,1.3-0.9,1.7c-0.5,0.4-1,0.6-1.7,0.6c-0.9,0-1.5-0.3-2.1-0.8s-0.8-1.4-0.8-2.4  c0-0.7,0.1-1.3,0.3-1.8c0.2-0.5,0.6-0.9,1-1.1c0.5-0.3,1-0.4,1.5-0.4c0.7,0,1.2,0.2,1.7,0.5c0.4,0.3,0.7,0.8,0.8,1.5l-1,0.2  c-0.1-0.4-0.3-0.7-0.5-0.9c-0.2-0.2-0.5-0.3-0.9-0.3c-0.5,0-1,0.2-1.3,0.6s-0.5,1-0.5,1.8c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.3,0.6  c0.4,0,0.8-0.1,1-0.4C89,47.6,89.1,47.2,89.2,46.7z"/>
<path d="M90.9,44.8c0-1,0.1-1.8,0.3-2.5c0.2-0.6,0.5-1.1,0.9-1.4c0.4-0.3,0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3s0.6,0.5,0.9,0.8  s0.4,0.8,0.5,1.3c0.1,0.5,0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4c-0.2,0.6-0.5,1.1-0.9,1.4c-0.4,0.3-0.9,0.5-1.6,0.5  c-0.8,0-1.5-0.3-2-0.9C91.2,47.5,90.9,46.4,90.9,44.8z M92,44.8c0,1.4,0.2,2.3,0.5,2.8s0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7  s0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8s-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C92.1,42.4,92,43.4,92,44.8z"/>
<path d="M103.1,42.5l-1.1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  c-0.2,0.5-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9c0.4-0.2,0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8s0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5  c-0.2,0.5-0.6,0.8-1,1.1c-0.4,0.2-0.9,0.4-1.4,0.4c-0.9,0-1.6-0.3-2.2-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6  c0.5-0.7,1.3-1,2.2-1c0.7,0,1.2,0.2,1.7,0.6C102.7,41.3,103,41.8,103.1,42.5z M98.7,46.2c0,0.4,0.1,0.7,0.2,1s0.4,0.6,0.6,0.8  s0.6,0.3,0.9,0.3c0.4,0,0.8-0.2,1.2-0.5s0.5-0.8,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.5  S98.7,45.7,98.7,46.2z"/>
<path d="M55.1,62.5l-2.4-6.2h1.1l1.3,3.7c0.1,0.4,0.3,0.8,0.4,1.3c0.1-0.3,0.2-0.7,0.4-1.2l1.4-3.8h1.1l-2.4,6.2H55.1z"/>
<path d="M63.7,60.5l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5s-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8c-0.5-0.6-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4c0.5-0.6,1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8c0.5,0.6,0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.7  c0,0.7,0.2,1.2,0.6,1.6c0.3,0.4,0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3S63.5,60.9,63.7,60.5z M60.2,58.8h3.5c0-0.5-0.2-0.9-0.4-1.2  C62.9,57.2,62.5,57,62,57c-0.5,0-0.9,0.2-1.2,0.5S60.2,58.2,60.2,58.8z"/>
<path d="M66.1,62.5v-6.2h1v0.9c0.2-0.4,0.5-0.7,0.7-0.9s0.4-0.2,0.7-0.2c0.4,0,0.7,0.1,1.1,0.3l-0.4,1c-0.3-0.2-0.5-0.2-0.8-0.2  c-0.2,0-0.4,0.1-0.6,0.2c-0.2,0.1-0.3,0.3-0.4,0.6c-0.1,0.4-0.2,0.8-0.2,1.2v3.3H66.1z"/>
<path d="M70.1,55.1v-1.2h1.1v1.2H70.1z M70.1,62.5v-6.2h1.1v6.2H70.1z"/>
<path d="M73,62.5v-5.4h-0.9v-0.8H73v-0.7c0-0.4,0-0.7,0.1-0.9c0.1-0.3,0.3-0.5,0.5-0.7c0.3-0.2,0.6-0.3,1.1-0.3c0.3,0,0.6,0,1,0.1  l-0.2,0.9c-0.2,0-0.4-0.1-0.6-0.1c-0.3,0-0.5,0.1-0.7,0.2c-0.1,0.1-0.2,0.4-0.2,0.8v0.6h1.2v0.8h-1.2v5.4H73z"/>
<path d="M76.1,55.1v-1.2h1.1v1.2H76.1z M76.1,62.5v-6.2h1.1v6.2H76.1z"/>
<path d="M83.1,60.5l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5s-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8c-0.5-0.6-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4c0.5-0.6,1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8c0.5,0.6,0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.7  c0,0.7,0.2,1.2,0.6,1.6c0.3,0.4,0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3S82.9,60.9,83.1,60.5z M79.6,58.8h3.5c0-0.5-0.2-0.9-0.4-1.2  c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5S79.6,58.2,79.6,58.8z"/>
<path d="M89.5,62.5v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4c-0.4-0.3-0.7-0.7-1-1.1c-0.2-0.5-0.3-1.1-0.3-1.7  c0-0.6,0.1-1.2,0.3-1.7s0.5-0.9,0.9-1.2c0.4-0.3,0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6v-3.1h1.1v8.6H89.5z   M86.2,59.4c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9S88.3,57,87.8,57  c-0.5,0-0.9,0.2-1.2,0.6C86.3,58,86.2,58.6,86.2,59.4z"/>
<path d="M92.3,62.5v-8.6h3.2c0.7,0,1.2,0.1,1.6,0.3c0.4,0.2,0.7,0.4,0.9,0.8c0.2,0.4,0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1  c-0.2,0.3-0.5,0.6-0.9,0.8c0.5,0.2,0.9,0.4,1.2,0.8c0.3,0.4,0.4,0.8,0.4,1.3c0,0.4-0.1,0.8-0.3,1.1s-0.4,0.6-0.6,0.8  c-0.3,0.2-0.6,0.3-0.9,0.4s-0.8,0.1-1.4,0.1H92.3z M93.4,57.5h1.9c0.5,0,0.9,0,1.1-0.1c0.3-0.1,0.5-0.2,0.7-0.4s0.2-0.4,0.2-0.8  c0-0.3-0.1-0.5-0.2-0.8s-0.3-0.4-0.6-0.4c-0.3-0.1-0.7-0.1-1.3-0.1h-1.7V57.5z M93.4,61.5h2.1c0.4,0,0.6,0,0.8,0  c0.3,0,0.5-0.1,0.7-0.2s0.3-0.3,0.4-0.5c0.1-0.2,0.2-0.5,0.2-0.7c0-0.3-0.1-0.6-0.2-0.8s-0.4-0.4-0.7-0.5s-0.7-0.1-1.3-0.1h-2V61.5z  "/>
<path d="M100.1,64.9l-0.1-1c0.2,0.1,0.4,0.1,0.6,0.1c0.2,0,0.4,0,0.6-0.1c0.1-0.1,0.3-0.2,0.3-0.3c0.1-0.1,0.2-0.4,0.3-0.8  c0-0.1,0.1-0.1,0.1-0.3l-2.4-6.2h1.1l1.3,3.6c0.2,0.5,0.3,0.9,0.5,1.4c0.1-0.5,0.3-1,0.4-1.4l1.3-3.6h1.1l-2.4,6.3  c-0.3,0.7-0.5,1.2-0.6,1.4c-0.2,0.3-0.4,0.6-0.6,0.8c-0.2,0.2-0.5,0.2-0.9,0.2C100.6,65,100.4,65,100.1,64.9z"/>
<rect x="52.6" y="38.5" fill-rule="evenodd" fill="none" width="52.7" height="27"/>
</svg></artwork>

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
envelope subject "Alice" | envelope encrypt \
    --key `envelope generate key`
~~~

### Envelope Notation

~~~
ENCRYPTED
~~~

### Tree

~~~
13941b48 ENCRYPTED
~~~

### Mermaid

<artwork type="svg"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.2" baseProfile="tiny" width="171.5px" height="104px" viewBox="0 0 171.5 104" xml:space="preserve">
<path d="M31,71.9h3.7v2.2H31V71.9z M36,69.6l-2.6,2.7l-1.6-1.6l2.6-2.7L36,69.6z M41.3,64.3l-2.6,2.7l-1.6-1.6l2.6-2.7L41.3,64.3z   M46.6,59l-2.6,2.7L42.3,60l2.6-2.7L46.6,59z M51.9,53.7l-2.6,2.7l-1.6-1.6l2.6-2.7L51.9,53.7z M48.3,46.8l2.6,2.7L49.4,51l-2.6-2.7  L48.3,46.8z M43,41.5l2.6,2.7l-1.6,1.6L41.4,43L43,41.5z M37.7,36.2l2.6,2.7l-1.6,1.6l-2.6-2.7L37.7,36.2z M32.4,30.9l2.6,2.7  l-1.6,1.6l-2.6-2.7L32.4,30.9z M37.6,32.1h-3.7v-2.2h3.7V32.1z M45,32.1h-3.7v-2.2H45V32.1z M52.5,32.1h-3.7v-2.2h3.7V32.1z   M60,32.1h-3.7v-2.2H60V32.1z M67.5,32.1h-3.7v-2.2h3.7V32.1z M75,32.1h-3.7v-2.2H75V32.1z M82.4,32.1h-3.7v-2.2h3.7V32.1z   M89.9,32.1h-3.7v-2.2h3.7V32.1z M97.4,32.1h-3.7v-2.2h3.7V32.1z M104.9,32.1h-3.7v-2.2h3.7V32.1z M112.4,32.1h-3.7v-2.2h3.7V32.1z   M119.9,32.1h-3.7v-2.2h3.7V32.1z M127.3,32.1h-3.7v-2.2h3.7V32.1z M134.8,32.1h-3.7v-2.2h3.7V32.1z M139.4,32.8V31h1.1v1.1h-2v-2.2  h3.1v2.9H139.4z M139.4,40.3v-3.8h2.2v3.8H139.4z M139.4,47.8V44h2.2v3.8H139.4z M139.4,55.3v-3.8h2.2v3.8H139.4z M139.4,62.8V59  h2.2v3.8H139.4z M139.4,70.3v-3.8h2.2v3.8H139.4z M135.7,71.9h3.7v2.2h-3.7V71.9z M128.3,71.9h3.7v2.2h-3.7V71.9z M120.8,71.9h3.7  v2.2h-3.7V71.9z M113.3,71.9h3.7v2.2h-3.7V71.9z M105.8,71.9h3.7v2.2h-3.7V71.9z M98.3,71.9h3.7v2.2h-3.7V71.9z M90.8,71.9h3.7v2.2  h-3.7V71.9z M83.4,71.9h3.7v2.2h-3.7V71.9z M75.9,71.9h3.7v2.2h-3.7V71.9z M68.4,71.9h3.7v2.2h-3.7V71.9z M60.9,71.9h3.7v2.2h-3.7  V71.9z M53.4,71.9h3.7v2.2h-3.7V71.9z M45.9,71.9h3.7v2.2h-3.7V71.9z M38.5,71.9h3.7v2.2h-3.7V71.9z"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="121.5" height="54"/>
<path d="M74,49H73v-6.7c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1s0.8-0.8,0.9-1.1H74V49z"/>
<path d="M76.7,46.7l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3c0.3,0.3,0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5c0.3-0.3,0.5-0.8,0.5-1.3  c0-0.5-0.2-0.9-0.5-1.2c-0.3-0.3-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1l0.1-0.9c0.1,0,0.1,0,0.2,0c0.4,0,0.9-0.1,1.2-0.4  s0.5-0.6,0.5-1.1c0-0.4-0.1-0.7-0.4-1s-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4s-0.4,0.6-0.5,1.2l-1.1-0.2c0.1-0.7,0.4-1.3,0.9-1.6  c0.5-0.4,1-0.6,1.7-0.6c0.5,0,0.9,0.1,1.3,0.3s0.7,0.5,0.9,0.8s0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-0.9,0.7  c0.5,0.1,0.9,0.4,1.2,0.7c0.3,0.4,0.4,0.8,0.4,1.4c0,0.8-0.3,1.4-0.8,1.9c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7  C77.1,48,76.8,47.4,76.7,46.7z"/>
<path d="M83.6,47l1-0.1c0.1,0.5,0.2,0.8,0.5,1s0.6,0.3,0.9,0.3c0.3,0,0.6-0.1,0.9-0.2c0.2-0.1,0.4-0.3,0.6-0.6  c0.2-0.2,0.3-0.6,0.4-1c0.1-0.4,0.2-0.9,0.2-1.3c0,0,0-0.1,0-0.2c-0.2,0.3-0.5,0.6-0.9,0.8s-0.8,0.3-1.2,0.3c-0.7,0-1.3-0.3-1.8-0.8  c-0.5-0.5-0.7-1.2-0.7-2c0-0.9,0.3-1.6,0.8-2.1c0.5-0.5,1.2-0.8,1.9-0.8c0.6,0,1.1,0.2,1.5,0.5c0.5,0.3,0.8,0.7,1.1,1.3  c0.2,0.6,0.4,1.4,0.4,2.4c0,1.1-0.1,2-0.4,2.6c-0.2,0.7-0.6,1.1-1.1,1.5c-0.5,0.3-1,0.5-1.7,0.5c-0.7,0-1.2-0.2-1.6-0.6  S83.6,47.7,83.6,47z M87.9,43.2c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.4-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.6c-0.3,0.4-0.5,0.9-0.5,1.5  c0,0.5,0.2,1,0.5,1.3c0.3,0.3,0.7,0.5,1.2,0.5c0.5,0,0.9-0.2,1.2-0.5C87.7,44.3,87.9,43.8,87.9,43.2z"/>
<path d="M93.4,49v-2.1h-3.7v-1l3.9-5.6h0.9V46h1.2v1h-1.2V49H93.4z M93.4,46v-3.9L90.7,46H93.4z"/>
<path d="M100.7,49h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1s0.8-0.8,0.9-1.1h0.7V49z"/>
<path d="M104.6,49h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1  c0.1,0.4,0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5c-0.5,0.6-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V49z M104.6,45.8  c0,0.7,0.1,1.3,0.3,1.6c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8  c-0.3-0.4-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6C104.8,44.5,104.6,45.1,104.6,45.8z"/>
<path d="M113.4,49v-2.1h-3.7v-1l3.9-5.6h0.9V46h1.2v1h-1.2V49H113.4z M113.4,46v-3.9l-2.7,3.9H113.4z"/>
<path d="M118.3,44.3c-0.4-0.2-0.8-0.4-1-0.7S117,43,117,42.6c0-0.6,0.2-1.2,0.7-1.6c0.4-0.4,1-0.6,1.8-0.6c0.7,0,1.4,0.2,1.8,0.7  s0.7,1,0.7,1.6c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-0.9,0.7c0.5,0.2,0.9,0.4,1.2,0.8c0.3,0.4,0.4,0.8,0.4,1.4c0,0.7-0.3,1.4-0.8,1.9  c-0.5,0.5-1.2,0.8-2,0.8c-0.8,0-1.5-0.3-2-0.8c-0.5-0.5-0.8-1.1-0.8-1.9c0-0.6,0.1-1,0.4-1.4C117.4,44.7,117.8,44.5,118.3,44.3z   M117.8,46.5c0,0.3,0.1,0.6,0.2,0.9s0.4,0.5,0.6,0.7s0.6,0.2,0.9,0.2c0.5,0,0.9-0.2,1.2-0.5c0.3-0.3,0.5-0.7,0.5-1.2  c0-0.5-0.2-0.9-0.5-1.3c-0.3-0.3-0.8-0.5-1.3-0.5c-0.5,0-0.9,0.2-1.2,0.5C117.9,45.6,117.8,46,117.8,46.5z M118.1,42.6  c0,0.4,0.1,0.7,0.4,1c0.3,0.3,0.6,0.4,1,0.4c0.4,0,0.7-0.1,1-0.4c0.3-0.3,0.4-0.6,0.4-0.9c0-0.4-0.1-0.7-0.4-1  c-0.3-0.3-0.6-0.4-1-0.4c-0.4,0-0.7,0.1-1,0.4C118.2,41.9,118.1,42.2,118.1,42.6z"/>
<path d="M60.4,62.5v-8.6h6.2v1h-5.1v2.6h4.7v1h-4.7v2.9h5.3v1H60.4z"/>
<path d="M68.3,62.5v-8.6h1.2l4.5,6.7v-6.7h1.1v8.6h-1.2l-4.5-6.8v6.8H68.3z"/>
<path d="M83.1,59.5l1.1,0.3c-0.2,0.9-0.7,1.6-1.3,2.1s-1.4,0.7-2.3,0.7c-0.9,0-1.7-0.2-2.3-0.6s-1-0.9-1.3-1.6  c-0.3-0.7-0.5-1.5-0.5-2.3c0-0.9,0.2-1.7,0.5-2.3c0.3-0.7,0.8-1.2,1.5-1.5s1.3-0.5,2.1-0.5c0.9,0,1.6,0.2,2.2,0.7  c0.6,0.4,1,1.1,1.2,1.8L83,56.5c-0.2-0.6-0.5-1.1-0.9-1.4s-0.9-0.4-1.4-0.4c-0.7,0-1.2,0.2-1.7,0.5s-0.8,0.7-0.9,1.3  s-0.3,1.1-0.3,1.6c0,0.7,0.1,1.4,0.3,1.9s0.5,1,1,1.2c0.4,0.3,0.9,0.4,1.5,0.4c0.6,0,1.2-0.2,1.6-0.6C82.6,60.8,82.9,60.2,83.1,59.5  z"/>
<path d="M85.6,62.5v-8.6h3.8c0.8,0,1.3,0.1,1.7,0.2s0.7,0.4,1,0.8s0.4,0.8,0.4,1.3c0,0.6-0.2,1.1-0.6,1.5s-1,0.7-1.8,0.8  c0.3,0.1,0.5,0.3,0.7,0.4c0.3,0.3,0.6,0.7,0.9,1.1l1.5,2.3h-1.4l-1.1-1.8c-0.3-0.5-0.6-0.9-0.8-1.2s-0.4-0.5-0.6-0.6  c-0.2-0.1-0.3-0.2-0.5-0.2c-0.1,0-0.3,0-0.6,0h-1.3v3.8H85.6z M86.8,57.7h2.4c0.5,0,0.9-0.1,1.2-0.2c0.3-0.1,0.5-0.3,0.7-0.5  c0.2-0.2,0.2-0.5,0.2-0.8c0-0.4-0.1-0.7-0.4-1c-0.3-0.3-0.8-0.4-1.4-0.4h-2.7V57.7z"/>
<path d="M96.5,62.5v-3.6l-3.3-5h1.4l1.7,2.6c0.3,0.5,0.6,1,0.9,1.5c0.3-0.4,0.6-1,0.9-1.5l1.7-2.5h1.3l-3.4,5v3.6H96.5z"/>
<path d="M102,62.5v-8.6h3.2c0.6,0,1,0,1.3,0.1c0.4,0.1,0.8,0.2,1.1,0.4c0.3,0.2,0.5,0.5,0.7,0.8s0.3,0.7,0.3,1.2  c0,0.7-0.2,1.3-0.7,1.9c-0.5,0.5-1.3,0.8-2.5,0.8h-2.2v3.5H102z M103.2,58h2.2c0.7,0,1.3-0.1,1.6-0.4c0.3-0.3,0.5-0.7,0.5-1.2  c0-0.4-0.1-0.7-0.3-0.9s-0.4-0.4-0.7-0.5c-0.2-0.1-0.5-0.1-1.1-0.1h-2.2V58z"/>
<path d="M112.2,62.5v-7.6h-2.8v-1h6.8v1h-2.8v7.6H112.2z"/>
<path d="M117.3,62.5v-8.6h6.2v1h-5.1v2.6h4.7v1h-4.7v2.9h5.3v1H117.3z"/>
<path d="M125.3,62.5v-8.6h3c0.7,0,1.2,0,1.5,0.1c0.5,0.1,0.9,0.3,1.3,0.6c0.5,0.4,0.8,0.9,1,1.5s0.3,1.3,0.3,2  c0,0.7-0.1,1.2-0.2,1.7c-0.2,0.5-0.3,0.9-0.6,1.3c-0.2,0.3-0.5,0.6-0.8,0.8c-0.3,0.2-0.6,0.3-1,0.4s-0.9,0.1-1.4,0.1H125.3z   M126.4,61.5h1.8c0.6,0,1-0.1,1.3-0.2c0.3-0.1,0.6-0.3,0.8-0.4c0.3-0.3,0.5-0.6,0.6-1.1s0.2-1,0.2-1.7c0-0.9-0.1-1.6-0.4-2.1  c-0.3-0.5-0.7-0.8-1.1-1c-0.3-0.1-0.8-0.2-1.5-0.2h-1.8V61.5z"/>
<rect x="59.4" y="38.5" fill-rule="evenodd" fill="none" width="73.3" height="27"/>
</svg></artwork>

### CBOR Diagnostic Notation

~~~
200(   ; envelope
   201(   ; crypto-msg
      [
         h'130b06fd0bfed08e',
         h'cbe81743cebf0e55dc77b55d',
         h'02dc64f9c7d7b0a162b36030a1b6ecaa',
         h'd8cb582013941b487c1ddebce827b6ec3f46d982938acdc7e3b6a140\
           db36062d9519dd2f'
      ]
   )
)
~~~

### CBOR Hex

~~~
d8c8d8c984486bfa027df241def04c5520ca6d9d798ffd32d075c450d4b4\
3d97a37eb280fdd89cf152ccf57d5824d8cb5820278403504ad3a9a9c24c\
1b35a3673eee165a5d523f8d2a5cf5ce6dd25a37f110
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
13941b48 ELIDED
~~~

### Mermaid

<artwork type="svg"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.2" baseProfile="tiny" width="151.2px" height="104px" viewBox="0 0 151.2 104" xml:space="preserve">
<path d="M41.5,71.9h3.7v2.2h-3.7V71.9z M39.9,67.4l1.7,3.4l-2,1l-1.7-3.4L39.9,67.4z M36.6,60.7l1.7,3.4l-2,1l-1.7-3.4L36.6,60.7z   M33.2,54l1.7,3.4l-2,1L31.2,55L33.2,54z M34.1,48.3l-1.7,3.4l-2-1l1.7-3.4L34.1,48.3z M37.5,41.6l-1.7,3.4l-2-1l1.7-3.4L37.5,41.6z   M40.8,34.9l-1.7,3.4l-2-1l1.7-3.4L40.8,34.9z M45.2,32.1h-3.7V31l1,0.5l0,0l-2-1l0.3-0.6h4.4V32.1z M52.7,32.1H49v-2.2h3.7V32.1z   M60.2,32.1h-3.7v-2.2h3.7V32.1z M67.7,32.1h-3.7v-2.2h3.7V32.1z M75.2,32.1h-3.7v-2.2h3.7V32.1z M82.7,32.1h-3.7v-2.2h3.7V32.1z   M90.1,32.1h-3.7v-2.2h3.7V32.1z M97.6,32.1h-3.7v-2.2h3.7V32.1z M105.1,32.1h-3.7v-2.2h3.7V32.1z M110,34.1l-1.3-2.5l1-0.5v1.1  h-0.9v-2.2h1.6L112,33L110,34.1z M113.4,40.8l-1.7-3.4l2-1l1.7,3.4L113.4,40.8z M116.7,47.5l-1.7-3.4l2-1l1.7,3.4L116.7,47.5z   M118.4,53.2l0.8-1.7l1,0.5l-1,0.5l-0.8-1.7l2-1l1.1,2.2l-1.1,2.2L118.4,53.2z M115.1,59.9l1.7-3.4l2,1l-1.7,3.4L115.1,59.9z   M111.7,66.6l1.7-3.4l2,1l-1.7,3.4L111.7,66.6z M108.9,71.9h0.9V73l-1-0.5l1.3-2.6l2,1l-1.6,3.2h-1.6V71.9z M101.4,71.9h3.7v2.2  h-3.7V71.9z M93.9,71.9h3.7v2.2h-3.7V71.9z M86.4,71.9h3.7v2.2h-3.7V71.9z M78.9,71.9h3.7v2.2h-3.7V71.9z M71.4,71.9h3.7v2.2h-3.7  V71.9z M63.9,71.9h3.7v2.2h-3.7V71.9z M56.5,71.9h3.7v2.2h-3.7V71.9z M49,71.9h3.7v2.2H49V71.9z"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="101.2" height="54"/>
<path d="M53.4,49h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1s0.8-0.8,0.9-1.1h0.7V49z"/>
<path d="M56.1,46.7l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3s0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5s0.5-0.8,0.5-1.3c0-0.5-0.2-0.9-0.5-1.2  s-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1l0.1-0.9c0.1,0,0.1,0,0.2,0c0.4,0,0.9-0.1,1.2-0.4s0.5-0.6,0.5-1.1c0-0.4-0.1-0.7-0.4-1  s-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4c-0.3,0.3-0.4,0.6-0.5,1.2l-1.1-0.2c0.1-0.7,0.4-1.3,0.9-1.6c0.5-0.4,1-0.6,1.7-0.6  c0.5,0,0.9,0.1,1.3,0.3s0.7,0.5,0.9,0.8c0.2,0.3,0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1c-0.2,0.3-0.5,0.5-0.9,0.7  c0.5,0.1,0.9,0.4,1.2,0.7s0.4,0.8,0.4,1.4c0,0.8-0.3,1.4-0.8,1.9c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7  C56.5,48,56.2,47.4,56.1,46.7z"/>
<path d="M63,47l1-0.1c0.1,0.5,0.2,0.8,0.5,1c0.2,0.2,0.6,0.3,0.9,0.3c0.3,0,0.6-0.1,0.9-0.2c0.2-0.1,0.4-0.3,0.6-0.6s0.3-0.6,0.4-1  s0.2-0.9,0.2-1.3c0,0,0-0.1,0-0.2c-0.2,0.3-0.5,0.6-0.9,0.8s-0.8,0.3-1.2,0.3c-0.7,0-1.3-0.3-1.8-0.8c-0.5-0.5-0.7-1.2-0.7-2  c0-0.9,0.3-1.6,0.8-2.1c0.5-0.5,1.2-0.8,1.9-0.8c0.6,0,1.1,0.2,1.5,0.5c0.5,0.3,0.8,0.7,1.1,1.3c0.2,0.6,0.4,1.4,0.4,2.4  c0,1.1-0.1,2-0.4,2.6c-0.2,0.7-0.6,1.1-1.1,1.5c-0.5,0.3-1,0.5-1.7,0.5c-0.7,0-1.2-0.2-1.6-0.6S63,47.7,63,47z M67.3,43.2  c0-0.6-0.2-1.1-0.5-1.4s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.6s-0.5,0.9-0.5,1.5c0,0.5,0.2,1,0.5,1.3s0.7,0.5,1.2,0.5  c0.5,0,0.9-0.2,1.2-0.5S67.3,43.8,67.3,43.2z"/>
<path d="M72.8,49v-2.1h-3.7v-1l3.9-5.6h0.9V46H75v1h-1.2V49H72.8z M72.8,46v-3.9L70.1,46H72.8z"/>
<path d="M80.1,49H79v-6.7c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1s0.8-0.8,0.9-1.1h0.7V49z"/>
<path d="M84.1,49h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5c-0.5,0.6-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V49z M84,45.8c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  C84.2,44.5,84,45.1,84,45.8z"/>
<path d="M92.8,49v-2.1h-3.7v-1l3.9-5.6h0.9V46H95v1h-1.2V49H92.8z M92.8,46v-3.9L90.1,46H92.8z"/>
<path d="M97.7,44.3c-0.4-0.2-0.8-0.4-1-0.7c-0.2-0.3-0.3-0.7-0.3-1.1c0-0.6,0.2-1.2,0.7-1.6c0.4-0.4,1-0.6,1.8-0.6  c0.7,0,1.4,0.2,1.8,0.7c0.5,0.4,0.7,1,0.7,1.6c0,0.4-0.1,0.7-0.3,1c-0.2,0.3-0.5,0.5-1,0.7c0.5,0.2,0.9,0.4,1.2,0.8  c0.3,0.4,0.4,0.8,0.4,1.4c0,0.7-0.3,1.4-0.8,1.9c-0.5,0.5-1.2,0.8-2,0.8c-0.8,0-1.5-0.3-2-0.8c-0.5-0.5-0.8-1.1-0.8-1.9  c0-0.6,0.1-1,0.4-1.4C96.8,44.7,97.2,44.5,97.7,44.3z M97.2,46.5c0,0.3,0.1,0.6,0.2,0.9c0.1,0.3,0.4,0.5,0.6,0.7s0.6,0.2,0.9,0.2  c0.5,0,0.9-0.2,1.2-0.5s0.5-0.7,0.5-1.2c0-0.5-0.2-0.9-0.5-1.3s-0.8-0.5-1.3-0.5c-0.5,0-0.9,0.2-1.2,0.5S97.2,46,97.2,46.5z   M97.5,42.6c0,0.4,0.1,0.7,0.4,1c0.3,0.3,0.6,0.4,1,0.4c0.4,0,0.7-0.1,1-0.4c0.3-0.3,0.4-0.6,0.4-0.9c0-0.4-0.1-0.7-0.4-1  c-0.3-0.3-0.6-0.4-1-0.4c-0.4,0-0.7,0.1-1,0.4C97.7,41.9,97.5,42.2,97.5,42.6z"/>
<path d="M54.9,62.5v-8.6h6.2v1h-5.1v2.6h4.7v1h-4.7v2.9h5.3v1H54.9z"/>
<path d="M62.8,62.5v-8.6H64v7.6h4.2v1H62.8z"/>
<path d="M69.8,62.5v-8.6h1.1v8.6H69.8z"/>
<path d="M72.9,62.5v-8.6h3c0.7,0,1.2,0,1.5,0.1c0.5,0.1,0.9,0.3,1.3,0.6c0.5,0.4,0.8,0.9,1,1.5s0.3,1.3,0.3,2c0,0.7-0.1,1.2-0.2,1.7  c-0.2,0.5-0.3,0.9-0.6,1.3c-0.2,0.3-0.5,0.6-0.8,0.8c-0.3,0.2-0.6,0.3-1,0.4c-0.4,0.1-0.9,0.1-1.4,0.1H72.9z M74,61.5h1.8  c0.6,0,1-0.1,1.3-0.2s0.6-0.3,0.8-0.4c0.3-0.3,0.5-0.6,0.6-1.1c0.2-0.5,0.2-1,0.2-1.7c0-0.9-0.1-1.6-0.4-2.1c-0.3-0.5-0.7-0.8-1.1-1  c-0.3-0.1-0.8-0.2-1.5-0.2H74V61.5z"/>
<path d="M81.6,62.5v-8.6h6.2v1h-5.1v2.6h4.7v1h-4.7v2.9H88v1H81.6z"/>
<path d="M89.5,62.5v-8.6h3c0.7,0,1.2,0,1.5,0.1c0.5,0.1,0.9,0.3,1.3,0.6c0.5,0.4,0.8,0.9,1,1.5s0.3,1.3,0.3,2c0,0.7-0.1,1.2-0.2,1.7  c-0.2,0.5-0.3,0.9-0.6,1.3c-0.2,0.3-0.5,0.6-0.8,0.8c-0.3,0.2-0.6,0.3-1,0.4c-0.4,0.1-0.9,0.1-1.4,0.1H89.5z M90.7,61.5h1.8  c0.6,0,1-0.1,1.3-0.2s0.6-0.3,0.8-0.4c0.3-0.3,0.5-0.6,0.6-1.1c0.2-0.5,0.2-1,0.2-1.7c0-0.9-0.1-1.6-0.4-2.1c-0.3-0.5-0.7-0.8-1.1-1  c-0.3-0.1-0.8-0.2-1.5-0.2h-1.8V61.5z"/>
<rect x="49" y="38.5" fill-rule="evenodd" fill="none" width="53.2" height="27"/>
</svg></artwork>

### CBOR Diagnostic Notation

~~~
200(   ; envelope
   203(   ; crypto-digest
     h'13941b487c1ddebce827b6ec3f46d982938acdc7e3b6a140db36062d9519dd2f'
   )
)
~~~

### CBOR Hex

~~~
d8c8d8cb5820278403504ad3a9a9c24c1b35a3673eee165a5d523f8d2a5cf5ce6dd2\
5a37f110
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
8955db5e NODE
    13941b48 subj "Alice"
    78d666eb ASSERTION
        db7dd21c pred "knows"
        13b74194 obj "Bob"
~~~

### Mermaid

<artwork type="svg"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.2" baseProfile="tiny" width="533px" height="223.2px" viewBox="0 0 533 223.2" xml:space="preserve">
<path fill="none" stroke="#000000" stroke-width="1.4997" d="M94.2,73.7l5.8-3.6c5.8-3.6,17.4-10.8,28.2-14.5s20.7-3.6,25.6-3.6h5"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="483" height="173.2"/>
<polygon fill="black" points="150.8,47.5 159.8,52 150.8,56.5 "/>
<rect x="149.3" y="47.5" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.4997" d="M94.2,109.8l5.8,3.6c5.8,3.6,17.4,10.8,31.7,14.5s31.2,3.6,39.7,3.6  h8.5"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="483" height="173.2"/>
<polygon fill="black" points="171.9,127 180.9,131.5 171.9,136 "/>
<rect x="170.4" y="127" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.4997" d="M274.6,112.5l8.6-3.5c8.6-3.5,25.9-10.4,39.7-13.9  c13.8-3.5,24-3.5,29.1-3.5h5.1"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="483" height="173.2"/>
<polygon fill="black" points="349.1,87.2 358.1,91.8 349.1,96.2 "/>
<rect x="347.6" y="87.2" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.4997" d="M274.6,150.5l8.6,3.5c8.6,3.5,25.9,10.4,40.8,13.9  c14.8,3.5,27.2,3.5,33.4,3.5h6.2"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="483" height="173.2"/>
<polygon fill="black" points="355.4,166.8 364.4,171.2 355.4,175.8 "/>
<rect x="353.9" y="166.8" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path d="M118.5,53.9l1-0.2c0.1,0.4,0.2,0.7,0.5,1c0.3,0.2,0.6,0.3,1.1,0.3c0.5,0,0.8-0.1,1.1-0.3s0.4-0.4,0.4-0.7  c0-0.2-0.1-0.4-0.3-0.6c-0.1-0.1-0.5-0.2-1.1-0.4c-0.8-0.2-1.3-0.4-1.6-0.5s-0.5-0.3-0.7-0.6s-0.2-0.5-0.2-0.8  c0-0.3,0.1-0.5,0.2-0.8s0.3-0.4,0.5-0.6c0.2-0.1,0.4-0.2,0.7-0.3c0.3-0.1,0.6-0.1,0.9-0.1c0.5,0,0.9,0.1,1.3,0.2  c0.4,0.1,0.6,0.3,0.8,0.6s0.3,0.6,0.4,1l-1,0.1c0-0.3-0.2-0.6-0.4-0.8s-0.5-0.3-1-0.3c-0.5,0-0.8,0.1-1,0.2  c-0.2,0.2-0.3,0.3-0.3,0.6c0,0.1,0,0.3,0.1,0.4c0.1,0.1,0.2,0.2,0.4,0.3c0.1,0,0.4,0.1,0.9,0.3c0.7,0.2,1.3,0.4,1.6,0.5  s0.5,0.3,0.7,0.6s0.3,0.5,0.3,0.9c0,0.4-0.1,0.7-0.3,1s-0.5,0.6-0.9,0.7c-0.4,0.2-0.8,0.3-1.3,0.3c-0.8,0-1.4-0.2-1.8-0.5  S118.6,54.6,118.5,53.9z"/>
<path d="M129,55.8v-0.9c-0.5,0.7-1.1,1.1-2,1.1c-0.4,0-0.7-0.1-1-0.2c-0.3-0.1-0.6-0.3-0.7-0.5s-0.3-0.5-0.3-0.8  c0-0.2-0.1-0.5-0.1-1v-3.9h1.1V53c0,0.6,0,0.9,0.1,1.1c0.1,0.3,0.2,0.5,0.4,0.7s0.5,0.2,0.8,0.2c0.3,0,0.6-0.1,0.9-0.2  s0.5-0.4,0.6-0.7s0.2-0.7,0.2-1.2v-3.3h1.1v6.2H129z"/>
<path d="M132.5,55.8h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5c-0.5,0.6-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V55.8z M132.5,52.6c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8c-0.3-0.4-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6S132.5,51.8,132.5,52.6z"/>
<path d="M136.9,58.2l0.2-0.9c0.2,0.1,0.4,0.1,0.5,0.1c0.2,0,0.4-0.1,0.5-0.2c0.1-0.1,0.2-0.5,0.2-1.1v-6.5h1.1v6.6  c0,0.8-0.1,1.3-0.3,1.6c-0.3,0.4-0.7,0.6-1.3,0.6C137.4,58.3,137.2,58.2,136.9,58.2z M138.2,48.4v-1.2h1.1v1.2H138.2z"/>
<rect x="118.1" y="45.2" fill-rule="evenodd" fill="none" width="21.7" height="13.5"/>
<path d="M315.2,97.9v-8.6h1v0.8c0.2-0.3,0.5-0.6,0.8-0.7s0.6-0.2,1-0.2c0.5,0,1,0.1,1.4,0.4s0.7,0.7,0.9,1.2s0.3,1,0.3,1.6  c0,0.6-0.1,1.2-0.3,1.7c-0.2,0.5-0.6,0.9-1,1.2s-0.9,0.4-1.4,0.4c-0.4,0-0.7-0.1-0.9-0.2s-0.5-0.3-0.7-0.6v3H315.2z M316.2,92.4  c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8  c-0.3-0.4-0.7-0.6-1.2-0.6c-0.4,0-0.8,0.2-1.2,0.6S316.2,91.6,316.2,92.4z"/>
<path d="M321.9,95.5v-6.2h0.9v0.9c0.2-0.4,0.5-0.7,0.7-0.9s0.4-0.2,0.7-0.2c0.4,0,0.7,0.1,1.1,0.3l-0.4,1c-0.3-0.2-0.5-0.2-0.8-0.2  c-0.2,0-0.4,0.1-0.6,0.2s-0.3,0.3-0.4,0.6c-0.1,0.4-0.2,0.8-0.2,1.2v3.3H321.9z"/>
<path d="M330.1,93.5l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5s-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8c-0.5-0.6-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4c0.5-0.6,1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8s0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6c0,0.7,0.2,1.2,0.6,1.6  s0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3S330,93.9,330.1,93.5z M326.7,91.8h3.5c0-0.5-0.2-0.9-0.4-1.2c-0.3-0.4-0.8-0.6-1.3-0.6  c-0.5,0-0.9,0.2-1.2,0.5S326.7,91.2,326.7,91.8z"/>
<path d="M336.6,95.5v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6v-3.1h1v8.6H336.6z M333.3,92.4  c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6S333.3,91.6,333.3,92.4z"/>
<rect x="314.4" y="85" fill-rule="evenodd" fill="none" width="24" height="13.5"/>
<path d="M318.8,171.9c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8c0.5,0.6,0.8,1.3,0.8,2.3  c0,0.8-0.1,1.4-0.4,1.9c-0.2,0.5-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8C319.1,173.7,318.8,172.9,318.8,171.9z   M319.9,171.9c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7  c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-1,0.2-1.3,0.6C320.1,170.5,319.9,171.1,319.9,171.9z"/>
<path d="M326.9,175h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1s0.2,0.8,0.2,1.3  c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V175z M326.8,171.8c0,0.7,0.1,1.3,0.3,1.6c0.3,0.5,0.8,0.8,1.3,0.8  c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6S326.8,171.1,326.8,171.8z"/>
<path d="M331.2,177.4l0.2-0.9c0.2,0.1,0.4,0.1,0.5,0.1c0.2,0,0.4-0.1,0.5-0.2s0.2-0.5,0.2-1.1v-6.5h1.1v6.6c0,0.8-0.1,1.3-0.3,1.6  c-0.3,0.4-0.7,0.6-1.3,0.6C331.8,177.5,331.5,177.5,331.2,177.4z M332.6,167.6v-1.2h1.1v1.2H332.6z"/>
<rect x="318.4" y="164.5" fill-rule="evenodd" fill="none" width="15.7" height="13.5"/>
<path fill="none" stroke="#000000" stroke-width="2.2496" d="M99.4,91.8c0,1.1-0.1,2.2-0.2,3.4c-0.1,1.1-0.3,2.2-0.5,3.3  c-0.2,1.1-0.5,2.2-0.8,3.3c-0.3,1.1-0.7,2.1-1.1,3.2c-0.4,1-0.9,2-1.4,3c-0.5,1-1.1,1.9-1.7,2.9c-0.6,0.9-1.3,1.8-2,2.7  s-1.5,1.7-2.3,2.5s-1.6,1.5-2.5,2.3c-0.9,0.7-1.8,1.4-2.7,2c-0.9,0.6-1.9,1.2-2.9,1.7c-1,0.5-2,1-3,1.4s-2.1,0.8-3.2,1.1  c-1.1,0.3-2.2,0.6-3.3,0.8s-2.2,0.4-3.3,0.5c-1.1,0.1-2.2,0.2-3.4,0.2c-1.1,0-2.2-0.1-3.4-0.2c-1.1-0.1-2.2-0.3-3.3-0.5  c-1.1-0.2-2.2-0.5-3.3-0.8c-1.1-0.3-2.1-0.7-3.2-1.1s-2-0.9-3-1.4c-1-0.5-1.9-1.1-2.9-1.7c-0.9-0.6-1.8-1.3-2.7-2  c-0.9-0.7-1.7-1.5-2.5-2.3s-1.5-1.6-2.3-2.5s-1.4-1.8-2-2.7c-0.6-0.9-1.2-1.9-1.7-2.9c-0.5-1-1-2-1.4-3c-0.4-1-0.8-2.1-1.1-3.2  c-0.3-1.1-0.6-2.2-0.8-3.3c-0.2-1.1-0.4-2.2-0.5-3.3C31.1,94,31,92.9,31,91.8c0-1.1,0.1-2.2,0.2-3.4c0.1-1.1,0.3-2.2,0.5-3.3  c0.2-1.1,0.5-2.2,0.8-3.3c0.3-1.1,0.7-2.1,1.1-3.2c0.4-1,0.9-2,1.4-3c0.5-1,1.1-1.9,1.7-2.9c0.6-0.9,1.3-1.8,2-2.7s1.5-1.7,2.3-2.5  s1.6-1.5,2.5-2.3c0.9-0.7,1.8-1.4,2.7-2c0.9-0.6,1.9-1.2,2.9-1.7c1-0.5,2-1,3-1.4s2.1-0.8,3.2-1.1c1.1-0.3,2.2-0.6,3.3-0.8  c1.1-0.2,2.2-0.4,3.3-0.5c1.1-0.1,2.2-0.2,3.4-0.2c1.1,0,2.2,0.1,3.4,0.2c1.1,0.1,2.2,0.3,3.3,0.5s2.2,0.5,3.3,0.8  c1.1,0.3,2.1,0.7,3.2,1.1s2,0.9,3,1.4c1,0.5,1.9,1.1,2.9,1.7c0.9,0.6,1.8,1.3,2.7,2c0.9,0.7,1.7,1.5,2.5,2.3s1.5,1.6,2.3,2.5  s1.4,1.8,2,2.7c0.6,0.9,1.2,1.9,1.7,2.9c0.5,1,1,2,1.4,3c0.4,1,0.8,2.1,1.1,3.2c0.3,1.1,0.6,2.2,0.8,3.3c0.2,1.1,0.4,2.2,0.5,3.3  C99.3,89.5,99.4,90.6,99.4,91.8z"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="483" height="173.2"/>
<path d="M40.6,84.1c-0.4-0.2-0.8-0.4-1-0.7s-0.3-0.7-0.3-1.1c0-0.6,0.2-1.2,0.7-1.6c0.4-0.4,1-0.6,1.8-0.6c0.8,0,1.4,0.2,1.8,0.7  s0.7,1,0.7,1.6c0,0.4-0.1,0.7-0.3,1c-0.2,0.3-0.5,0.5-1,0.7c0.5,0.2,0.9,0.4,1.2,0.8c0.3,0.4,0.4,0.8,0.4,1.4c0,0.7-0.3,1.4-0.8,1.9  c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.5-0.3-2-0.8C39.2,87.6,39,87,39,86.3c0-0.6,0.1-1,0.4-1.4S40.1,84.2,40.6,84.1z M40.1,86.3  c0,0.3,0.1,0.6,0.2,0.9c0.1,0.3,0.4,0.5,0.6,0.7s0.6,0.2,0.9,0.2c0.5,0,0.9-0.2,1.2-0.5c0.3-0.3,0.5-0.7,0.5-1.2  c0-0.5-0.2-0.9-0.5-1.3c-0.3-0.3-0.8-0.5-1.3-0.5c-0.5,0-0.9,0.2-1.2,0.5C40.2,85.4,40.1,85.8,40.1,86.3z M40.4,82.3  c0,0.4,0.1,0.7,0.4,1s0.6,0.4,1,0.4c0.4,0,0.7-0.1,1-0.4c0.3-0.3,0.4-0.6,0.4-0.9c0-0.4-0.1-0.7-0.4-1c-0.3-0.3-0.6-0.4-1-0.4  c-0.4,0-0.7,0.1-1,0.4S40.4,81.9,40.4,82.3z"/>
<path d="M45.8,86.8l1-0.1c0.1,0.5,0.2,0.8,0.5,1s0.6,0.3,0.9,0.3c0.3,0,0.6-0.1,0.9-0.2s0.4-0.3,0.6-0.6s0.3-0.6,0.4-1  s0.2-0.9,0.2-1.3c0,0,0-0.1,0-0.2c-0.2,0.3-0.5,0.6-0.9,0.8c-0.4,0.2-0.8,0.3-1.2,0.3c-0.7,0-1.3-0.3-1.8-0.8s-0.7-1.2-0.7-2  c0-0.9,0.3-1.6,0.8-2.1c0.5-0.5,1.2-0.8,1.9-0.8c0.6,0,1.1,0.2,1.5,0.5c0.5,0.3,0.8,0.7,1.1,1.3c0.2,0.6,0.4,1.4,0.4,2.4  c0,1.1-0.1,2-0.4,2.6c-0.2,0.7-0.6,1.1-1.1,1.5s-1,0.5-1.7,0.5c-0.7,0-1.2-0.2-1.6-0.6C46.2,88,45.9,87.4,45.8,86.8z M50.1,83  c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.4-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.6s-0.5,0.9-0.5,1.5c0,0.5,0.2,1,0.5,1.3s0.7,0.5,1.2,0.5  c0.5,0,0.9-0.2,1.2-0.5C50,84.1,50.1,83.6,50.1,83z"/>
<path d="M52.3,86.5l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2c0.3,0.3,0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6c0.4-0.4,0.5-0.9,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.3-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2s-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4l-0.5,2.3  c0.5-0.4,1.1-0.5,1.6-0.5c0.8,0,1.4,0.3,1.9,0.8c0.5,0.5,0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1  c-0.8,0-1.4-0.2-1.9-0.7C52.7,87.8,52.4,87.2,52.3,86.5z"/>
<path d="M59,86.5l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2c0.3,0.3,0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6c0.4-0.4,0.5-0.9,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.3-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2s-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4l-0.5,2.3  c0.5-0.4,1.1-0.5,1.6-0.5c0.8,0,1.4,0.3,1.9,0.8c0.5,0.5,0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1  c-0.8,0-1.4-0.2-1.9-0.7C59.4,87.8,59.1,87.2,59,86.5z"/>
<path d="M70,88.8V88c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4c-0.4-0.3-0.7-0.7-1-1.1c-0.2-0.5-0.3-1.1-0.3-1.7  c0-0.6,0.1-1.2,0.3-1.7s0.5-0.9,0.9-1.2c0.4-0.3,0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6v-3.1h1v8.6H70z M66.7,85.6  c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9  c-0.3-0.4-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6C66.8,84.2,66.7,84.8,66.7,85.6z"/>
<path d="M73.6,88.8h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5c-0.5,0.6-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V88.8z M73.6,85.6c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8c-0.3-0.4-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6S73.6,84.8,73.6,85.6z"/>
<path d="M79,86.5l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2c0.3,0.3,0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6c0.4-0.4,0.5-0.9,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.3-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2s-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4l-0.5,2.3  c0.5-0.4,1.1-0.5,1.6-0.5c0.8,0,1.4,0.3,1.9,0.8c0.5,0.5,0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1  c-0.8,0-1.4-0.2-1.9-0.7C79.4,87.8,79.1,87.2,79,86.5z"/>
<path d="M90.2,86.7l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5c-0.5,0.4-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8s-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4s1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8c0.5,0.6,0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6c0,0.7,0.2,1.2,0.6,1.6  s0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3C89.9,87.5,90.1,87.2,90.2,86.7z M86.8,85h3.5c0-0.5-0.2-0.9-0.4-1.2c-0.3-0.4-0.8-0.6-1.3-0.6  c-0.5,0-0.9,0.2-1.2,0.5S86.8,84.5,86.8,85z"/>
<path d="M48.8,102.2v-8.6h1.2l4.5,6.7v-6.7h1.1v8.6h-1.2l-4.5-6.8v6.8H48.8z"/>
<path d="M57.1,98.1c0-1.4,0.4-2.5,1.1-3.3c0.8-0.8,1.8-1.2,3-1.2c0.8,0,1.5,0.2,2.1,0.6c0.6,0.4,1.1,0.9,1.5,1.6  c0.3,0.7,0.5,1.4,0.5,2.3c0,0.9-0.2,1.7-0.5,2.3c-0.4,0.7-0.8,1.2-1.5,1.6c-0.6,0.4-1.3,0.5-2.1,0.5c-0.8,0-1.5-0.2-2.2-0.6  c-0.6-0.4-1.1-0.9-1.4-1.6S57.1,98.8,57.1,98.1z M58.3,98.1c0,1,0.3,1.9,0.8,2.4s1.3,0.9,2.1,0.9c0.9,0,1.6-0.3,2.1-0.9  c0.6-0.6,0.8-1.5,0.8-2.6c0-0.7-0.1-1.3-0.4-1.8s-0.6-0.9-1-1.2s-1-0.4-1.5-0.4c-0.8,0-1.5,0.3-2.1,0.8  C58.6,95.9,58.3,96.8,58.3,98.1z"/>
<path d="M66.8,102.2v-8.6h3c0.7,0,1.2,0,1.5,0.1c0.5,0.1,0.9,0.3,1.3,0.6c0.5,0.4,0.8,0.9,1,1.5s0.3,1.3,0.3,2  c0,0.7-0.1,1.2-0.2,1.7s-0.3,0.9-0.6,1.3s-0.5,0.6-0.8,0.8s-0.6,0.3-1,0.4c-0.4,0.1-0.9,0.1-1.4,0.1H66.8z M67.9,101.2h1.8  c0.6,0,1-0.1,1.3-0.2s0.6-0.3,0.8-0.4c0.3-0.3,0.5-0.6,0.6-1.1c0.1-0.5,0.2-1,0.2-1.7c0-0.9-0.1-1.6-0.4-2.1s-0.7-0.8-1.1-1  c-0.3-0.1-0.8-0.2-1.5-0.2h-1.8V101.2z"/>
<path d="M75.5,102.2v-8.6h6.2v1h-5.1v2.6h4.8v1h-4.8v2.9h5.3v1H75.5z"/>
<rect x="38.5" y="78.2" fill-rule="evenodd" fill="none" width="53.2" height="27"/>
<rect x="158.9" y="31" fill="none" stroke="#000000" stroke-width="2.2496" width="136.8" height="42"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="483" height="173.2"/>
<path d="M205.1,49H204v-6.7c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1c0.4-0.4,0.8-0.8,0.9-1.1h0.7V49z"/>
<path d="M207.8,46.7l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3s0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5c0.3-0.3,0.5-0.8,0.5-1.3  c0-0.5-0.2-0.9-0.5-1.2c-0.3-0.3-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1L210,44c0.1,0,0.1,0,0.2,0c0.4,0,0.9-0.1,1.2-0.4  c0.4-0.2,0.5-0.6,0.5-1.1c0-0.4-0.1-0.7-0.4-1c-0.3-0.3-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4s-0.4,0.6-0.5,1.2l-1.1-0.2  c0.1-0.7,0.4-1.3,0.9-1.6c0.5-0.4,1-0.6,1.7-0.6c0.5,0,0.9,0.1,1.3,0.3c0.4,0.2,0.7,0.5,0.9,0.8c0.2,0.3,0.3,0.7,0.3,1.1  c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-0.9,0.7c0.5,0.1,0.9,0.4,1.2,0.7c0.3,0.4,0.4,0.8,0.4,1.4c0,0.8-0.3,1.4-0.8,1.9  c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7S207.8,47.4,207.8,46.7z"/>
<path d="M214.6,47l1-0.1c0.1,0.5,0.2,0.8,0.5,1s0.6,0.3,0.9,0.3c0.3,0,0.6-0.1,0.9-0.2s0.4-0.3,0.6-0.6s0.3-0.6,0.4-1  s0.2-0.9,0.2-1.3c0,0,0-0.1,0-0.2c-0.2,0.3-0.5,0.6-0.9,0.8c-0.4,0.2-0.8,0.3-1.2,0.3c-0.7,0-1.3-0.3-1.8-0.8s-0.7-1.2-0.7-2  c0-0.9,0.3-1.6,0.8-2.1c0.5-0.5,1.2-0.8,1.9-0.8c0.6,0,1.1,0.2,1.5,0.5c0.5,0.3,0.8,0.7,1.1,1.3c0.2,0.6,0.4,1.4,0.4,2.4  c0,1.1-0.1,2-0.4,2.6c-0.2,0.7-0.6,1.1-1.1,1.5s-1,0.5-1.7,0.5c-0.7,0-1.2-0.2-1.6-0.6C214.9,48.2,214.7,47.7,214.6,47z M218.9,43.2  c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.4-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.6s-0.5,0.9-0.5,1.5c0,0.5,0.2,1,0.5,1.3s0.7,0.5,1.2,0.5  c0.5,0,0.9-0.2,1.2-0.5C218.7,44.3,218.9,43.8,218.9,43.2z"/>
<path d="M224.5,49v-2.1h-3.7v-1l3.9-5.6h0.9V46h1.2v1h-1.2V49H224.5z M224.5,46v-3.9l-2.7,3.9H224.5z"/>
<path d="M231.7,49h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1c0.4-0.4,0.8-0.8,0.9-1.1h0.7V49z"/>
<path d="M235.7,49h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5c-0.5,0.6-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V49z M235.7,45.8c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8c-0.3-0.4-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6S235.7,45.1,235.7,45.8z"/>
<path d="M244.5,49v-2.1h-3.7v-1l3.9-5.6h0.9V46h1.2v1h-1.2V49H244.5z M244.5,46v-3.9l-2.7,3.9H244.5z"/>
<path d="M249.4,44.3c-0.4-0.2-0.8-0.4-1-0.7s-0.3-0.7-0.3-1.1c0-0.6,0.2-1.2,0.7-1.6c0.4-0.4,1-0.6,1.8-0.6c0.8,0,1.4,0.2,1.8,0.7  s0.7,1,0.7,1.6c0,0.4-0.1,0.7-0.3,1c-0.2,0.3-0.5,0.5-1,0.7c0.5,0.2,0.9,0.4,1.2,0.8c0.3,0.4,0.4,0.8,0.4,1.4c0,0.7-0.3,1.4-0.8,1.9  c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.5-0.3-2-0.8c-0.5-0.5-0.8-1.1-0.8-1.9c0-0.6,0.1-1,0.4-1.4S248.9,44.5,249.4,44.3z M248.9,46.5  c0,0.3,0.1,0.6,0.2,0.9c0.1,0.3,0.4,0.5,0.6,0.7s0.6,0.2,0.9,0.2c0.5,0,0.9-0.2,1.2-0.5c0.3-0.3,0.5-0.7,0.5-1.2  c0-0.5-0.2-0.9-0.5-1.3c-0.3-0.3-0.8-0.5-1.3-0.5c-0.5,0-0.9,0.2-1.2,0.5C249,45.6,248.9,46,248.9,46.5z M249.2,42.6  c0,0.4,0.1,0.7,0.4,1s0.6,0.4,1,0.4c0.4,0,0.7-0.1,1-0.4c0.3-0.3,0.4-0.6,0.4-0.9c0-0.4-0.1-0.7-0.4-1c-0.3-0.3-0.6-0.4-1-0.4  c-0.4,0-0.7,0.1-1,0.4S249.2,42.2,249.2,42.6z"/>
<path d="M210.9,57l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H210.9z M212.8,57l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H212.8z"/>
<path d="M214.3,62.5l3.3-8.6h1.2l3.5,8.6H221l-1-2.6h-3.6l-0.9,2.6H214.3z M216.7,59h2.9l-0.9-2.4c-0.3-0.7-0.5-1.3-0.6-1.8  c-0.1,0.6-0.3,1.1-0.5,1.6L216.7,59z"/>
<path d="M223,62.5v-8.6h1.1v8.6H223z"/>
<path d="M225.7,55.1v-1.2h1.1v1.2H225.7z M225.7,62.5v-6.2h1.1v6.2H225.7z"/>
<path d="M232.5,60.2l1,0.1c-0.1,0.7-0.4,1.3-0.9,1.7s-1,0.6-1.7,0.6c-0.9,0-1.5-0.3-2.1-0.8s-0.8-1.4-0.8-2.4c0-0.7,0.1-1.3,0.3-1.8  c0.2-0.5,0.6-0.9,1-1.1c0.5-0.3,0.9-0.4,1.5-0.4c0.7,0,1.2,0.2,1.7,0.5s0.7,0.8,0.8,1.5l-1,0.2c-0.1-0.4-0.3-0.7-0.5-0.9  c-0.2-0.2-0.5-0.3-0.9-0.3c-0.5,0-1,0.2-1.3,0.6c-0.3,0.4-0.5,1-0.5,1.8c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.3,0.6  c0.4,0,0.8-0.1,1-0.4C232.2,61.1,232.4,60.7,232.5,60.2z"/>
<path d="M238.6,60.5l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5c-0.5,0.4-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8s-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4s1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8c0.5,0.6,0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6c0,0.7,0.2,1.2,0.6,1.6  s0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3C238.3,61.3,238.5,60.9,238.6,60.5z M235.2,58.8h3.5c0-0.5-0.2-0.9-0.4-1.2  c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5S235.2,58.2,235.2,58.8z"/>
<path d="M241.1,57l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H241.1z M243.1,57l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H243.1z"/>
<rect x="166.4" y="38.5" fill-rule="evenodd" fill="none" width="122.2" height="27"/>
<path fill="none" stroke="#000000" stroke-width="2.2496" d="M201,110.5h52.6c0.7,0,1.4,0,2.1,0.1c0.7,0.1,1.4,0.2,2,0.3  c0.7,0.1,1.3,0.3,2,0.5s1.3,0.4,1.9,0.7c0.6,0.3,1.3,0.6,1.9,0.9s1.2,0.7,1.8,1.1c0.6,0.4,1.1,0.8,1.7,1.2s1,0.9,1.5,1.4  s0.9,1,1.4,1.5s0.8,1.1,1.2,1.7c0.4,0.6,0.7,1.2,1.1,1.8s0.6,1.2,0.9,1.9c0.3,0.6,0.5,1.3,0.7,1.9c0.2,0.7,0.4,1.3,0.5,2  c0.1,0.7,0.2,1.4,0.3,2s0.1,1.4,0.1,2.1s0,1.4-0.1,2.1c-0.1,0.7-0.2,1.4-0.3,2c-0.1,0.7-0.3,1.3-0.5,2c-0.2,0.7-0.4,1.3-0.7,1.9  c-0.3,0.6-0.6,1.3-0.9,1.9s-0.7,1.2-1.1,1.8c-0.4,0.6-0.8,1.1-1.2,1.7s-0.9,1-1.4,1.5s-1,0.9-1.5,1.4s-1.1,0.8-1.7,1.2  c-0.6,0.4-1.2,0.7-1.8,1.1s-1.2,0.6-1.9,0.9c-0.6,0.3-1.3,0.5-1.9,0.7s-1.3,0.4-2,0.5c-0.7,0.1-1.4,0.2-2,0.3  c-0.7,0.1-1.4,0.1-2.1,0.1H201c-0.7,0-1.4,0-2.1-0.1c-0.7-0.1-1.4-0.2-2-0.3c-0.7-0.1-1.3-0.3-2-0.5c-0.7-0.2-1.3-0.4-1.9-0.7  c-0.6-0.3-1.3-0.6-1.9-0.9s-1.2-0.7-1.8-1.1c-0.6-0.4-1.1-0.8-1.7-1.2s-1-0.9-1.5-1.4s-0.9-1-1.4-1.5c-0.4-0.5-0.8-1.1-1.2-1.7  c-0.4-0.6-0.7-1.2-1.1-1.8s-0.6-1.2-0.9-1.9c-0.3-0.6-0.5-1.3-0.7-1.9c-0.2-0.7-0.4-1.3-0.5-2s-0.2-1.4-0.3-2  c-0.1-0.7-0.1-1.4-0.1-2.1s0-1.4,0.1-2.1s0.2-1.4,0.3-2s0.3-1.3,0.5-2c0.2-0.7,0.4-1.3,0.7-1.9c0.3-0.6,0.6-1.3,0.9-1.9  c0.3-0.6,0.7-1.2,1.1-1.8c0.4-0.6,0.8-1.1,1.2-1.7c0.4-0.5,0.9-1,1.4-1.5s1-0.9,1.5-1.4s1.1-0.8,1.7-1.2c0.6-0.4,1.2-0.7,1.8-1.1  s1.2-0.6,1.9-0.9c0.6-0.3,1.3-0.5,1.9-0.7c0.7-0.2,1.3-0.4,2-0.5c0.7-0.1,1.4-0.2,2-0.3C199.6,110.5,200.3,110.5,201,110.5z"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="483" height="173.2"/>
<path d="M201.1,121v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3c-0.5,1-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  s0.6-1.9,1.1-2.8c0.5-0.9,1-1.6,1.5-2.2H201.1z"/>
<path d="M209.4,123.8c-0.4-0.2-0.8-0.4-1-0.7s-0.3-0.7-0.3-1.1c0-0.6,0.2-1.2,0.7-1.6c0.4-0.4,1-0.6,1.8-0.6c0.8,0,1.4,0.2,1.8,0.7  s0.7,1,0.7,1.6c0,0.4-0.1,0.7-0.3,1c-0.2,0.3-0.5,0.5-1,0.7c0.5,0.2,0.9,0.4,1.2,0.8c0.3,0.4,0.4,0.8,0.4,1.4c0,0.7-0.3,1.4-0.8,1.9  c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.5-0.3-2-0.8c-0.5-0.5-0.8-1.1-0.8-1.9c0-0.6,0.1-1,0.4-1.4S208.8,124,209.4,123.8z M208.8,126  c0,0.3,0.1,0.6,0.2,0.9c0.1,0.3,0.4,0.5,0.6,0.7s0.6,0.2,0.9,0.2c0.5,0,0.9-0.2,1.2-0.5c0.3-0.3,0.5-0.7,0.5-1.2  c0-0.5-0.2-0.9-0.5-1.3c-0.3-0.3-0.8-0.5-1.3-0.5c-0.5,0-0.9,0.2-1.2,0.5C209,125.1,208.8,125.5,208.8,126z M209.2,122.1  c0,0.4,0.1,0.7,0.4,1s0.6,0.4,1,0.4c0.4,0,0.7-0.1,1-0.4c0.3-0.3,0.4-0.6,0.4-0.9c0-0.4-0.1-0.7-0.4-1c-0.3-0.3-0.6-0.4-1-0.4  c-0.4,0-0.7,0.1-1,0.4S209.2,121.7,209.2,122.1z"/>
<path d="M218.7,128.5v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4c-0.4-0.3-0.7-0.7-1-1.1c-0.2-0.5-0.3-1.1-0.3-1.7  c0-0.6,0.1-1.2,0.3-1.7s0.5-0.9,0.9-1.2c0.4-0.3,0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6v-3.1h1v8.6H218.7z   M215.4,125.4c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9  c-0.3-0.4-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6C215.6,124,215.4,124.6,215.4,125.4z"/>
<path d="M226.6,122l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  c-0.2,0.5-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9s0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8c0.5,0.5,0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5  c-0.2,0.5-0.6,0.8-1,1.1s-0.9,0.4-1.4,0.4c-0.9,0-1.6-0.3-2.1-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6  c0.5-0.7,1.3-1,2.2-1c0.7,0,1.2,0.2,1.7,0.6C226.2,120.8,226.5,121.3,226.6,122z M222.3,125.7c0,0.4,0.1,0.7,0.2,1s0.4,0.6,0.6,0.8  s0.6,0.3,0.9,0.3c0.4,0,0.8-0.2,1.1-0.5c0.3-0.4,0.5-0.8,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.3-0.7-0.5-1.2-0.5  c-0.5,0-0.9,0.2-1.2,0.5S222.3,125.2,222.3,125.7z"/>
<path d="M233.2,122l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  c-0.2,0.5-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9s0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8c0.5,0.5,0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5  c-0.2,0.5-0.6,0.8-1,1.1s-0.9,0.4-1.4,0.4c-0.9,0-1.6-0.3-2.1-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6  c0.5-0.7,1.3-1,2.2-1c0.7,0,1.2,0.2,1.7,0.6C232.9,120.8,233.1,121.3,233.2,122z M228.9,125.7c0,0.4,0.1,0.7,0.2,1s0.4,0.6,0.6,0.8  s0.6,0.3,0.9,0.3c0.4,0,0.8-0.2,1.1-0.5c0.3-0.4,0.5-0.8,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.3-0.7-0.5-1.2-0.5  c-0.5,0-0.9,0.2-1.2,0.5S228.9,125.2,228.9,125.7z"/>
<path d="M239.9,122l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  c-0.2,0.5-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9s0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8c0.5,0.5,0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5  c-0.2,0.5-0.6,0.8-1,1.1s-0.9,0.4-1.4,0.4c-0.9,0-1.6-0.3-2.1-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6  c0.5-0.7,1.3-1,2.2-1c0.7,0,1.2,0.2,1.7,0.6C239.6,120.8,239.8,121.3,239.9,122z M235.6,125.7c0,0.4,0.1,0.7,0.2,1s0.4,0.6,0.6,0.8  s0.6,0.3,0.9,0.3c0.4,0,0.8-0.2,1.1-0.5c0.3-0.4,0.5-0.8,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.3-0.7-0.5-1.2-0.5  c-0.5,0-0.9,0.2-1.2,0.5S235.6,125.2,235.6,125.7z"/>
<path d="M245.7,126.5l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5c-0.5,0.4-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8s-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4s1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8c0.5,0.6,0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6c0,0.7,0.2,1.2,0.6,1.6  s0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3C245.3,127.3,245.5,126.9,245.7,126.5z M242.2,124.8h3.5c0-0.5-0.2-0.9-0.4-1.2  c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5S242.2,124.2,242.2,124.8z"/>
<path d="M249,128.5h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5c-0.5,0.6-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V128.5z M249,125.3c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8c-0.3-0.4-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6S249,124.6,249,125.3z"/>
<path d="M192.7,142l3.3-8.6h1.2l3.5,8.6h-1.3l-1-2.6h-3.6l-0.9,2.6H192.7z M195.2,138.5h2.9l-0.9-2.4c-0.3-0.7-0.5-1.3-0.6-1.8  c-0.1,0.6-0.3,1.1-0.5,1.6L195.2,138.5z"/>
<path d="M201.3,139.2l1.1-0.1c0.1,0.4,0.2,0.8,0.4,1.1c0.2,0.3,0.5,0.5,0.9,0.7c0.4,0.2,0.8,0.3,1.3,0.3c0.4,0,0.8-0.1,1.1-0.2  c0.3-0.1,0.6-0.3,0.7-0.5s0.2-0.5,0.2-0.7c0-0.3-0.1-0.5-0.2-0.7s-0.4-0.4-0.8-0.5c-0.2-0.1-0.7-0.2-1.5-0.4s-1.3-0.4-1.7-0.5  c-0.4-0.2-0.7-0.5-0.9-0.8s-0.3-0.7-0.3-1.1c0-0.4,0.1-0.8,0.4-1.2s0.6-0.7,1.1-0.9s1-0.3,1.6-0.3c0.6,0,1.2,0.1,1.7,0.3  c0.5,0.2,0.9,0.5,1.1,0.9c0.3,0.4,0.4,0.8,0.4,1.4l-1.1,0.1c-0.1-0.5-0.3-1-0.6-1.2c-0.3-0.3-0.8-0.4-1.5-0.4  c-0.7,0-1.2,0.1-1.5,0.4s-0.5,0.6-0.5,0.9c0,0.3,0.1,0.6,0.3,0.8c0.2,0.2,0.8,0.4,1.7,0.6c0.9,0.2,1.6,0.4,1.9,0.5  c0.5,0.2,0.9,0.5,1.1,0.9c0.2,0.4,0.4,0.8,0.4,1.2c0,0.5-0.1,0.9-0.4,1.3c-0.3,0.4-0.6,0.7-1.1,0.9c-0.5,0.2-1,0.3-1.7,0.3  c-0.8,0-1.4-0.1-2-0.3c-0.5-0.2-0.9-0.6-1.2-1S201.3,139.8,201.3,139.2z"/>
<path d="M209.3,139.2l1.1-0.1c0.1,0.4,0.2,0.8,0.4,1.1c0.2,0.3,0.5,0.5,0.9,0.7c0.4,0.2,0.8,0.3,1.3,0.3c0.4,0,0.8-0.1,1.1-0.2  c0.3-0.1,0.6-0.3,0.7-0.5s0.2-0.5,0.2-0.7c0-0.3-0.1-0.5-0.2-0.7s-0.4-0.4-0.8-0.5c-0.2-0.1-0.7-0.2-1.5-0.4s-1.3-0.4-1.7-0.5  c-0.4-0.2-0.7-0.5-0.9-0.8s-0.3-0.7-0.3-1.1c0-0.4,0.1-0.8,0.4-1.2s0.6-0.7,1.1-0.9s1-0.3,1.6-0.3c0.6,0,1.2,0.1,1.7,0.3  c0.5,0.2,0.9,0.5,1.1,0.9c0.3,0.4,0.4,0.8,0.4,1.4l-1.1,0.1c-0.1-0.5-0.3-1-0.6-1.2c-0.3-0.3-0.8-0.4-1.5-0.4  c-0.7,0-1.2,0.1-1.5,0.4s-0.5,0.6-0.5,0.9c0,0.3,0.1,0.6,0.3,0.8c0.2,0.2,0.8,0.4,1.7,0.6c0.9,0.2,1.6,0.4,1.9,0.5  c0.5,0.2,0.9,0.5,1.1,0.9c0.2,0.4,0.4,0.8,0.4,1.2c0,0.5-0.1,0.9-0.4,1.3c-0.3,0.4-0.6,0.7-1.1,0.9c-0.5,0.2-1,0.3-1.7,0.3  c-0.8,0-1.4-0.1-2-0.3c-0.5-0.2-0.9-0.6-1.2-1S209.3,139.8,209.3,139.2z"/>
<path d="M217.7,142v-8.6h6.2v1h-5.1v2.6h4.8v1h-4.8v2.9h5.3v1H217.7z"/>
<path d="M225.7,142v-8.6h3.8c0.8,0,1.3,0.1,1.7,0.2s0.7,0.4,1,0.8s0.4,0.8,0.4,1.3c0,0.6-0.2,1.1-0.6,1.5s-1,0.7-1.8,0.8  c0.3,0.1,0.5,0.3,0.7,0.4c0.3,0.3,0.6,0.7,0.9,1.1l1.5,2.3h-1.4l-1.1-1.8c-0.3-0.5-0.6-0.9-0.8-1.2s-0.4-0.5-0.6-0.6  c-0.2-0.1-0.3-0.2-0.5-0.2c-0.1,0-0.3,0-0.6,0h-1.3v3.8H225.7z M226.8,137.2h2.4c0.5,0,0.9-0.1,1.2-0.2c0.3-0.1,0.5-0.3,0.7-0.5  s0.2-0.5,0.2-0.8c0-0.4-0.1-0.7-0.4-1s-0.8-0.4-1.4-0.4h-2.7V137.2z"/>
<path d="M236.3,142v-7.6h-2.8v-1h6.8v1h-2.8v7.6H236.3z"/>
<path d="M241.6,142v-8.6h1.1v8.6H241.6z"/>
<path d="M244.4,137.8c0-1.4,0.4-2.5,1.1-3.3c0.8-0.8,1.8-1.2,3-1.2c0.8,0,1.5,0.2,2.1,0.6c0.6,0.4,1.1,0.9,1.5,1.6  c0.3,0.7,0.5,1.4,0.5,2.3c0,0.9-0.2,1.7-0.5,2.3c-0.4,0.7-0.8,1.2-1.5,1.6c-0.6,0.4-1.3,0.5-2.1,0.5c-0.8,0-1.5-0.2-2.2-0.6  c-0.6-0.4-1.1-0.9-1.4-1.6S244.4,138.6,244.4,137.8z M245.6,137.8c0,1,0.3,1.9,0.8,2.4s1.3,0.9,2.1,0.9c0.9,0,1.6-0.3,2.1-0.9  c0.6-0.6,0.8-1.5,0.8-2.6c0-0.7-0.1-1.3-0.4-1.8s-0.6-0.9-1-1.2s-1-0.4-1.5-0.4c-0.8,0-1.5,0.3-2.1,0.8  C245.9,135.6,245.6,136.5,245.6,137.8z"/>
<path d="M254.1,142v-8.6h1.2l4.5,6.7v-6.7h1.1v8.6h-1.2l-4.5-6.8v6.8H254.1z"/>
<rect x="192.7" y="118" fill-rule="evenodd" fill="none" width="69" height="27"/>
<rect x="357.2" y="70.8" fill="none" stroke="#000000" stroke-width="2.2496" width="144.8" height="42"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="483" height="173.2"/>
<path d="M408.1,88.8V88c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6v-3.1h1v8.6H408.1z M404.7,85.6  c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6S404.7,84.8,404.7,85.6z"/>
<path d="M411.7,88.8h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1s0.2,0.8,0.2,1.3  c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V88.8z M411.7,85.6c0,0.7,0.1,1.3,0.3,1.6c0.3,0.5,0.8,0.8,1.3,0.8  c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6S411.7,84.8,411.7,85.6z"/>
<path d="M417.2,81.3v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  s0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H417.2z"/>
<path d="M428.1,88.8V88c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6v-3.1h1v8.6H428.1z M424.7,85.6  c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6S424.7,84.8,424.7,85.6z"/>
<path d="M434.8,88.8V88c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6v-3.1h1v8.6H434.8z M431.4,85.6  c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6S431.4,84.8,431.4,85.6z"/>
<path d="M442.6,87.7v1H437c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1c0.3-0.4,0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8  s0.5-0.9,0.5-1.3c0-0.4-0.1-0.8-0.4-1.1s-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5s-0.5,0.7-0.5,1.3l-1.1-0.1  c0.1-0.8,0.4-1.4,0.8-1.8c0.5-0.4,1.1-0.6,2-0.6c0.8,0,1.5,0.2,2,0.7s0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1s-0.4,0.7-0.7,1  s-0.9,0.9-1.6,1.5c-0.6,0.5-1,0.9-1.2,1.1s-0.3,0.4-0.4,0.6H442.6z"/>
<path d="M447.7,88.8h-1.1V82c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1s0.8-0.8,0.9-1.1h0.7V88.8z"/>
<path d="M454.8,86.5l1,0.1c-0.1,0.7-0.4,1.3-0.9,1.7s-1,0.6-1.7,0.6c-0.9,0-1.5-0.3-2.1-0.8c-0.5-0.6-0.8-1.4-0.8-2.4  c0-0.7,0.1-1.3,0.3-1.8s0.6-0.9,1-1.1s1-0.4,1.5-0.4c0.7,0,1.2,0.2,1.7,0.5s0.7,0.8,0.8,1.5l-1,0.2c-0.1-0.4-0.3-0.7-0.5-0.9  s-0.5-0.3-0.9-0.3c-0.5,0-1,0.2-1.3,0.6s-0.5,1-0.5,1.8c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.3,0.6c0.4,0,0.8-0.1,1-0.4  S454.7,87,454.8,86.5z"/>
<path d="M409.2,96.7l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H409.2z M411.1,96.7l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H411.1z"/>
<path d="M413.4,102.2v-8.6h1.1v4.9l2.5-2.5h1.4l-2.4,2.3l2.6,3.9h-1.3l-2.1-3.2l-0.7,0.7v2.5H413.4z"/>
<path d="M419.4,102.2V96h0.9v0.9c0.5-0.7,1.1-1,2-1c0.4,0,0.7,0.1,1,0.2s0.5,0.3,0.7,0.5s0.3,0.5,0.3,0.8c0,0.2,0.1,0.5,0.1,1v3.8  h-1.1v-3.8c0-0.4,0-0.8-0.1-1s-0.2-0.4-0.4-0.5s-0.5-0.2-0.7-0.2c-0.4,0-0.8,0.1-1.2,0.4s-0.5,0.8-0.5,1.6v3.4H419.4z"/>
<path d="M425.7,99.1c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8s0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  s-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8C425.9,101,425.7,100.2,425.7,99.1z M426.7,99.1c0,0.8,0.2,1.4,0.5,1.8  s0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7s-0.8-0.6-1.3-0.6c-0.5,0-1,0.2-1.3,0.6  S426.7,98.3,426.7,99.1z"/>
<path d="M433.9,102.2L432,96h1.1l1,3.6l0.4,1.3c0-0.1,0.1-0.5,0.3-1.3l1-3.6h1.1l0.9,3.6l0.3,1.2l0.4-1.2l1.1-3.6h1l-1.9,6.2h-1.1  l-1-3.7l-0.2-1.1l-1.3,4.8H433.9z"/>
<path d="M441,100.4l1-0.2c0.1,0.4,0.2,0.7,0.5,1s0.6,0.3,1.1,0.3c0.5,0,0.8-0.1,1.1-0.3s0.4-0.4,0.4-0.7c0-0.2-0.1-0.4-0.3-0.6  c-0.1-0.1-0.5-0.2-1.1-0.4c-0.8-0.2-1.3-0.4-1.6-0.5c-0.3-0.1-0.5-0.3-0.7-0.6s-0.2-0.5-0.2-0.8c0-0.3,0.1-0.5,0.2-0.8  s0.3-0.4,0.5-0.6c0.2-0.1,0.4-0.2,0.7-0.3s0.6-0.1,0.9-0.1c0.5,0,0.9,0.1,1.3,0.2c0.4,0.1,0.6,0.3,0.8,0.6s0.3,0.6,0.4,1l-1,0.1  c0-0.3-0.2-0.6-0.4-0.8s-0.5-0.3-1-0.3c-0.5,0-0.8,0.1-1,0.2s-0.3,0.3-0.3,0.6c0,0.1,0,0.3,0.1,0.4c0.1,0.1,0.2,0.2,0.4,0.3  c0.1,0,0.4,0.1,0.9,0.3c0.7,0.2,1.3,0.4,1.6,0.5s0.5,0.3,0.7,0.6s0.3,0.5,0.3,0.9c0,0.4-0.1,0.7-0.3,1s-0.5,0.6-0.9,0.7  s-0.8,0.3-1.3,0.3c-0.8,0-1.4-0.2-1.8-0.5C441.4,101.6,441.1,101.1,441,100.4z"/>
<path d="M447.4,96.7l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H447.4z M449.4,96.7l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H449.4z"/>
<rect x="364.7" y="78.2" fill-rule="evenodd" fill="none" width="129.7" height="27"/>
<rect x="363.5" y="150.2" fill="none" stroke="#000000" stroke-width="2.2496" width="132.2" height="42"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="483" height="173.2"/>
<path d="M407.4,168.2h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1s0.8-0.8,0.9-1.1h0.7V168.2z"/>
<path d="M410.1,166l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3s0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5s0.5-0.8,0.5-1.3c0-0.5-0.2-0.9-0.5-1.2  s-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1l0.1-0.9c0.1,0,0.1,0,0.2,0c0.4,0,0.9-0.1,1.2-0.4s0.5-0.6,0.5-1.1c0-0.4-0.1-0.7-0.4-1  s-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4s-0.4,0.6-0.5,1.2l-1.1-0.2c0.1-0.7,0.4-1.3,0.9-1.6c0.5-0.4,1-0.6,1.7-0.6  c0.5,0,0.9,0.1,1.3,0.3s0.7,0.5,0.9,0.8s0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-0.9,0.7c0.5,0.1,0.9,0.4,1.2,0.7  s0.4,0.8,0.4,1.4c0,0.8-0.3,1.4-0.8,1.9s-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7C410.4,167.3,410.2,166.7,410.1,166z"/>
<path d="M418,168.2h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1s0.2,0.8,0.2,1.3  c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V168.2z M418,165.1c0,0.7,0.1,1.3,0.3,1.6c0.3,0.5,0.8,0.8,1.3,0.8  c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6S418,164.3,418,165.1z"/>
<path d="M423.5,160.8v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  s0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H423.5z"/>
<path d="M433.5,168.2v-2.1h-3.7v-1l3.9-5.6h0.9v5.6h1.2v1h-1.2v2.1H433.5z M433.5,165.2v-3.9l-2.7,3.9H433.5z"/>
<path d="M440.7,168.2h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1s0.8-0.8,0.9-1.1h0.7V168.2z"/>
<path d="M443.6,166.3l1-0.1c0.1,0.5,0.2,0.8,0.5,1s0.6,0.3,0.9,0.3c0.3,0,0.6-0.1,0.9-0.2s0.4-0.3,0.6-0.6s0.3-0.6,0.4-1  s0.2-0.9,0.2-1.3c0,0,0-0.1,0-0.2c-0.2,0.3-0.5,0.6-0.9,0.8s-0.8,0.3-1.2,0.3c-0.7,0-1.3-0.3-1.8-0.8c-0.5-0.5-0.7-1.2-0.7-2  c0-0.9,0.3-1.6,0.8-2.1c0.5-0.5,1.2-0.8,1.9-0.8c0.6,0,1.1,0.2,1.5,0.5s0.8,0.7,1.1,1.3s0.4,1.4,0.4,2.4c0,1.1-0.1,2-0.4,2.6  s-0.6,1.1-1.1,1.5s-1,0.5-1.7,0.5c-0.7,0-1.2-0.2-1.6-0.6C443.9,167.5,443.7,166.9,443.6,166.3z M447.9,162.5c0-0.6-0.2-1.1-0.5-1.4  s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.6s-0.5,0.9-0.5,1.5c0,0.5,0.2,1,0.5,1.3s0.7,0.5,1.2,0.5c0.5,0,0.9-0.2,1.2-0.5  S447.9,163.1,447.9,162.5z"/>
<path d="M453.5,168.2v-2.1h-3.7v-1l3.9-5.6h0.9v5.6h1.2v1h-1.2v2.1H453.5z M453.5,165.2v-3.9l-2.7,3.9H453.5z"/>
<path d="M415.5,176.2l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H415.5z M417.4,176.2l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H417.4z"/>
<path d="M419.8,181.8v-8.6h3.2c0.7,0,1.2,0.1,1.6,0.3s0.7,0.4,0.9,0.8s0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1s-0.5,0.6-0.9,0.8  c0.5,0.2,0.9,0.4,1.2,0.8s0.4,0.8,0.4,1.3c0,0.4-0.1,0.8-0.3,1.1s-0.4,0.6-0.6,0.8s-0.6,0.3-0.9,0.4s-0.8,0.1-1.4,0.1H419.8z   M420.9,176.8h1.9c0.5,0,0.9,0,1.1-0.1c0.3-0.1,0.5-0.2,0.7-0.4s0.2-0.4,0.2-0.8c0-0.3-0.1-0.5-0.2-0.8s-0.3-0.4-0.6-0.4  s-0.7-0.1-1.3-0.1h-1.7V176.8z M420.9,180.7h2.1c0.4,0,0.6,0,0.8,0c0.3,0,0.5-0.1,0.7-0.2s0.3-0.3,0.4-0.5s0.2-0.5,0.2-0.7  c0-0.3-0.1-0.6-0.2-0.8s-0.4-0.4-0.7-0.5s-0.7-0.1-1.3-0.1h-2V180.7z"/>
<path d="M427.3,178.6c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8s0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  s-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8C427.6,180.5,427.3,179.7,427.3,178.6z M428.4,178.6c0,0.8,0.2,1.4,0.5,1.8  s0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7s-0.8-0.6-1.3-0.6c-0.5,0-1,0.2-1.3,0.6  S428.4,177.8,428.4,178.6z"/>
<path d="M435.3,181.8h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1s0.2,0.8,0.2,1.3  c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V181.8z M435.3,178.6c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  S435.3,177.8,435.3,178.6z"/>
<path d="M441.1,176.2l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H441.1z M443,176.2l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H443z"/>
<rect x="371" y="157.8" fill-rule="evenodd" fill="none" width="117" height="27"/>
</svg></artwork>

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
d8c882d8c8d81865416c696365d8c8d8dd82d8c8d818656b6e6f7773d8c8d8\
1863426f62
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
2bc17c65 WRAPPED
    13941b48 subj "Alice"
~~~

### Mermaid

<artwork type="svg"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.2" baseProfile="tiny" width="362px" height="104px" viewBox="0 0 362 104" xml:space="preserve">
<path fill="none" stroke="#000000" stroke-width="1.4998" d="M124.5,52.4l6.6-0.1c6.6-0.1,19.9-0.2,31.5-0.2s21.5-0.1,26.5-0.1h5"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="312" height="54"/>
<polygon fill="black" points="186.1,47.5 195.1,52 186.1,56.5 "/>
<rect x="184.6" y="47.5" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path d="M153.8,53.9l1-0.2c0.1,0.4,0.2,0.7,0.5,1s0.6,0.3,1.1,0.3c0.5,0,0.8-0.1,1.1-0.3s0.4-0.4,0.4-0.7c0-0.2-0.1-0.4-0.3-0.6  c-0.1-0.1-0.5-0.2-1.1-0.4c-0.8-0.2-1.3-0.4-1.6-0.5s-0.5-0.3-0.7-0.6c-0.2-0.3-0.2-0.5-0.2-0.8c0-0.3,0.1-0.5,0.2-0.8  c0.1-0.2,0.3-0.4,0.5-0.6c0.2-0.1,0.4-0.2,0.7-0.3s0.6-0.1,0.9-0.1c0.5,0,0.9,0.1,1.3,0.2s0.6,0.3,0.8,0.6s0.3,0.6,0.4,1l-1,0.1  c0-0.3-0.2-0.6-0.4-0.8s-0.5-0.3-1-0.3c-0.5,0-0.8,0.1-1,0.2s-0.3,0.3-0.3,0.6c0,0.1,0,0.3,0.1,0.4c0.1,0.1,0.2,0.2,0.4,0.3  c0.1,0,0.4,0.1,0.9,0.3c0.7,0.2,1.3,0.4,1.6,0.5s0.5,0.3,0.7,0.6s0.3,0.5,0.3,0.9c0,0.4-0.1,0.7-0.3,1c-0.2,0.3-0.5,0.6-0.9,0.7  s-0.8,0.3-1.3,0.3c-0.8,0-1.4-0.2-1.8-0.5C154.2,55.1,153.9,54.6,153.8,53.9z"/>
<path d="M164.3,55.8v-0.9c-0.5,0.7-1.1,1.1-2,1.1c-0.4,0-0.7-0.1-1-0.2s-0.6-0.3-0.7-0.5s-0.3-0.5-0.3-0.8c0-0.2-0.1-0.5-0.1-1v-3.9  h1.1V53c0,0.6,0,0.9,0.1,1.1c0.1,0.3,0.2,0.5,0.4,0.7s0.5,0.2,0.8,0.2c0.3,0,0.6-0.1,0.9-0.2s0.5-0.4,0.6-0.7s0.2-0.7,0.2-1.2v-3.3  h1.1v6.2H164.3z"/>
<path d="M167.8,55.8h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1s0.2,0.8,0.2,1.3  c0,1.1-0.3,1.9-0.8,2.5c-0.5,0.6-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V55.8z M167.8,52.6c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  S167.8,51.8,167.8,52.6z"/>
<path d="M172.2,58.2l0.2-0.9c0.2,0.1,0.4,0.1,0.5,0.1c0.2,0,0.4-0.1,0.5-0.2s0.2-0.5,0.2-1.1v-6.5h1.1v6.6c0,0.8-0.1,1.3-0.3,1.6  c-0.3,0.4-0.7,0.6-1.3,0.6C172.7,58.3,172.5,58.2,172.2,58.2z M173.5,48.4v-1.2h1.1v1.2H173.5z"/>
<rect x="153.4" y="45.3" fill-rule="evenodd" fill="none" width="21.7" height="13.5"/>
<polygon fill="none" stroke="#000000" stroke-width="2.2497" points="31,73 134.7,73 113.7,31 52,31 "/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="312" height="54"/>
<path d="M62.8,48v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1s0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8s0.5-0.9,0.5-1.3  c0-0.4-0.1-0.8-0.4-1.1s-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5s-0.5,0.7-0.5,1.3l-1.1-0.1c0.1-0.8,0.4-1.4,0.8-1.8s1.1-0.6,2-0.6  c0.8,0,1.5,0.2,2,0.7c0.5,0.5,0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1s-0.4,0.7-0.7,1c-0.3,0.4-0.9,0.9-1.6,1.5c-0.6,0.5-1,0.9-1.2,1.1  s-0.3,0.4-0.4,0.6H62.8z"/>
<path d="M65.2,49h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1s0.2,0.8,0.2,1.3  c0,1.1-0.3,1.9-0.8,2.5c-0.5,0.6-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V49z M65.2,45.8c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  S65.2,45.1,65.2,45.8z"/>
<path d="M75,46.7l1,0.1c-0.1,0.7-0.4,1.3-0.9,1.7c-0.5,0.4-1,0.6-1.7,0.6c-0.9,0-1.5-0.3-2.1-0.8c-0.5-0.6-0.8-1.4-0.8-2.4  c0-0.7,0.1-1.3,0.3-1.8s0.6-0.9,1-1.1s1-0.4,1.5-0.4c0.7,0,1.2,0.2,1.7,0.5c0.4,0.3,0.7,0.8,0.8,1.5l-1,0.2  c-0.1-0.4-0.3-0.7-0.5-0.9s-0.5-0.3-0.9-0.3c-0.5,0-1,0.2-1.3,0.6s-0.5,1-0.5,1.8c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.3,0.6  c0.4,0,0.8-0.1,1-0.4S74.9,47.2,75,46.7z"/>
<path d="M80.6,49h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1c0.4-0.4,0.8-0.8,0.9-1.1h0.7V49z"/>
<path d="M83.4,41.5v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3c-0.5,1-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  s0.6-1.9,1.1-2.8c0.5-0.9,1-1.6,1.5-2.2H83.4z"/>
<path d="M94.3,46.7l1,0.1c-0.1,0.7-0.4,1.3-0.9,1.7c-0.5,0.4-1,0.6-1.7,0.6c-0.9,0-1.5-0.3-2.1-0.8C90.2,47.7,90,47,90,45.9  c0-0.7,0.1-1.3,0.3-1.8s0.6-0.9,1-1.1s1-0.4,1.5-0.4c0.7,0,1.2,0.2,1.7,0.5c0.4,0.3,0.7,0.8,0.8,1.5l-1,0.2  c-0.1-0.4-0.3-0.7-0.5-0.9s-0.5-0.3-0.9-0.3c-0.5,0-1,0.2-1.3,0.6s-0.5,1-0.5,1.8c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.3,0.6  c0.4,0,0.8-0.1,1-0.4S94.3,47.2,94.3,46.7z"/>
<path d="M101.5,42.5l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  s-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9s0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8s0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5s-0.6,0.8-1,1.1  c-0.4,0.2-0.9,0.4-1.4,0.4c-0.9,0-1.6-0.3-2.1-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6c0.5-0.7,1.3-1,2.2-1  c0.7,0,1.2,0.2,1.7,0.6C101.1,41.3,101.4,41.8,101.5,42.5z M97.2,46.2c0,0.4,0.1,0.7,0.2,1s0.4,0.6,0.6,0.8s0.6,0.3,0.9,0.3  c0.4,0,0.8-0.2,1.1-0.5c0.3-0.4,0.5-0.8,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.5  S97.2,45.7,97.2,46.2z"/>
<path d="M102.7,46.8l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2s0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6s0.5-0.9,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4  c-0.3-0.3-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2s-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4l-0.5,2.3c0.5-0.4,1.1-0.5,1.6-0.5  c0.8,0,1.4,0.3,1.9,0.8c0.5,0.5,0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1c-0.8,0-1.4-0.2-1.9-0.7  S102.7,47.5,102.7,46.8z"/>
<path d="M54.9,62.5l-2.3-8.6h1.2l1.3,5.6c0.1,0.6,0.3,1.2,0.4,1.8c0.2-0.9,0.3-1.4,0.4-1.6l1.6-5.8h1.4l1.2,4.3  c0.3,1.1,0.5,2.1,0.7,3c0.1-0.5,0.3-1.2,0.4-1.9l1.3-5.5h1.1l-2.4,8.6h-1.1L58.4,56c-0.2-0.5-0.2-0.9-0.3-1c-0.1,0.4-0.2,0.7-0.3,1  l-1.8,6.5H54.9z"/>
<path d="M64.8,62.5v-8.6h3.8c0.8,0,1.3,0.1,1.7,0.2s0.7,0.4,1,0.8s0.4,0.8,0.4,1.3c0,0.6-0.2,1.1-0.6,1.5c-0.4,0.4-1,0.7-1.8,0.8  c0.3,0.1,0.5,0.3,0.7,0.4c0.3,0.3,0.6,0.7,0.9,1.1l1.5,2.3h-1.4l-1.1-1.8c-0.3-0.5-0.6-0.9-0.8-1.2c-0.2-0.3-0.4-0.5-0.6-0.6  s-0.3-0.2-0.5-0.2c-0.1,0-0.3,0-0.6,0h-1.3v3.8H64.8z M65.9,57.7h2.4c0.5,0,0.9-0.1,1.2-0.2s0.5-0.3,0.7-0.5s0.2-0.5,0.2-0.8  c0-0.4-0.1-0.7-0.4-1s-0.8-0.4-1.4-0.4h-2.7V57.7z"/>
<path d="M72.5,62.5l3.3-8.6H77l3.5,8.6h-1.3l-1-2.6h-3.6l-0.9,2.6H72.5z M74.9,59h2.9L77,56.6c-0.3-0.7-0.5-1.3-0.6-1.8  c-0.1,0.6-0.3,1.1-0.5,1.6L74.9,59z"/>
<path d="M81.4,62.5v-8.6h3.2c0.6,0,1,0,1.3,0.1c0.4,0.1,0.8,0.2,1.1,0.4s0.5,0.5,0.7,0.8c0.2,0.4,0.3,0.7,0.3,1.2  c0,0.7-0.2,1.3-0.7,1.9C86.8,58.8,86,59,84.7,59h-2.2v3.5H81.4z M82.5,58h2.2c0.7,0,1.3-0.1,1.6-0.4s0.5-0.7,0.5-1.2  c0-0.4-0.1-0.7-0.3-0.9s-0.4-0.4-0.7-0.5c-0.2-0.1-0.5-0.1-1.1-0.1h-2.2V58z"/>
<path d="M89.4,62.5v-8.6h3.2c0.6,0,1,0,1.3,0.1c0.4,0.1,0.8,0.2,1.1,0.4s0.5,0.5,0.7,0.8c0.2,0.4,0.3,0.7,0.3,1.2  c0,0.7-0.2,1.3-0.7,1.9C94.8,58.8,94,59,92.7,59h-2.2v3.5H89.4z M90.5,58h2.2c0.7,0,1.3-0.1,1.6-0.4s0.5-0.7,0.5-1.2  c0-0.4-0.1-0.7-0.3-0.9s-0.4-0.4-0.7-0.5c-0.2-0.1-0.5-0.1-1.1-0.1h-2.2V58z"/>
<path d="M97.4,62.5v-8.6h6.2v1h-5.1v2.6h4.8v1h-4.8v2.9h5.3v1H97.4z"/>
<path d="M105.4,62.5v-8.6h3c0.7,0,1.2,0,1.5,0.1c0.5,0.1,0.9,0.3,1.3,0.6c0.5,0.4,0.8,0.9,1,1.5s0.3,1.3,0.3,2  c0,0.7-0.1,1.2-0.2,1.7s-0.3,0.9-0.6,1.3c-0.2,0.3-0.5,0.6-0.8,0.8s-0.6,0.3-1,0.4s-0.9,0.1-1.4,0.1H105.4z M106.6,61.5h1.8  c0.6,0,1-0.1,1.3-0.2c0.3-0.1,0.6-0.3,0.8-0.4c0.3-0.3,0.5-0.6,0.6-1.1s0.2-1,0.2-1.7c0-0.9-0.1-1.6-0.4-2.1s-0.7-0.8-1.1-1  c-0.3-0.1-0.8-0.2-1.5-0.2h-1.8V61.5z"/>
<rect x="52.5" y="38.5" fill-rule="evenodd" fill="none" width="60.7" height="27"/>
<rect x="194.2" y="31" fill="none" stroke="#000000" stroke-width="2.2497" width="136.8" height="42"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="312" height="54"/>
<path d="M240.4,49h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1c0.4-0.4,0.8-0.8,0.9-1.1h0.7V49z"/>
<path d="M243.1,46.7l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3s0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5s0.5-0.8,0.5-1.3c0-0.5-0.2-0.9-0.5-1.2  s-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1l0.1-0.9c0.1,0,0.1,0,0.2,0c0.4,0,0.9-0.1,1.2-0.4s0.5-0.6,0.5-1.1c0-0.4-0.1-0.7-0.4-1  s-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4s-0.4,0.6-0.5,1.2l-1.1-0.2c0.1-0.7,0.4-1.3,0.9-1.6s1-0.6,1.7-0.6c0.5,0,0.9,0.1,1.3,0.3  s0.7,0.5,0.9,0.8s0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-0.9,0.7c0.5,0.1,0.9,0.4,1.2,0.7s0.4,0.8,0.4,1.4  c0,0.8-0.3,1.4-0.8,1.9c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7C243.4,48,243.1,47.4,243.1,46.7z"/>
<path d="M249.9,47l1-0.1c0.1,0.5,0.2,0.8,0.5,1s0.6,0.3,0.9,0.3c0.3,0,0.6-0.1,0.9-0.2s0.4-0.3,0.6-0.6s0.3-0.6,0.4-1  s0.2-0.9,0.2-1.3c0,0,0-0.1,0-0.2c-0.2,0.3-0.5,0.6-0.9,0.8s-0.8,0.3-1.2,0.3c-0.7,0-1.3-0.3-1.8-0.8c-0.5-0.5-0.7-1.2-0.7-2  c0-0.9,0.3-1.6,0.8-2.1c0.5-0.5,1.2-0.8,1.9-0.8c0.6,0,1.1,0.2,1.5,0.5c0.5,0.3,0.8,0.7,1.1,1.3s0.4,1.4,0.4,2.4  c0,1.1-0.1,2-0.4,2.6s-0.6,1.1-1.1,1.5c-0.5,0.3-1,0.5-1.7,0.5c-0.7,0-1.2-0.2-1.6-0.6S250,47.7,249.9,47z M254.2,43.2  c0-0.6-0.2-1.1-0.5-1.4s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.6s-0.5,0.9-0.5,1.5c0,0.5,0.2,1,0.5,1.3s0.7,0.5,1.2,0.5  c0.5,0,0.9-0.2,1.2-0.5S254.2,43.8,254.2,43.2z"/>
<path d="M259.8,49v-2.1h-3.7v-1l3.9-5.6h0.9V46h1.2v1h-1.2V49H259.8z M259.8,46v-3.9l-2.7,3.9H259.8z"/>
<path d="M267,49H266v-6.7c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1c0.4-0.4,0.8-0.8,0.9-1.1h0.7V49z"/>
<path d="M271,49h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1s0.2,0.8,0.2,1.3  c0,1.1-0.3,1.9-0.8,2.5c-0.5,0.6-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V49z M271,45.8c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  S271,45.1,271,45.8z"/>
<path d="M279.8,49v-2.1h-3.7v-1l3.9-5.6h0.9V46h1.2v1h-1.2V49H279.8z M279.8,46v-3.9l-2.7,3.9H279.8z"/>
<path d="M284.7,44.3c-0.4-0.2-0.8-0.4-1-0.7c-0.2-0.3-0.3-0.7-0.3-1.1c0-0.6,0.2-1.2,0.7-1.6s1-0.6,1.8-0.6c0.8,0,1.4,0.2,1.8,0.7  c0.5,0.4,0.7,1,0.7,1.6c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-1,0.7c0.5,0.2,0.9,0.4,1.2,0.8s0.4,0.8,0.4,1.4c0,0.7-0.3,1.4-0.8,1.9  c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.5-0.3-2.1-0.8c-0.5-0.5-0.8-1.1-0.8-1.9c0-0.6,0.1-1,0.4-1.4C283.8,44.7,284.2,44.5,284.7,44.3z   M284.2,46.5c0,0.3,0.1,0.6,0.2,0.9s0.4,0.5,0.6,0.7s0.6,0.2,0.9,0.2c0.5,0,0.9-0.2,1.2-0.5s0.5-0.7,0.5-1.2c0-0.5-0.2-0.9-0.5-1.3  c-0.3-0.3-0.8-0.5-1.3-0.5c-0.5,0-0.9,0.2-1.2,0.5S284.2,46,284.2,46.5z M284.5,42.6c0,0.4,0.1,0.7,0.4,1s0.6,0.4,1,0.4  c0.4,0,0.7-0.1,1-0.4s0.4-0.6,0.4-0.9c0-0.4-0.1-0.7-0.4-1s-0.6-0.4-1-0.4c-0.4,0-0.7,0.1-1,0.4S284.5,42.2,284.5,42.6z"/>
<path d="M246.2,57l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H246.2z M248.1,57l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H248.1z"/>
<path d="M249.6,62.5l3.3-8.6h1.2l3.5,8.6h-1.3l-1-2.6h-3.6l-0.9,2.6H249.6z M252,59h2.9l-0.9-2.4c-0.3-0.7-0.5-1.3-0.6-1.8  c-0.1,0.6-0.3,1.1-0.5,1.6L252,59z"/>
<path d="M258.4,62.5v-8.6h1.1v8.6H258.4z"/>
<path d="M261,55.1v-1.2h1.1v1.2H261z M261,62.5v-6.2h1.1v6.2H261z"/>
<path d="M267.8,60.2l1,0.1c-0.1,0.7-0.4,1.3-0.9,1.7c-0.5,0.4-1,0.6-1.7,0.6c-0.9,0-1.5-0.3-2.1-0.8c-0.5-0.6-0.8-1.4-0.8-2.4  c0-0.7,0.1-1.3,0.3-1.8s0.6-0.9,1-1.1s1-0.4,1.5-0.4c0.7,0,1.2,0.2,1.7,0.5c0.4,0.3,0.7,0.8,0.8,1.5l-1,0.2  c-0.1-0.4-0.3-0.7-0.5-0.9s-0.5-0.3-0.9-0.3c-0.5,0-1,0.2-1.3,0.6s-0.5,1-0.5,1.8c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.3,0.6  c0.4,0,0.8-0.1,1-0.4S267.7,60.7,267.8,60.2z"/>
<path d="M274,60.5l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5c-0.5,0.4-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8c-0.5-0.6-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4c0.5-0.6,1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8c0.5,0.6,0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6  c0,0.7,0.2,1.2,0.6,1.6s0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3S273.8,60.9,274,60.5z M270.5,58.8h3.5c0-0.5-0.2-0.9-0.4-1.2  c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5S270.5,58.2,270.5,58.8z"/>
<path d="M276.4,57l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H276.4z M278.4,57l-0.3-1.6v-1.4h1.2v1.4L279,57H278.4z"/>
<rect x="201.7" y="38.5" fill-rule="evenodd" fill="none" width="122.2" height="27"/>
</svg></artwork>

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
78d666eb ASSERTION
    db7dd21c pred "knows"
    13b74194 obj "Bob"
~~~

### Mermaid

<artwork type="svg"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.2" baseProfile="tiny" width="362.8px" height="183.5px" viewBox="0 0 362.8 183.5" xml:space="preserve">
<path fill="none" stroke="#000000" stroke-width="1.4993" d="M119.5,70.8l6.1-3.1c6.1-3.1,18.4-9.4,29.7-12.5  c11.3-3.1,21.5-3.1,26.6-3.1h5.1"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="312.8" height="133.5"/>
<polygon fill="black" points="178.9,47.5 187.9,52 178.9,56.5 "/>
<rect x="177.4" y="47.5" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.4993" d="M119.5,112.8l6.1,3.1c6.1,3.1,18.4,9.4,30.7,12.5  c12.3,3.1,24.7,3.1,30.8,3.1h6.2"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="312.8" height="133.5"/>
<polygon fill="black" points="185.2,127 194.2,131.5 185.2,136 "/>
<rect x="183.7" y="127" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path d="M145.1,58.1v-8.6h1v0.8c0.2-0.3,0.5-0.6,0.8-0.7c0.3-0.2,0.6-0.2,1-0.2c0.5,0,1,0.1,1.4,0.4c0.4,0.3,0.7,0.7,0.9,1.2  s0.3,1,0.3,1.6c0,0.6-0.1,1.2-0.3,1.7c-0.2,0.5-0.6,0.9-1,1.2s-0.9,0.4-1.4,0.4c-0.4,0-0.7-0.1-0.9-0.2c-0.3-0.1-0.5-0.3-0.7-0.6v3  H145.1z M146,52.7c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.8  c0-0.8-0.2-1.4-0.5-1.8c-0.3-0.4-0.7-0.6-1.2-0.6c-0.4,0-0.8,0.2-1.2,0.6C146.2,51.3,146,51.9,146,52.7z"/>
<path d="M151.7,55.8v-6.2h0.9v0.9c0.2-0.4,0.5-0.7,0.7-0.9c0.2-0.1,0.4-0.2,0.7-0.2c0.4,0,0.7,0.1,1.1,0.3l-0.4,1  c-0.3-0.2-0.5-0.2-0.8-0.2c-0.2,0-0.4,0.1-0.6,0.2c-0.2,0.1-0.3,0.3-0.4,0.6c-0.1,0.4-0.2,0.8-0.2,1.2v3.3H151.7z"/>
<path d="M160,53.7l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5c-0.5,0.4-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8s-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4s1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8s0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6c0,0.7,0.2,1.2,0.6,1.6  s0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3C159.6,54.5,159.8,54.2,160,53.7z M156.5,52h3.5c0-0.5-0.2-0.9-0.4-1.2  c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5S156.6,51.5,156.5,52z"/>
<path d="M166.4,55.8V55c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1c-0.2-0.5-0.3-1.1-0.3-1.7  c0-0.6,0.1-1.2,0.3-1.7c0.2-0.5,0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6v-3.1h1v8.6H166.4z   M163.1,52.6c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9  s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6C163.2,51.2,163.1,51.8,163.1,52.6z"/>
<rect x="144.3" y="45.2" fill-rule="evenodd" fill="none" width="24" height="13.5"/>
<path d="M148.7,132.1c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8s0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  c-0.2,0.5-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8S148.7,133.2,148.7,132.1z M149.8,132.1c0,0.8,0.2,1.4,0.5,1.8  c0.3,0.4,0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7c-0.3-0.4-0.8-0.6-1.3-0.6  c-0.5,0-1,0.2-1.3,0.6C149.9,130.7,149.8,131.3,149.8,132.1z"/>
<path d="M156.7,135.2h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2c0.3,0.2,0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V135.2z M156.7,132.1c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8c-0.3-0.4-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C156.9,130.8,156.7,131.3,156.7,132.1z"/>
<path d="M161.1,137.7l0.2-0.9c0.2,0.1,0.4,0.1,0.5,0.1c0.2,0,0.4-0.1,0.5-0.2s0.2-0.5,0.2-1.1V129h1.1v6.6c0,0.8-0.1,1.3-0.3,1.6  c-0.3,0.4-0.7,0.6-1.3,0.6C161.6,137.8,161.3,137.7,161.1,137.7z M162.4,127.9v-1.2h1.1v1.2H162.4z"/>
<rect x="148.3" y="124.8" fill-rule="evenodd" fill="none" width="15.7" height="13.5"/>
<path fill="none" stroke="#000000" stroke-width="2.249" d="M52,70.8h52.6c0.7,0,1.4,0,2.1,0.1c0.7,0.1,1.4,0.2,2,0.3  c0.7,0.1,1.3,0.3,2,0.5s1.3,0.4,1.9,0.7c0.6,0.3,1.3,0.6,1.9,0.9c0.6,0.3,1.2,0.7,1.8,1.1c0.6,0.4,1.1,0.8,1.7,1.2  c0.5,0.4,1,0.9,1.5,1.4s0.9,1,1.4,1.5s0.8,1.1,1.2,1.7c0.4,0.6,0.7,1.2,1.1,1.8c0.3,0.6,0.6,1.2,0.9,1.9c0.3,0.6,0.5,1.3,0.7,1.9  c0.2,0.7,0.4,1.3,0.5,2s0.2,1.4,0.3,2c0.1,0.7,0.1,1.4,0.1,2.1s0,1.4-0.1,2.1c-0.1,0.7-0.2,1.4-0.3,2s-0.3,1.3-0.5,2  c-0.2,0.7-0.4,1.3-0.7,1.9c-0.3,0.6-0.6,1.3-0.9,1.9c-0.3,0.6-0.7,1.2-1.1,1.8c-0.4,0.6-0.8,1.1-1.2,1.7s-0.9,1-1.4,1.5  s-1,0.9-1.5,1.4c-0.5,0.4-1.1,0.8-1.7,1.2c-0.6,0.4-1.2,0.7-1.8,1.1c-0.6,0.3-1.2,0.6-1.9,0.9c-0.6,0.3-1.3,0.5-1.9,0.7  s-1.3,0.4-2,0.5c-0.7,0.1-1.4,0.2-2,0.3c-0.7,0.1-1.4,0.1-2.1,0.1H52c-0.7,0-1.4,0-2.1-0.1c-0.7-0.1-1.4-0.2-2-0.3  c-0.7-0.1-1.3-0.3-2-0.5s-1.3-0.4-1.9-0.7c-0.6-0.3-1.3-0.6-1.9-0.9c-0.6-0.3-1.2-0.7-1.8-1.1c-0.6-0.4-1.1-0.8-1.7-1.2  c-0.5-0.4-1-0.9-1.5-1.4s-0.9-1-1.4-1.5s-0.8-1.1-1.2-1.7c-0.4-0.6-0.7-1.2-1.1-1.8c-0.3-0.6-0.6-1.2-0.9-1.9  c-0.3-0.6-0.5-1.3-0.7-1.9c-0.2-0.7-0.4-1.3-0.5-2c-0.1-0.7-0.2-1.4-0.3-2C31,93.1,31,92.4,31,91.8s0-1.4,0.1-2.1s0.2-1.4,0.3-2  c0.1-0.7,0.3-1.3,0.5-2c0.2-0.7,0.4-1.3,0.7-1.9c0.3-0.6,0.6-1.3,0.9-1.9c0.3-0.6,0.7-1.2,1.1-1.8c0.4-0.6,0.8-1.1,1.2-1.7  s0.9-1,1.4-1.5s1-0.9,1.5-1.4c0.5-0.4,1.1-0.8,1.7-1.2c0.6-0.4,1.2-0.7,1.8-1.1c0.6-0.3,1.2-0.6,1.9-0.9c0.6-0.3,1.3-0.5,1.9-0.7  s1.3-0.4,2-0.5c0.7-0.1,1.4-0.2,2-0.3C50.6,70.8,51.3,70.8,52,70.8z"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="312.8" height="133.5"/>
<path d="M52.2,81.3v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  c0.3-1,0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H52.2z"/>
<path d="M60.4,84.1c-0.4-0.2-0.8-0.4-1-0.7c-0.2-0.3-0.3-0.7-0.3-1.1c0-0.6,0.2-1.2,0.7-1.6s1-0.6,1.8-0.6c0.7,0,1.4,0.2,1.8,0.7  c0.5,0.4,0.7,1,0.7,1.6c0,0.4-0.1,0.7-0.3,1c-0.2,0.3-0.5,0.5-1,0.7c0.5,0.2,0.9,0.4,1.2,0.8c0.3,0.4,0.4,0.8,0.4,1.4  c0,0.7-0.3,1.4-0.8,1.9s-1.2,0.8-2,0.8c-0.8,0-1.5-0.3-2-0.8s-0.8-1.1-0.8-1.9c0-0.6,0.1-1,0.4-1.4C59.5,84.5,59.9,84.2,60.4,84.1z   M59.8,86.3c0,0.3,0.1,0.6,0.2,0.9c0.1,0.3,0.4,0.5,0.6,0.7C61,88,61.3,88,61.6,88c0.5,0,0.9-0.2,1.2-0.5c0.3-0.3,0.5-0.7,0.5-1.2  c0-0.5-0.2-0.9-0.5-1.3c-0.3-0.3-0.8-0.5-1.3-0.5c-0.5,0-0.9,0.2-1.2,0.5S59.8,85.8,59.8,86.3z M60.2,82.3c0,0.4,0.1,0.7,0.4,1  c0.3,0.3,0.6,0.4,1,0.4c0.4,0,0.7-0.1,1-0.4s0.4-0.6,0.4-0.9c0-0.4-0.1-0.7-0.4-1c-0.3-0.3-0.6-0.4-1-0.4c-0.4,0-0.7,0.1-1,0.4  C60.3,81.6,60.2,81.9,60.2,82.3z"/>
<path d="M69.7,88.8V88c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1c-0.2-0.5-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  c0.2-0.5,0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6v-3.1h1v8.6H69.7z M66.4,85.6  c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C66.6,84.2,66.4,84.8,66.4,85.6z"/>
<path d="M77.6,82.3l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  c-0.2,0.5-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9c0.4-0.2,0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8s0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5  c-0.2,0.5-0.6,0.8-1,1.1s-0.9,0.4-1.4,0.4c-0.9,0-1.6-0.3-2.1-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6  c0.5-0.7,1.3-1,2.2-1c0.7,0,1.2,0.2,1.7,0.6C77.2,81.1,77.5,81.6,77.6,82.3z M73.3,86c0,0.4,0.1,0.7,0.2,1c0.2,0.3,0.4,0.6,0.6,0.8  c0.3,0.2,0.6,0.3,0.9,0.3c0.4,0,0.8-0.2,1.1-0.5c0.3-0.4,0.5-0.8,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.3-0.7-0.5-1.2-0.5  c-0.5,0-0.9,0.2-1.2,0.5S73.3,85.4,73.3,86z"/>
<path d="M84.2,82.3l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  c-0.2,0.5-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9c0.4-0.2,0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8s0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5  c-0.2,0.5-0.6,0.8-1,1.1s-0.9,0.4-1.4,0.4c-0.9,0-1.6-0.3-2.1-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6  c0.5-0.7,1.3-1,2.2-1c0.7,0,1.2,0.2,1.7,0.6C83.9,81.1,84.1,81.6,84.2,82.3z M79.9,86c0,0.4,0.1,0.7,0.2,1c0.2,0.3,0.4,0.6,0.6,0.8  c0.3,0.2,0.6,0.3,0.9,0.3c0.4,0,0.8-0.2,1.1-0.5c0.3-0.4,0.5-0.8,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.3-0.7-0.5-1.2-0.5  c-0.5,0-0.9,0.2-1.2,0.5S79.9,85.4,79.9,86z"/>
<path d="M90.9,82.3l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  c-0.2,0.5-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9c0.4-0.2,0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8s0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5  c-0.2,0.5-0.6,0.8-1,1.1s-0.9,0.4-1.4,0.4c-0.9,0-1.6-0.3-2.1-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6  c0.5-0.7,1.3-1,2.2-1c0.7,0,1.2,0.2,1.7,0.6C90.5,81.1,90.8,81.6,90.9,82.3z M86.6,86c0,0.4,0.1,0.7,0.2,1c0.2,0.3,0.4,0.6,0.6,0.8  c0.3,0.2,0.6,0.3,0.9,0.3c0.4,0,0.8-0.2,1.1-0.5c0.3-0.4,0.5-0.8,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.3-0.7-0.5-1.2-0.5  c-0.5,0-0.9,0.2-1.2,0.5S86.6,85.4,86.6,86z"/>
<path d="M96.6,86.7l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5c-0.5,0.4-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8S92,86.7,92,85.7  c0-1,0.3-1.9,0.8-2.4s1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8s0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6c0,0.7,0.2,1.2,0.6,1.6  S94.5,88,95,88c0.4,0,0.7-0.1,1-0.3C96.3,87.5,96.5,87.2,96.6,86.7z M93.2,85h3.5c0-0.5-0.2-0.9-0.4-1.2c-0.3-0.4-0.8-0.6-1.3-0.6  c-0.5,0-0.9,0.2-1.2,0.5S93.2,84.5,93.2,85z"/>
<path d="M100,88.8h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2c0.3,0.2,0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V88.8z M100,85.6c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8c-0.3-0.4-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C100.2,84.3,100,84.8,100,85.6z"/>
<path d="M43.7,102.2l3.3-8.6h1.2l3.5,8.6h-1.3l-1-2.6h-3.6l-0.9,2.6H43.7z M46.2,98.7h2.9l-0.9-2.4c-0.3-0.7-0.5-1.3-0.6-1.8  c-0.1,0.6-0.3,1.1-0.5,1.6L46.2,98.7z"/>
<path d="M52.3,99.5l1.1-0.1c0.1,0.4,0.2,0.8,0.4,1.1c0.2,0.3,0.5,0.5,0.9,0.7c0.4,0.2,0.8,0.3,1.3,0.3c0.4,0,0.8-0.1,1.1-0.2  c0.3-0.1,0.6-0.3,0.7-0.5c0.2-0.2,0.2-0.5,0.2-0.7c0-0.3-0.1-0.5-0.2-0.7c-0.2-0.2-0.4-0.4-0.8-0.5c-0.2-0.1-0.7-0.2-1.5-0.4  s-1.3-0.4-1.7-0.5c-0.4-0.2-0.7-0.5-0.9-0.8c-0.2-0.3-0.3-0.7-0.3-1.1c0-0.4,0.1-0.8,0.4-1.2c0.2-0.4,0.6-0.7,1.1-0.9s1-0.3,1.6-0.3  c0.6,0,1.2,0.1,1.7,0.3s0.9,0.5,1.1,0.9c0.3,0.4,0.4,0.8,0.4,1.4l-1.1,0.1c-0.1-0.5-0.3-1-0.6-1.2s-0.8-0.4-1.5-0.4  c-0.7,0-1.2,0.1-1.5,0.4c-0.3,0.3-0.5,0.6-0.5,0.9c0,0.3,0.1,0.6,0.3,0.8c0.2,0.2,0.8,0.4,1.7,0.6c0.9,0.2,1.6,0.4,1.9,0.5  c0.5,0.2,0.9,0.5,1.1,0.9s0.4,0.8,0.4,1.2c0,0.5-0.1,0.9-0.4,1.3c-0.3,0.4-0.6,0.7-1.1,0.9s-1,0.3-1.7,0.3c-0.8,0-1.4-0.1-2-0.3  s-0.9-0.6-1.2-1C52.4,100.6,52.3,100.1,52.3,99.5z"/>
<path d="M60.3,99.5l1.1-0.1c0.1,0.4,0.2,0.8,0.4,1.1c0.2,0.3,0.5,0.5,0.9,0.7c0.4,0.2,0.8,0.3,1.3,0.3c0.4,0,0.8-0.1,1.1-0.2  c0.3-0.1,0.6-0.3,0.7-0.5c0.2-0.2,0.2-0.5,0.2-0.7c0-0.3-0.1-0.5-0.2-0.7c-0.2-0.2-0.4-0.4-0.8-0.5c-0.2-0.1-0.7-0.2-1.5-0.4  s-1.3-0.4-1.7-0.5c-0.4-0.2-0.7-0.5-0.9-0.8c-0.2-0.3-0.3-0.7-0.3-1.1c0-0.4,0.1-0.8,0.4-1.2c0.2-0.4,0.6-0.7,1.1-0.9s1-0.3,1.6-0.3  c0.6,0,1.2,0.1,1.7,0.3s0.9,0.5,1.1,0.9c0.3,0.4,0.4,0.8,0.4,1.4l-1.1,0.1c-0.1-0.5-0.3-1-0.6-1.2s-0.8-0.4-1.5-0.4  c-0.7,0-1.2,0.1-1.5,0.4c-0.3,0.3-0.5,0.6-0.5,0.9c0,0.3,0.1,0.6,0.3,0.8c0.2,0.2,0.8,0.4,1.7,0.6c0.9,0.2,1.6,0.4,1.9,0.5  c0.5,0.2,0.9,0.5,1.1,0.9s0.4,0.8,0.4,1.2c0,0.5-0.1,0.9-0.4,1.3c-0.3,0.4-0.6,0.7-1.1,0.9s-1,0.3-1.7,0.3c-0.8,0-1.4-0.1-2-0.3  s-0.9-0.6-1.2-1C60.4,100.6,60.3,100.1,60.3,99.5z"/>
<path d="M68.7,102.2v-8.6h6.2v1h-5.1v2.6h4.7v1h-4.7v2.9h5.3v1H68.7z"/>
<path d="M76.7,102.2v-8.6h3.8c0.8,0,1.3,0.1,1.7,0.2s0.7,0.4,1,0.8c0.2,0.4,0.4,0.8,0.4,1.3c0,0.6-0.2,1.1-0.6,1.5  c-0.4,0.4-1,0.7-1.8,0.8c0.3,0.1,0.5,0.3,0.7,0.4c0.3,0.3,0.6,0.7,0.9,1.1l1.5,2.3h-1.4l-1.1-1.8c-0.3-0.5-0.6-0.9-0.8-1.2  c-0.2-0.3-0.4-0.5-0.6-0.6c-0.2-0.1-0.3-0.2-0.5-0.2c-0.1,0-0.3,0-0.6,0h-1.3v3.8H76.7z M77.8,97.5h2.4c0.5,0,0.9-0.1,1.2-0.2  c0.3-0.1,0.5-0.3,0.7-0.5s0.2-0.5,0.2-0.8c0-0.4-0.1-0.7-0.4-1c-0.3-0.3-0.8-0.4-1.4-0.4h-2.7V97.5z"/>
<path d="M87.3,102.2v-7.6h-2.8v-1h6.8v1h-2.8v7.6H87.3z"/>
<path d="M92.6,102.2v-8.6h1.1v8.6H92.6z"/>
<path d="M95.4,98.1c0-1.4,0.4-2.5,1.1-3.3c0.8-0.8,1.8-1.2,3-1.2c0.8,0,1.5,0.2,2.1,0.6c0.6,0.4,1.1,0.9,1.5,1.6  c0.3,0.7,0.5,1.4,0.5,2.3c0,0.9-0.2,1.7-0.5,2.3c-0.4,0.7-0.8,1.2-1.5,1.6c-0.6,0.4-1.3,0.5-2.1,0.5c-0.8,0-1.5-0.2-2.2-0.6  s-1.1-0.9-1.4-1.6S95.4,98.8,95.4,98.1z M96.6,98.1c0,1,0.3,1.9,0.8,2.4s1.3,0.9,2.1,0.9c0.9,0,1.6-0.3,2.1-0.9s0.8-1.5,0.8-2.6  c0-0.7-0.1-1.3-0.4-1.8c-0.2-0.5-0.6-0.9-1-1.2c-0.5-0.3-1-0.4-1.5-0.4c-0.8,0-1.5,0.3-2.1,0.8S96.6,96.8,96.6,98.1z"/>
<path d="M105.1,102.2v-8.6h1.2l4.5,6.7v-6.7h1.1v8.6h-1.2l-4.5-6.8v6.8H105.1z"/>
<rect x="43.7" y="78.2" fill-rule="evenodd" fill="none" width="68.9" height="27"/>
<rect x="187" y="31" fill="none" stroke="#000000" stroke-width="2.249" width="144.7" height="42"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="312.8" height="133.5"/>
<path d="M237.9,49v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1c-0.2-0.5-0.3-1.1-0.3-1.7  c0-0.6,0.1-1.2,0.3-1.7c0.2-0.5,0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6v-3.1h1V49H237.9z   M234.5,45.9c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9  s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6C234.7,44.5,234.5,45.1,234.5,45.9z"/>
<path d="M241.5,49h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2c0.3,0.2,0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V49z M241.5,45.8c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8c-0.3-0.4-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C241.6,44.5,241.5,45.1,241.5,45.8z"/>
<path d="M246.9,41.5v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  c0.3-1,0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H246.9z"/>
<path d="M257.9,49v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1c-0.2-0.5-0.3-1.1-0.3-1.7  c0-0.6,0.1-1.2,0.3-1.7c0.2-0.5,0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6v-3.1h1V49H257.9z   M254.5,45.9c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9  s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6C254.7,44.5,254.5,45.1,254.5,45.9z"/>
<path d="M264.5,49v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1c-0.2-0.5-0.3-1.1-0.3-1.7  c0-0.6,0.1-1.2,0.3-1.7c0.2-0.5,0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6v-3.1h1V49H264.5z   M261.2,45.9c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9  s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6C261.4,44.5,261.2,45.1,261.2,45.9z"/>
<path d="M272.4,48v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1c0.3-0.4,0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8  c0.3-0.4,0.5-0.9,0.5-1.3c0-0.4-0.1-0.8-0.4-1.1c-0.3-0.3-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5c-0.3,0.3-0.5,0.7-0.5,1.3  l-1.1-0.1c0.1-0.8,0.4-1.4,0.8-1.8s1.1-0.6,1.9-0.6c0.8,0,1.5,0.2,2,0.7s0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1c-0.1,0.3-0.4,0.7-0.7,1  c-0.3,0.4-0.9,0.9-1.6,1.5c-0.6,0.5-1,0.9-1.2,1.1c-0.2,0.2-0.3,0.4-0.4,0.6H272.4z"/>
<path d="M277.5,49h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7c-0.4,0.2-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1c0.4-0.4,0.8-0.8,0.9-1.1  h0.7V49z"/>
<path d="M284.6,46.7l1,0.1c-0.1,0.7-0.4,1.3-0.9,1.7s-1,0.6-1.7,0.6c-0.9,0-1.5-0.3-2.1-0.8s-0.8-1.4-0.8-2.4c0-0.7,0.1-1.3,0.3-1.8  c0.2-0.5,0.6-0.9,1-1.1c0.5-0.3,0.9-0.4,1.5-0.4c0.7,0,1.2,0.2,1.7,0.5s0.7,0.8,0.8,1.5l-1,0.2c-0.1-0.4-0.3-0.7-0.5-0.9  c-0.2-0.2-0.5-0.3-0.9-0.3c-0.5,0-1,0.2-1.3,0.6s-0.5,1-0.5,1.8c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.3,0.6c0.4,0,0.8-0.1,1-0.4  C284.3,47.6,284.5,47.2,284.6,46.7z"/>
<path d="M239,57l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H239z M240.9,57l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H240.9z"/>
<path d="M243.2,62.5v-8.6h1.1v4.9l2.5-2.5h1.4l-2.4,2.3l2.6,3.9H247l-2.1-3.2l-0.7,0.7v2.5H243.2z"/>
<path d="M249.2,62.5v-6.2h0.9v0.9c0.5-0.7,1.1-1,2-1c0.4,0,0.7,0.1,1,0.2c0.3,0.1,0.5,0.3,0.7,0.5s0.3,0.5,0.3,0.8  c0,0.2,0.1,0.5,0.1,1v3.8h-1.1v-3.8c0-0.4,0-0.8-0.1-1c-0.1-0.2-0.2-0.4-0.4-0.5c-0.2-0.1-0.5-0.2-0.7-0.2c-0.4,0-0.8,0.1-1.2,0.4  c-0.3,0.3-0.5,0.8-0.5,1.6v3.4H249.2z"/>
<path d="M255.5,59.4c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8s0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  c-0.2,0.5-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8S255.5,60.4,255.5,59.4z M256.5,59.4c0,0.8,0.2,1.4,0.5,1.8  c0.3,0.4,0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7c-0.3-0.4-0.8-0.6-1.3-0.6  c-0.5,0-1,0.2-1.3,0.6C256.7,58,256.5,58.6,256.5,59.4z"/>
<path d="M263.7,62.5l-1.9-6.2h1.1l1,3.6l0.4,1.3c0-0.1,0.1-0.5,0.3-1.3l1-3.6h1.1l0.9,3.6l0.3,1.2l0.4-1.2l1.1-3.6h1l-1.9,6.2h-1.1  l-1-3.7l-0.2-1.1l-1.3,4.8H263.7z"/>
<path d="M270.7,60.6l1-0.2c0.1,0.4,0.2,0.7,0.5,1c0.3,0.2,0.6,0.3,1.1,0.3c0.5,0,0.8-0.1,1.1-0.3c0.2-0.2,0.4-0.4,0.4-0.7  c0-0.2-0.1-0.4-0.3-0.6c-0.1-0.1-0.5-0.2-1.1-0.4c-0.8-0.2-1.3-0.4-1.6-0.5c-0.3-0.1-0.5-0.3-0.7-0.6c-0.2-0.3-0.2-0.5-0.2-0.8  c0-0.3,0.1-0.5,0.2-0.8c0.1-0.2,0.3-0.4,0.5-0.6c0.2-0.1,0.4-0.2,0.7-0.3c0.3-0.1,0.6-0.1,0.9-0.1c0.5,0,0.9,0.1,1.3,0.2  c0.4,0.1,0.6,0.3,0.8,0.6s0.3,0.6,0.4,1l-1,0.1c0-0.3-0.2-0.6-0.4-0.8c-0.2-0.2-0.5-0.3-1-0.3c-0.5,0-0.8,0.1-1,0.2  c-0.2,0.2-0.3,0.3-0.3,0.6c0,0.1,0,0.3,0.1,0.4c0.1,0.1,0.2,0.2,0.4,0.3c0.1,0,0.4,0.1,0.9,0.3c0.7,0.2,1.3,0.4,1.6,0.5  c0.3,0.1,0.5,0.3,0.7,0.6c0.2,0.2,0.3,0.5,0.3,0.9c0,0.4-0.1,0.7-0.3,1c-0.2,0.3-0.5,0.6-0.9,0.7s-0.8,0.3-1.3,0.3  c-0.8,0-1.4-0.2-1.8-0.5C271.1,61.8,270.9,61.3,270.7,60.6z"/>
<path d="M277.2,57l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H277.2z M279.2,57l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H279.2z"/>
<rect x="194.5" y="38.5" fill-rule="evenodd" fill="none" width="129.6" height="27"/>
<rect x="193.3" y="110.5" fill="none" stroke="#000000" stroke-width="2.249" width="132.1" height="42"/>
<rect x="25" y="25" fill-rule="evenodd" fill="none" width="312.8" height="133.5"/>
<path d="M237.2,128.5h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7c-0.4,0.2-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1c0.4-0.4,0.8-0.8,0.9-1.1  h0.7V128.5z"/>
<path d="M239.9,126.2l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3c0.3,0.3,0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5c0.3-0.3,0.5-0.8,0.5-1.3  c0-0.5-0.2-0.9-0.5-1.2c-0.3-0.3-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1l0.1-0.9c0.1,0,0.1,0,0.2,0c0.4,0,0.9-0.1,1.2-0.4  c0.4-0.2,0.5-0.6,0.5-1.1c0-0.4-0.1-0.7-0.4-1c-0.3-0.3-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4c-0.3,0.3-0.4,0.6-0.5,1.2l-1.1-0.2  c0.1-0.7,0.4-1.3,0.9-1.6s1-0.6,1.7-0.6c0.5,0,0.9,0.1,1.3,0.3c0.4,0.2,0.7,0.5,0.9,0.8s0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1  s-0.5,0.5-0.9,0.7c0.5,0.1,0.9,0.4,1.2,0.7c0.3,0.4,0.4,0.8,0.4,1.4c0,0.8-0.3,1.4-0.8,1.9s-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7  C240.2,127.5,240,126.9,239.9,126.2z"/>
<path d="M247.8,128.5h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2c0.3,0.2,0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V128.5z M247.8,125.3c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8c-0.3-0.4-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C248,124,247.8,124.6,247.8,125.3z"/>
<path d="M253.3,121v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  c0.3-1,0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H253.3z"/>
<path d="M263.3,128.5v-2.1h-3.7v-1l3.9-5.6h0.9v5.6h1.2v1h-1.2v2.1H263.3z M263.3,125.5v-3.9l-2.7,3.9H263.3z"/>
<path d="M270.5,128.5h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7c-0.4,0.2-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1c0.4-0.4,0.8-0.8,0.9-1.1  h0.7V128.5z"/>
<path d="M273.4,126.5l1-0.1c0.1,0.5,0.2,0.8,0.5,1s0.6,0.3,0.9,0.3c0.3,0,0.6-0.1,0.9-0.2c0.2-0.1,0.4-0.3,0.6-0.6  c0.2-0.2,0.3-0.6,0.4-1s0.2-0.9,0.2-1.3c0,0,0-0.1,0-0.2c-0.2,0.3-0.5,0.6-0.9,0.8s-0.8,0.3-1.2,0.3c-0.7,0-1.3-0.3-1.8-0.8  s-0.7-1.2-0.7-2c0-0.9,0.3-1.6,0.8-2.1s1.2-0.8,1.9-0.8c0.6,0,1.1,0.2,1.5,0.5s0.8,0.7,1.1,1.3c0.2,0.6,0.4,1.4,0.4,2.4  c0,1.1-0.1,2-0.4,2.6c-0.2,0.7-0.6,1.1-1.1,1.5s-1,0.5-1.7,0.5c-0.7,0-1.2-0.2-1.6-0.6S273.5,127.2,273.4,126.5z M277.7,122.7  c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.4-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.6s-0.5,0.9-0.5,1.5c0,0.5,0.2,1,0.5,1.3  c0.3,0.3,0.7,0.5,1.2,0.5c0.5,0,0.9-0.2,1.2-0.5C277.5,123.8,277.7,123.3,277.7,122.7z"/>
<path d="M283.3,128.5v-2.1h-3.7v-1l3.9-5.6h0.9v5.6h1.2v1h-1.2v2.1H283.3z M283.3,125.5v-3.9l-2.7,3.9H283.3z"/>
<path d="M245.3,136.5l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H245.3z M247.2,136.5l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H247.2z"/>
<path d="M249.6,142v-8.6h3.2c0.7,0,1.2,0.1,1.6,0.3c0.4,0.2,0.7,0.4,0.9,0.8c0.2,0.4,0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1  c-0.2,0.3-0.5,0.6-0.9,0.8c0.5,0.2,0.9,0.4,1.2,0.8c0.3,0.4,0.4,0.8,0.4,1.3c0,0.4-0.1,0.8-0.3,1.1s-0.4,0.6-0.6,0.8  c-0.2,0.2-0.6,0.3-0.9,0.4c-0.4,0.1-0.8,0.1-1.4,0.1H249.6z M250.7,137h1.9c0.5,0,0.9,0,1.1-0.1c0.3-0.1,0.5-0.2,0.7-0.4  c0.1-0.2,0.2-0.4,0.2-0.8c0-0.3-0.1-0.5-0.2-0.8c-0.1-0.2-0.3-0.4-0.6-0.4c-0.3-0.1-0.7-0.1-1.3-0.1h-1.7V137z M250.7,141h2.1  c0.4,0,0.6,0,0.8,0c0.3,0,0.5-0.1,0.7-0.2c0.2-0.1,0.3-0.3,0.4-0.5s0.2-0.5,0.2-0.7c0-0.3-0.1-0.6-0.2-0.8s-0.4-0.4-0.7-0.5  c-0.3-0.1-0.7-0.1-1.3-0.1h-2V141z"/>
<path d="M257.1,138.9c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8s0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  c-0.2,0.5-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8S257.1,139.9,257.1,138.9z M258.2,138.9c0,0.8,0.2,1.4,0.5,1.8  c0.3,0.4,0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7c-0.3-0.4-0.8-0.6-1.3-0.6  c-0.5,0-1,0.2-1.3,0.6C258.4,137.5,258.2,138.1,258.2,138.9z"/>
<path d="M265.1,142h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2c0.3,0.2,0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V142z M265.1,138.8c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8c-0.3-0.4-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C265.3,137.5,265.1,138.1,265.1,138.8z"/>
<path d="M270.9,136.5l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H270.9z M272.8,136.5l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H272.8z"/>
<rect x="200.8" y="118" fill-rule="evenodd" fill="none" width="116.9" height="27"/>
</svg></artwork>

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

Known values are a specific case of an envelope that defines a namespace consisting of single unsigned integers. The expectation is that the most common and widely useful predicates will be assigned in this namespace, but known values may be used in any position in an envelope.

Most of the examples in this document use UTF-8 strings as predicates, but in real-world applications, the same predicate may be used many times in a document and across a body of knowledge. Since the size of an envelope is proportionate to the size of its content, a predicate made using a string like a human-readable sentence or a URL could take up a great deal of space in a typical envelope. Even emplacing the digest of a known structure takes 32 bytes. Known values provide a way to compactly represent predicates and other common values in as few as three bytes.

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
| 6     | `sskrShare`      | predicate | A single SSKR {{SSKR}} share of the ephemeral encryption key that was used to encrypt the subject. |
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
| 102   | `error`          | predicate | RPC: A result of an unsuccessful function call. The object is a message or other diagnostic state. |
| 103   | `ok`             | object    | RPC: The object of a `result` predicate for a successful remote procedure call that has no other return value. |
| 104   | `processing`     | object    | RPC: The object of a `result` predicate where a function call is accepted for processing and has not yet produced a result or error. |

# Existence Proofs

This section is informative.

Because each element of an envelope provides a unique digest, and because changing an element in an envelope changes the digest of all elements upwards towards its root, the structure of an envelope is comparable to a merkle tree {{MERKLE}}.

In a Merkle Tree, all semantically significant information is carried by the tree's leaves (for example, the transactions in a block of Bitcoin transactions), while the internal nodes of the tree are nothing but digests computed from combinations of pairs of lower nodes, all the way up to the root of the tree (the "Merkle root".)

In an envelope, every digest references some semantically significant content: it could reference the subject of the envelope, or one of the assertions in the envelope, or at the predicate or object of a given assertion. Of course, those elements are all envelopes themselves, and thus potentially the root of their own subtree.

In a Merkle tree, the minimum subset of hashes necessary to confirm that a specific leaf node (the "target") must be present is called a "Merkle proof." For envelopes, an analogous proof would be a transformation of the envelope that is entirely elided but preserves the structure necessary to reveal the target.

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

We then elide the entire envelope, leaving only the root-level digest. This digest is a cryptographic commitment to the envelope's contents.

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

The holder can then produce a proof, which is an elided form of the original document that contains a minimum spanning set of digests, including the target.

~~~ sh
$ KNOWS_BOB_DIGEST=`envelope digest $REQUESTED_ASSERTION`

$ KNOWS_BOB_PROOF=`envelope proof create $ALICE_FRIENDS \
    $KNOWS_BOB_DIGEST`

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

Criteria 3 was met when the proof was produced. Criteria 1 and 2 are checked by the command line tool when confirming the proof:

~~~ sh
$ envelope proof confirm --silent $COMMITMENT $KNOWS_BOB_PROOF \
    $KNOWS_BOB_DIGEST && echo "Success"
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

For the sake of this example, we assume the new method to be supported has all the same fields but needs to be processed differently. In this case, the first element of the array could become an optional integer:

~~~ cddl
crypto-msg = #6.201([ ? version, ciphertext, nonce, auth, ? aad ])
version = uint           ; absent for old method, 1 for new method
~~~

If present, the first field specifies the later encryption method. If absent, the original encryption method is specified. For low-numbered versions, the storage cost of specifying a later version is one byte, and backward compatibility is preserved.

## Commitment to the Hash Algorithm

For changes that are more sweeping, like supporting a different hash algorithm to produce the merkle tree digests, it would be necessary to use a different top-level CBOR tag to represent the envelope itself. Currently the envelope tag is #6.200, and the choice of digest algorithm in our reference implementation is SHA-256. If this version were officially released and a future version of Gordian Envelope was also released that supported SHA-256, it will need to have a different tag. However, a problem for interoperability of these two distinct formats then arises in the choice of whether a particular envelope is encoded assuming SHA-256 or SHA-256. Whenever there is a choice about two or more ways to encode particular data, this violates the determinism requirement that Gordian Envelopes are designed to uphold. In other words, an envelope encoding certain information using SHA-256 will not, in general, be structurally identical to the same information encoded in an envelope using SHA-256. For instance, they will both have different root hashes, and simply knowing which algorithm produced each one will not help you know whether they have equivalent content. Only two envelope cases actually encode their digest in the binary stream: ELIDED and ENCRYPTED. If an envelope doesn't use either of these cases, then you could choose to decode the envelope with either algorithm, but if it does use either of these cases then the envelope will still decode, but attempting to decrypt or unelide its contents will result in mismatched digests. This is why the envelope itself needs to declare the hashing algorithm used using its top-level CBOR tag, and why the choice of which hash algorithm to commit to should be carefully considered.

# Security Considerations

This section is informative unless noted otherwise.

## Structural Considerations

### CBOR Considerations

Generally, this document inherits the security considerations of CBOR {{-CBOR}}. Though CBOR has limited web usage, it has received strong usage in hardware, resulting in a mature specification.

## Cryptographic Considerations

### Inherited Considerations

Generally, this document inherits the security considerations of the cryptographic constructs it uses such as IETF-ChaCha20-Poly1305 {{-CHACHA}} and SHA-256 {{-SHA-256}}.

### Choice of Cryptographic Primitives (No Set Curve)

Though envelope recommends the use of certain cryptographic algorithms, most are not required (with the exception of SHA-256 usage, noted below). In particular, envelope has no required curve. Different choices will obviously result in different security considerations.

## Validation Requirements

Unlike HTML, envelope is intended to be conservative in both what it sends _and_ what it accepts. This means that receivers of envelope-based documents should carefully validate them. Any deviation from the validation requirements of this specification MUST result in the rejection of the entire envelope. Even after validation, envelope contents should be treated with due skepticism.

## Signature Considerations

This specification allows the signing of envelopes that are partially (or even entirely) elided. There may be use cases for this, such as when multiple users are each signing partially elided envelopes that will then be united. However, it's generally a dangerous practice. Our own tools require overrides to allow it. Other developers should take care to warn users of the dangers of signing elided envelopes.

## Hashing

### Choice of SHA-256 Hash Primitive

Envelope uses the SHA-256 digest algorithm, which is regarded as reliable and widely supported by many implementations in both software and hardware.

### Well-Known Hashes

Because they are short unsigned integers, well-known values produce well-known digests. Elided envelopes may, in some cases, inadvertently reveal information by transmitting digests that may be correlated to known information. Envelopes can be salted by adding assertions that contain random data to perturb the digest tree, hence decorrelating it from any known values.

### Digest Trees

Existence proofs include the minimal set of digests that are necessary to calculate the digest tree from the target to the root, but may themselves leak information about the contents of the envelope due to the other digests that must be included in the spanning set. Designers of envelope-based formats should anticipate such attacks and use decorrelation mechanisms like salting where necessary.

### A Tree, Not a List

Envelope makes use of a hash tree instead of a hash list to allow this sort of minimal revelation. This decision may also have advantages in scaling. However, there should be further investigation of the limitations of hash trees regarding scaling, particularly for the scaling of large, elided structures.

There should also be careful consideration of the best practices needed for the creation of deeply nested envelopes, for the usage of sub-envelopes created at different times, and for other technical details related to the use of a potentially broad hash tree, as such best practices do not currently exist.

### Salts

Specifics for the size and usage of salt are not included in this specifications. There are also no requirements for whether salts should be revealed or can be elided. Careful attention may be required for these factors to ensure that they don't accidentally introduce vulnerabilities into usage.

### Collisions

Hash trees tend to make it harder to create collisions than the use of a raw hash function. If attackers manage to find a collision for a hash, they can only replace one node (and its children), so the impact is limited, especially since finding collisions higher in a hash tree grows increasingly difficult because the collision must be a concatenation of multiple hashes. This should generally reduce issues with collisions: finding collisions that fit a hash tree tends to be harder than finding regular collisions. But, the issue should always be considered.

### Leaf-Node Attacks

Envelope's hash tree is proof against the leaf-node weakness of Bitcoin that can affect SPVs because its predicates are an unordered set, serialized in increasing lexicographic order by digest, with no possibility for duplication and thus fully deterministic ordering of the tree.

See the leaf-node attack at {{LEAF-MERKLE}}.

### Forgery Attacks on Unbalanced Trees

Envelopes should be proof against a known forgery attack against Bitcoin because of their different construction, in which all tree nodes contain semantically important data and duplicate assertions are not allowed.

See the forgery attack here: {{BLOCK-EXPLOIT}}.

## Elision

### Duplication of Claims

Support for elision allows for the possibility of contradictory claims where one is kept hidden at any time. So, for example, an envelope could contain contradictory predictions of election results and only reveal the one that matches the actual results. As a result, revealed material should be carefully assessed for this possibility when elided material also exists.

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

# Appendix: Why CBOR?

The Concise Binary Object Representation, or CBOR, was chosen as the foundational data structure envelopes for a variety of reasons. These include:

1. **IETF Standardization.** CBOR is a mature open international IETF standard {{-CBOR}}.
2. **IANA Registration.** CBOR is further standardized by the registration of common data type tags through IANA {{IANA-CBOR-TAGS}}.
3. **Fully Extensible.** Beyond that, CBOR is entirely extensible with any data types desired, such as our own listing of UR tags {{BC-UR-TAGS}}.
4. **Self-describing Descriptions.** CBOR-encoded data is self-describing, so there are no requirements for pre-defined schemas nor more complex descriptions such as those found in ASN.1 {{ASN-1}}.
5. **Constraint Friendly.** CBOR is built to be frugal with CPU and memory, so it works well in constrained environments such as on cryptographic silicon chips.
6. **Unambiguous Encoding.** Our use of Deterministic CBOR, combined with our own specification rules, such as the sorting of Envelopes by hash, results in a singular, unambiguous encoding.
7. **Multiple Implementations.** Implementation are available in a variety of languages {{CBOR-IMPLS}}.
8. **Compact Implementations.** Compactness of encoding and decoding is one of CBOR's core goals; implementations are built on headers or snippets of code, and do not require any external tools.

Also see a comparison to Protocol Buffers {{UR-QA}}, a comparison to Flatbuffers {{CBOR-FLATBUFFERS}}, and a comparison to other binary formats {{CBOR-FORMAT-COMPARISON}}.

--- back

# Acknowledgments
{:numbered="false"}

TODO acknowledge.
