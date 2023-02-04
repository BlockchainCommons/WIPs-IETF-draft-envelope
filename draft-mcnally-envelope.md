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

This section specifies how the digests for each of the envelope cases are computed. The minimum size of the digest and order of operations specified is normative, but the specific cryptographic hash algorithm used by the reference implementation {{BLAKE3}} is informative. When implementing using BLAKE3, the examples in this section may be used as test vectors.

Each of the seven enumerated envelope cases produces an image which is used as input to a cryptographic hash function to produce a digest of its contents.

The overall digest of an envelope is the digest of its specific case.

In this and subsequent sections:

*  `digest(image)` is the BLAKE3 hash function that produces a 32-byte digest.
*  The `.digest` attribute is the digest of the named element computed as specified herein.
*  The `||` operator represents the concatenation of byte sequences.

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

The `encrypted` case declares its digest to be the digest of plaintext before encryption. The declaration is made using a MAC, and when decrypting an element, the implementation MUST compare the digest of the decrypted element to the declared digest and flag an error if they do not match.

### Example

If we create the envelope from the leaf example above, encrypt it, and then request its digest:

~~~
$ KEY=`envelope generate key`
$ envelope subject "Hello" | \
    envelope encrypt --key $KEY | \
    envelope digest --hex
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
digest(subject.digest || assertion-0.digest ||
    assertion-1.digest || ... || assertion-n.digest)
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

We then calculate the BLAKE3 hash of the concatenation of these four digests. Note that this is the same digest as the composite envelope's digest:

~~~
echo "278403504ad3a9a9c24c1b35a3673eee165a5d523f8d2a5cf5ce6dd2\
5a37f1101e0b049b8d2b21d4bb32f90b4a9e6b5031526f868da303268a9c1c\
75c008244655560bdf060f1220199c87e84e29cecef96ef811de4f399dab2f\
de9425d0d41871a3069088c61c928f54ec50859f3f09b9318e9ca6734e6a3b\
5f77aa3159a711" | xxd -r -p | b3sum --no-names
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
$ envelope subject "Hello" | \
    envelope subject --wrapped | \
    envelope digest --hex
55d4e04399c54bec23346ebf612bf237e659a72e34df14420e18e0290f2\
8c31b

$ echo "bd6c78899fc1f22c667cfe6893aa2414f8124f25ae6ea80a1a66\
c2d1d6b455ea" | xxd -r -p | b3sum --no-names
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

We then calculate the BLAKE3 hash of the concatenation of these two digests. Note that this is the same digest as the composite envelope's digest:

~~~
echo "7092d62002c3d0f3c889058092e6915bad908f03263c2dc91bfea6fd8e\
e62fab9a7717153d7a31b0390011413bdf9500ff4d8870ccf102ae31eaa165ab\
25df1a" | xxd -r -p | b3sum --no-names
55560bdf060f1220199c87e84e29cecef96ef811de4f399dab2fde9425d0d418

$ envelope digest --hex $ASSERTION
55560bdf060f1220199c87e84e29cecef96ef811de4f399dab2fde9425d0d418
~~~

# Envelope Hierarchy

This section is informative, and describes envelopes from the perspective of their hierarchical structure and the various ways they can be formatted.

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

<artwork type="svg"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.2" baseProfile="tiny" width="529.3px" height="531.5px" viewBox="0 0 529.3 531.5" xml:space="preserve">
<path fill="none" stroke="#000000" stroke-width="1.4997" d="M72.5,174.7l8.5-21.3c8.5-21.3,25.5-63.8,39-85s23.4-21.3,28.3-21.3h5"/>
<polygon fill="black" points="145.2,42.6 154.2,47.1 145.2,51.6 "/>
<rect x="143.7" y="42.6" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.4997" d="M81.1,179.7l7.1-8.8c7.1-8.8,21.2-26.5,36.8-35.4s32.5-8.8,41-8.8h8.5"/>
<polygon fill="black" points="166.3,122.1 175.3,126.6 166.3,131.1 "/>
<rect x="164.8" y="122.1" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.4997" d="M269,107.7l8.6-3.5c8.6-3.5,25.9-10.4,40.3-13.9  c14.3-3.5,25.7-3.5,31.4-3.5h5.7"/>
<polygon fill="black" points="346.9,82.4 355.9,86.9 346.9,91.4 "/>
<rect x="345.4" y="82.4" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.4997" d="M269,145.6l8.6,3.5c8.6,3.5,25.9,10.4,39.7,13.9  c13.8,3.5,24,3.5,29.1,3.5h5.1"/>
<polygon fill="black" points="343.5,161.9 352.5,166.4 343.5,170.9 "/>
<rect x="342" y="161.9" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.4997" d="M81.1,232.6l7.1,8.8c7.1,8.8,21.2,26.5,36.8,35.4s32.5,8.8,41,8.8h8.5"/>
<polygon fill="black" points="166.3,281.1 175.3,285.6 166.3,290.1 "/>
<rect x="164.8" y="281.1" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.4997" d="M269,266.7l8.6-3.5c8.6-3.5,25.9-10.4,40.3-13.9  c14.3-3.5,25.7-3.5,31.4-3.5h5.7"/>
<polygon fill="black" points="346.9,241.4 355.9,245.9 346.9,250.4 "/>
<rect x="345.4" y="241.4" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.4997" d="M269,304.6l8.6,3.5c8.6,3.5,25.9,10.4,41.3,13.9s28.9,3.5,35.6,3.5h6.7  "/>
<polygon fill="black" points="353.2,320.9 362.2,325.4 353.2,329.9 "/>
<rect x="351.7" y="320.9" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.4997" d="M68.7,238.8l9.1,34.3c9.1,34.3,27.4,102.9,45.1,137.2  s34.6,34.3,43.1,34.3h8.5"/>
<polygon fill="black" points="166.3,440.1 175.3,444.6 166.3,449.1 "/>
<rect x="164.8" y="440.1" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.4997" d="M269,425.7l8.6-3.5c8.6-3.5,25.9-10.4,40.3-13.9  c14.3-3.5,25.7-3.5,31.4-3.5h5.7"/>
<polygon fill="black" points="346.9,400.4 355.9,404.9 346.9,409.4 "/>
<rect x="345.4" y="400.4" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.4997" d="M269,463.6l8.6,3.5c8.6,3.5,25.9,10.4,40.7,13.9  c14.8,3.5,27,3.5,33.1,3.5h6.1"/>
<polygon fill="black" points="349.5,479.9 358.5,484.4 349.5,488.9 "/>
<rect x="348" y="479.9" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path d="M112.9,49l1-0.2c0.1,0.4,0.2,0.7,0.5,1c0.3,0.2,0.6,0.3,1.1,0.3c0.5,0,0.8-0.1,1.1-0.3s0.4-0.4,0.4-0.7  c0-0.2-0.1-0.4-0.3-0.6c-0.1-0.1-0.5-0.2-1.1-0.4c-0.8-0.2-1.3-0.4-1.6-0.5s-0.5-0.3-0.7-0.6s-0.2-0.5-0.2-0.8  c0-0.3,0.1-0.5,0.2-0.8s0.3-0.4,0.5-0.6c0.2-0.1,0.4-0.2,0.7-0.3c0.3-0.1,0.6-0.1,0.9-0.1c0.5,0,0.9,0.1,1.3,0.2  c0.4,0.1,0.6,0.3,0.8,0.6s0.3,0.6,0.4,1l-1,0.1c0-0.3-0.2-0.6-0.4-0.8s-0.5-0.3-1-0.3c-0.5,0-0.8,0.1-1,0.2  c-0.2,0.2-0.3,0.3-0.3,0.6c0,0.1,0,0.3,0.1,0.4c0.1,0.1,0.2,0.2,0.4,0.3c0.1,0,0.4,0.1,0.9,0.3c0.7,0.2,1.3,0.4,1.6,0.5  c0.3,0.1,0.5,0.3,0.7,0.6s0.3,0.5,0.3,0.9c0,0.4-0.1,0.7-0.3,1s-0.5,0.6-0.9,0.7c-0.4,0.2-0.8,0.3-1.3,0.3c-0.8,0-1.4-0.2-1.8-0.5  S113.1,49.7,112.9,49z"/>
<path d="M123.4,50.9V50c-0.5,0.7-1.1,1.1-2,1.1c-0.4,0-0.7-0.1-1-0.2c-0.3-0.1-0.6-0.3-0.7-0.5s-0.3-0.5-0.3-0.8  c0-0.2-0.1-0.5-0.1-1v-3.9h1.1v3.5c0,0.6,0,0.9,0.1,1.1c0.1,0.3,0.2,0.5,0.4,0.7s0.5,0.2,0.8,0.2c0.3,0,0.6-0.1,0.9-0.2  s0.5-0.4,0.6-0.7s0.2-0.7,0.2-1.2v-3.3h1.1v6.2H123.4z"/>
<path d="M127,50.9h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2c0.3,0.2,0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5c-0.5,0.6-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V50.9z M127,47.7c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8c-0.3-0.4-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6S127,47,127,47.7z"/>
<path d="M131.4,53.3l0.2-0.9c0.2,0.1,0.4,0.1,0.5,0.1c0.2,0,0.4-0.1,0.5-0.2c0.1-0.1,0.2-0.5,0.2-1.1v-6.5h1.1v6.6  c0,0.8-0.1,1.3-0.3,1.6c-0.3,0.4-0.7,0.6-1.3,0.6C131.9,53.4,131.6,53.4,131.4,53.3z M132.7,43.5v-1.2h1.1v1.2H132.7z"/>
<rect x="112.6" y="40.4" fill-rule="evenodd" fill="none" width="21.7" height="13.5"/>
<path d="M309.7,93v-8.6h1v0.8c0.2-0.3,0.5-0.6,0.8-0.7s0.6-0.2,1-0.2c0.5,0,1,0.1,1.4,0.4s0.7,0.7,0.9,1.2s0.3,1,0.3,1.6  c0,0.6-0.1,1.2-0.3,1.7c-0.2,0.5-0.6,0.9-1,1.2s-0.9,0.4-1.4,0.4c-0.4,0-0.7-0.1-0.9-0.2s-0.5-0.3-0.7-0.6v3H309.7z M310.6,87.5  c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8  c-0.3-0.4-0.7-0.6-1.2-0.6c-0.4,0-0.8,0.2-1.2,0.6S310.6,86.7,310.6,87.5z"/>
<path d="M316.3,90.6v-6.2h0.9v0.9c0.2-0.4,0.5-0.7,0.7-0.9s0.4-0.2,0.7-0.2c0.4,0,0.7,0.1,1.1,0.3l-0.4,1c-0.3-0.2-0.5-0.2-0.8-0.2  c-0.2,0-0.4,0.1-0.6,0.2s-0.3,0.3-0.4,0.6c-0.1,0.4-0.2,0.8-0.2,1.2v3.3H316.3z"/>
<path d="M324.6,88.6l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5s-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8c-0.5-0.6-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4s1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8s0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6c0,0.7,0.2,1.2,0.6,1.6  s0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3S324.4,89.1,324.6,88.6z M321.1,86.9h3.5c0-0.5-0.2-0.9-0.4-1.2c-0.3-0.4-0.8-0.6-1.3-0.6  c-0.5,0-0.9,0.2-1.2,0.5S321.2,86.4,321.1,86.9z"/>
<path d="M331,90.6v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6V82h1v8.6H331z M327.7,87.5c0,0.8,0.2,1.4,0.5,1.8  s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  S327.7,86.7,327.7,87.5z"/>
<rect x="308.9" y="80.1" fill-rule="evenodd" fill="none" width="24" height="13.5"/>
<path d="M313.3,167c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8c0.5,0.6,0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  c-0.2,0.5-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8S313.3,168.1,313.3,167z M314.4,167c0,0.8,0.2,1.4,0.5,1.8  c0.3,0.4,0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7c-0.3-0.4-0.8-0.6-1.3-0.6  c-0.5,0-1,0.2-1.3,0.6C314.5,165.6,314.4,166.2,314.4,167z"/>
<path d="M321.3,170.1h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1s0.2,0.8,0.2,1.3  c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V170.1z M321.3,167c0,0.7,0.1,1.3,0.3,1.6c0.3,0.5,0.8,0.8,1.3,0.8  c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6S321.3,166.2,321.3,167z"/>
<path d="M325.7,172.5l0.2-0.9c0.2,0.1,0.4,0.1,0.5,0.1c0.2,0,0.4-0.1,0.5-0.2s0.2-0.5,0.2-1.1v-6.5h1.1v6.6c0,0.8-0.1,1.3-0.3,1.6  c-0.3,0.4-0.7,0.6-1.3,0.6C326.2,172.7,325.9,172.6,325.7,172.5z M327,162.8v-1.2h1.1v1.2H327z"/>
<rect x="312.9" y="159.6" fill-rule="evenodd" fill="none" width="15.7" height="13.5"/>
<path d="M309.7,252v-8.6h1v0.8c0.2-0.3,0.5-0.6,0.8-0.7s0.6-0.2,1-0.2c0.5,0,1,0.1,1.4,0.4s0.7,0.7,0.9,1.2s0.3,1,0.3,1.6  c0,0.6-0.1,1.2-0.3,1.7c-0.2,0.5-0.6,0.9-1,1.2s-0.9,0.4-1.4,0.4c-0.4,0-0.7-0.1-0.9-0.2s-0.5-0.3-0.7-0.6v3H309.7z M310.6,246.5  c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8  c-0.3-0.4-0.7-0.6-1.2-0.6c-0.4,0-0.8,0.2-1.2,0.6S310.6,245.7,310.6,246.5z"/>
<path d="M316.3,249.6v-6.2h0.9v0.9c0.2-0.4,0.5-0.7,0.7-0.9s0.4-0.2,0.7-0.2c0.4,0,0.7,0.1,1.1,0.3l-0.4,1c-0.3-0.2-0.5-0.2-0.8-0.2  c-0.2,0-0.4,0.1-0.6,0.2s-0.3,0.3-0.4,0.6c-0.1,0.4-0.2,0.8-0.2,1.2v3.3H316.3z"/>
<path d="M324.6,247.6l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5s-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8c-0.5-0.6-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4s1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8s0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6c0,0.7,0.2,1.2,0.6,1.6  s0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3S324.4,248.1,324.6,247.6z M321.1,245.9h3.5c0-0.5-0.2-0.9-0.4-1.2c-0.3-0.4-0.8-0.6-1.3-0.6  c-0.5,0-0.9,0.2-1.2,0.5S321.2,245.4,321.1,245.9z"/>
<path d="M331,249.6v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6V241h1v8.6H331z M327.7,246.5c0,0.8,0.2,1.4,0.5,1.8  s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  S327.7,245.7,327.7,246.5z"/>
<rect x="308.9" y="239.1" fill-rule="evenodd" fill="none" width="24" height="13.5"/>
<path d="M313.3,326c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8c0.5,0.6,0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  c-0.2,0.5-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8S313.3,327.1,313.3,326z M314.4,326c0,0.8,0.2,1.4,0.5,1.8  c0.3,0.4,0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7c-0.3-0.4-0.8-0.6-1.3-0.6  c-0.5,0-1,0.2-1.3,0.6C314.5,324.6,314.4,325.2,314.4,326z"/>
<path d="M321.3,329.1h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1s0.2,0.8,0.2,1.3  c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V329.1z M321.3,326c0,0.7,0.1,1.3,0.3,1.6c0.3,0.5,0.8,0.8,1.3,0.8  c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6S321.3,325.2,321.3,326z"/>
<path d="M325.7,331.5l0.2-0.9c0.2,0.1,0.4,0.1,0.5,0.1c0.2,0,0.4-0.1,0.5-0.2s0.2-0.5,0.2-1.1v-6.5h1.1v6.6c0,0.8-0.1,1.3-0.3,1.6  c-0.3,0.4-0.7,0.6-1.3,0.6C326.2,331.7,325.9,331.6,325.7,331.5z M327,321.8v-1.2h1.1v1.2H327z"/>
<rect x="312.9" y="318.6" fill-rule="evenodd" fill="none" width="15.7" height="13.5"/>
<path d="M309.7,411v-8.6h1v0.8c0.2-0.3,0.5-0.6,0.8-0.7s0.6-0.2,1-0.2c0.5,0,1,0.1,1.4,0.4s0.7,0.7,0.9,1.2s0.3,1,0.3,1.6  c0,0.6-0.1,1.2-0.3,1.7c-0.2,0.5-0.6,0.9-1,1.2s-0.9,0.4-1.4,0.4c-0.4,0-0.7-0.1-0.9-0.2s-0.5-0.3-0.7-0.6v3H309.7z M310.6,405.5  c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8  c-0.3-0.4-0.7-0.6-1.2-0.6c-0.4,0-0.8,0.2-1.2,0.6S310.6,404.7,310.6,405.5z"/>
<path d="M316.3,408.6v-6.2h0.9v0.9c0.2-0.4,0.5-0.7,0.7-0.9s0.4-0.2,0.7-0.2c0.4,0,0.7,0.1,1.1,0.3l-0.4,1c-0.3-0.2-0.5-0.2-0.8-0.2  c-0.2,0-0.4,0.1-0.6,0.2s-0.3,0.3-0.4,0.6c-0.1,0.4-0.2,0.8-0.2,1.2v3.3H316.3z"/>
<path d="M324.6,406.6l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5s-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8c-0.5-0.6-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4s1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8s0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6c0,0.7,0.2,1.2,0.6,1.6  s0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3S324.4,407.1,324.6,406.6z M321.1,404.9h3.5c0-0.5-0.2-0.9-0.4-1.2c-0.3-0.4-0.8-0.6-1.3-0.6  c-0.5,0-0.9,0.2-1.2,0.5S321.2,404.4,321.1,404.9z"/>
<path d="M331,408.6v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6V400h1v8.6H331z M327.7,405.5c0,0.8,0.2,1.4,0.5,1.8  s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  S327.7,404.7,327.7,405.5z"/>
<rect x="308.9" y="398.1" fill-rule="evenodd" fill="none" width="24" height="13.5"/>
<path d="M313.3,485c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8c0.5,0.6,0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  c-0.2,0.5-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8S313.3,486.1,313.3,485z M314.4,485c0,0.8,0.2,1.4,0.5,1.8  c0.3,0.4,0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7c-0.3-0.4-0.8-0.6-1.3-0.6  c-0.5,0-1,0.2-1.3,0.6C314.5,483.6,314.4,484.2,314.4,485z"/>
<path d="M321.3,488.1h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1s0.2,0.8,0.2,1.3  c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V488.1z M321.3,485c0,0.7,0.1,1.3,0.3,1.6c0.3,0.5,0.8,0.8,1.3,0.8  c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6S321.3,484.2,321.3,485z"/>
<path d="M325.7,490.5l0.2-0.9c0.2,0.1,0.4,0.1,0.5,0.1c0.2,0,0.4-0.1,0.5-0.2s0.2-0.5,0.2-1.1v-6.5h1.1v6.6c0,0.8-0.1,1.3-0.3,1.6  c-0.3,0.4-0.7,0.6-1.3,0.6C326.2,490.7,325.9,490.6,325.7,490.5z M327,480.8v-1.2h1.1v1.2H327z"/>
<rect x="312.9" y="477.6" fill-rule="evenodd" fill="none" width="15.7" height="13.5"/>
<path fill="none" stroke="#000000" stroke-width="2.2496" d="M93.8,206.1c0,1.1-0.1,2.2-0.2,3.3c-0.1,1.1-0.3,2.2-0.5,3.3  c-0.2,1.1-0.5,2.2-0.8,3.2c-0.3,1.1-0.7,2.1-1.1,3.1c-0.4,1-0.9,2-1.4,3c-0.5,1-1.1,1.9-1.7,2.9c-0.6,0.9-1.3,1.8-2,2.7  c-0.7,0.9-1.4,1.7-2.2,2.5c-0.8,0.8-1.6,1.5-2.5,2.2c-0.9,0.7-1.7,1.4-2.7,2c-0.9,0.6-1.9,1.2-2.8,1.7s-2,1-3,1.4  c-1,0.4-2.1,0.8-3.1,1.1c-1.1,0.3-2.1,0.6-3.2,0.8c-1.1,0.2-2.2,0.4-3.3,0.5S61.1,240,60,240s-2.2-0.1-3.3-0.2s-2.2-0.3-3.3-0.5  c-1.1-0.2-2.2-0.5-3.2-0.8c-1.1-0.3-2.1-0.7-3.1-1.1c-1-0.4-2-0.9-3-1.4c-1-0.5-1.9-1.1-2.8-1.7s-1.8-1.3-2.7-2s-1.7-1.4-2.5-2.2  c-0.8-0.8-1.5-1.6-2.2-2.5c-0.7-0.9-1.4-1.7-2-2.7c-0.6-0.9-1.2-1.9-1.7-2.9c-0.5-1-1-2-1.4-3c-0.4-1-0.8-2.1-1.1-3.1  c-0.3-1.1-0.6-2.1-0.8-3.2s-0.4-2.2-0.5-3.3c-0.1-1.1-0.2-2.2-0.2-3.3s0.1-2.2,0.2-3.3c0.1-1.1,0.3-2.2,0.5-3.3s0.5-2.2,0.8-3.2  c0.3-1.1,0.7-2.1,1.1-3.1c0.4-1,0.9-2,1.4-3c0.5-1,1.1-1.9,1.7-2.9c0.6-0.9,1.3-1.8,2-2.7c0.7-0.9,1.4-1.7,2.2-2.5  c0.8-0.8,1.6-1.5,2.5-2.2s1.7-1.4,2.7-2s1.9-1.2,2.8-1.7c1-0.5,2-1,3-1.4c1-0.4,2.1-0.8,3.1-1.1c1.1-0.3,2.1-0.6,3.2-0.8  c1.1-0.2,2.2-0.4,3.3-0.5s2.2-0.2,3.3-0.2s2.2,0.1,3.3,0.2s2.2,0.3,3.3,0.5c1.1,0.2,2.2,0.5,3.2,0.8c1.1,0.3,2.1,0.7,3.1,1.1  c1,0.4,2,0.9,3,1.4s1.9,1.1,2.8,1.7c0.9,0.6,1.8,1.3,2.7,2s1.7,1.4,2.5,2.2c0.8,0.8,1.5,1.6,2.2,2.5c0.7,0.9,1.4,1.7,2,2.7  c0.6,0.9,1.2,1.9,1.7,2.9c0.5,1,1,2,1.4,3c0.4,1,0.8,2.1,1.1,3.1c0.3,1.1,0.6,2.1,0.8,3.2c0.2,1.1,0.4,2.2,0.5,3.3  C93.8,203.9,93.8,205,93.8,206.1z"/>
<path d="M34.1,198.9c0-1,0.1-1.8,0.3-2.5s0.5-1.1,0.9-1.4c0.4-0.3,0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3c0.3,0.2,0.6,0.5,0.9,0.8  c0.2,0.3,0.4,0.8,0.5,1.3s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9  C34.4,201.7,34.1,200.5,34.1,198.9z M35.2,198.9c0,1.4,0.2,2.3,0.5,2.8c0.3,0.5,0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7  c0.3-0.5,0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8c-0.3-0.5-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C35.4,196.5,35.2,197.5,35.2,198.9  z"/>
<path d="M45.1,202.4c-0.4,0.3-0.8,0.6-1.1,0.7s-0.7,0.2-1.2,0.2c-0.7,0-1.2-0.2-1.6-0.5s-0.6-0.8-0.6-1.3c0-0.3,0.1-0.6,0.2-0.8  c0.1-0.3,0.3-0.5,0.5-0.6s0.5-0.3,0.8-0.3c0.2-0.1,0.5-0.1,0.9-0.2c0.9-0.1,1.5-0.2,1.9-0.4c0-0.1,0-0.2,0-0.3  c0-0.4-0.1-0.7-0.3-0.9c-0.3-0.2-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.1-1.1,0.3s-0.4,0.5-0.5,0.9l-1-0.1c0.1-0.4,0.2-0.8,0.5-1.1  s0.5-0.5,0.9-0.6c0.4-0.1,0.9-0.2,1.4-0.2c0.5,0,1,0.1,1.3,0.2s0.6,0.3,0.7,0.5c0.2,0.2,0.3,0.4,0.3,0.7c0,0.2,0.1,0.5,0.1,1v1.4  c0,1,0,1.6,0.1,1.9s0.1,0.5,0.3,0.7h-1.1C45.2,202.9,45.2,202.7,45.1,202.4z M45.1,200c-0.4,0.2-1,0.3-1.7,0.4  c-0.4,0.1-0.7,0.1-0.9,0.2s-0.3,0.2-0.4,0.3c-0.1,0.2-0.1,0.3-0.1,0.5c0,0.3,0.1,0.5,0.3,0.7c0.2,0.2,0.5,0.3,0.9,0.3  c0.4,0,0.8-0.1,1.1-0.3s0.5-0.4,0.7-0.7c0.1-0.2,0.2-0.6,0.2-1.1V200z"/>
<path d="M48.7,203.1h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2c0.3,0.2,0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5c-0.5,0.6-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V203.1z M48.7,200c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8c-0.3-0.4-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6S48.7,199.2,48.7,200z"/>
<path d="M58.5,202.4c-0.4,0.3-0.8,0.6-1.1,0.7s-0.7,0.2-1.2,0.2c-0.7,0-1.2-0.2-1.6-0.5s-0.6-0.8-0.6-1.3c0-0.3,0.1-0.6,0.2-0.8  c0.1-0.3,0.3-0.5,0.5-0.6s0.5-0.3,0.8-0.3c0.2-0.1,0.5-0.1,0.9-0.2c0.9-0.1,1.5-0.2,1.9-0.4c0-0.1,0-0.2,0-0.3  c0-0.4-0.1-0.7-0.3-0.9c-0.3-0.2-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.1-1.1,0.3s-0.4,0.5-0.5,0.9l-1-0.1c0.1-0.4,0.2-0.8,0.5-1.1  s0.5-0.5,0.9-0.6c0.4-0.1,0.9-0.2,1.4-0.2c0.5,0,1,0.1,1.3,0.2s0.6,0.3,0.7,0.5c0.2,0.2,0.3,0.4,0.3,0.7c0,0.2,0.1,0.5,0.1,1v1.4  c0,1,0,1.6,0.1,1.9s0.1,0.5,0.3,0.7h-1.1C58.6,202.9,58.5,202.7,58.5,202.4z M58.4,200c-0.4,0.2-1,0.3-1.7,0.4  c-0.4,0.1-0.7,0.1-0.9,0.2s-0.3,0.2-0.4,0.3c-0.1,0.2-0.1,0.3-0.1,0.5c0,0.3,0.1,0.5,0.3,0.7c0.2,0.2,0.5,0.3,0.9,0.3  c0.4,0,0.8-0.1,1.1-0.3s0.5-0.4,0.7-0.7c0.1-0.2,0.2-0.6,0.2-1.1V200z"/>
<path d="M65.2,200.8l1,0.1c-0.1,0.7-0.4,1.3-0.9,1.7s-1,0.6-1.7,0.6c-0.9,0-1.5-0.3-2.1-0.8s-0.8-1.4-0.8-2.4c0-0.7,0.1-1.3,0.3-1.8  c0.2-0.5,0.6-0.9,1-1.1c0.5-0.3,0.9-0.4,1.5-0.4c0.7,0,1.2,0.2,1.7,0.5s0.7,0.8,0.8,1.5l-1,0.2c-0.1-0.4-0.3-0.7-0.5-0.9  c-0.2-0.2-0.5-0.3-0.9-0.3c-0.5,0-1,0.2-1.3,0.6c-0.3,0.4-0.5,1-0.5,1.8c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.3,0.6  c0.4,0,0.8-0.1,1-0.4C64.9,201.8,65.1,201.4,65.2,200.8z"/>
<path d="M72.3,196.6l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  c-0.2,0.5-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9s0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8c0.5,0.5,0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5  c-0.2,0.5-0.6,0.8-1,1.1s-0.9,0.4-1.4,0.4c-0.9,0-1.6-0.3-2.1-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6  c0.5-0.7,1.3-1,2.2-1c0.7,0,1.2,0.2,1.7,0.6C71.9,195.4,72.2,196,72.3,196.6z M68,200.3c0,0.4,0.1,0.7,0.2,1  c0.2,0.3,0.4,0.6,0.6,0.8s0.6,0.3,0.9,0.3c0.4,0,0.8-0.2,1.1-0.5c0.3-0.4,0.5-0.8,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4  c-0.3-0.3-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.5C68.1,199.3,68,199.8,68,200.3z"/>
<path d="M73.5,198.9c0-1,0.1-1.8,0.3-2.5s0.5-1.1,0.9-1.4c0.4-0.3,0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3c0.3,0.2,0.6,0.5,0.9,0.8  c0.2,0.3,0.4,0.8,0.5,1.3s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9  C73.8,201.7,73.5,200.5,73.5,198.9z M74.6,198.9c0,1.4,0.2,2.3,0.5,2.8c0.3,0.5,0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7  c0.3-0.5,0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8c-0.3-0.5-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C74.7,196.5,74.6,197.5,74.6,198.9  z"/>
<path d="M84.5,202.4c-0.4,0.3-0.8,0.6-1.1,0.7s-0.7,0.2-1.2,0.2c-0.7,0-1.2-0.2-1.6-0.5s-0.6-0.8-0.6-1.3c0-0.3,0.1-0.6,0.2-0.8  c0.1-0.3,0.3-0.5,0.5-0.6s0.5-0.3,0.8-0.3c0.2-0.1,0.5-0.1,0.9-0.2c0.9-0.1,1.5-0.2,1.9-0.4c0-0.1,0-0.2,0-0.3  c0-0.4-0.1-0.7-0.3-0.9c-0.3-0.2-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.1-1.1,0.3s-0.4,0.5-0.5,0.9l-1-0.1c0.1-0.4,0.2-0.8,0.5-1.1  s0.5-0.5,0.9-0.6c0.4-0.1,0.9-0.2,1.4-0.2c0.5,0,1,0.1,1.3,0.2s0.6,0.3,0.7,0.5c0.2,0.2,0.3,0.4,0.3,0.7c0,0.2,0.1,0.5,0.1,1v1.4  c0,1,0,1.6,0.1,1.9s0.1,0.5,0.3,0.7h-1.1C84.6,202.9,84.5,202.7,84.5,202.4z M84.4,200c-0.4,0.2-1,0.3-1.7,0.4  c-0.4,0.1-0.7,0.1-0.9,0.2s-0.3,0.2-0.4,0.3c-0.1,0.2-0.1,0.3-0.1,0.5c0,0.3,0.1,0.5,0.3,0.7c0.2,0.2,0.5,0.3,0.9,0.3  c0.4,0,0.8-0.1,1.1-0.3s0.5-0.4,0.7-0.7c0.1-0.2,0.2-0.6,0.2-1.1V200z"/>
<path d="M43.6,216.6V208h1.2l4.5,6.7V208h1.1v8.6h-1.2l-4.5-6.8v6.8H43.6z"/>
<path d="M51.9,212.4c0-1.4,0.4-2.5,1.1-3.3c0.8-0.8,1.8-1.2,3-1.2c0.8,0,1.5,0.2,2.1,0.6c0.6,0.4,1.1,0.9,1.5,1.6  c0.3,0.7,0.5,1.4,0.5,2.3c0,0.9-0.2,1.7-0.5,2.3c-0.4,0.7-0.8,1.2-1.5,1.6c-0.6,0.4-1.3,0.5-2.1,0.5c-0.8,0-1.5-0.2-2.2-0.6  c-0.6-0.4-1.1-0.9-1.4-1.6S51.9,213.2,51.9,212.4z M53.1,212.5c0,1,0.3,1.9,0.8,2.4s1.3,0.9,2.1,0.9c0.9,0,1.6-0.3,2.1-0.9  c0.6-0.6,0.8-1.5,0.8-2.6c0-0.7-0.1-1.3-0.4-1.8s-0.6-0.9-1-1.2s-1-0.4-1.5-0.4c-0.8,0-1.5,0.3-2.1,0.8  C53.3,210.2,53.1,211.2,53.1,212.5z"/>
<path d="M61.6,216.6V208h3c0.7,0,1.2,0,1.5,0.1c0.5,0.1,0.9,0.3,1.3,0.6c0.5,0.4,0.8,0.9,1,1.5s0.3,1.3,0.3,2c0,0.7-0.1,1.2-0.2,1.7  s-0.3,0.9-0.6,1.3s-0.5,0.6-0.8,0.8s-0.6,0.3-1,0.4c-0.4,0.1-0.9,0.1-1.4,0.1H61.6z M62.7,215.6h1.8c0.6,0,1-0.1,1.3-0.2  s0.6-0.3,0.8-0.4c0.3-0.3,0.5-0.6,0.6-1.1s0.2-1,0.2-1.7c0-0.9-0.1-1.6-0.4-2.1s-0.7-0.8-1.1-1c-0.3-0.1-0.8-0.2-1.5-0.2h-1.8V215.6  z"/>
<path d="M70.2,216.6V208h6.2v1h-5.1v2.6h4.8v1h-4.8v2.9h5.3v1H70.2z"/>
<rect x="33.6" y="192.6" fill-rule="evenodd" fill="none" width="52.5" height="27"/>
<rect x="153.3" y="26.1" fill="none" stroke="#000000" stroke-width="2.2496" width="136.8" height="42"/>
<path d="M201.1,43.1v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1s0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8  c0.3-0.4,0.5-0.9,0.5-1.3c0-0.4-0.1-0.8-0.4-1.1c-0.3-0.3-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5c-0.3,0.3-0.5,0.7-0.5,1.3  l-1.1-0.1c0.1-0.8,0.4-1.4,0.8-1.8c0.5-0.4,1.1-0.6,2-0.6c0.8,0,1.5,0.2,2,0.7c0.5,0.5,0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1  c-0.1,0.3-0.4,0.7-0.7,1s-0.9,0.9-1.6,1.5c-0.6,0.5-1,0.9-1.2,1.1s-0.3,0.4-0.4,0.6H201.1z"/>
<path d="M202.3,36.7v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3c-0.5,1-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  s0.6-1.9,1.1-2.8c0.5-0.9,1-1.6,1.5-2.2H202.3z"/>
<path d="M210.5,39.5c-0.4-0.2-0.8-0.4-1-0.7s-0.3-0.7-0.3-1.1c0-0.6,0.2-1.2,0.7-1.6c0.4-0.4,1-0.6,1.8-0.6c0.8,0,1.4,0.2,1.8,0.7  s0.7,1,0.7,1.6c0,0.4-0.1,0.7-0.3,1c-0.2,0.3-0.5,0.5-1,0.7c0.5,0.2,0.9,0.4,1.2,0.8c0.3,0.4,0.4,0.8,0.4,1.4c0,0.7-0.3,1.4-0.8,1.9  c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.5-0.3-2-0.8c-0.5-0.5-0.8-1.1-0.8-1.9c0-0.6,0.1-1,0.4-1.4S210,39.6,210.5,39.5z M210,41.6  c0,0.3,0.1,0.6,0.2,0.9c0.1,0.3,0.4,0.5,0.6,0.7s0.6,0.2,0.9,0.2c0.5,0,0.9-0.2,1.2-0.5c0.3-0.3,0.5-0.7,0.5-1.2  c0-0.5-0.2-0.9-0.5-1.3c-0.3-0.3-0.8-0.5-1.3-0.5c-0.5,0-0.9,0.2-1.2,0.5C210.1,40.7,210,41.2,210,41.6z M210.3,37.7  c0,0.4,0.1,0.7,0.4,1s0.6,0.4,1,0.4c0.4,0,0.7-0.1,1-0.4c0.3-0.3,0.4-0.6,0.4-0.9c0-0.4-0.1-0.7-0.4-1c-0.3-0.3-0.6-0.4-1-0.4  c-0.4,0-0.7,0.1-1,0.4S210.3,37.3,210.3,37.7z"/>
<path d="M218.9,44.1v-2.1h-3.7v-1l3.9-5.6h0.9v5.6h1.2v1H220v2.1H218.9z M218.9,41.1v-3.9l-2.7,3.9H218.9z"/>
<path d="M222.2,39.9c0-1,0.1-1.8,0.3-2.5s0.5-1.1,0.9-1.4c0.4-0.3,0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3c0.3,0.2,0.6,0.5,0.9,0.8  c0.2,0.3,0.4,0.8,0.5,1.3s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9  C222.5,42.7,222.2,41.5,222.2,39.9z M223.3,39.9c0,1.4,0.2,2.3,0.5,2.8c0.3,0.5,0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7  c0.3-0.5,0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8c-0.3-0.5-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C223.5,37.5,223.3,38.5,223.3,39.9  z"/>
<path d="M228.9,41.9l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3s0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5c0.3-0.3,0.5-0.8,0.5-1.3  c0-0.5-0.2-0.9-0.5-1.2c-0.3-0.3-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1l0.1-0.9c0.1,0,0.1,0,0.2,0c0.4,0,0.9-0.1,1.2-0.4  c0.4-0.2,0.5-0.6,0.5-1.1c0-0.4-0.1-0.7-0.4-1c-0.3-0.3-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4s-0.4,0.6-0.5,1.2l-1.1-0.2  c0.1-0.7,0.4-1.3,0.9-1.6c0.5-0.4,1-0.6,1.7-0.6c0.5,0,0.9,0.1,1.3,0.3c0.4,0.2,0.7,0.5,0.9,0.8c0.2,0.3,0.3,0.7,0.3,1.1  c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-0.9,0.7c0.5,0.1,0.9,0.4,1.2,0.7c0.3,0.4,0.4,0.8,0.4,1.4c0,0.8-0.3,1.4-0.8,1.9  c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7S229,42.6,228.9,41.9z"/>
<path d="M235.6,41.9l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2c0.3,0.3,0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6c0.4-0.4,0.5-0.9,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.3-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2s-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4L237,39  c0.5-0.4,1.1-0.5,1.6-0.5c0.8,0,1.4,0.3,1.9,0.8c0.5,0.5,0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1  c-0.8,0-1.4-0.2-1.9-0.7C235.9,43.2,235.6,42.6,235.6,41.9z"/>
<path d="M242.2,39.9c0-1,0.1-1.8,0.3-2.5s0.5-1.1,0.9-1.4c0.4-0.3,0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3c0.3,0.2,0.6,0.5,0.9,0.8  c0.2,0.3,0.4,0.8,0.5,1.3s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9  C242.5,42.7,242.2,41.5,242.2,39.9z M243.3,39.9c0,1.4,0.2,2.3,0.5,2.8c0.3,0.5,0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7  c0.3-0.5,0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8c-0.3-0.5-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C243.5,37.5,243.3,38.5,243.3,39.9  z"/>
<path d="M205.3,52.1l-0.3-1.6V49h1.2v1.4l-0.3,1.6H205.3z M207.3,52.1l-0.3-1.6V49h1.2v1.4l-0.3,1.6H207.3z"/>
<path d="M208.7,57.6L212,49h1.2l3.5,8.6h-1.3l-1-2.6h-3.6l-0.9,2.6H208.7z M211.2,54.1h2.9l-0.9-2.4c-0.3-0.7-0.5-1.3-0.6-1.8  c-0.1,0.6-0.3,1.1-0.5,1.6L211.2,54.1z"/>
<path d="M217.5,57.6V49h1.1v8.6H217.5z"/>
<path d="M220.2,50.2V49h1.1v1.2H220.2z M220.2,57.6v-6.2h1.1v6.2H220.2z"/>
<path d="M226.9,55.3l1,0.1c-0.1,0.7-0.4,1.3-0.9,1.7s-1,0.6-1.7,0.6c-0.9,0-1.5-0.3-2.1-0.8s-0.8-1.4-0.8-2.4c0-0.7,0.1-1.3,0.3-1.8  c0.2-0.5,0.6-0.9,1-1.1c0.5-0.3,0.9-0.4,1.5-0.4c0.7,0,1.2,0.2,1.7,0.5s0.7,0.8,0.8,1.5l-1,0.2c-0.1-0.4-0.3-0.7-0.5-0.9  c-0.2-0.2-0.5-0.3-0.9-0.3c-0.5,0-1,0.2-1.3,0.6c-0.3,0.4-0.5,1-0.5,1.8c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.3,0.6  c0.4,0,0.8-0.1,1-0.4C226.7,56.3,226.8,55.9,226.9,55.3z"/>
<path d="M233.1,55.6l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5s-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8s-0.8-1.3-0.8-2.4c0-1,0.3-1.9,0.8-2.4  s1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8c0.5,0.6,0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6c0,0.7,0.2,1.2,0.6,1.6s0.8,0.5,1.3,0.5  c0.4,0,0.7-0.1,1-0.3C232.7,56.4,232.9,56.1,233.1,55.6z M229.6,53.9h3.5c0-0.5-0.2-0.9-0.4-1.2c-0.3-0.4-0.8-0.6-1.3-0.6  c-0.5,0-0.9,0.2-1.2,0.5S229.7,53.4,229.6,53.9z"/>
<path d="M235.6,52.1l-0.3-1.6V49h1.2v1.4l-0.3,1.6H235.6z M237.5,52.1l-0.3-1.6V49h1.2v1.4l-0.3,1.6H237.5z"/>
<rect x="160.8" y="33.6" fill-rule="evenodd" fill="none" width="122.2" height="27"/>
<path fill="none" stroke="#000000" stroke-width="2.2496" d="M195.4,105.6H248c0.7,0,1.4,0,2.1,0.1c0.7,0.1,1.4,0.2,2,0.3  c0.7,0.1,1.3,0.3,2,0.5c0.7,0.2,1.3,0.4,1.9,0.7c0.6,0.3,1.3,0.6,1.9,0.9c0.6,0.3,1.2,0.7,1.8,1.1c0.6,0.4,1.1,0.8,1.7,1.2  s1,0.9,1.5,1.4s0.9,1,1.4,1.5s0.8,1.1,1.2,1.7c0.4,0.6,0.7,1.2,1.1,1.8s0.6,1.2,0.9,1.9c0.3,0.6,0.5,1.3,0.7,1.9  c0.2,0.7,0.4,1.3,0.5,2s0.2,1.4,0.3,2s0.1,1.4,0.1,2.1s0,1.4-0.1,2.1c-0.1,0.7-0.2,1.4-0.3,2s-0.3,1.3-0.5,2  c-0.2,0.7-0.4,1.3-0.7,1.9c-0.3,0.6-0.6,1.3-0.9,1.9c-0.3,0.6-0.7,1.2-1.1,1.8c-0.4,0.6-0.8,1.1-1.2,1.7s-0.9,1-1.4,1.5  s-1,0.9-1.5,1.4s-1.1,0.8-1.7,1.2c-0.6,0.4-1.2,0.7-1.8,1.1c-0.6,0.3-1.2,0.6-1.9,0.9c-0.6,0.3-1.3,0.5-1.9,0.7  c-0.7,0.2-1.3,0.4-2,0.5c-0.7,0.1-1.4,0.2-2,0.3c-0.7,0.1-1.4,0.1-2.1,0.1h-52.6c-0.7,0-1.4,0-2.1-0.1c-0.7-0.1-1.4-0.2-2-0.3  c-0.7-0.1-1.3-0.3-2-0.5c-0.7-0.2-1.3-0.4-1.9-0.7c-0.6-0.3-1.3-0.6-1.9-0.9c-0.6-0.3-1.2-0.7-1.8-1.1c-0.6-0.4-1.1-0.8-1.7-1.2  c-0.5-0.4-1-0.9-1.5-1.4s-0.9-1-1.4-1.5s-0.8-1.1-1.2-1.7c-0.4-0.6-0.7-1.2-1.1-1.8s-0.6-1.2-0.9-1.9c-0.3-0.6-0.5-1.3-0.7-1.9  c-0.2-0.7-0.4-1.3-0.5-2s-0.2-1.4-0.3-2s-0.1-1.4-0.1-2.1s0-1.4,0.1-2.1c0.1-0.7,0.2-1.4,0.3-2s0.3-1.3,0.5-2  c0.2-0.7,0.4-1.3,0.7-1.9c0.3-0.6,0.6-1.3,0.9-1.9c0.3-0.6,0.7-1.2,1.1-1.8c0.4-0.6,0.8-1.1,1.2-1.7s0.9-1,1.4-1.5s1-0.9,1.5-1.4  c0.5-0.4,1.1-0.8,1.7-1.2c0.6-0.4,1.2-0.7,1.8-1.1c0.6-0.3,1.2-0.6,1.9-0.9c0.6-0.3,1.3-0.5,1.9-0.7c0.7-0.2,1.3-0.4,2-0.5  c0.7-0.1,1.4-0.2,2-0.3C194.1,105.7,194.7,105.6,195.4,105.6z"/>
<path d="M199.5,123.6h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1c0.4-0.4,0.8-0.8,0.9-1.1h0.7  V123.6z"/>
<path d="M206.8,121.6l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5s-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8s-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4s1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8c0.5,0.6,0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6c0,0.7,0.2,1.2,0.6,1.6  s0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3C206.4,122.4,206.6,122.1,206.8,121.6z M203.3,119.9h3.5c0-0.5-0.2-0.9-0.4-1.2  c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5S203.3,119.4,203.3,119.9z"/>
<path d="M208.9,119.4c0-1,0.1-1.8,0.3-2.5s0.5-1.1,0.9-1.4c0.4-0.3,0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3c0.3,0.2,0.6,0.5,0.9,0.8  c0.2,0.3,0.4,0.8,0.5,1.3s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9  C209.2,122.2,208.9,121,208.9,119.4z M210,119.4c0,1.4,0.2,2.3,0.5,2.8c0.3,0.5,0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7  c0.3-0.5,0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8c-0.3-0.5-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C210.1,117,210,118,210,119.4z"/>
<path d="M216.8,123.6h-1V115h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2c0.3,0.2,0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5c-0.5,0.6-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V123.6z M216.8,120.5  c0,0.7,0.1,1.3,0.3,1.6c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8  c-0.3-0.4-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6S216.8,119.7,216.8,120.5z"/>
<path d="M222.2,119.4c0-1,0.1-1.8,0.3-2.5s0.5-1.1,0.9-1.4c0.4-0.3,0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3c0.3,0.2,0.6,0.5,0.9,0.8  c0.2,0.3,0.4,0.8,0.5,1.3s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9  C222.5,122.2,222.2,121,222.2,119.4z M223.3,119.4c0,1.4,0.2,2.3,0.5,2.8c0.3,0.5,0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7  c0.3-0.5,0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8c-0.3-0.5-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C223.5,117,223.3,118,223.3,119.4z  "/>
<path d="M232.3,123.6v-2.1h-3.7v-1l3.9-5.6h0.9v5.6h1.2v1h-1.2v2.1H232.3z M232.3,120.6v-3.9l-2.7,3.9H232.3z"/>
<path d="M235.7,121.6l1-0.1c0.1,0.5,0.2,0.8,0.5,1s0.6,0.3,0.9,0.3c0.3,0,0.6-0.1,0.9-0.2s0.4-0.3,0.6-0.6s0.3-0.6,0.4-1  s0.2-0.9,0.2-1.3c0,0,0-0.1,0-0.2c-0.2,0.3-0.5,0.6-0.9,0.8c-0.4,0.2-0.8,0.3-1.2,0.3c-0.7,0-1.3-0.3-1.8-0.8s-0.7-1.2-0.7-2  c0-0.9,0.3-1.6,0.8-2.1c0.5-0.5,1.2-0.8,1.9-0.8c0.6,0,1.1,0.2,1.5,0.5c0.5,0.3,0.8,0.7,1.1,1.3c0.2,0.6,0.4,1.4,0.4,2.4  c0,1.1-0.1,2-0.4,2.6c-0.2,0.7-0.6,1.1-1.1,1.5c-0.5,0.3-1,0.5-1.7,0.5c-0.7,0-1.2-0.2-1.6-0.6C236.1,122.8,235.8,122.3,235.7,121.6  z M240,117.8c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.4-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.6s-0.5,0.9-0.5,1.5c0,0.5,0.2,1,0.5,1.3  c0.3,0.3,0.7,0.5,1.2,0.5c0.5,0,0.9-0.2,1.2-0.5C239.9,118.9,240,118.5,240,117.8z"/>
<path d="M243.5,123.6h-1V115h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2c0.3,0.2,0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5c-0.5,0.6-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V123.6z M243.5,120.5  c0,0.7,0.1,1.3,0.3,1.6c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8  c-0.3-0.4-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6S243.5,119.7,243.5,120.5z"/>
<path d="M187.2,137.1l3.3-8.6h1.2l3.5,8.6h-1.3l-1-2.6h-3.6l-0.9,2.6H187.2z M189.6,133.6h2.9l-0.9-2.4c-0.3-0.7-0.5-1.3-0.6-1.8  c-0.1,0.6-0.3,1.1-0.5,1.6L189.6,133.6z"/>
<path d="M195.7,134.4l1.1-0.1c0.1,0.4,0.2,0.8,0.4,1.1c0.2,0.3,0.5,0.5,0.9,0.7c0.4,0.2,0.8,0.3,1.3,0.3c0.4,0,0.8-0.1,1.1-0.2  c0.3-0.1,0.6-0.3,0.7-0.5s0.2-0.5,0.2-0.7c0-0.3-0.1-0.5-0.2-0.7s-0.4-0.4-0.8-0.5c-0.2-0.1-0.7-0.2-1.5-0.4s-1.3-0.4-1.7-0.5  c-0.4-0.2-0.7-0.5-0.9-0.8s-0.3-0.7-0.3-1.1c0-0.4,0.1-0.8,0.4-1.2s0.6-0.7,1.1-0.9s1-0.3,1.6-0.3c0.6,0,1.2,0.1,1.7,0.3  c0.5,0.2,0.9,0.5,1.1,0.9c0.3,0.4,0.4,0.8,0.4,1.4l-1.1,0.1c-0.1-0.5-0.3-1-0.6-1.2c-0.3-0.3-0.8-0.4-1.5-0.4  c-0.7,0-1.2,0.1-1.5,0.4s-0.5,0.6-0.5,0.9c0,0.3,0.1,0.6,0.3,0.8c0.2,0.2,0.8,0.4,1.7,0.6s1.6,0.4,1.9,0.5c0.5,0.2,0.9,0.5,1.1,0.9  c0.2,0.4,0.4,0.8,0.4,1.2c0,0.5-0.1,0.9-0.4,1.3c-0.3,0.4-0.6,0.7-1.1,0.9c-0.5,0.2-1,0.3-1.7,0.3c-0.8,0-1.4-0.1-2-0.3  c-0.5-0.2-0.9-0.6-1.2-1S195.7,134.9,195.7,134.4z"/>
<path d="M203.7,134.4l1.1-0.1c0.1,0.4,0.2,0.8,0.4,1.1c0.2,0.3,0.5,0.5,0.9,0.7c0.4,0.2,0.8,0.3,1.3,0.3c0.4,0,0.8-0.1,1.1-0.2  c0.3-0.1,0.6-0.3,0.7-0.5s0.2-0.5,0.2-0.7c0-0.3-0.1-0.5-0.2-0.7s-0.4-0.4-0.8-0.5c-0.2-0.1-0.7-0.2-1.5-0.4s-1.3-0.4-1.7-0.5  c-0.4-0.2-0.7-0.5-0.9-0.8s-0.3-0.7-0.3-1.1c0-0.4,0.1-0.8,0.4-1.2s0.6-0.7,1.1-0.9s1-0.3,1.6-0.3c0.6,0,1.2,0.1,1.7,0.3  c0.5,0.2,0.9,0.5,1.1,0.9c0.3,0.4,0.4,0.8,0.4,1.4l-1.1,0.1c-0.1-0.5-0.3-1-0.6-1.2c-0.3-0.3-0.8-0.4-1.5-0.4  c-0.7,0-1.2,0.1-1.5,0.4s-0.5,0.6-0.5,0.9c0,0.3,0.1,0.6,0.3,0.8c0.2,0.2,0.8,0.4,1.7,0.6s1.6,0.4,1.9,0.5c0.5,0.2,0.9,0.5,1.1,0.9  c0.2,0.4,0.4,0.8,0.4,1.2c0,0.5-0.1,0.9-0.4,1.3c-0.3,0.4-0.6,0.7-1.1,0.9c-0.5,0.2-1,0.3-1.7,0.3c-0.8,0-1.4-0.1-2-0.3  c-0.5-0.2-0.9-0.6-1.2-1S203.7,134.9,203.7,134.4z"/>
<path d="M212.1,137.1v-8.6h6.2v1h-5.1v2.6h4.8v1h-4.8v2.9h5.3v1H212.1z"/>
<path d="M220.1,137.1v-8.6h3.8c0.8,0,1.3,0.1,1.7,0.2s0.7,0.4,1,0.8s0.4,0.8,0.4,1.3c0,0.6-0.2,1.1-0.6,1.5c-0.4,0.4-1,0.7-1.8,0.8  c0.3,0.1,0.5,0.3,0.7,0.4c0.3,0.3,0.6,0.7,0.9,1.1l1.5,2.3h-1.4l-1.1-1.8c-0.3-0.5-0.6-0.9-0.8-1.2s-0.4-0.5-0.6-0.6  c-0.2-0.1-0.3-0.2-0.5-0.2c-0.1,0-0.3,0-0.6,0h-1.3v3.8H220.1z M221.3,132.3h2.4c0.5,0,0.9-0.1,1.2-0.2c0.3-0.1,0.5-0.3,0.7-0.5  s0.2-0.5,0.2-0.8c0-0.4-0.1-0.7-0.4-1s-0.8-0.4-1.4-0.4h-2.7V132.3z"/>
<path d="M230.7,137.1v-7.6h-2.8v-1h6.8v1h-2.8v7.6H230.7z"/>
<path d="M236.1,137.1v-8.6h1.1v8.6H236.1z"/>
<path d="M238.9,132.9c0-1.4,0.4-2.5,1.1-3.3c0.8-0.8,1.8-1.2,3-1.2c0.8,0,1.5,0.2,2.1,0.6c0.6,0.4,1.1,0.9,1.5,1.6  c0.3,0.7,0.5,1.4,0.5,2.3c0,0.9-0.2,1.7-0.5,2.3c-0.4,0.7-0.8,1.2-1.5,1.6c-0.6,0.4-1.3,0.5-2.1,0.5c-0.8,0-1.5-0.2-2.2-0.6  c-0.6-0.4-1.1-0.9-1.4-1.6S238.9,133.7,238.9,132.9z M240,133c0,1,0.3,1.9,0.8,2.4s1.3,0.9,2.1,0.9c0.9,0,1.6-0.3,2.1-0.9  c0.6-0.6,0.8-1.5,0.8-2.6c0-0.7-0.1-1.3-0.4-1.8s-0.6-0.9-1-1.2s-1-0.4-1.5-0.4c-0.8,0-1.5,0.3-2.1,0.8  C240.3,130.7,240,131.7,240,133z"/>
<path d="M248.5,137.1v-8.6h1.2l4.5,6.7v-6.7h1.1v8.6h-1.2l-4.5-6.8v6.8H248.5z"/>
<rect x="187.2" y="113.1" fill-rule="evenodd" fill="none" width="69" height="27"/>
<rect x="355" y="65.9" fill="none" stroke="#000000" stroke-width="2.2496" width="144.8" height="42"/>
<path d="M401.3,76.4v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  s0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H401.3z"/>
<path d="M407.9,79.6c0-1,0.1-1.8,0.3-2.5s0.5-1.1,0.9-1.4s0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3s0.6,0.5,0.9,0.8s0.4,0.8,0.5,1.3  s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9C408.1,82.4,407.9,81.3,407.9,79.6z   M408.9,79.6c0,1.4,0.2,2.3,0.5,2.8s0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7s0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8s-0.7-0.7-1.2-0.7  c-0.5,0-0.9,0.2-1.2,0.6C409.1,77.3,408.9,78.2,408.9,79.6z"/>
<path d="M414.7,81.9l1-0.1c0.1,0.5,0.2,0.8,0.5,1s0.6,0.3,0.9,0.3c0.3,0,0.6-0.1,0.9-0.2c0.2-0.1,0.4-0.3,0.6-0.6s0.3-0.6,0.4-1  s0.2-0.9,0.2-1.3c0,0,0-0.1,0-0.2c-0.2,0.3-0.5,0.6-0.9,0.8s-0.8,0.3-1.2,0.3c-0.7,0-1.3-0.3-1.8-0.8c-0.5-0.5-0.7-1.2-0.7-2  c0-0.9,0.3-1.6,0.8-2.1c0.5-0.5,1.2-0.8,1.9-0.8c0.6,0,1.1,0.2,1.5,0.5s0.8,0.7,1.1,1.3s0.4,1.4,0.4,2.4c0,1.1-0.1,2-0.4,2.6  s-0.6,1.1-1.1,1.5s-1,0.5-1.7,0.5c-0.7,0-1.2-0.2-1.6-0.6C415,83.1,414.8,82.6,414.7,81.9z M419,78.1c0-0.6-0.2-1.1-0.5-1.4  s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.6s-0.5,0.9-0.5,1.5c0,0.5,0.2,1,0.5,1.3s0.7,0.5,1.2,0.5c0.5,0,0.9-0.2,1.2-0.5  S419,78.7,419,78.1z"/>
<path d="M426.7,82.9v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1c0.3-0.4,0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8  s0.5-0.9,0.5-1.3c0-0.4-0.1-0.8-0.4-1.1s-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5s-0.5,0.7-0.5,1.3l-1.1-0.1  c0.1-0.8,0.4-1.4,0.8-1.8c0.5-0.4,1.1-0.6,2-0.6c0.8,0,1.5,0.2,2,0.7s0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1s-0.4,0.7-0.7,1  s-0.9,0.9-1.6,1.5c-0.6,0.5-1,0.9-1.2,1.1s-0.3,0.4-0.4,0.6H426.7z"/>
<path d="M432.2,83.9v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6v-3.1h1v8.6H432.2z M428.9,80.8  c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6S428.9,79.9,428.9,80.8z"/>
<path d="M440,77.4l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  s-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9s0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8s0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5s-0.6,0.8-1,1.1  S438,84,437.5,84c-0.9,0-1.6-0.3-2.2-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6c0.5-0.7,1.3-1,2.2-1c0.7,0,1.2,0.2,1.7,0.6  S439.9,76.7,440,77.4z M435.7,81.1c0,0.4,0.1,0.7,0.2,1s0.4,0.6,0.6,0.8s0.6,0.3,0.9,0.3c0.4,0,0.8-0.2,1.1-0.5s0.5-0.8,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.5S435.7,80.5,435.7,81.1z"/>
<path d="M446.8,82.9v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1c0.3-0.4,0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8  s0.5-0.9,0.5-1.3c0-0.4-0.1-0.8-0.4-1.1s-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5s-0.5,0.7-0.5,1.3l-1.1-0.1  c0.1-0.8,0.4-1.4,0.8-1.8c0.5-0.4,1.1-0.6,2-0.6c0.8,0,1.5,0.2,2,0.7s0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1s-0.4,0.7-0.7,1  s-0.9,0.9-1.6,1.5c-0.6,0.5-1,0.9-1.2,1.1s-0.3,0.4-0.4,0.6H446.8z"/>
<path d="M447.9,79.6c0-1,0.1-1.8,0.3-2.5s0.5-1.1,0.9-1.4s0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3s0.6,0.5,0.9,0.8s0.4,0.8,0.5,1.3  s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9C448.2,82.4,447.9,81.3,447.9,79.6z   M449,79.6c0,1.4,0.2,2.3,0.5,2.8s0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7s0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8s-0.7-0.7-1.2-0.7  c-0.5,0-0.9,0.2-1.2,0.6C449.2,77.3,449,78.2,449,79.6z"/>
<path d="M407,91.8l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H407z M408.9,91.8l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H408.9z"/>
<path d="M411.2,97.4v-8.6h1.1v4.9l2.5-2.5h1.4l-2.4,2.3l2.6,3.9H415l-2.1-3.2l-0.7,0.7v2.5H411.2z"/>
<path d="M417.2,97.4v-6.2h0.9V92c0.5-0.7,1.1-1,2-1c0.4,0,0.7,0.1,1,0.2s0.5,0.3,0.7,0.5s0.3,0.5,0.3,0.8c0,0.2,0.1,0.5,0.1,1v3.8  h-1.1v-3.8c0-0.4,0-0.8-0.1-1s-0.2-0.4-0.4-0.5s-0.5-0.2-0.7-0.2c-0.4,0-0.8,0.1-1.2,0.4s-0.5,0.8-0.5,1.6v3.4H417.2z"/>
<path d="M423.4,94.3c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8s0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  s-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8C423.7,96.1,423.4,95.3,423.4,94.3z M424.5,94.3c0,0.8,0.2,1.4,0.5,1.8  s0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7s-0.8-0.6-1.3-0.6c-0.5,0-1,0.2-1.3,0.6  S424.5,93.5,424.5,94.3z"/>
<path d="M431.7,97.4l-1.9-6.2h1.1l1,3.6l0.4,1.3c0-0.1,0.1-0.5,0.3-1.3l1-3.6h1.1l0.9,3.6l0.3,1.2l0.4-1.2l1.1-3.6h1l-1.9,6.2h-1.1  l-1-3.7l-0.2-1.1l-1.3,4.8H431.7z"/>
<path d="M438.7,95.5l1-0.2c0.1,0.4,0.2,0.7,0.5,1s0.6,0.3,1.1,0.3c0.5,0,0.8-0.1,1.1-0.3s0.4-0.4,0.4-0.7c0-0.2-0.1-0.4-0.3-0.6  c-0.1-0.1-0.5-0.2-1.1-0.4c-0.8-0.2-1.3-0.4-1.6-0.5c-0.3-0.1-0.5-0.3-0.7-0.6s-0.2-0.5-0.2-0.8c0-0.3,0.1-0.5,0.2-0.8  s0.3-0.4,0.5-0.6c0.2-0.1,0.4-0.2,0.7-0.3s0.6-0.1,0.9-0.1c0.5,0,0.9,0.1,1.3,0.2c0.4,0.1,0.6,0.3,0.8,0.6s0.3,0.6,0.4,1l-1,0.1  c0-0.3-0.2-0.6-0.4-0.8c-0.2-0.2-0.5-0.3-1-0.3c-0.5,0-0.8,0.1-1,0.2s-0.3,0.3-0.3,0.6c0,0.1,0,0.3,0.1,0.4c0.1,0.1,0.2,0.2,0.4,0.3  c0.1,0,0.4,0.1,0.9,0.3c0.7,0.2,1.3,0.4,1.6,0.5s0.5,0.3,0.7,0.6s0.3,0.5,0.3,0.9c0,0.4-0.1,0.7-0.3,1s-0.5,0.6-0.9,0.7  s-0.8,0.3-1.3,0.3c-0.8,0-1.4-0.2-1.8-0.5C439.1,96.7,438.9,96.2,438.7,95.5z"/>
<path d="M445.2,91.8l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H445.2z M447.2,91.8l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H447.2z"/>
<rect x="362.5" y="73.4" fill-rule="evenodd" fill="none" width="129.7" height="27"/>
<rect x="351.6" y="145.4" fill="none" stroke="#000000" stroke-width="2.2496" width="151.5" height="42"/>
<path d="M409,163.4v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6v-3.1h1v8.6H409z M405.6,160.3c0,0.8,0.2,1.4,0.5,1.8  s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  S405.6,159.4,405.6,160.3z"/>
<path d="M411.3,161.1l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2s0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6s0.5-0.9,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4s-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2s-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4l-0.5,2.3  c0.5-0.4,1.1-0.5,1.6-0.5c0.7,0,1.4,0.3,1.9,0.8s0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1c-0.8,0-1.4-0.2-1.9-0.7  C411.7,162.4,411.4,161.8,411.3,161.1z"/>
<path d="M422.3,162.6c-0.4,0.3-0.8,0.6-1.1,0.7c-0.4,0.1-0.7,0.2-1.2,0.2c-0.7,0-1.2-0.2-1.6-0.5c-0.4-0.3-0.6-0.8-0.6-1.3  c0-0.3,0.1-0.6,0.2-0.8s0.3-0.5,0.5-0.6c0.2-0.2,0.5-0.3,0.8-0.3c0.2-0.1,0.5-0.1,0.9-0.2c0.9-0.1,1.5-0.2,1.9-0.4  c0-0.1,0-0.2,0-0.3c0-0.4-0.1-0.7-0.3-0.9c-0.3-0.2-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.1-1.1,0.3s-0.4,0.5-0.5,0.9l-1-0.1  c0.1-0.4,0.2-0.8,0.5-1.1c0.2-0.3,0.5-0.5,0.9-0.6s0.9-0.2,1.4-0.2c0.5,0,1,0.1,1.3,0.2s0.6,0.3,0.7,0.5s0.3,0.4,0.3,0.7  c0,0.2,0.1,0.5,0.1,1v1.4c0,1,0,1.6,0.1,1.9s0.1,0.5,0.3,0.7h-1.1C422.4,163.2,422.4,162.9,422.3,162.6z M422.2,160.3  c-0.4,0.2-1,0.3-1.7,0.4c-0.4,0.1-0.7,0.1-0.9,0.2s-0.3,0.2-0.4,0.3s-0.1,0.3-0.1,0.5c0,0.3,0.1,0.5,0.3,0.7s0.5,0.3,0.9,0.3  c0.4,0,0.8-0.1,1.1-0.3c0.3-0.2,0.5-0.4,0.7-0.7c0.1-0.2,0.2-0.6,0.2-1.1V160.3z"/>
<path d="M424.7,161.1l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3s0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5s0.5-0.8,0.5-1.3c0-0.5-0.2-0.9-0.5-1.2  s-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1l0.1-0.9c0.1,0,0.1,0,0.2,0c0.4,0,0.9-0.1,1.2-0.4s0.5-0.6,0.5-1.1c0-0.4-0.1-0.7-0.4-1  s-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4s-0.4,0.6-0.5,1.2l-1.1-0.2c0.1-0.7,0.4-1.3,0.9-1.6c0.5-0.4,1-0.6,1.7-0.6  c0.5,0,0.9,0.1,1.3,0.3s0.7,0.5,0.9,0.8s0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-0.9,0.7c0.5,0.1,0.9,0.4,1.2,0.7  s0.4,0.8,0.4,1.4c0,0.8-0.3,1.4-0.8,1.9s-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7C425,162.4,424.7,161.8,424.7,161.1z"/>
<path d="M431.4,155.9v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  s0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H431.4z"/>
<path d="M438,161.1l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2s0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6s0.5-0.9,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4  s-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2s-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4l-0.5,2.3c0.5-0.4,1.1-0.5,1.6-0.5  c0.7,0,1.4,0.3,1.9,0.8s0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1c-0.8,0-1.4-0.2-1.9-0.7  C438.4,162.4,438.1,161.8,438,161.1z"/>
<path d="M445.2,163.4V158h-0.9v-0.8h0.9v-0.7c0-0.4,0-0.7,0.1-0.9c0.1-0.3,0.3-0.5,0.5-0.7s0.6-0.3,1.1-0.3c0.3,0,0.6,0,1,0.1  l-0.2,0.9c-0.2,0-0.4-0.1-0.6-0.1c-0.3,0-0.5,0.1-0.7,0.2s-0.2,0.4-0.2,0.8v0.6h1.2v0.8h-1.2v5.4H445.2z"/>
<path d="M448.3,163.4V158h-0.9v-0.8h0.9v-0.7c0-0.4,0-0.7,0.1-0.9c0.1-0.3,0.3-0.5,0.5-0.7s0.6-0.3,1.1-0.3c0.3,0,0.6,0,1,0.1  l-0.2,0.9c-0.2,0-0.4-0.1-0.6-0.1c-0.3,0-0.5,0.1-0.7,0.2s-0.2,0.4-0.2,0.8v0.6h1.2v0.8h-1.2v5.4H448.3z"/>
<path d="M403.6,171.3l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H403.6z M405.6,171.3l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H405.6z"/>
<path d="M408,176.9v-8.6h6.2v1h-5.1v2.6h4.8v1h-4.8v2.9h5.3v1H408z"/>
<path d="M419.9,176.9v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6v-3.1h1v8.6H419.9z M416.5,173.8  c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6S416.5,172.9,416.5,173.8z"/>
<path d="M423.7,176.9l-1.9-6.2h1.1l1,3.6l0.4,1.3c0-0.1,0.1-0.5,0.3-1.3l1-3.6h1.1l0.9,3.6l0.3,1.2l0.4-1.2l1.1-3.6h1l-1.9,6.2h-1.1  l-1-3.7l-0.2-1.1l-1.3,4.8H423.7z"/>
<path d="M435.2,176.1c-0.4,0.3-0.8,0.6-1.1,0.7c-0.4,0.1-0.7,0.2-1.2,0.2c-0.7,0-1.2-0.2-1.6-0.5c-0.4-0.3-0.6-0.8-0.6-1.3  c0-0.3,0.1-0.6,0.2-0.8s0.3-0.5,0.5-0.6c0.2-0.2,0.5-0.3,0.8-0.3c0.2-0.1,0.5-0.1,0.9-0.2c0.9-0.1,1.5-0.2,1.9-0.4  c0-0.1,0-0.2,0-0.3c0-0.4-0.1-0.7-0.3-0.9c-0.3-0.2-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.1-1.1,0.3s-0.4,0.5-0.5,0.9l-1-0.1  c0.1-0.4,0.2-0.8,0.5-1.1c0.2-0.3,0.5-0.5,0.9-0.6s0.9-0.2,1.4-0.2c0.5,0,1,0.1,1.3,0.2s0.6,0.3,0.7,0.5s0.3,0.4,0.3,0.7  c0,0.2,0.1,0.5,0.1,1v1.4c0,1,0,1.6,0.1,1.9s0.1,0.5,0.3,0.7h-1.1C435.3,176.7,435.3,176.4,435.2,176.1z M435.1,173.8  c-0.4,0.2-1,0.3-1.7,0.4c-0.4,0.1-0.7,0.1-0.9,0.2s-0.3,0.2-0.4,0.3s-0.1,0.3-0.1,0.5c0,0.3,0.1,0.5,0.3,0.7s0.5,0.3,0.9,0.3  c0.4,0,0.8-0.1,1.1-0.3c0.3-0.2,0.5-0.4,0.7-0.7c0.1-0.2,0.2-0.6,0.2-1.1V173.8z"/>
<path d="M437.8,176.9v-6.2h0.9v0.9c0.2-0.4,0.5-0.7,0.7-0.9s0.4-0.2,0.7-0.2c0.4,0,0.7,0.1,1.1,0.3l-0.4,1c-0.3-0.2-0.5-0.2-0.8-0.2  c-0.2,0-0.4,0.1-0.6,0.2s-0.3,0.3-0.4,0.6c-0.1,0.4-0.2,0.8-0.2,1.2v3.3H437.8z"/>
<path d="M445.9,176.9v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6v-3.1h1v8.6H445.9z M442.5,173.8  c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6S442.5,172.9,442.5,173.8z"/>
<path d="M448.6,171.3l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H448.6z M450.5,171.3l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H450.5z"/>
<rect x="359.1" y="152.9" fill-rule="evenodd" fill="none" width="136.4" height="27"/>
<path fill="none" stroke="#000000" stroke-width="2.2496" d="M195.4,264.6H248c0.7,0,1.4,0,2.1,0.1c0.7,0.1,1.4,0.2,2,0.3  c0.7,0.1,1.3,0.3,2,0.5c0.7,0.2,1.3,0.4,1.9,0.7c0.6,0.3,1.3,0.6,1.9,0.9c0.6,0.3,1.2,0.7,1.8,1.1c0.6,0.4,1.1,0.8,1.7,1.2  s1,0.9,1.5,1.4s0.9,1,1.4,1.5s0.8,1.1,1.2,1.7c0.4,0.6,0.7,1.2,1.1,1.8s0.6,1.2,0.9,1.9c0.3,0.6,0.5,1.3,0.7,1.9  c0.2,0.7,0.4,1.3,0.5,2s0.2,1.4,0.3,2s0.1,1.4,0.1,2.1s0,1.4-0.1,2.1c-0.1,0.7-0.2,1.4-0.3,2s-0.3,1.3-0.5,2  c-0.2,0.7-0.4,1.3-0.7,1.9c-0.3,0.6-0.6,1.3-0.9,1.9c-0.3,0.6-0.7,1.2-1.1,1.8c-0.4,0.6-0.8,1.1-1.2,1.7c-0.4,0.5-0.9,1-1.4,1.5  s-1,0.9-1.5,1.4s-1.1,0.8-1.7,1.2c-0.6,0.4-1.2,0.7-1.8,1.1c-0.6,0.3-1.2,0.6-1.9,0.9c-0.6,0.3-1.3,0.5-1.9,0.7  c-0.7,0.2-1.3,0.4-2,0.5c-0.7,0.1-1.4,0.2-2,0.3s-1.4,0.1-2.1,0.1h-52.6c-0.7,0-1.4,0-2.1-0.1s-1.4-0.2-2-0.3  c-0.7-0.1-1.3-0.3-2-0.5c-0.7-0.2-1.3-0.4-1.9-0.7c-0.6-0.3-1.3-0.6-1.9-0.9c-0.6-0.3-1.2-0.7-1.8-1.1c-0.6-0.4-1.1-0.8-1.7-1.2  c-0.5-0.4-1-0.9-1.5-1.4s-0.9-1-1.4-1.5c-0.4-0.5-0.8-1.1-1.2-1.7c-0.4-0.6-0.7-1.2-1.1-1.8s-0.6-1.2-0.9-1.9  c-0.3-0.6-0.5-1.3-0.7-1.9c-0.2-0.7-0.4-1.3-0.5-2s-0.2-1.4-0.3-2s-0.1-1.4-0.1-2.1s0-1.4,0.1-2.1c0.1-0.7,0.2-1.4,0.3-2  s0.3-1.3,0.5-2c0.2-0.7,0.4-1.3,0.7-1.9c0.3-0.6,0.6-1.3,0.9-1.9c0.3-0.6,0.7-1.2,1.1-1.8c0.4-0.6,0.8-1.1,1.2-1.7s0.9-1,1.4-1.5  s1-0.9,1.5-1.4c0.5-0.4,1.1-0.8,1.7-1.2c0.6-0.4,1.2-0.7,1.8-1.1c0.6-0.3,1.2-0.6,1.9-0.9c0.6-0.3,1.3-0.5,1.9-0.7  c0.7-0.2,1.3-0.4,2-0.5c0.7-0.1,1.4-0.2,2-0.3C194.1,264.7,194.7,264.6,195.4,264.6z"/>
<path d="M197.2,280.4l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2c0.3,0.3,0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6c0.4-0.4,0.5-0.9,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.3-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2s-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4l-0.5,2.3  c0.5-0.4,1.1-0.5,1.6-0.5c0.8,0,1.4,0.3,1.9,0.8c0.5,0.5,0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1  c-0.8,0-1.4-0.2-1.9-0.7C197.6,281.7,197.3,281.1,197.2,280.4z"/>
<path d="M203.9,280.4l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2c0.3,0.3,0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6c0.4-0.4,0.5-0.9,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.3-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2s-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4l-0.5,2.3  c0.5-0.4,1.1-0.5,1.6-0.5c0.8,0,1.4,0.3,1.9,0.8c0.5,0.5,0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1  c-0.8,0-1.4-0.2-1.9-0.7C204.2,281.7,204,281.1,203.9,280.4z"/>
<path d="M210.6,280.4l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2c0.3,0.3,0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6c0.4-0.4,0.5-0.9,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.3-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2s-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4l-0.5,2.3  c0.5-0.4,1.1-0.5,1.6-0.5c0.8,0,1.4,0.3,1.9,0.8c0.5,0.5,0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1  c-0.8,0-1.4-0.2-1.9-0.7C210.9,281.7,210.6,281.1,210.6,280.4z"/>
<path d="M222.7,276.1l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  c-0.2,0.5-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9s0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8c0.5,0.5,0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5  c-0.2,0.5-0.6,0.8-1,1.1s-0.9,0.4-1.4,0.4c-0.9,0-1.6-0.3-2.1-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6  c0.5-0.7,1.3-1,2.2-1c0.7,0,1.2,0.2,1.7,0.6C222.4,274.9,222.6,275.5,222.7,276.1z M218.4,279.8c0,0.4,0.1,0.7,0.2,1  c0.2,0.3,0.4,0.6,0.6,0.8s0.6,0.3,0.9,0.3c0.4,0,0.8-0.2,1.1-0.5c0.3-0.4,0.5-0.8,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4  c-0.3-0.3-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.5C218.6,278.8,218.4,279.3,218.4,279.8z"/>
<path d="M223.9,278.4c0-1,0.1-1.8,0.3-2.5s0.5-1.1,0.9-1.4c0.4-0.3,0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3c0.3,0.2,0.6,0.5,0.9,0.8  c0.2,0.3,0.4,0.8,0.5,1.3s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9  C224.2,281.2,223.9,280,223.9,278.4z M225,278.4c0,1.4,0.2,2.3,0.5,2.8c0.3,0.5,0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7  c0.3-0.5,0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8c-0.3-0.5-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C225.2,276,225,277,225,278.4z"/>
<path d="M231.8,282.6h-1V274h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2c0.3,0.2,0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5c-0.5,0.6-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V282.6z M231.8,279.5  c0,0.7,0.1,1.3,0.3,1.6c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8  c-0.3-0.4-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6S231.8,278.7,231.8,279.5z"/>
<path d="M241.6,282.6v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4c-0.4-0.3-0.7-0.7-1-1.1c-0.2-0.5-0.3-1.1-0.3-1.7  c0-0.6,0.1-1.2,0.3-1.7s0.5-0.9,0.9-1.2c0.4-0.3,0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6V274h1v8.6H241.6z   M238.2,279.5c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9  c-0.3-0.4-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6C238.4,278.1,238.2,278.7,238.2,279.5z"/>
<path d="M244.5,282.6v-5.4h-0.9v-0.8h0.9v-0.7c0-0.4,0-0.7,0.1-0.9c0.1-0.3,0.3-0.5,0.5-0.7c0.3-0.2,0.6-0.3,1.1-0.3  c0.3,0,0.6,0,1,0.1l-0.2,0.9c-0.2,0-0.4-0.1-0.6-0.1c-0.3,0-0.5,0.1-0.7,0.2s-0.2,0.4-0.2,0.8v0.6h1.2v0.8h-1.2v5.4H244.5z"/>
<path d="M187.2,296.1l3.3-8.6h1.2l3.5,8.6h-1.3l-1-2.6h-3.6l-0.9,2.6H187.2z M189.6,292.6h2.9l-0.9-2.4c-0.3-0.7-0.5-1.3-0.6-1.8  c-0.1,0.6-0.3,1.1-0.5,1.6L189.6,292.6z"/>
<path d="M195.7,293.4l1.1-0.1c0.1,0.4,0.2,0.8,0.4,1.1c0.2,0.3,0.5,0.5,0.9,0.7c0.4,0.2,0.8,0.3,1.3,0.3c0.4,0,0.8-0.1,1.1-0.2  c0.3-0.1,0.6-0.3,0.7-0.5s0.2-0.5,0.2-0.7c0-0.3-0.1-0.5-0.2-0.7s-0.4-0.4-0.8-0.5c-0.2-0.1-0.7-0.2-1.5-0.4s-1.3-0.4-1.7-0.5  c-0.4-0.2-0.7-0.5-0.9-0.8s-0.3-0.7-0.3-1.1c0-0.4,0.1-0.8,0.4-1.2s0.6-0.7,1.1-0.9s1-0.3,1.6-0.3c0.6,0,1.2,0.1,1.7,0.3  c0.5,0.2,0.9,0.5,1.1,0.9c0.3,0.4,0.4,0.8,0.4,1.4l-1.1,0.1c-0.1-0.5-0.3-1-0.6-1.2c-0.3-0.3-0.8-0.4-1.5-0.4  c-0.7,0-1.2,0.1-1.5,0.4s-0.5,0.6-0.5,0.9c0,0.3,0.1,0.6,0.3,0.8c0.2,0.2,0.8,0.4,1.7,0.6s1.6,0.4,1.9,0.5c0.5,0.2,0.9,0.5,1.1,0.9  c0.2,0.4,0.4,0.8,0.4,1.2c0,0.5-0.1,0.9-0.4,1.3c-0.3,0.4-0.6,0.7-1.1,0.9c-0.5,0.2-1,0.3-1.7,0.3c-0.8,0-1.4-0.1-2-0.3  c-0.5-0.2-0.9-0.6-1.2-1S195.7,293.9,195.7,293.4z"/>
<path d="M203.7,293.4l1.1-0.1c0.1,0.4,0.2,0.8,0.4,1.1c0.2,0.3,0.5,0.5,0.9,0.7c0.4,0.2,0.8,0.3,1.3,0.3c0.4,0,0.8-0.1,1.1-0.2  c0.3-0.1,0.6-0.3,0.7-0.5s0.2-0.5,0.2-0.7c0-0.3-0.1-0.5-0.2-0.7s-0.4-0.4-0.8-0.5c-0.2-0.1-0.7-0.2-1.5-0.4s-1.3-0.4-1.7-0.5  c-0.4-0.2-0.7-0.5-0.9-0.8s-0.3-0.7-0.3-1.1c0-0.4,0.1-0.8,0.4-1.2s0.6-0.7,1.1-0.9s1-0.3,1.6-0.3c0.6,0,1.2,0.1,1.7,0.3  c0.5,0.2,0.9,0.5,1.1,0.9c0.3,0.4,0.4,0.8,0.4,1.4l-1.1,0.1c-0.1-0.5-0.3-1-0.6-1.2c-0.3-0.3-0.8-0.4-1.5-0.4  c-0.7,0-1.2,0.1-1.5,0.4s-0.5,0.6-0.5,0.9c0,0.3,0.1,0.6,0.3,0.8c0.2,0.2,0.8,0.4,1.7,0.6s1.6,0.4,1.9,0.5c0.5,0.2,0.9,0.5,1.1,0.9  c0.2,0.4,0.4,0.8,0.4,1.2c0,0.5-0.1,0.9-0.4,1.3c-0.3,0.4-0.6,0.7-1.1,0.9c-0.5,0.2-1,0.3-1.7,0.3c-0.8,0-1.4-0.1-2-0.3  c-0.5-0.2-0.9-0.6-1.2-1S203.7,293.9,203.7,293.4z"/>
<path d="M212.1,296.1v-8.6h6.2v1h-5.1v2.6h4.8v1h-4.8v2.9h5.3v1H212.1z"/>
<path d="M220.1,296.1v-8.6h3.8c0.8,0,1.3,0.1,1.7,0.2s0.7,0.4,1,0.8s0.4,0.8,0.4,1.3c0,0.6-0.2,1.1-0.6,1.5c-0.4,0.4-1,0.7-1.8,0.8  c0.3,0.1,0.5,0.3,0.7,0.4c0.3,0.3,0.6,0.7,0.9,1.1l1.5,2.3h-1.4l-1.1-1.8c-0.3-0.5-0.6-0.9-0.8-1.2s-0.4-0.5-0.6-0.6  c-0.2-0.1-0.3-0.2-0.5-0.2c-0.1,0-0.3,0-0.6,0h-1.3v3.8H220.1z M221.3,291.3h2.4c0.5,0,0.9-0.1,1.2-0.2c0.3-0.1,0.5-0.3,0.7-0.5  s0.2-0.5,0.2-0.8c0-0.4-0.1-0.7-0.4-1s-0.8-0.4-1.4-0.4h-2.7V291.3z"/>
<path d="M230.7,296.1v-7.6h-2.8v-1h6.8v1h-2.8v7.6H230.7z"/>
<path d="M236.1,296.1v-8.6h1.1v8.6H236.1z"/>
<path d="M238.9,291.9c0-1.4,0.4-2.5,1.1-3.3c0.8-0.8,1.8-1.2,3-1.2c0.8,0,1.5,0.2,2.1,0.6c0.6,0.4,1.1,0.9,1.5,1.6  c0.3,0.7,0.5,1.4,0.5,2.3c0,0.9-0.2,1.7-0.5,2.3c-0.4,0.7-0.8,1.2-1.5,1.6c-0.6,0.4-1.3,0.5-2.1,0.5c-0.8,0-1.5-0.2-2.2-0.6  c-0.6-0.4-1.1-0.9-1.4-1.6S238.9,292.7,238.9,291.9z M240,292c0,1,0.3,1.9,0.8,2.4s1.3,0.9,2.1,0.9c0.9,0,1.6-0.3,2.1-0.9  c0.6-0.6,0.8-1.5,0.8-2.6c0-0.7-0.1-1.3-0.4-1.8s-0.6-0.9-1-1.2s-1-0.4-1.5-0.4c-0.8,0-1.5,0.3-2.1,0.8  C240.3,289.7,240,290.7,240,292z"/>
<path d="M248.5,296.1v-8.6h1.2l4.5,6.7v-6.7h1.1v8.6h-1.2l-4.5-6.8v6.8H248.5z"/>
<rect x="187.2" y="272.1" fill-rule="evenodd" fill="none" width="69" height="27"/>
<rect x="355" y="224.9" fill="none" stroke="#000000" stroke-width="2.2496" width="144.8" height="42"/>
<path d="M401.3,235.4v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  s0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H401.3z"/>
<path d="M407.9,238.6c0-1,0.1-1.8,0.3-2.5s0.5-1.1,0.9-1.4s0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3s0.6,0.5,0.9,0.8s0.4,0.8,0.5,1.3  s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9C408.1,241.4,407.9,240.3,407.9,238.6z   M408.9,238.6c0,1.4,0.2,2.3,0.5,2.8s0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7s0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8  s-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C409.1,236.3,408.9,237.2,408.9,238.6z"/>
<path d="M414.7,240.9l1-0.1c0.1,0.5,0.2,0.8,0.5,1s0.6,0.3,0.9,0.3c0.3,0,0.6-0.1,0.9-0.2c0.2-0.1,0.4-0.3,0.6-0.6s0.3-0.6,0.4-1  s0.2-0.9,0.2-1.3c0,0,0-0.1,0-0.2c-0.2,0.3-0.5,0.6-0.9,0.8s-0.8,0.3-1.2,0.3c-0.7,0-1.3-0.3-1.8-0.8c-0.5-0.5-0.7-1.2-0.7-2  c0-0.9,0.3-1.6,0.8-2.1c0.5-0.5,1.2-0.8,1.9-0.8c0.6,0,1.1,0.2,1.5,0.5s0.8,0.7,1.1,1.3s0.4,1.4,0.4,2.4c0,1.1-0.1,2-0.4,2.6  s-0.6,1.1-1.1,1.5s-1,0.5-1.7,0.5c-0.7,0-1.2-0.2-1.6-0.6C415,242.1,414.8,241.6,414.7,240.9z M419,237.1c0-0.6-0.2-1.1-0.5-1.4  s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.6s-0.5,0.9-0.5,1.5c0,0.5,0.2,1,0.5,1.3s0.7,0.5,1.2,0.5c0.5,0,0.9-0.2,1.2-0.5  S419,237.7,419,237.1z"/>
<path d="M426.7,241.9v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1c0.3-0.4,0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8  s0.5-0.9,0.5-1.3c0-0.4-0.1-0.8-0.4-1.1s-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5s-0.5,0.7-0.5,1.3l-1.1-0.1  c0.1-0.8,0.4-1.4,0.8-1.8c0.5-0.4,1.1-0.6,2-0.6c0.8,0,1.5,0.2,2,0.7s0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1s-0.4,0.7-0.7,1  s-0.9,0.9-1.6,1.5c-0.6,0.5-1,0.9-1.2,1.1s-0.3,0.4-0.4,0.6H426.7z"/>
<path d="M432.2,242.9v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6v-3.1h1v8.6H432.2z M428.9,239.8  c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6S428.9,238.9,428.9,239.8z"/>
<path d="M440,236.4l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  s-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9s0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8s0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5s-0.6,0.8-1,1.1  s-0.9,0.4-1.4,0.4c-0.9,0-1.6-0.3-2.2-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6c0.5-0.7,1.3-1,2.2-1c0.7,0,1.2,0.2,1.7,0.6  S439.9,235.7,440,236.4z M435.7,240.1c0,0.4,0.1,0.7,0.2,1s0.4,0.6,0.6,0.8s0.6,0.3,0.9,0.3c0.4,0,0.8-0.2,1.1-0.5s0.5-0.8,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.5S435.7,239.5,435.7,240.1z"/>
<path d="M446.8,241.9v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1c0.3-0.4,0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8  s0.5-0.9,0.5-1.3c0-0.4-0.1-0.8-0.4-1.1s-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5s-0.5,0.7-0.5,1.3l-1.1-0.1  c0.1-0.8,0.4-1.4,0.8-1.8c0.5-0.4,1.1-0.6,2-0.6c0.8,0,1.5,0.2,2,0.7s0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1s-0.4,0.7-0.7,1  s-0.9,0.9-1.6,1.5c-0.6,0.5-1,0.9-1.2,1.1s-0.3,0.4-0.4,0.6H446.8z"/>
<path d="M447.9,238.6c0-1,0.1-1.8,0.3-2.5s0.5-1.1,0.9-1.4s0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3s0.6,0.5,0.9,0.8s0.4,0.8,0.5,1.3  s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9C448.2,241.4,447.9,240.3,447.9,238.6z   M449,238.6c0,1.4,0.2,2.3,0.5,2.8s0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7s0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8s-0.7-0.7-1.2-0.7  c-0.5,0-0.9,0.2-1.2,0.6C449.2,236.3,449,237.2,449,238.6z"/>
<path d="M407,250.8l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H407z M408.9,250.8l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H408.9z"/>
<path d="M411.2,256.4v-8.6h1.1v4.9l2.5-2.5h1.4l-2.4,2.3l2.6,3.9H415l-2.1-3.2l-0.7,0.7v2.5H411.2z"/>
<path d="M417.2,256.4v-6.2h0.9v0.9c0.5-0.7,1.1-1,2-1c0.4,0,0.7,0.1,1,0.2s0.5,0.3,0.7,0.5s0.3,0.5,0.3,0.8c0,0.2,0.1,0.5,0.1,1v3.8  h-1.1v-3.8c0-0.4,0-0.8-0.1-1s-0.2-0.4-0.4-0.5s-0.5-0.2-0.7-0.2c-0.4,0-0.8,0.1-1.2,0.4s-0.5,0.8-0.5,1.6v3.4H417.2z"/>
<path d="M423.4,253.3c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8s0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  s-0.6,0.8-1,1.1c-0.5,0.3-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8C423.7,255.1,423.4,254.3,423.4,253.3z M424.5,253.3  c0,0.8,0.2,1.4,0.5,1.8s0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7s-0.8-0.6-1.3-0.6  c-0.5,0-1,0.2-1.3,0.6S424.5,252.5,424.5,253.3z"/>
<path d="M431.7,256.4l-1.9-6.2h1.1l1,3.6l0.4,1.3c0-0.1,0.1-0.5,0.3-1.3l1-3.6h1.1l0.9,3.6l0.3,1.2l0.4-1.2l1.1-3.6h1l-1.9,6.2h-1.1  l-1-3.7l-0.2-1.1l-1.3,4.8H431.7z"/>
<path d="M438.7,254.5l1-0.2c0.1,0.4,0.2,0.7,0.5,1s0.6,0.3,1.1,0.3c0.5,0,0.8-0.1,1.1-0.3s0.4-0.4,0.4-0.7c0-0.2-0.1-0.4-0.3-0.6  c-0.1-0.1-0.5-0.2-1.1-0.4c-0.8-0.2-1.3-0.4-1.6-0.5c-0.3-0.1-0.5-0.3-0.7-0.6s-0.2-0.5-0.2-0.8c0-0.3,0.1-0.5,0.2-0.8  s0.3-0.4,0.5-0.6c0.2-0.1,0.4-0.2,0.7-0.3s0.6-0.1,0.9-0.1c0.5,0,0.9,0.1,1.3,0.2c0.4,0.1,0.6,0.3,0.8,0.6s0.3,0.6,0.4,1l-1,0.1  c0-0.3-0.2-0.6-0.4-0.8c-0.2-0.2-0.5-0.3-1-0.3c-0.5,0-0.8,0.1-1,0.2s-0.3,0.3-0.3,0.6c0,0.1,0,0.3,0.1,0.4c0.1,0.1,0.2,0.2,0.4,0.3  c0.1,0,0.4,0.1,0.9,0.3c0.7,0.2,1.3,0.4,1.6,0.5s0.5,0.3,0.7,0.6s0.3,0.5,0.3,0.9c0,0.4-0.1,0.7-0.3,1s-0.5,0.6-0.9,0.7  s-0.8,0.3-1.3,0.3c-0.8,0-1.4-0.2-1.8-0.5C439.1,255.7,438.9,255.2,438.7,254.5z"/>
<path d="M445.2,250.8l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H445.2z M447.2,250.8l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H447.2z"/>
<rect x="362.5" y="232.4" fill-rule="evenodd" fill="none" width="129.7" height="27"/>
<rect x="361.3" y="304.4" fill="none" stroke="#000000" stroke-width="2.2496" width="132.2" height="42"/>
<path d="M401.4,320.4l1-0.1c0.1,0.5,0.2,0.8,0.5,1s0.6,0.3,0.9,0.3c0.3,0,0.6-0.1,0.9-0.2c0.2-0.1,0.4-0.3,0.6-0.6s0.3-0.6,0.4-1  s0.2-0.9,0.2-1.3c0,0,0-0.1,0-0.2c-0.2,0.3-0.5,0.6-0.9,0.8s-0.8,0.3-1.2,0.3c-0.7,0-1.3-0.3-1.8-0.8c-0.5-0.5-0.7-1.2-0.7-2  c0-0.9,0.3-1.6,0.8-2.1c0.5-0.5,1.2-0.8,1.9-0.8c0.6,0,1.1,0.2,1.5,0.5s0.8,0.7,1.1,1.3s0.4,1.4,0.4,2.4c0,1.1-0.1,2-0.4,2.6  s-0.6,1.1-1.1,1.5s-1,0.5-1.7,0.5c-0.7,0-1.2-0.2-1.6-0.6C401.7,321.6,401.4,321.1,401.4,320.4z M405.7,316.6c0-0.6-0.2-1.1-0.5-1.4  s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.6s-0.5,0.9-0.5,1.5c0,0.5,0.2,1,0.5,1.3s0.7,0.5,1.2,0.5c0.5,0,0.9-0.2,1.2-0.5  S405.7,317.2,405.7,316.6z"/>
<path d="M412.2,321.6c-0.4,0.3-0.8,0.6-1.1,0.7c-0.4,0.1-0.7,0.2-1.2,0.2c-0.7,0-1.2-0.2-1.6-0.5c-0.4-0.3-0.6-0.8-0.6-1.3  c0-0.3,0.1-0.6,0.2-0.8s0.3-0.5,0.5-0.6c0.2-0.2,0.5-0.3,0.8-0.3c0.2-0.1,0.5-0.1,0.9-0.2c0.9-0.1,1.5-0.2,1.9-0.4  c0-0.1,0-0.2,0-0.3c0-0.4-0.1-0.7-0.3-0.9c-0.3-0.2-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.1-1.1,0.3s-0.4,0.5-0.5,0.9l-1-0.1  c0.1-0.4,0.2-0.8,0.5-1.1c0.2-0.3,0.5-0.5,0.9-0.6s0.9-0.2,1.4-0.2c0.5,0,1,0.1,1.3,0.2s0.6,0.3,0.7,0.5s0.3,0.4,0.3,0.7  c0,0.2,0.1,0.5,0.1,1v1.4c0,1,0,1.6,0.1,1.9s0.1,0.5,0.3,0.7h-1.1C412.3,322.2,412.3,321.9,412.2,321.6z M412.1,319.3  c-0.4,0.2-1,0.3-1.7,0.4c-0.4,0.1-0.7,0.1-0.9,0.2s-0.3,0.2-0.4,0.3s-0.1,0.3-0.1,0.5c0,0.3,0.1,0.5,0.3,0.7s0.5,0.3,0.9,0.3  c0.4,0,0.8-0.1,1.1-0.3c0.3-0.2,0.5-0.4,0.7-0.7c0.1-0.2,0.2-0.6,0.2-1.1V319.3z"/>
<path d="M414.6,314.9v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  s0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H414.6z"/>
<path d="M421.3,314.9v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  s0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H421.3z"/>
<path d="M431.9,322.4h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1s0.8-0.8,0.9-1.1h0.7V322.4z"/>
<path d="M434.6,314.9v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  s0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H434.6z"/>
<path d="M445.2,322.4h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1s0.8-0.8,0.9-1.1h0.7V322.4z"/>
<path d="M447.9,320.1l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2s0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6s0.5-0.9,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4s-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2s-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4l-0.5,2.3  c0.5-0.4,1.1-0.5,1.6-0.5c0.7,0,1.4,0.3,1.9,0.8s0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1c-0.8,0-1.4-0.2-1.9-0.7  C448.2,321.4,448,320.8,447.9,320.1z"/>
<path d="M413.3,330.3l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H413.3z M415.2,330.3l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H415.2z"/>
<path d="M417.6,335.9v-8.6h3.2c0.7,0,1.2,0.1,1.6,0.3s0.7,0.4,0.9,0.8s0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1s-0.5,0.6-0.9,0.8  c0.5,0.2,0.9,0.4,1.2,0.8s0.4,0.8,0.4,1.3c0,0.4-0.1,0.8-0.3,1.1s-0.4,0.6-0.6,0.8c-0.2,0.2-0.6,0.3-0.9,0.4s-0.8,0.1-1.4,0.1H417.6  z M418.7,330.9h1.9c0.5,0,0.9,0,1.1-0.1c0.3-0.1,0.5-0.2,0.7-0.4s0.2-0.4,0.2-0.8c0-0.3-0.1-0.5-0.2-0.8s-0.3-0.4-0.6-0.4  s-0.7-0.1-1.3-0.1h-1.7V330.9z M418.7,334.9h2.1c0.4,0,0.6,0,0.8,0c0.3,0,0.5-0.1,0.7-0.2s0.3-0.3,0.4-0.5s0.2-0.5,0.2-0.7  c0-0.3-0.1-0.6-0.2-0.8s-0.4-0.4-0.7-0.5s-0.7-0.1-1.3-0.1h-2V334.9z"/>
<path d="M425.1,332.8c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8s0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  s-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8C425.4,334.6,425.1,333.8,425.1,332.8z M426.2,332.8c0,0.8,0.2,1.4,0.5,1.8  s0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7s-0.8-0.6-1.3-0.6c-0.5,0-1,0.2-1.3,0.6  S426.2,332,426.2,332.8z"/>
<path d="M433.1,335.9h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1s0.2,0.8,0.2,1.3  c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V335.9z M433.1,332.7c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  S433.1,332,433.1,332.7z"/>
<path d="M438.9,330.3l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H438.9z M440.8,330.3l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H440.8z"/>
<rect x="368.8" y="311.9" fill-rule="evenodd" fill="none" width="117" height="27"/>
<path fill="none" stroke="#000000" stroke-width="2.2496" d="M195.4,423.6H248c0.7,0,1.4,0,2.1,0.1s1.4,0.2,2,0.3  c0.7,0.1,1.3,0.3,2,0.5c0.7,0.2,1.3,0.4,1.9,0.7c0.6,0.3,1.3,0.6,1.9,0.9c0.6,0.3,1.2,0.7,1.8,1.1c0.6,0.4,1.1,0.8,1.7,1.2  s1,0.9,1.5,1.4s0.9,1,1.4,1.5c0.4,0.5,0.8,1.1,1.2,1.7c0.4,0.6,0.7,1.2,1.1,1.8s0.6,1.2,0.9,1.9c0.3,0.6,0.5,1.3,0.7,1.9  c0.2,0.7,0.4,1.3,0.5,2s0.2,1.4,0.3,2c0.1,0.7,0.1,1.4,0.1,2.1s0,1.4-0.1,2.1c-0.1,0.7-0.2,1.4-0.3,2s-0.3,1.3-0.5,2  c-0.2,0.7-0.4,1.3-0.7,1.9c-0.3,0.6-0.6,1.3-0.9,1.9c-0.3,0.6-0.7,1.2-1.1,1.8c-0.4,0.6-0.8,1.1-1.2,1.7c-0.4,0.5-0.9,1-1.4,1.5  s-1,0.9-1.5,1.4s-1.1,0.8-1.7,1.2c-0.6,0.4-1.2,0.7-1.8,1.1c-0.6,0.3-1.2,0.6-1.9,0.9c-0.6,0.3-1.3,0.5-1.9,0.7  c-0.7,0.2-1.3,0.4-2,0.5c-0.7,0.1-1.4,0.2-2,0.3s-1.4,0.1-2.1,0.1h-52.6c-0.7,0-1.4,0-2.1-0.1s-1.4-0.2-2-0.3  c-0.7-0.1-1.3-0.3-2-0.5c-0.7-0.2-1.3-0.4-1.9-0.7c-0.6-0.3-1.3-0.6-1.9-0.9c-0.6-0.3-1.2-0.7-1.8-1.1c-0.6-0.4-1.1-0.8-1.7-1.2  c-0.5-0.4-1-0.9-1.5-1.4s-0.9-1-1.4-1.5c-0.4-0.5-0.8-1.1-1.2-1.7c-0.4-0.6-0.7-1.2-1.1-1.8s-0.6-1.2-0.9-1.9  c-0.3-0.6-0.5-1.3-0.7-1.9c-0.2-0.7-0.4-1.3-0.5-2s-0.2-1.4-0.3-2c-0.1-0.7-0.1-1.4-0.1-2.1s0-1.4,0.1-2.1c0.1-0.7,0.2-1.4,0.3-2  s0.3-1.3,0.5-2c0.2-0.7,0.4-1.3,0.7-1.9c0.3-0.6,0.6-1.3,0.9-1.9c0.3-0.6,0.7-1.2,1.1-1.8c0.4-0.6,0.8-1.1,1.2-1.7  c0.4-0.5,0.9-1,1.4-1.5s1-0.9,1.5-1.4c0.5-0.4,1.1-0.8,1.7-1.2c0.6-0.4,1.2-0.7,1.8-1.1c0.6-0.3,1.2-0.6,1.9-0.9  c0.6-0.3,1.3-0.5,1.9-0.7c0.7-0.2,1.3-0.4,2-0.5c0.7-0.1,1.4-0.2,2-0.3S194.7,423.6,195.4,423.6z"/>
<path d="M195.6,434.2v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3c-0.5,1-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  s0.6-1.9,1.1-2.8c0.5-0.9,1-1.6,1.5-2.2H195.6z"/>
<path d="M206.2,441.6h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1c0.4-0.4,0.8-0.8,0.9-1.1h0.7  V441.6z"/>
<path d="M213.2,440.9c-0.4,0.3-0.8,0.6-1.1,0.7s-0.7,0.2-1.2,0.2c-0.7,0-1.2-0.2-1.6-0.5s-0.6-0.8-0.6-1.3c0-0.3,0.1-0.6,0.2-0.8  c0.1-0.3,0.3-0.5,0.5-0.6s0.5-0.3,0.8-0.3c0.2-0.1,0.5-0.1,0.9-0.2c0.9-0.1,1.5-0.2,1.9-0.4c0-0.1,0-0.2,0-0.3  c0-0.4-0.1-0.7-0.3-0.9c-0.3-0.2-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.1-1.1,0.3s-0.4,0.5-0.5,0.9l-1-0.1c0.1-0.4,0.2-0.8,0.5-1.1  s0.5-0.5,0.9-0.6c0.4-0.1,0.9-0.2,1.4-0.2c0.5,0,1,0.1,1.3,0.2s0.6,0.3,0.7,0.5c0.2,0.2,0.3,0.4,0.3,0.7c0,0.2,0.1,0.5,0.1,1v1.4  c0,1,0,1.6,0.1,1.9s0.1,0.5,0.3,0.7h-1.1C213.3,441.4,213.3,441.2,213.2,440.9z M213.1,438.5c-0.4,0.2-1,0.3-1.7,0.4  c-0.4,0.1-0.7,0.1-0.9,0.2s-0.3,0.2-0.4,0.3c-0.1,0.2-0.1,0.3-0.1,0.5c0,0.3,0.1,0.5,0.3,0.7c0.2,0.2,0.5,0.3,0.9,0.3  c0.4,0,0.8-0.1,1.1-0.3s0.5-0.4,0.7-0.7c0.1-0.2,0.2-0.6,0.2-1.1V438.5z"/>
<path d="M215.6,439.4l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3s0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5c0.3-0.3,0.5-0.8,0.5-1.3  c0-0.5-0.2-0.9-0.5-1.2c-0.3-0.3-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1l0.1-0.9c0.1,0,0.1,0,0.2,0c0.4,0,0.9-0.1,1.2-0.4  c0.4-0.2,0.5-0.6,0.5-1.1c0-0.4-0.1-0.7-0.4-1c-0.3-0.3-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4s-0.4,0.6-0.5,1.2l-1.1-0.2  c0.1-0.7,0.4-1.3,0.9-1.6c0.5-0.4,1-0.6,1.7-0.6c0.5,0,0.9,0.1,1.3,0.3c0.4,0.2,0.7,0.5,0.9,0.8c0.2,0.3,0.3,0.7,0.3,1.1  c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-0.9,0.7c0.5,0.1,0.9,0.4,1.2,0.7c0.3,0.4,0.4,0.8,0.4,1.4c0,0.8-0.3,1.4-0.8,1.9  c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7S215.6,440.1,215.6,439.4z"/>
<path d="M222.2,437.4c0-1,0.1-1.8,0.3-2.5s0.5-1.1,0.9-1.4c0.4-0.3,0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3c0.3,0.2,0.6,0.5,0.9,0.8  c0.2,0.3,0.4,0.8,0.5,1.3s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9  C222.5,440.2,222.2,439,222.2,437.4z M223.3,437.4c0,1.4,0.2,2.3,0.5,2.8c0.3,0.5,0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7  c0.3-0.5,0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8c-0.3-0.5-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C223.5,435,223.3,436,223.3,437.4z  "/>
<path d="M234.4,435.1l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  c-0.2,0.5-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9s0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8c0.5,0.5,0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5  c-0.2,0.5-0.6,0.8-1,1.1s-0.9,0.4-1.4,0.4c-0.9,0-1.6-0.3-2.1-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6  c0.5-0.7,1.3-1,2.2-1c0.7,0,1.2,0.2,1.7,0.6C234,433.9,234.3,434.5,234.4,435.1z M230.1,438.8c0,0.4,0.1,0.7,0.2,1  c0.2,0.3,0.4,0.6,0.6,0.8s0.6,0.3,0.9,0.3c0.4,0,0.8-0.2,1.1-0.5c0.3-0.4,0.5-0.8,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4  c-0.3-0.3-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.5C230.2,437.8,230.1,438.3,230.1,438.8z"/>
<path d="M235.7,439.6l1-0.1c0.1,0.5,0.2,0.8,0.5,1s0.6,0.3,0.9,0.3c0.3,0,0.6-0.1,0.9-0.2s0.4-0.3,0.6-0.6s0.3-0.6,0.4-1  s0.2-0.9,0.2-1.3c0,0,0-0.1,0-0.2c-0.2,0.3-0.5,0.6-0.9,0.8c-0.4,0.2-0.8,0.3-1.2,0.3c-0.7,0-1.3-0.3-1.8-0.8s-0.7-1.2-0.7-2  c0-0.9,0.3-1.6,0.8-2.1c0.5-0.5,1.2-0.8,1.9-0.8c0.6,0,1.1,0.2,1.5,0.5c0.5,0.3,0.8,0.7,1.1,1.3c0.2,0.6,0.4,1.4,0.4,2.4  c0,1.1-0.1,2-0.4,2.6c-0.2,0.7-0.6,1.1-1.1,1.5c-0.5,0.3-1,0.5-1.7,0.5c-0.7,0-1.2-0.2-1.6-0.6C236.1,440.8,235.8,440.3,235.7,439.6  z M240,435.8c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.4-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.6s-0.5,0.9-0.5,1.5c0,0.5,0.2,1,0.5,1.3  c0.3,0.3,0.7,0.5,1.2,0.5c0.5,0,0.9-0.2,1.2-0.5C239.9,436.9,240,436.5,240,435.8z"/>
<path d="M242.2,437.4c0-1,0.1-1.8,0.3-2.5s0.5-1.1,0.9-1.4c0.4-0.3,0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3c0.3,0.2,0.6,0.5,0.9,0.8  c0.2,0.3,0.4,0.8,0.5,1.3s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9  C242.5,440.2,242.2,439,242.2,437.4z M243.3,437.4c0,1.4,0.2,2.3,0.5,2.8c0.3,0.5,0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7  c0.3-0.5,0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8c-0.3-0.5-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C243.5,435,243.3,436,243.3,437.4z  "/>
<path d="M187.2,455.1l3.3-8.6h1.2l3.5,8.6h-1.3l-1-2.6h-3.6l-0.9,2.6H187.2z M189.6,451.6h2.9l-0.9-2.4c-0.3-0.7-0.5-1.3-0.6-1.8  c-0.1,0.6-0.3,1.1-0.5,1.6L189.6,451.6z"/>
<path d="M195.7,452.4l1.1-0.1c0.1,0.4,0.2,0.8,0.4,1.1c0.2,0.3,0.5,0.5,0.9,0.7c0.4,0.2,0.8,0.3,1.3,0.3c0.4,0,0.8-0.1,1.1-0.2  c0.3-0.1,0.6-0.3,0.7-0.5s0.2-0.5,0.2-0.7c0-0.3-0.1-0.5-0.2-0.7s-0.4-0.4-0.8-0.5c-0.2-0.1-0.7-0.2-1.5-0.4s-1.3-0.4-1.7-0.5  c-0.4-0.2-0.7-0.5-0.9-0.8s-0.3-0.7-0.3-1.1c0-0.4,0.1-0.8,0.4-1.2s0.6-0.7,1.1-0.9s1-0.3,1.6-0.3c0.6,0,1.2,0.1,1.7,0.3  c0.5,0.2,0.9,0.5,1.1,0.9c0.3,0.4,0.4,0.8,0.4,1.4l-1.1,0.1c-0.1-0.5-0.3-1-0.6-1.2c-0.3-0.3-0.8-0.4-1.5-0.4  c-0.7,0-1.2,0.1-1.5,0.4s-0.5,0.6-0.5,0.9c0,0.3,0.1,0.6,0.3,0.8c0.2,0.2,0.8,0.4,1.7,0.6s1.6,0.4,1.9,0.5c0.5,0.2,0.9,0.5,1.1,0.9  c0.2,0.4,0.4,0.8,0.4,1.2c0,0.5-0.1,0.9-0.4,1.3c-0.3,0.4-0.6,0.7-1.1,0.9c-0.5,0.2-1,0.3-1.7,0.3c-0.8,0-1.4-0.1-2-0.3  c-0.5-0.2-0.9-0.6-1.2-1S195.7,452.9,195.7,452.4z"/>
<path d="M203.7,452.4l1.1-0.1c0.1,0.4,0.2,0.8,0.4,1.1c0.2,0.3,0.5,0.5,0.9,0.7c0.4,0.2,0.8,0.3,1.3,0.3c0.4,0,0.8-0.1,1.1-0.2  c0.3-0.1,0.6-0.3,0.7-0.5s0.2-0.5,0.2-0.7c0-0.3-0.1-0.5-0.2-0.7s-0.4-0.4-0.8-0.5c-0.2-0.1-0.7-0.2-1.5-0.4s-1.3-0.4-1.7-0.5  c-0.4-0.2-0.7-0.5-0.9-0.8s-0.3-0.7-0.3-1.1c0-0.4,0.1-0.8,0.4-1.2s0.6-0.7,1.1-0.9s1-0.3,1.6-0.3c0.6,0,1.2,0.1,1.7,0.3  c0.5,0.2,0.9,0.5,1.1,0.9c0.3,0.4,0.4,0.8,0.4,1.4l-1.1,0.1c-0.1-0.5-0.3-1-0.6-1.2c-0.3-0.3-0.8-0.4-1.5-0.4  c-0.7,0-1.2,0.1-1.5,0.4s-0.5,0.6-0.5,0.9c0,0.3,0.1,0.6,0.3,0.8c0.2,0.2,0.8,0.4,1.7,0.6s1.6,0.4,1.9,0.5c0.5,0.2,0.9,0.5,1.1,0.9  c0.2,0.4,0.4,0.8,0.4,1.2c0,0.5-0.1,0.9-0.4,1.3c-0.3,0.4-0.6,0.7-1.1,0.9c-0.5,0.2-1,0.3-1.7,0.3c-0.8,0-1.4-0.1-2-0.3  c-0.5-0.2-0.9-0.6-1.2-1S203.7,452.9,203.7,452.4z"/>
<path d="M212.1,455.1v-8.6h6.2v1h-5.1v2.6h4.8v1h-4.8v2.9h5.3v1H212.1z"/>
<path d="M220.1,455.1v-8.6h3.8c0.8,0,1.3,0.1,1.7,0.2s0.7,0.4,1,0.8s0.4,0.8,0.4,1.3c0,0.6-0.2,1.1-0.6,1.5c-0.4,0.4-1,0.7-1.8,0.8  c0.3,0.1,0.5,0.3,0.7,0.4c0.3,0.3,0.6,0.7,0.9,1.1l1.5,2.3h-1.4l-1.1-1.8c-0.3-0.5-0.6-0.9-0.8-1.2s-0.4-0.5-0.6-0.6  c-0.2-0.1-0.3-0.2-0.5-0.2c-0.1,0-0.3,0-0.6,0h-1.3v3.8H220.1z M221.3,450.3h2.4c0.5,0,0.9-0.1,1.2-0.2c0.3-0.1,0.5-0.3,0.7-0.5  s0.2-0.5,0.2-0.8c0-0.4-0.1-0.7-0.4-1s-0.8-0.4-1.4-0.4h-2.7V450.3z"/>
<path d="M230.7,455.1v-7.6h-2.8v-1h6.8v1h-2.8v7.6H230.7z"/>
<path d="M236.1,455.1v-8.6h1.1v8.6H236.1z"/>
<path d="M238.9,450.9c0-1.4,0.4-2.5,1.1-3.3c0.8-0.8,1.8-1.2,3-1.2c0.8,0,1.5,0.2,2.1,0.6c0.6,0.4,1.1,0.9,1.5,1.6  c0.3,0.7,0.5,1.4,0.5,2.3c0,0.9-0.2,1.7-0.5,2.3c-0.4,0.7-0.8,1.2-1.5,1.6c-0.6,0.4-1.3,0.5-2.1,0.5c-0.8,0-1.5-0.2-2.2-0.6  c-0.6-0.4-1.1-0.9-1.4-1.6S238.9,451.7,238.9,450.9z M240,451c0,1,0.3,1.9,0.8,2.4s1.3,0.9,2.1,0.9c0.9,0,1.6-0.3,2.1-0.9  c0.6-0.6,0.8-1.5,0.8-2.6c0-0.7-0.1-1.3-0.4-1.8s-0.6-0.9-1-1.2s-1-0.4-1.5-0.4c-0.8,0-1.5,0.3-2.1,0.8  C240.3,448.7,240,449.7,240,451z"/>
<path d="M248.5,455.1v-8.6h1.2l4.5,6.7v-6.7h1.1v8.6h-1.2l-4.5-6.8v6.8H248.5z"/>
<rect x="187.2" y="431.1" fill-rule="evenodd" fill="none" width="69" height="27"/>
<rect x="355" y="383.9" fill="none" stroke="#000000" stroke-width="2.2496" width="144.8" height="42"/>
<path d="M401.3,394.4v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  s0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H401.3z"/>
<path d="M407.9,397.6c0-1,0.1-1.8,0.3-2.5s0.5-1.1,0.9-1.4s0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3s0.6,0.5,0.9,0.8s0.4,0.8,0.5,1.3  s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9C408.1,400.4,407.9,399.3,407.9,397.6z   M408.9,397.6c0,1.4,0.2,2.3,0.5,2.8s0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7s0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8  s-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C409.1,395.3,408.9,396.2,408.9,397.6z"/>
<path d="M414.7,399.9l1-0.1c0.1,0.5,0.2,0.8,0.5,1s0.6,0.3,0.9,0.3c0.3,0,0.6-0.1,0.9-0.2c0.2-0.1,0.4-0.3,0.6-0.6s0.3-0.6,0.4-1  s0.2-0.9,0.2-1.3c0,0,0-0.1,0-0.2c-0.2,0.3-0.5,0.6-0.9,0.8s-0.8,0.3-1.2,0.3c-0.7,0-1.3-0.3-1.8-0.8c-0.5-0.5-0.7-1.2-0.7-2  c0-0.9,0.3-1.6,0.8-2.1c0.5-0.5,1.2-0.8,1.9-0.8c0.6,0,1.1,0.2,1.5,0.5s0.8,0.7,1.1,1.3s0.4,1.4,0.4,2.4c0,1.1-0.1,2-0.4,2.6  s-0.6,1.1-1.1,1.5s-1,0.5-1.7,0.5c-0.7,0-1.2-0.2-1.6-0.6C415,401.1,414.8,400.6,414.7,399.9z M419,396.1c0-0.6-0.2-1.1-0.5-1.4  s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.6s-0.5,0.9-0.5,1.5c0,0.5,0.2,1,0.5,1.3s0.7,0.5,1.2,0.5c0.5,0,0.9-0.2,1.2-0.5  S419,396.7,419,396.1z"/>
<path d="M426.7,400.9v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1c0.3-0.4,0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8  s0.5-0.9,0.5-1.3c0-0.4-0.1-0.8-0.4-1.1s-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5s-0.5,0.7-0.5,1.3l-1.1-0.1  c0.1-0.8,0.4-1.4,0.8-1.8c0.5-0.4,1.1-0.6,2-0.6c0.8,0,1.5,0.2,2,0.7s0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1s-0.4,0.7-0.7,1  s-0.9,0.9-1.6,1.5c-0.6,0.5-1,0.9-1.2,1.1s-0.3,0.4-0.4,0.6H426.7z"/>
<path d="M432.2,401.9v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6v-3.1h1v8.6H432.2z M428.9,398.8  c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6S428.9,397.9,428.9,398.8z"/>
<path d="M440,395.4l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  s-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9s0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8s0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5s-0.6,0.8-1,1.1  s-0.9,0.4-1.4,0.4c-0.9,0-1.6-0.3-2.2-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6c0.5-0.7,1.3-1,2.2-1c0.7,0,1.2,0.2,1.7,0.6  S439.9,394.7,440,395.4z M435.7,399.1c0,0.4,0.1,0.7,0.2,1s0.4,0.6,0.6,0.8s0.6,0.3,0.9,0.3c0.4,0,0.8-0.2,1.1-0.5s0.5-0.8,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.5S435.7,398.5,435.7,399.1z"/>
<path d="M446.8,400.9v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1c0.3-0.4,0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8  s0.5-0.9,0.5-1.3c0-0.4-0.1-0.8-0.4-1.1s-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5s-0.5,0.7-0.5,1.3l-1.1-0.1  c0.1-0.8,0.4-1.4,0.8-1.8c0.5-0.4,1.1-0.6,2-0.6c0.8,0,1.5,0.2,2,0.7s0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1s-0.4,0.7-0.7,1  s-0.9,0.9-1.6,1.5c-0.6,0.5-1,0.9-1.2,1.1s-0.3,0.4-0.4,0.6H446.8z"/>
<path d="M447.9,397.6c0-1,0.1-1.8,0.3-2.5s0.5-1.1,0.9-1.4s0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3s0.6,0.5,0.9,0.8s0.4,0.8,0.5,1.3  s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9C448.2,400.4,447.9,399.3,447.9,397.6z   M449,397.6c0,1.4,0.2,2.3,0.5,2.8s0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7s0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8s-0.7-0.7-1.2-0.7  c-0.5,0-0.9,0.2-1.2,0.6C449.2,395.3,449,396.2,449,397.6z"/>
<path d="M407,409.8l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H407z M408.9,409.8l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H408.9z"/>
<path d="M411.2,415.4v-8.6h1.1v4.9l2.5-2.5h1.4l-2.4,2.3l2.6,3.9H415l-2.1-3.2l-0.7,0.7v2.5H411.2z"/>
<path d="M417.2,415.4v-6.2h0.9v0.9c0.5-0.7,1.1-1,2-1c0.4,0,0.7,0.1,1,0.2s0.5,0.3,0.7,0.5s0.3,0.5,0.3,0.8c0,0.2,0.1,0.5,0.1,1v3.8  h-1.1v-3.8c0-0.4,0-0.8-0.1-1s-0.2-0.4-0.4-0.5s-0.5-0.2-0.7-0.2c-0.4,0-0.8,0.1-1.2,0.4s-0.5,0.8-0.5,1.6v3.4H417.2z"/>
<path d="M423.4,412.3c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8s0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  s-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8C423.7,414.1,423.4,413.3,423.4,412.3z M424.5,412.3c0,0.8,0.2,1.4,0.5,1.8  s0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7s-0.8-0.6-1.3-0.6c-0.5,0-1,0.2-1.3,0.6  S424.5,411.5,424.5,412.3z"/>
<path d="M431.7,415.4l-1.9-6.2h1.1l1,3.6l0.4,1.3c0-0.1,0.1-0.5,0.3-1.3l1-3.6h1.1l0.9,3.6l0.3,1.2l0.4-1.2l1.1-3.6h1l-1.9,6.2h-1.1  l-1-3.7l-0.2-1.1l-1.3,4.8H431.7z"/>
<path d="M438.7,413.5l1-0.2c0.1,0.4,0.2,0.7,0.5,1s0.6,0.3,1.1,0.3c0.5,0,0.8-0.1,1.1-0.3s0.4-0.4,0.4-0.7c0-0.2-0.1-0.4-0.3-0.6  c-0.1-0.1-0.5-0.2-1.1-0.4c-0.8-0.2-1.3-0.4-1.6-0.5c-0.3-0.1-0.5-0.3-0.7-0.6s-0.2-0.5-0.2-0.8c0-0.3,0.1-0.5,0.2-0.8  s0.3-0.4,0.5-0.6c0.2-0.1,0.4-0.2,0.7-0.3s0.6-0.1,0.9-0.1c0.5,0,0.9,0.1,1.3,0.2c0.4,0.1,0.6,0.3,0.8,0.6s0.3,0.6,0.4,1l-1,0.1  c0-0.3-0.2-0.6-0.4-0.8c-0.2-0.2-0.5-0.3-1-0.3c-0.5,0-0.8,0.1-1,0.2s-0.3,0.3-0.3,0.6c0,0.1,0,0.3,0.1,0.4c0.1,0.1,0.2,0.2,0.4,0.3  c0.1,0,0.4,0.1,0.9,0.3c0.7,0.2,1.3,0.4,1.6,0.5s0.5,0.3,0.7,0.6s0.3,0.5,0.3,0.9c0,0.4-0.1,0.7-0.3,1s-0.5,0.6-0.9,0.7  s-0.8,0.3-1.3,0.3c-0.8,0-1.4-0.2-1.8-0.5C439.1,414.7,438.9,414.2,438.7,413.5z"/>
<path d="M445.2,409.8l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H445.2z M447.2,409.8l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H447.2z"/>
<rect x="362.5" y="391.4" fill-rule="evenodd" fill="none" width="129.7" height="27"/>
<rect x="357.6" y="463.4" fill="none" stroke="#000000" stroke-width="2.2496" width="139.5" height="42"/>
<path d="M405.9,480.6c-0.4,0.3-0.8,0.6-1.1,0.7c-0.4,0.1-0.7,0.2-1.2,0.2c-0.7,0-1.2-0.2-1.6-0.5c-0.4-0.3-0.6-0.8-0.6-1.3  c0-0.3,0.1-0.6,0.2-0.8s0.3-0.5,0.5-0.6c0.2-0.2,0.5-0.3,0.8-0.3c0.2-0.1,0.5-0.1,0.9-0.2c0.9-0.1,1.5-0.2,1.9-0.4  c0-0.1,0-0.2,0-0.3c0-0.4-0.1-0.7-0.3-0.9c-0.3-0.2-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.1-1.1,0.3s-0.4,0.5-0.5,0.9l-1-0.1  c0.1-0.4,0.2-0.8,0.5-1.1c0.2-0.3,0.5-0.5,0.9-0.6s0.9-0.2,1.4-0.2c0.5,0,1,0.1,1.3,0.2s0.6,0.3,0.7,0.5s0.3,0.4,0.3,0.7  c0,0.2,0.1,0.5,0.1,1v1.4c0,1,0,1.6,0.1,1.9s0.1,0.5,0.3,0.7h-1.1C406,481.2,405.9,480.9,405.9,480.6z M405.8,478.3  c-0.4,0.2-1,0.3-1.7,0.4c-0.4,0.1-0.7,0.1-0.9,0.2s-0.3,0.2-0.4,0.3s-0.1,0.3-0.1,0.5c0,0.3,0.1,0.5,0.3,0.7s0.5,0.3,0.9,0.3  c0.4,0,0.8-0.1,1.1-0.3c0.3-0.2,0.5-0.4,0.7-0.7c0.1-0.2,0.2-0.6,0.2-1.1V478.3z"/>
<path d="M412.5,481.4v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  s0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6v-3.1h1v8.6H412.5z M409.2,478.3  c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6S409.2,477.4,409.2,478.3z"/>
<path d="M420.4,480.4v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1c0.3-0.4,0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8  s0.5-0.9,0.5-1.3c0-0.4-0.1-0.8-0.4-1.1s-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5s-0.5,0.7-0.5,1.3l-1.1-0.1  c0.1-0.8,0.4-1.4,0.8-1.8c0.5-0.4,1.1-0.6,2-0.6c0.8,0,1.5,0.2,2,0.7s0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1s-0.4,0.7-0.7,1  s-0.9,0.9-1.6,1.5c-0.6,0.5-1,0.9-1.2,1.1s-0.3,0.4-0.4,0.6H420.4z"/>
<path d="M425.9,479.1l1,0.1c-0.1,0.7-0.4,1.3-0.9,1.7s-1,0.6-1.7,0.6c-0.9,0-1.5-0.3-2.1-0.8c-0.5-0.6-0.8-1.4-0.8-2.4  c0-0.7,0.1-1.3,0.3-1.8s0.6-0.9,1-1.1s1-0.4,1.5-0.4c0.7,0,1.2,0.2,1.7,0.5s0.7,0.8,0.8,1.5l-1,0.2c-0.1-0.4-0.3-0.7-0.5-0.9  s-0.5-0.3-0.9-0.3c-0.5,0-1,0.2-1.3,0.6s-0.5,1-0.5,1.8c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.3,0.6c0.4,0,0.8-0.1,1-0.4  S425.8,479.6,425.9,479.1z"/>
<path d="M430.9,481.4v-2.1h-3.7v-1l3.9-5.6h0.9v5.6h1.2v1H432v2.1H430.9z M430.9,478.4v-3.9l-2.7,3.9H430.9z"/>
<path d="M434.2,479.1l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2s0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6s0.5-0.9,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4s-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2s-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4l-0.5,2.3  c0.5-0.4,1.1-0.5,1.6-0.5c0.7,0,1.4,0.3,1.9,0.8s0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1c-0.8,0-1.4-0.2-1.9-0.7  C434.6,480.4,434.3,479.8,434.2,479.1z"/>
<path d="M444.3,481.4v-2.1h-3.7v-1l3.9-5.6h0.9v5.6h1.2v1h-1.2v2.1H444.3z M444.3,478.4v-3.9l-2.7,3.9H444.3z"/>
<path d="M448.8,481.4h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1s0.2,0.8,0.2,1.3  c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V481.4z M448.8,478.2c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  S448.8,477.5,448.8,478.2z"/>
<path d="M409.6,489.3l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H409.6z M411.6,489.3l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H411.6z"/>
<path d="M420.1,491.9l1.1,0.3c-0.2,0.9-0.7,1.6-1.3,2.1c-0.6,0.5-1.4,0.7-2.3,0.7c-0.9,0-1.7-0.2-2.3-0.6s-1-0.9-1.3-1.6  c-0.3-0.7-0.5-1.5-0.5-2.3c0-0.9,0.2-1.7,0.5-2.3c0.3-0.7,0.8-1.2,1.5-1.5s1.3-0.5,2.1-0.5c0.9,0,1.6,0.2,2.2,0.7  c0.6,0.4,1,1.1,1.2,1.8l-1.1,0.3c-0.2-0.6-0.5-1.1-0.9-1.4c-0.4-0.3-0.9-0.4-1.4-0.4c-0.7,0-1.2,0.2-1.7,0.5s-0.8,0.7-0.9,1.3  s-0.3,1.1-0.3,1.6c0,0.7,0.1,1.4,0.3,1.9s0.5,1,1,1.2s0.9,0.4,1.5,0.4c0.6,0,1.2-0.2,1.6-0.6C419.6,493.1,419.9,492.6,420.1,491.9z"/>
<path d="M426.6,494.1c-0.4,0.3-0.8,0.6-1.1,0.7c-0.4,0.1-0.7,0.2-1.2,0.2c-0.7,0-1.2-0.2-1.6-0.5c-0.4-0.3-0.6-0.8-0.6-1.3  c0-0.3,0.1-0.6,0.2-0.8s0.3-0.5,0.5-0.6c0.2-0.2,0.5-0.3,0.8-0.3c0.2-0.1,0.5-0.1,0.9-0.2c0.9-0.1,1.5-0.2,1.9-0.4  c0-0.1,0-0.2,0-0.3c0-0.4-0.1-0.7-0.3-0.9c-0.3-0.2-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.1-1.1,0.3s-0.4,0.5-0.5,0.9l-1-0.1  c0.1-0.4,0.2-0.8,0.5-1.1c0.2-0.3,0.5-0.5,0.9-0.6s0.9-0.2,1.4-0.2c0.5,0,1,0.1,1.3,0.2s0.6,0.3,0.7,0.5s0.3,0.4,0.3,0.7  c0,0.2,0.1,0.5,0.1,1v1.4c0,1,0,1.6,0.1,1.9s0.1,0.5,0.3,0.7h-1.1C426.7,494.7,426.6,494.4,426.6,494.1z M426.5,491.8  c-0.4,0.2-1,0.3-1.7,0.4c-0.4,0.1-0.7,0.1-0.9,0.2s-0.3,0.2-0.4,0.3s-0.1,0.3-0.1,0.5c0,0.3,0.1,0.5,0.3,0.7s0.5,0.3,0.9,0.3  c0.4,0,0.8-0.1,1.1-0.3c0.3-0.2,0.5-0.4,0.7-0.7c0.1-0.2,0.2-0.6,0.2-1.1V491.8z"/>
<path d="M429.2,494.9v-6.2h0.9v0.9c0.2-0.4,0.5-0.7,0.7-0.9s0.4-0.2,0.7-0.2c0.4,0,0.7,0.1,1.1,0.3l-0.4,1c-0.3-0.2-0.5-0.2-0.8-0.2  c-0.2,0-0.4,0.1-0.6,0.2s-0.3,0.3-0.4,0.6c-0.1,0.4-0.2,0.8-0.2,1.2v3.3H429.2z"/>
<path d="M432.8,491.8c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8s0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  s-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8C433,493.6,432.8,492.8,432.8,491.8z M433.9,491.8c0,0.8,0.2,1.4,0.5,1.8  s0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7s-0.8-0.6-1.3-0.6c-0.5,0-1,0.2-1.3,0.6  S433.9,491,433.9,491.8z"/>
<path d="M439.8,494.9v-8.6h1.1v8.6H439.8z"/>
<path d="M442.6,489.3l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H442.6z M444.5,489.3l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H444.5z"/>
<rect x="365.1" y="470.9" fill-rule="evenodd" fill="none" width="124.5" height="27"/>
</svg>
</artwork>

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
27840350 "Alice"
~~~

### Mermaid

<artwork type="svg"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.2" baseProfile="tiny" width="189.5px" height="94.3px" viewBox="0 0 189.5 94.3" xml:space="preserve">
<rect x="26.1" y="26.1" fill="none" stroke="#000000" stroke-width="2.2528" width="137.2" height="42"/>
<path d="M74,43.1v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1s0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8s0.5-0.9,0.5-1.3  c0-0.4-0.1-0.8-0.4-1.1c-0.3-0.3-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5c-0.3,0.3-0.5,0.7-0.5,1.3L68.5,38c0.1-0.8,0.4-1.4,0.8-1.8  c0.5-0.4,1.1-0.6,2-0.6c0.8,0,1.5,0.2,2,0.7c0.5,0.5,0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1s-0.4,0.7-0.7,1c-0.3,0.4-0.9,0.9-1.6,1.5  c-0.6,0.5-1,0.9-1.2,1.1s-0.3,0.4-0.4,0.6H74z"/>
<path d="M75.2,36.7v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  s0.6-1.9,1.1-2.8c0.5-0.9,1-1.6,1.5-2.2H75.2z"/>
<path d="M83.5,39.5c-0.4-0.2-0.8-0.4-1-0.7s-0.3-0.7-0.3-1.1c0-0.6,0.2-1.2,0.7-1.6c0.5-0.4,1-0.6,1.8-0.6c0.8,0,1.4,0.2,1.8,0.7  c0.5,0.4,0.7,1,0.7,1.6c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-1,0.7c0.5,0.2,0.9,0.4,1.2,0.8c0.3,0.4,0.4,0.8,0.4,1.4c0,0.7-0.3,1.4-0.8,1.9  c-0.5,0.5-1.2,0.8-2.1,0.8s-1.5-0.3-2.1-0.8c-0.5-0.5-0.8-1.1-0.8-1.9c0-0.6,0.1-1,0.4-1.4C82.6,39.9,83,39.6,83.5,39.5z M82.9,41.6  c0,0.3,0.1,0.6,0.2,0.9s0.4,0.5,0.6,0.7c0.3,0.2,0.6,0.2,0.9,0.2c0.5,0,0.9-0.2,1.3-0.5c0.3-0.3,0.5-0.7,0.5-1.2  c0-0.5-0.2-0.9-0.5-1.3c-0.3-0.3-0.8-0.5-1.3-0.5c-0.5,0-0.9,0.2-1.2,0.5C83.1,40.7,82.9,41.2,82.9,41.6z M83.3,37.7  c0,0.4,0.1,0.7,0.4,1c0.3,0.3,0.6,0.4,1,0.4c0.4,0,0.7-0.1,1-0.4c0.3-0.3,0.4-0.6,0.4-0.9c0-0.4-0.1-0.7-0.4-1s-0.6-0.4-1-0.4  c-0.4,0-0.7,0.1-1,0.4C83.4,37,83.3,37.3,83.3,37.7z"/>
<path d="M91.9,44.1v-2.1h-3.7v-1l3.9-5.6H93v5.6h1.2v1H93v2.1H91.9z M91.9,41.1v-3.9l-2.7,3.9H91.9z"/>
<path d="M95.2,39.9c0-1,0.1-1.8,0.3-2.5s0.5-1.1,0.9-1.4s0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3s0.6,0.5,0.9,0.8  c0.2,0.3,0.4,0.8,0.5,1.3c0.1,0.5,0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9  C95.5,42.7,95.2,41.5,95.2,39.9z M96.3,39.9c0,1.4,0.2,2.3,0.5,2.8c0.3,0.5,0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7s0.5-1.4,0.5-2.8  c0-1.4-0.2-2.4-0.5-2.8s-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C96.5,37.5,96.3,38.5,96.3,39.9z"/>
<path d="M101.9,41.9l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3c0.3,0.3,0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5s0.5-0.8,0.5-1.3  c0-0.5-0.2-0.9-0.5-1.2c-0.3-0.3-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1l0.1-0.9c0.1,0,0.1,0,0.2,0c0.5,0,0.9-0.1,1.2-0.4  s0.5-0.6,0.5-1.1c0-0.4-0.1-0.7-0.4-1c-0.3-0.3-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4c-0.3,0.3-0.5,0.6-0.5,1.2l-1.1-0.2  c0.1-0.7,0.4-1.3,0.9-1.6c0.5-0.4,1-0.6,1.7-0.6c0.5,0,0.9,0.1,1.3,0.3s0.7,0.5,0.9,0.8s0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1  s-0.5,0.5-0.9,0.7c0.5,0.1,0.9,0.4,1.2,0.7c0.3,0.4,0.4,0.8,0.4,1.4c0,0.8-0.3,1.4-0.8,1.9s-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7  S102,42.6,101.9,41.9z"/>
<path d="M108.6,41.9l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2c0.3,0.3,0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6c0.4-0.4,0.5-0.9,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.3-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2c-0.3,0.2-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4  L110,39c0.5-0.4,1.1-0.5,1.6-0.5c0.8,0,1.4,0.3,1.9,0.8s0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1  c-0.8,0-1.4-0.2-1.9-0.7C109,43.2,108.7,42.6,108.6,41.9z"/>
<path d="M115.3,39.9c0-1,0.1-1.8,0.3-2.5s0.5-1.1,0.9-1.4s0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3s0.6,0.5,0.9,0.8  c0.2,0.3,0.4,0.8,0.5,1.3c0.1,0.5,0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9  C115.6,42.7,115.3,41.5,115.3,39.9z M116.4,39.9c0,1.4,0.2,2.3,0.5,2.8c0.3,0.5,0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7  s0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8s-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C116.6,37.5,116.4,38.5,116.4,39.9z"/>
<path d="M78.3,52.1L78,50.4V49h1.2v1.4l-0.3,1.6H78.3z M80.2,52.1l-0.3-1.6V49h1.2v1.4l-0.3,1.6H80.2z"/>
<path d="M81.7,57.6L85,49h1.2l3.5,8.6h-1.3l-1-2.6h-3.6l-0.9,2.6H81.7z M84.2,54.1h2.9l-0.9-2.4c-0.3-0.7-0.5-1.3-0.6-1.8  c-0.1,0.6-0.3,1.1-0.5,1.6L84.2,54.1z"/>
<path d="M90.5,57.6V49h1.1v8.6H90.5z"/>
<path d="M93.2,50.2V49h1.1v1.2H93.2z M93.2,57.6v-6.2h1.1v6.2H93.2z"/>
<path d="M99.9,55.3l1,0.1c-0.1,0.7-0.4,1.3-0.9,1.7c-0.5,0.4-1,0.6-1.7,0.6c-0.9,0-1.5-0.3-2.1-0.8c-0.5-0.6-0.8-1.4-0.8-2.4  c0-0.7,0.1-1.3,0.3-1.8s0.6-0.9,1-1.1c0.5-0.3,1-0.4,1.5-0.4c0.7,0,1.2,0.2,1.7,0.5c0.4,0.3,0.7,0.8,0.8,1.5l-1,0.2  c-0.1-0.4-0.3-0.7-0.5-0.9c-0.2-0.2-0.5-0.3-0.9-0.3c-0.5,0-1,0.2-1.3,0.6c-0.3,0.4-0.5,1-0.5,1.8c0,0.8,0.2,1.4,0.5,1.8  c0.3,0.4,0.7,0.6,1.3,0.6c0.4,0,0.8-0.1,1-0.4C99.7,56.3,99.9,55.9,99.9,55.3z"/>
<path d="M106.1,55.6l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5c-0.5,0.4-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8c-0.5-0.6-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4c0.5-0.6,1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8c0.5,0.6,0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.7  c0,0.7,0.2,1.2,0.6,1.6s0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3C105.8,56.4,106,56.1,106.1,55.6z M102.7,53.9h3.5  c0-0.5-0.2-0.9-0.4-1.2c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5S102.7,53.4,102.7,53.9z"/>
<path d="M108.6,52.1l-0.3-1.6V49h1.2v1.4l-0.3,1.6H108.6z M110.6,52.1l-0.3-1.6V49h1.2v1.4l-0.3,1.6H110.6z"/>
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
d59f8c0f verifiedBy
~~~

### Mermaid

<artwork type="svg"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.2" baseProfile="tiny" width="149.6px" height="94.3px" viewBox="0 0 149.6 94.3" xml:space="preserve">
<polygon fill="none" stroke="#000000" stroke-width="2.2532" points="26.8,68.1 101.7,68.1 122.8,26.1 47.9,26.1 "/>
<path d="M56.6,44.1v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4c-0.4-0.3-0.7-0.7-1-1.1c-0.2-0.5-0.3-1.1-0.3-1.7  c0-0.6,0.1-1.2,0.3-1.7s0.5-0.9,0.9-1.2c0.4-0.3,0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6v-3.1h1.1v8.6H56.6z M53.2,41  c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C53.4,39.6,53.2,40.2,53.2,41z"/>
<path d="M58.9,41.9l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2s0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6s0.5-0.9,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4  s-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2c-0.3,0.2-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4L60.3,39c0.5-0.4,1.1-0.5,1.6-0.5  c0.8,0,1.4,0.3,1.9,0.8c0.5,0.5,0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1c-0.8,0-1.4-0.2-1.9-0.7S59,42.6,58.9,41.9z  "/>
<path d="M65.8,42.1l1-0.1c0.1,0.5,0.3,0.8,0.5,1c0.2,0.2,0.6,0.3,0.9,0.3c0.3,0,0.6-0.1,0.9-0.2c0.2-0.1,0.4-0.3,0.6-0.6  s0.3-0.6,0.4-1c0.1-0.4,0.2-0.9,0.2-1.3c0,0,0-0.1,0-0.2c-0.2,0.3-0.5,0.6-0.9,0.8s-0.8,0.3-1.2,0.3c-0.7,0-1.3-0.3-1.8-0.8  s-0.7-1.2-0.7-2c0-0.9,0.3-1.6,0.8-2.1c0.5-0.5,1.2-0.8,1.9-0.8c0.6,0,1.1,0.2,1.5,0.5s0.8,0.7,1.1,1.3c0.2,0.6,0.4,1.4,0.4,2.4  c0,1.1-0.1,2-0.4,2.6c-0.2,0.7-0.6,1.1-1.1,1.5s-1,0.5-1.7,0.5c-0.7,0-1.2-0.2-1.7-0.6C66.1,43.3,65.9,42.8,65.8,42.1z M70.1,38.3  c0-0.6-0.2-1.1-0.5-1.4s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.6c-0.3,0.4-0.5,0.9-0.5,1.5c0,0.5,0.2,1,0.5,1.3s0.7,0.5,1.2,0.5  c0.5,0,0.9-0.2,1.2-0.5S70.1,39,70.1,38.3z"/>
<path d="M72.9,44.1v-5.4h-0.9v-0.8h0.9v-0.7c0-0.4,0-0.7,0.1-0.9c0.1-0.3,0.3-0.5,0.5-0.7c0.3-0.2,0.6-0.3,1.1-0.3  c0.3,0,0.6,0,1,0.1l-0.2,0.9c-0.2,0-0.4-0.1-0.6-0.1c-0.3,0-0.5,0.1-0.7,0.2c-0.1,0.1-0.2,0.4-0.2,0.8v0.6h1.2v0.8h-1.2v5.4H72.9z"/>
<path d="M77.3,39.5c-0.4-0.2-0.8-0.4-1-0.7c-0.2-0.3-0.3-0.7-0.3-1.1c0-0.6,0.2-1.1,0.7-1.6c0.5-0.4,1-0.6,1.8-0.6  c0.8,0,1.4,0.2,1.8,0.7c0.5,0.4,0.7,1,0.7,1.6c0,0.4-0.1,0.7-0.3,1c-0.2,0.3-0.5,0.5-1,0.7c0.5,0.2,0.9,0.4,1.2,0.8s0.4,0.8,0.4,1.4  c0,0.7-0.3,1.4-0.8,1.9s-1.2,0.8-2.1,0.8s-1.5-0.3-2.1-0.8c-0.5-0.5-0.8-1.1-0.8-1.9c0-0.6,0.1-1,0.4-1.4  C76.3,39.9,76.8,39.6,77.3,39.5z M76.7,41.6c0,0.3,0.1,0.6,0.2,0.9c0.1,0.3,0.4,0.5,0.6,0.7c0.3,0.2,0.6,0.2,0.9,0.2  c0.5,0,0.9-0.2,1.3-0.5s0.5-0.7,0.5-1.2c0-0.5-0.2-0.9-0.5-1.3s-0.8-0.5-1.3-0.5c-0.5,0-0.9,0.2-1.2,0.5S76.7,41.2,76.7,41.6z   M77.1,37.7c0,0.4,0.1,0.7,0.4,1c0.3,0.3,0.6,0.4,1,0.4c0.4,0,0.7-0.1,1-0.4c0.3-0.3,0.4-0.6,0.4-0.9c0-0.4-0.1-0.7-0.4-1  c-0.3-0.3-0.6-0.4-1-0.4c-0.4,0-0.7,0.1-1,0.4C77.2,37,77.1,37.3,77.1,37.7z"/>
<path d="M86.7,41.8l1,0.1c-0.1,0.7-0.4,1.3-0.9,1.7c-0.5,0.4-1,0.6-1.7,0.6c-0.9,0-1.5-0.3-2.1-0.8s-0.8-1.4-0.8-2.4  c0-0.7,0.1-1.3,0.3-1.8c0.2-0.5,0.6-0.9,1-1.1c0.5-0.3,1-0.4,1.5-0.4c0.7,0,1.2,0.2,1.7,0.5c0.4,0.3,0.7,0.8,0.8,1.5l-1,0.2  c-0.1-0.4-0.3-0.7-0.5-0.9c-0.2-0.2-0.5-0.3-0.9-0.3c-0.5,0-1,0.2-1.3,0.6s-0.5,1-0.5,1.8c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.3,0.6  c0.4,0,0.8-0.1,1-0.4C86.5,42.8,86.6,42.4,86.7,41.8z"/>
<path d="M88.4,39.9c0-1,0.1-1.8,0.3-2.5c0.2-0.6,0.5-1.1,0.9-1.4c0.4-0.3,0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3s0.6,0.5,0.9,0.8  s0.4,0.8,0.5,1.3c0.1,0.5,0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4c-0.2,0.6-0.5,1.1-0.9,1.4c-0.4,0.3-0.9,0.5-1.6,0.5  c-0.8,0-1.5-0.3-2-0.9C88.6,42.7,88.4,41.5,88.4,39.9z M89.4,39.9c0,1.4,0.2,2.3,0.5,2.8s0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7  s0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8s-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C89.6,37.5,89.4,38.5,89.4,39.9z"/>
<path d="M95.6,44.1v-5.4h-0.9v-0.8h0.9v-0.7c0-0.4,0-0.7,0.1-0.9c0.1-0.3,0.3-0.5,0.5-0.7c0.3-0.2,0.6-0.3,1.1-0.3  c0.3,0,0.6,0,1,0.1l-0.2,0.9c-0.2,0-0.4-0.1-0.6-0.1c-0.3,0-0.5,0.1-0.7,0.2c-0.1,0.1-0.2,0.4-0.2,0.8v0.6h1.2v0.8h-1.2v5.4H95.6z"/>
<path d="M50.9,57.6l-2.4-6.2h1.1l1.3,3.7c0.1,0.4,0.3,0.8,0.4,1.3c0.1-0.3,0.2-0.7,0.4-1.2l1.4-3.8h1.1l-2.4,6.2H50.9z"/>
<path d="M59.5,55.6l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5s-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8c-0.5-0.6-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4c0.5-0.6,1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8c0.5,0.6,0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.7  c0,0.7,0.2,1.2,0.6,1.6c0.3,0.4,0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3S59.3,56.1,59.5,55.6z M56,53.9h3.5c0-0.5-0.2-0.9-0.4-1.2  c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5S56,53.4,56,53.9z"/>
<path d="M61.9,57.6v-6.2h1v0.9c0.2-0.4,0.5-0.7,0.7-0.9s0.4-0.2,0.7-0.2c0.4,0,0.7,0.1,1.1,0.3l-0.4,1c-0.3-0.2-0.5-0.2-0.8-0.2  c-0.2,0-0.4,0.1-0.6,0.2c-0.2,0.1-0.3,0.3-0.4,0.6c-0.1,0.4-0.2,0.8-0.2,1.2v3.3H61.9z"/>
<path d="M65.9,50.2V49H67v1.2H65.9z M65.9,57.6v-6.2H67v6.2H65.9z"/>
<path d="M68.8,57.6v-5.4h-0.9v-0.8h0.9v-0.7c0-0.4,0-0.7,0.1-0.9c0.1-0.3,0.3-0.5,0.5-0.7c0.3-0.2,0.6-0.3,1.1-0.3  c0.3,0,0.6,0,1,0.1l-0.2,0.9c-0.2,0-0.4-0.1-0.6-0.1c-0.3,0-0.5,0.1-0.7,0.2c-0.1,0.1-0.2,0.4-0.2,0.8v0.6h1.2v0.8h-1.2v5.4H68.8z"/>
<path d="M71.9,50.2V49H73v1.2H71.9z M71.9,57.6v-6.2H73v6.2H71.9z"/>
<path d="M78.9,55.6l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5s-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8c-0.5-0.6-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4c0.5-0.6,1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8c0.5,0.6,0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.7  c0,0.7,0.2,1.2,0.6,1.6c0.3,0.4,0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3S78.7,56.1,78.9,55.6z M75.4,53.9h3.5c0-0.5-0.2-0.9-0.4-1.2  c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5S75.4,53.4,75.4,53.9z"/>
<path d="M85.3,57.6v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4c-0.4-0.3-0.7-0.7-1-1.1c-0.2-0.5-0.3-1.1-0.3-1.7  c0-0.6,0.1-1.2,0.3-1.7s0.5-0.9,0.9-1.2c0.4-0.3,0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6V49h1.1v8.6H85.3z M82,54.5  c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C82.1,53.1,82,53.7,82,54.5z"/>
<path d="M88.1,57.6V49h3.2c0.7,0,1.2,0.1,1.6,0.3c0.4,0.2,0.7,0.4,0.9,0.8c0.2,0.4,0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1  c-0.2,0.3-0.5,0.6-0.9,0.8c0.5,0.2,0.9,0.4,1.2,0.8c0.3,0.4,0.4,0.8,0.4,1.3c0,0.4-0.1,0.8-0.3,1.1s-0.4,0.6-0.6,0.8  c-0.3,0.2-0.6,0.3-0.9,0.4s-0.8,0.1-1.4,0.1H88.1z M89.2,52.6h1.9c0.5,0,0.9,0,1.1-0.1c0.3-0.1,0.5-0.2,0.7-0.4s0.2-0.4,0.2-0.8  c0-0.3-0.1-0.5-0.2-0.8s-0.3-0.4-0.6-0.4c-0.3-0.1-0.7-0.1-1.3-0.1h-1.7V52.6z M89.2,56.6h2.1c0.4,0,0.6,0,0.8,0  c0.3,0,0.5-0.1,0.7-0.2s0.3-0.3,0.4-0.5c0.1-0.2,0.2-0.5,0.2-0.7c0-0.3-0.1-0.6-0.2-0.8s-0.4-0.4-0.7-0.5s-0.7-0.1-1.3-0.1h-2V56.6z  "/>
<path d="M96,60l-0.1-1c0.2,0.1,0.4,0.1,0.6,0.1c0.2,0,0.4,0,0.6-0.1c0.1-0.1,0.3-0.2,0.3-0.3c0.1-0.1,0.2-0.4,0.3-0.8  c0-0.1,0.1-0.1,0.1-0.3l-2.4-6.2h1.1l1.3,3.6c0.2,0.5,0.3,0.9,0.5,1.4c0.1-0.5,0.3-1,0.4-1.4l1.3-3.6h1.1l-2.4,6.3  c-0.3,0.7-0.5,1.2-0.6,1.4c-0.2,0.3-0.4,0.6-0.6,0.8c-0.2,0.2-0.5,0.2-0.9,0.2C96.4,60.2,96.2,60.1,96,60z"/>
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
27840350 ENCRYPTED
~~~

### Mermaid

<artwork type="svg"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.2" baseProfile="tiny" width="160.8px" height="94.2px" viewBox="0 0 160.8 94.2" xml:space="preserve">
<path d="M25.1,67h3.7v2.2h-3.7V67z M30.2,64.7l-2.6,2.7l-1.6-1.6l2.6-2.7L30.2,64.7z M35.5,59.4L32.8,62l-1.6-1.6l2.6-2.7L35.5,59.4  z M40.7,54.1l-2.6,2.7l-1.6-1.6l2.6-2.7L40.7,54.1z M46,48.8l-2.6,2.7l-1.6-1.6l2.6-2.7L46,48.8z M42.5,41.9l2.6,2.7l-1.6,1.6  l-2.6-2.7L42.5,41.9z M37.2,36.6l2.6,2.7l-1.6,1.6l-2.6-2.7L37.2,36.6z M31.9,31.3l2.6,2.7l-1.6,1.6l-2.6-2.7L31.9,31.3z M26.6,26  l2.6,2.7l-1.6,1.6L25,27.6L26.6,26z M31.7,27.2H28V25h3.7V27.2z M39.2,27.2h-3.7V25h3.7V27.2z M46.7,27.2h-3.7V25h3.7V27.2z   M54.2,27.2h-3.7V25h3.7V27.2z M61.6,27.2h-3.7V25h3.7V27.2z M69.1,27.2h-3.7V25h3.7V27.2z M76.6,27.2h-3.7V25h3.7V27.2z M84.1,27.2  h-3.7V25h3.7V27.2z M91.6,27.2h-3.7V25h3.7V27.2z M99.1,27.2h-3.7V25h3.7V27.2z M106.5,27.2h-3.7V25h3.7V27.2z M114,27.2h-3.7V25  h3.7V27.2z M121.5,27.2h-3.7V25h3.7V27.2z M129,27.2h-3.7V25h3.7V27.2z M133.6,27.9v-1.8h1.1v1.1h-2V25h3.1v2.9H133.6z M133.6,35.4  v-3.8h2.2v3.8H133.6z M133.6,42.9v-3.8h2.2v3.8H133.6z M133.6,50.4v-3.8h2.2v3.8H133.6z M133.6,57.9v-3.8h2.2v3.8H133.6z   M133.6,65.4v-3.8h2.2v3.8H133.6z M129.9,67h3.7v2.2h-3.7V67z M122.4,67h3.7v2.2h-3.7V67z M114.9,67h3.7v2.2h-3.7V67z M107.5,67h3.7  v2.2h-3.7V67z M100,67h3.7v2.2H100V67z M92.5,67h3.7v2.2h-3.7V67z M85,67h3.7v2.2H85V67z M77.5,67h3.7v2.2h-3.7V67z M70,67h3.7v2.2  H70V67z M62.6,67h3.7v2.2h-3.7V67z M55.1,67h3.7v2.2h-3.7V67z M47.6,67h3.7v2.2h-3.7V67z M40.1,67h3.7v2.2h-3.7V67z M32.6,67h3.7  v2.2h-3.7V67z"/>
<path d="M69.8,43.1v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1c0.3-0.4,0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8  s0.5-0.9,0.5-1.3c0-0.4-0.1-0.8-0.4-1.1c-0.3-0.3-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5c-0.3,0.3-0.5,0.7-0.5,1.3L64.3,38  c0.1-0.8,0.4-1.4,0.8-1.8s1.1-0.6,1.9-0.6c0.8,0,1.5,0.2,2,0.7c0.5,0.5,0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1c-0.1,0.3-0.4,0.7-0.7,1  c-0.3,0.4-0.9,0.9-1.6,1.5c-0.6,0.5-1,0.9-1.2,1.1s-0.3,0.4-0.4,0.6H69.8z"/>
<path d="M71,36.7v-1h5.5v0.8c-0.5,0.6-1.1,1.4-1.6,2.3c-0.5,1-0.9,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  s0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H71z"/>
<path d="M79.2,39.5c-0.4-0.2-0.8-0.4-1-0.7s-0.3-0.7-0.3-1.1c0-0.6,0.2-1.2,0.7-1.6c0.4-0.4,1-0.6,1.8-0.6c0.7,0,1.4,0.2,1.8,0.7  s0.7,1,0.7,1.6c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-0.9,0.7c0.5,0.2,0.9,0.4,1.2,0.8c0.3,0.4,0.4,0.8,0.4,1.4c0,0.7-0.3,1.4-0.8,1.9  c-0.5,0.5-1.2,0.8-2,0.8c-0.8,0-1.5-0.3-2-0.8c-0.5-0.5-0.8-1.1-0.8-1.9c0-0.6,0.1-1,0.4-1.4C78.3,39.9,78.7,39.6,79.2,39.5z   M78.6,41.6c0,0.3,0.1,0.6,0.2,0.9s0.4,0.5,0.6,0.7s0.6,0.2,0.9,0.2c0.5,0,0.9-0.2,1.2-0.5c0.3-0.3,0.5-0.7,0.5-1.2  c0-0.5-0.2-0.9-0.5-1.3c-0.3-0.3-0.8-0.5-1.3-0.5c-0.5,0-0.9,0.2-1.2,0.5C78.8,40.7,78.6,41.2,78.6,41.6z M79,37.7  c0,0.4,0.1,0.7,0.4,1c0.3,0.3,0.6,0.4,1,0.4c0.4,0,0.7-0.1,1-0.4c0.3-0.3,0.4-0.6,0.4-0.9c0-0.4-0.1-0.7-0.4-1  c-0.3-0.3-0.6-0.4-1-0.4c-0.4,0-0.7,0.1-1,0.4C79.1,37,79,37.3,79,37.7z"/>
<path d="M87.6,44.1v-2.1h-3.7v-1l3.9-5.6h0.9v5.6h1.2v1h-1.2v2.1H87.6z M87.6,41.1v-3.9l-2.7,3.9H87.6z"/>
<path d="M90.9,39.9c0-1,0.1-1.8,0.3-2.5s0.5-1.1,0.9-1.4s0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3c0.3,0.2,0.6,0.5,0.9,0.8  c0.2,0.3,0.4,0.8,0.5,1.3s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-1.9-0.9  C91.2,42.7,90.9,41.5,90.9,39.9z M92,39.9c0,1.4,0.2,2.3,0.5,2.8c0.3,0.5,0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7  c0.3-0.5,0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8c-0.3-0.5-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C92.1,37.5,92,38.5,92,39.9z"/>
<path d="M97.5,41.9l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3c0.3,0.3,0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5c0.3-0.3,0.5-0.8,0.5-1.3  c0-0.5-0.2-0.9-0.5-1.2c-0.3-0.3-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1l0.1-0.9c0.1,0,0.1,0,0.2,0c0.4,0,0.9-0.1,1.2-0.4  s0.5-0.6,0.5-1.1c0-0.4-0.1-0.7-0.4-1s-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4s-0.4,0.6-0.5,1.2l-1.1-0.2c0.1-0.7,0.4-1.3,0.9-1.6  c0.5-0.4,1-0.6,1.7-0.6c0.5,0,0.9,0.1,1.3,0.3s0.7,0.5,0.9,0.8s0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-0.9,0.7  c0.5,0.1,0.9,0.4,1.2,0.7c0.3,0.4,0.4,0.8,0.4,1.4c0,0.8-0.3,1.4-0.8,1.9c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7  C97.9,43.2,97.6,42.6,97.5,41.9z"/>
<path d="M104.2,41.9l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2c0.3,0.3,0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6c0.4-0.4,0.5-0.9,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.3-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2c-0.3,0.2-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4  l-0.5,2.3c0.5-0.4,1.1-0.5,1.6-0.5c0.7,0,1.4,0.3,1.9,0.8c0.5,0.5,0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.5,0.7-1.3,1-2.3,1  c-0.8,0-1.4-0.2-1.9-0.7C104.5,43.2,104.3,42.6,104.2,41.9z"/>
<path d="M110.9,39.9c0-1,0.1-1.8,0.3-2.5s0.5-1.1,0.9-1.4s0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3c0.3,0.2,0.6,0.5,0.9,0.8  c0.2,0.3,0.4,0.8,0.5,1.3s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-1.9-0.9  C111.1,42.7,110.9,41.5,110.9,39.9z M111.9,39.9c0,1.4,0.2,2.3,0.5,2.8c0.3,0.5,0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7  c0.3-0.5,0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8c-0.3-0.5-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C112.1,37.5,111.9,38.5,111.9,39.9  z"/>
<path d="M54.5,57.6V49h6.2v1h-5.1v2.6h4.7v1h-4.7v2.9h5.3v1H54.5z"/>
<path d="M62.5,57.6V49h1.2l4.5,6.7V49h1.1v8.6h-1.2l-4.5-6.8v6.8H62.5z"/>
<path d="M77.2,54.6l1.1,0.3c-0.2,0.9-0.7,1.6-1.3,2.1s-1.4,0.7-2.3,0.7c-0.9,0-1.7-0.2-2.3-0.6s-1-0.9-1.3-1.6  c-0.3-0.7-0.5-1.5-0.5-2.3c0-0.9,0.2-1.7,0.5-2.3c0.3-0.7,0.8-1.2,1.5-1.5s1.3-0.5,2.1-0.5c0.9,0,1.6,0.2,2.2,0.7  c0.6,0.4,1,1.1,1.2,1.8l-1.1,0.3c-0.2-0.6-0.5-1.1-0.9-1.4s-0.9-0.4-1.4-0.4c-0.7,0-1.2,0.2-1.7,0.5s-0.8,0.7-0.9,1.3  S72,52.7,72,53.3c0,0.7,0.1,1.4,0.3,1.9s0.5,1,1,1.2c0.4,0.3,0.9,0.4,1.5,0.4c0.6,0,1.2-0.2,1.6-0.6C76.8,55.9,77.1,55.3,77.2,54.6z  "/>
<path d="M79.8,57.6V49h3.8c0.8,0,1.3,0.1,1.7,0.2s0.7,0.4,1,0.8s0.4,0.8,0.4,1.3c0,0.6-0.2,1.1-0.6,1.5s-1,0.7-1.8,0.8  c0.3,0.1,0.5,0.3,0.7,0.4c0.3,0.3,0.6,0.7,0.9,1.1l1.5,2.3h-1.4l-1.1-1.8c-0.3-0.5-0.6-0.9-0.8-1.2s-0.4-0.5-0.6-0.6  c-0.2-0.1-0.3-0.2-0.5-0.2c-0.1,0-0.3,0-0.6,0h-1.3v3.8H79.8z M80.9,52.8h2.4c0.5,0,0.9-0.1,1.2-0.2c0.3-0.1,0.5-0.3,0.7-0.5  c0.2-0.2,0.2-0.5,0.2-0.8c0-0.4-0.1-0.7-0.4-1c-0.3-0.3-0.8-0.4-1.4-0.4h-2.7V52.8z"/>
<path d="M90.6,57.6V54l-3.3-5h1.4l1.7,2.6c0.3,0.5,0.6,1,0.9,1.5c0.3-0.4,0.6-1,0.9-1.5l1.7-2.5h1.3l-3.4,5v3.6H90.6z"/>
<path d="M96.2,57.6V49h3.2c0.6,0,1,0,1.3,0.1c0.4,0.1,0.8,0.2,1.1,0.4c0.3,0.2,0.5,0.5,0.7,0.8s0.3,0.7,0.3,1.2  c0,0.7-0.2,1.3-0.7,1.9c-0.5,0.5-1.3,0.8-2.5,0.8h-2.2v3.5H96.2z M97.3,53.1h2.2c0.7,0,1.3-0.1,1.6-0.4c0.3-0.3,0.5-0.7,0.5-1.2  c0-0.4-0.1-0.7-0.3-0.9s-0.4-0.4-0.7-0.5c-0.2-0.1-0.5-0.1-1.1-0.1h-2.2V53.1z"/>
<path d="M106.4,57.6V50h-2.8v-1h6.8v1h-2.8v7.6H106.4z"/>
<path d="M111.5,57.6V49h6.2v1h-5.1v2.6h4.7v1h-4.7v2.9h5.3v1H111.5z"/>
<path d="M119.5,57.6V49h3c0.7,0,1.2,0,1.5,0.1c0.5,0.1,0.9,0.3,1.3,0.6c0.5,0.4,0.8,0.9,1,1.5s0.3,1.3,0.3,2c0,0.7-0.1,1.2-0.2,1.7  c-0.2,0.5-0.3,0.9-0.6,1.3c-0.2,0.3-0.5,0.6-0.8,0.8c-0.3,0.2-0.6,0.3-1,0.4s-0.9,0.1-1.4,0.1H119.5z M120.6,56.6h1.8  c0.6,0,1-0.1,1.3-0.2c0.3-0.1,0.6-0.3,0.8-0.4c0.3-0.3,0.5-0.6,0.6-1.1s0.2-1,0.2-1.7c0-0.9-0.1-1.6-0.4-2.1c-0.3-0.5-0.7-0.8-1.1-1  c-0.3-0.1-0.8-0.2-1.5-0.2h-1.8V56.6z"/>
</svg></artwork>

### CBOR Diagnostic Notation

~~~
200(   ; envelope
   201(   ; crypto-msg
      [
         h'6bfa027df241def0',
         h'5520ca6d9d798ffd32d075c4',
         h'd4b43d97a37eb280fdd89cf152ccf57d',
         h'd8cb5820278403504ad3a9a9c24c1b35a3673eee165a5d52\
         3f8d2a5cf5ce6dd25a37f110'
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
27840350 ELIDED
~~~

### Mermaid

<artwork type="svg"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.2" baseProfile="tiny" width="141.1px" height="94.2px" viewBox="0 0 141.1 94.2" xml:space="preserve">
<path d="M36.1,67h3.7v2.2h-3.7V67z M34.5,62.5l1.7,3.4l-2,1l-1.7-3.4L34.5,62.5z M31.2,55.8l1.7,3.4l-2,1l-1.7-3.4L31.2,55.8z   M27.8,49.1l1.7,3.4l-2,1l-1.7-3.4L27.8,49.1z M28.7,43.4L27,46.8l-2-1l1.7-3.4L28.7,43.4z M32,36.7l-1.7,3.4l-2-1l1.7-3.4L32,36.7z   M35.4,30l-1.7,3.4l-2-1l1.7-3.4L35.4,30z M39.8,27.2h-3.7v-1.1l1,0.5l0,0l-2-1l0.3-0.6h4.4V27.2z M47.3,27.2h-3.7V25h3.7V27.2z   M54.8,27.2H51V25h3.7V27.2z M62.3,27.2h-3.7V25h3.7V27.2z M69.8,27.2H66V25h3.7V27.2z M77.2,27.2h-3.7V25h3.7V27.2z M84.7,27.2H81  V25h3.7V27.2z M92.2,27.2h-3.7V25h3.7V27.2z M99.7,27.2H96V25h3.7V27.2z M104.6,29.2l-1.3-2.5l1-0.5v1.1h-0.9V25h1.6l1.6,3.2  L104.6,29.2z M108,35.9l-1.7-3.4l2-1l1.7,3.4L108,35.9z M111.3,42.6l-1.7-3.4l2-1l1.7,3.4L111.3,42.6z M113,48.3l0.8-1.7l1,0.5  l-1,0.5l-0.8-1.7l2-1l1.1,2.2l-1.1,2.2L113,48.3z M109.7,55l1.7-3.4l2,1l-1.7,3.4L109.7,55z M106.3,61.7l1.7-3.4l2,1l-1.7,3.4  L106.3,61.7z M103.5,67h0.9v1.1l-1-0.5l1.3-2.6l2,1l-1.6,3.2h-1.6V67z M96,67h3.7v2.2H96V67z M88.5,67h3.7v2.2h-3.7V67z M81,67h3.7  v2.2H81V67z M73.5,67h3.7v2.2h-3.7V67z M66,67h3.7v2.2H66V67z M58.5,67h3.7v2.2h-3.7V67z M51,67h3.7v2.2H51V67z M43.5,67h3.7v2.2  h-3.7V67z"/>
<path d="M49.6,43.1v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1c0.3-0.4,0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8  s0.5-0.9,0.5-1.3c0-0.4-0.1-0.8-0.4-1.1s-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5s-0.5,0.7-0.5,1.3L44.1,38c0.1-0.8,0.4-1.4,0.8-1.8  s1.1-0.6,1.9-0.6c0.8,0,1.5,0.2,2,0.7s0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1c-0.1,0.3-0.4,0.7-0.7,1s-0.9,0.9-1.6,1.5  c-0.6,0.5-1,0.9-1.2,1.1c-0.2,0.2-0.3,0.4-0.4,0.6H49.6z"/>
<path d="M50.8,36.7v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3c-0.5,1-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4H52c0-0.7,0.1-1.5,0.4-2.4  c0.3-1,0.6-1.9,1.1-2.8c0.5-0.9,1-1.6,1.5-2.2H50.8z"/>
<path d="M59,39.5c-0.4-0.2-0.8-0.4-1-0.7c-0.2-0.3-0.3-0.7-0.3-1.1c0-0.6,0.2-1.2,0.7-1.6c0.4-0.4,1-0.6,1.8-0.6  c0.7,0,1.4,0.2,1.8,0.7c0.5,0.4,0.7,1,0.7,1.6c0,0.4-0.1,0.7-0.3,1c-0.2,0.3-0.5,0.5-1,0.7c0.5,0.2,0.9,0.4,1.2,0.8  c0.3,0.4,0.4,0.8,0.4,1.4c0,0.7-0.3,1.4-0.8,1.9c-0.5,0.5-1.2,0.8-2,0.8c-0.8,0-1.5-0.3-2-0.8c-0.5-0.5-0.8-1.1-0.8-1.9  c0-0.6,0.1-1,0.4-1.4C58.1,39.9,58.5,39.6,59,39.5z M58.4,41.6c0,0.3,0.1,0.6,0.2,0.9c0.1,0.3,0.4,0.5,0.6,0.7s0.6,0.2,0.9,0.2  c0.5,0,0.9-0.2,1.2-0.5s0.5-0.7,0.5-1.2c0-0.5-0.2-0.9-0.5-1.3s-0.8-0.5-1.3-0.5c-0.5,0-0.9,0.2-1.2,0.5S58.4,41.2,58.4,41.6z   M58.8,37.7c0,0.4,0.1,0.7,0.4,1c0.3,0.3,0.6,0.4,1,0.4c0.4,0,0.7-0.1,1-0.4c0.3-0.3,0.4-0.6,0.4-0.9c0-0.4-0.1-0.7-0.4-1  c-0.3-0.3-0.6-0.4-1-0.4c-0.4,0-0.7,0.1-1,0.4C58.9,37,58.8,37.3,58.8,37.7z"/>
<path d="M67.4,44.1v-2.1h-3.7v-1l3.9-5.6h0.9v5.6h1.2v1h-1.2v2.1H67.4z M67.4,41.1v-3.9l-2.7,3.9H67.4z"/>
<path d="M70.7,39.9c0-1,0.1-1.8,0.3-2.5c0.2-0.6,0.5-1.1,0.9-1.4s0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3s0.6,0.5,0.9,0.8  c0.2,0.3,0.4,0.8,0.5,1.3c0.1,0.5,0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4c-0.2,0.6-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5  c-0.8,0-1.5-0.3-1.9-0.9C71,42.7,70.7,41.5,70.7,39.9z M71.8,39.9c0,1.4,0.2,2.3,0.5,2.8s0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7  s0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8s-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C72,37.5,71.8,38.5,71.8,39.9z"/>
<path d="M77.4,41.9l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3s0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5s0.5-0.8,0.5-1.3c0-0.5-0.2-0.9-0.5-1.2  s-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1l0.1-0.9c0.1,0,0.1,0,0.2,0c0.4,0,0.9-0.1,1.2-0.4s0.5-0.6,0.5-1.1c0-0.4-0.1-0.7-0.4-1  s-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4c-0.3,0.3-0.4,0.6-0.5,1.2l-1.1-0.2c0.1-0.7,0.4-1.3,0.9-1.6c0.5-0.4,1-0.6,1.7-0.6  c0.5,0,0.9,0.1,1.3,0.3s0.7,0.5,0.9,0.8c0.2,0.3,0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1c-0.2,0.3-0.5,0.5-0.9,0.7  c0.5,0.1,0.9,0.4,1.2,0.7S83,41,83,41.6c0,0.8-0.3,1.4-0.8,1.9c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7  C77.7,43.2,77.4,42.6,77.4,41.9z"/>
<path d="M84,41.9l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2s0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6s0.5-0.9,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4  s-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2c-0.3,0.2-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4L85.4,39c0.5-0.4,1.1-0.5,1.6-0.5  c0.7,0,1.4,0.3,1.9,0.8c0.5,0.5,0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.5,0.7-1.3,1-2.3,1c-0.8,0-1.4-0.2-1.9-0.7S84.1,42.6,84,41.9z  "/>
<path d="M90.7,39.9c0-1,0.1-1.8,0.3-2.5c0.2-0.6,0.5-1.1,0.9-1.4s0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3s0.6,0.5,0.9,0.8  c0.2,0.3,0.4,0.8,0.5,1.3c0.1,0.5,0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4c-0.2,0.6-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5  c-0.8,0-1.5-0.3-1.9-0.9C91,42.7,90.7,41.5,90.7,39.9z M91.8,39.9c0,1.4,0.2,2.3,0.5,2.8s0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7  s0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8s-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C92,37.5,91.8,38.5,91.8,39.9z"/>
<path d="M49.5,57.6V49h6.2v1h-5.1v2.6h4.7v1h-4.7v2.9h5.3v1H49.5z"/>
<path d="M57.4,57.6V49h1.1v7.6h4.2v1H57.4z"/>
<path d="M64.3,57.6V49h1.1v8.6H64.3z"/>
<path d="M67.5,57.6V49h3c0.7,0,1.2,0,1.5,0.1c0.5,0.1,0.9,0.3,1.3,0.6c0.5,0.4,0.8,0.9,1,1.5s0.3,1.3,0.3,2c0,0.7-0.1,1.2-0.2,1.7  c-0.2,0.5-0.3,0.9-0.6,1.3c-0.2,0.3-0.5,0.6-0.8,0.8c-0.3,0.2-0.6,0.3-1,0.4c-0.4,0.1-0.9,0.1-1.4,0.1H67.5z M68.6,56.6h1.8  c0.6,0,1-0.1,1.3-0.2s0.6-0.3,0.8-0.4c0.3-0.3,0.5-0.6,0.6-1.1c0.2-0.5,0.2-1,0.2-1.7c0-0.9-0.1-1.6-0.4-2.1c-0.3-0.5-0.7-0.8-1.1-1  c-0.3-0.1-0.8-0.2-1.5-0.2h-1.8V56.6z"/>
<path d="M76.1,57.6V49h6.2v1h-5.1v2.6H82v1h-4.7v2.9h5.3v1H76.1z"/>
<path d="M84.1,57.6V49h3c0.7,0,1.2,0,1.5,0.1c0.5,0.1,0.9,0.3,1.3,0.6c0.5,0.4,0.8,0.9,1,1.5s0.3,1.3,0.3,2c0,0.7-0.1,1.2-0.2,1.7  c-0.2,0.5-0.3,0.9-0.6,1.3c-0.2,0.3-0.5,0.6-0.8,0.8c-0.3,0.2-0.6,0.3-1,0.4c-0.4,0.1-0.9,0.1-1.4,0.1H84.1z M85.2,56.6h1.8  c0.6,0,1-0.1,1.3-0.2s0.6-0.3,0.8-0.4c0.3-0.3,0.5-0.6,0.6-1.1c0.2-0.5,0.2-1,0.2-1.7c0-0.9-0.1-1.6-0.4-2.1c-0.3-0.5-0.7-0.8-1.1-1  c-0.3-0.1-0.8-0.2-1.5-0.2h-1.8V56.6z"/>
</svg></artwork>

### CBOR Diagnostic Notation

~~~
200(   ; envelope
   203(   ; crypto-digest
      h'278403504ad3a9a9c24c1b35a3673eee165a5d523f8d2a5cf5ce6dd25a37\
      f110'
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
e54d6fd3 NODE
    27840350 subj "Alice"
    55560bdf ASSERTION
        7092d620 pred "knows"
        9a771715 obj "Bob"
~~~

### Mermaid

<artwork type="svg"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.2" baseProfile="tiny" width="520.2px" height="213.5px" viewBox="0 0 520.2 213.5" xml:space="preserve">
<path fill="none" stroke="#000000" stroke-width="1.5002" d="M86.1,69.4l5.8-3.7c5.8-3.7,17.4-11.1,28.2-14.8  c10.8-3.7,20.7-3.7,25.7-3.7h5"/>
<polygon fill="black" points="142.6,42.6 151.6,47.1 142.6,51.6 "/>
<rect x="141.1" y="42.6" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.5002" d="M86.1,104.4l5.8,3.7c5.8,3.7,17.4,11.1,31.7,14.8  c14.3,3.7,31.3,3.7,39.7,3.7h8.5"/>
<polygon fill="black" points="163.8,122.1 172.8,126.6 163.8,131.1 "/>
<rect x="162.3" y="122.1" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.5002" d="M266.5,107.7l8.7-3.5c8.7-3.5,26-10.4,39.7-13.9  c13.8-3.5,24-3.5,29.2-3.5h5.1"/>
<polygon fill="black" points="341.1,82.4 350.1,86.9 341.1,91.4 "/>
<rect x="339.6" y="82.4" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.5002" d="M266.5,145.6l8.7,3.5c8.7,3.5,26,10.4,40.8,13.9  c14.8,3.5,27.2,3.5,33.4,3.5h6.2"/>
<polygon fill="black" points="347.4,161.9 356.4,166.4 347.4,170.9 "/>
<rect x="345.9" y="161.9" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path d="M110.3,49l1-0.2c0.1,0.4,0.2,0.7,0.5,1s0.6,0.3,1.1,0.3c0.5,0,0.8-0.1,1.1-0.3s0.4-0.4,0.4-0.7c0-0.2-0.1-0.4-0.3-0.6  c-0.1-0.1-0.5-0.2-1.1-0.4c-0.8-0.2-1.3-0.4-1.6-0.5s-0.5-0.3-0.7-0.6c-0.2-0.3-0.2-0.5-0.2-0.8c0-0.3,0.1-0.5,0.2-0.8  s0.3-0.4,0.5-0.6c0.2-0.1,0.4-0.2,0.7-0.3s0.6-0.1,0.9-0.1c0.5,0,0.9,0.1,1.3,0.2c0.4,0.1,0.6,0.3,0.8,0.6s0.3,0.6,0.4,1l-1,0.1  c0-0.3-0.2-0.6-0.4-0.8c-0.2-0.2-0.5-0.3-1-0.3c-0.5,0-0.8,0.1-1,0.2s-0.3,0.3-0.3,0.6c0,0.1,0,0.3,0.1,0.4c0.1,0.1,0.2,0.2,0.4,0.3  c0.1,0,0.4,0.1,0.9,0.3c0.7,0.2,1.3,0.4,1.6,0.5s0.5,0.3,0.7,0.6s0.3,0.5,0.3,0.9c0,0.4-0.1,0.7-0.3,1c-0.2,0.3-0.5,0.6-0.9,0.7  S113.5,51,113,51c-0.8,0-1.4-0.2-1.8-0.5C110.7,50.2,110.4,49.7,110.3,49z"/>
<path d="M120.8,50.9V50c-0.5,0.7-1.1,1.1-2,1.1c-0.4,0-0.7-0.1-1-0.2s-0.6-0.3-0.7-0.5s-0.3-0.5-0.3-0.8c0-0.2-0.1-0.5-0.1-1v-3.9  h1.1v3.5c0,0.6,0,0.9,0.1,1.1c0.1,0.3,0.2,0.5,0.4,0.7c0.2,0.2,0.5,0.2,0.8,0.2s0.6-0.1,0.9-0.2c0.3-0.2,0.5-0.4,0.6-0.7  s0.2-0.7,0.2-1.2v-3.3h1.1v6.2H120.8z"/>
<path d="M124.4,50.9h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5c-0.5,0.6-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V50.9z M124.4,47.7c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  C124.6,46.4,124.4,47,124.4,47.7z"/>
<path d="M128.8,53.3l0.2-0.9c0.2,0.1,0.4,0.1,0.5,0.1c0.2,0,0.4-0.1,0.5-0.2s0.2-0.5,0.2-1.1v-6.5h1.1v6.6c0,0.8-0.1,1.3-0.3,1.6  c-0.3,0.4-0.7,0.6-1.3,0.6C129.3,53.4,129,53.4,128.8,53.3z M130.1,43.5v-1.2h1.1v1.2H130.1z"/>
<rect x="110" y="40.4" fill-rule="evenodd" fill="none" width="21.8" height="13.5"/>
<path d="M307.2,93v-8.6h1v0.8c0.2-0.3,0.5-0.6,0.8-0.7c0.3-0.2,0.6-0.2,1-0.2c0.5,0,1,0.1,1.4,0.4s0.7,0.7,0.9,1.2s0.3,1,0.3,1.6  c0,0.6-0.1,1.2-0.3,1.7s-0.6,0.9-1,1.2s-0.9,0.4-1.4,0.4c-0.4,0-0.7-0.1-0.9-0.2c-0.3-0.1-0.5-0.3-0.7-0.6v3H307.2z M308.2,87.5  c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6  c-0.4,0-0.8,0.2-1.2,0.6C308.3,86.1,308.2,86.7,308.2,87.5z"/>
<path d="M313.9,90.6v-6.2h0.9v0.9c0.2-0.4,0.5-0.7,0.7-0.9c0.2-0.1,0.4-0.2,0.7-0.2c0.4,0,0.7,0.1,1.1,0.3l-0.4,1  c-0.3-0.2-0.5-0.2-0.8-0.2c-0.2,0-0.4,0.1-0.6,0.2c-0.2,0.1-0.3,0.3-0.4,0.6c-0.1,0.4-0.2,0.8-0.2,1.2v3.3H313.9z"/>
<path d="M322.1,88.6l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5s-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8c-0.5-0.6-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4c0.5-0.6,1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8s0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6c0,0.7,0.2,1.2,0.6,1.6  c0.3,0.4,0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3S322,89.1,322.1,88.6z M318.7,86.9h3.5c0-0.5-0.2-0.9-0.4-1.2  c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5C318.9,85.9,318.7,86.4,318.7,86.9z"/>
<path d="M328.6,90.6v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4c-0.4-0.3-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7  c0-0.6,0.1-1.2,0.3-1.7s0.5-0.9,0.9-1.2c0.4-0.3,0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6V82h1v8.6H328.6z M325.3,87.5  c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9  c-0.3-0.4-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6S325.3,86.7,325.3,87.5z"/>
<rect x="306.4" y="80.1" fill-rule="evenodd" fill="none" width="24" height="13.5"/>
<path d="M310.8,167c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8c0.5,0.6,0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  s-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8C311.1,168.9,310.8,168.1,310.8,167z M311.9,167c0,0.8,0.2,1.4,0.5,1.8  s0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7s-0.8-0.6-1.3-0.6c-0.5,0-1,0.2-1.3,0.6  S311.9,166.2,311.9,167z"/>
<path d="M318.9,170.1h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2c0.3,0.2,0.6,0.4,0.8,0.7s0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V170.1z M318.8,167c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8c-0.3-0.4-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C319,165.6,318.8,166.2,318.8,167z"/>
<path d="M323.2,172.5l0.2-0.9c0.2,0.1,0.4,0.1,0.5,0.1c0.2,0,0.4-0.1,0.5-0.2s0.2-0.5,0.2-1.1v-6.5h1.1v6.6c0,0.8-0.1,1.3-0.3,1.6  c-0.3,0.4-0.7,0.6-1.3,0.6C323.8,172.7,323.5,172.6,323.2,172.5z M324.6,162.8v-1.2h1.1v1.2H324.6z"/>
<rect x="310.4" y="159.6" fill-rule="evenodd" fill="none" width="15.8" height="13.5"/>
<path fill="none" stroke="#000000" stroke-width="2.2504" d="M91.2,86.9c0,1.1-0.1,2.1-0.2,3.2s-0.3,2.1-0.5,3.2  c-0.2,1-0.5,2.1-0.8,3.1c-0.3,1-0.7,2-1.1,3c-0.4,1-0.9,1.9-1.4,2.9c-0.5,0.9-1,1.9-1.6,2.7c-0.6,0.9-1.2,1.7-1.9,2.6  c-0.7,0.8-1.4,1.6-2.1,2.4c-0.8,0.8-1.5,1.5-2.4,2.1c-0.8,0.7-1.7,1.3-2.6,1.9c-0.9,0.6-1.8,1.1-2.7,1.6c-0.9,0.5-1.9,1-2.9,1.4  c-1,0.4-2,0.8-3,1.1c-1,0.3-2.1,0.6-3.1,0.8s-2.1,0.4-3.2,0.5c-1.1,0.1-2.1,0.2-3.2,0.2s-2.1-0.1-3.2-0.2c-1.1-0.1-2.1-0.3-3.2-0.5  c-1-0.2-2.1-0.5-3.1-0.8c-1-0.3-2-0.7-3-1.1s-1.9-0.9-2.9-1.4c-0.9-0.5-1.9-1-2.7-1.6c-0.9-0.6-1.7-1.2-2.6-1.9  c-0.8-0.7-1.6-1.4-2.4-2.1c-0.8-0.8-1.5-1.5-2.1-2.4c-0.7-0.8-1.3-1.7-1.9-2.6c-0.6-0.9-1.1-1.8-1.6-2.7c-0.5-0.9-1-1.9-1.4-2.9  c-0.4-1-0.8-2-1.1-3c-0.3-1-0.6-2.1-0.8-3.1c-0.2-1-0.4-2.1-0.5-3.2s-0.2-2.1-0.2-3.2c0-1.1,0.1-2.1,0.2-3.2s0.3-2.1,0.5-3.2  c0.2-1,0.5-2.1,0.8-3.1c0.3-1,0.7-2,1.1-3c0.4-1,0.9-1.9,1.4-2.9c0.5-0.9,1-1.9,1.6-2.7c0.6-0.9,1.2-1.7,1.9-2.6  c0.7-0.8,1.4-1.6,2.1-2.4c0.8-0.8,1.5-1.5,2.4-2.1c0.8-0.7,1.7-1.3,2.6-1.9c0.9-0.6,1.8-1.1,2.7-1.6c0.9-0.5,1.9-1,2.9-1.4  s2-0.8,3-1.1c1-0.3,2.1-0.6,3.1-0.8c1-0.2,2.1-0.4,3.2-0.5c1.1-0.1,2.1-0.2,3.2-0.2s2.1,0.1,3.2,0.2c1.1,0.1,2.1,0.3,3.2,0.5  s2.1,0.5,3.1,0.8c1,0.3,2,0.7,3,1.1c1,0.4,1.9,0.9,2.9,1.4c0.9,0.5,1.9,1,2.7,1.6c0.9,0.6,1.7,1.2,2.6,1.9c0.8,0.7,1.6,1.4,2.4,2.1  c0.8,0.8,1.5,1.5,2.1,2.4c0.7,0.8,1.3,1.7,1.9,2.6c0.6,0.9,1.1,1.8,1.6,2.7c0.5,0.9,1,1.9,1.4,2.9c0.4,1,0.8,2,1.1,3  c0.3,1,0.6,2.1,0.8,3.1c0.2,1,0.4,2.1,0.5,3.2S91.2,85.8,91.2,86.9z"/>
<path d="M38.7,81.9l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5C38.3,83.8,37.8,84,37,84c-0.9,0-1.6-0.3-2.2-0.8c-0.5-0.6-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4c0.5-0.6,1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8c0.5,0.6,0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6  c0,0.7,0.2,1.2,0.6,1.6c0.3,0.4,0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3S38.5,82.3,38.7,81.9z M35.2,80.2h3.5c0-0.5-0.2-0.9-0.4-1.2  c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5C35.4,79.2,35.3,79.6,35.2,80.2z"/>
<path d="M40.8,81.6l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2c0.3,0.3,0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6s0.5-0.9,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4s-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2c-0.3,0.2-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4l-0.5,2.3  c0.5-0.4,1.1-0.5,1.6-0.5c0.8,0,1.4,0.3,1.9,0.8c0.5,0.5,0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1  c-0.8,0-1.4-0.2-1.9-0.7C41.2,82.9,40.9,82.3,40.8,81.6z"/>
<path d="M50.9,83.9v-2.1h-3.7v-1l3.9-5.6h0.9v5.6h1.2v1h-1.2v2.1H50.9z M50.9,80.9V77l-2.7,3.9H50.9z"/>
<path d="M58.5,83.9v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1c-0.2-0.5-0.3-1.1-0.3-1.7  c0-0.6,0.1-1.2,0.3-1.7c0.2-0.5,0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6v-3.1h1v8.6H58.5z   M55.2,80.8c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6S55.2,79.9,55.2,80.8z"/>
<path d="M66.3,77.4l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  s-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9c0.4-0.2,0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8c0.5,0.5,0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5  s-0.6,0.8-1,1.1S64.3,84,63.8,84c-0.9,0-1.6-0.3-2.2-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6c0.5-0.7,1.3-1,2.2-1  c0.7,0,1.2,0.2,1.7,0.6C66,76.2,66.2,76.7,66.3,77.4z M62,81.1c0,0.4,0.1,0.7,0.2,1s0.4,0.6,0.6,0.8c0.3,0.2,0.6,0.3,0.9,0.3  c0.4,0,0.8-0.2,1.1-0.5s0.5-0.8,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.5S62,80.5,62,81.1z"/>
<path d="M68.1,83.9v-5.4h-0.9v-0.8h0.9V77c0-0.4,0-0.7,0.1-0.9c0.1-0.3,0.3-0.5,0.5-0.7s0.6-0.3,1.1-0.3c0.3,0,0.6,0,1,0.1l-0.2,0.9  c-0.2,0-0.4-0.1-0.6-0.1c-0.3,0-0.5,0.1-0.7,0.2s-0.2,0.4-0.2,0.8v0.6h1.2v0.8h-1.2v5.4H68.1z"/>
<path d="M75.2,83.9v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1c-0.2-0.5-0.3-1.1-0.3-1.7  c0-0.6,0.1-1.2,0.3-1.7c0.2-0.5,0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6v-3.1h1v8.6H75.2z   M71.8,80.8c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6S71.8,79.9,71.8,80.8z"/>
<path d="M77.5,81.6l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3s0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5s0.5-0.8,0.5-1.3c0-0.5-0.2-0.9-0.5-1.2  s-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1l0.1-0.9c0.1,0,0.1,0,0.2,0c0.4,0,0.9-0.1,1.2-0.4c0.4-0.2,0.5-0.6,0.5-1.1  c0-0.4-0.1-0.7-0.4-1s-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4s-0.4,0.6-0.5,1.2l-1.1-0.2c0.1-0.7,0.4-1.3,0.9-1.6s1-0.6,1.7-0.6  c0.5,0,0.9,0.1,1.3,0.3s0.7,0.5,0.9,0.8c0.2,0.3,0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1c-0.2,0.3-0.5,0.5-0.9,0.7  c0.5,0.1,0.9,0.4,1.2,0.7s0.4,0.8,0.4,1.4c0,0.8-0.3,1.4-0.8,1.9c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7  S77.6,82.3,77.5,81.6z"/>
<path d="M42.2,97.4v-8.6h1.2l4.5,6.7v-6.7H49v8.6h-1.2l-4.5-6.8v6.8H42.2z"/>
<path d="M50.6,93.2c0-1.4,0.4-2.5,1.1-3.3s1.8-1.2,3-1.2c0.8,0,1.5,0.2,2.1,0.6c0.6,0.4,1.1,0.9,1.5,1.6c0.3,0.7,0.5,1.4,0.5,2.3  c0,0.9-0.2,1.7-0.5,2.3c-0.4,0.7-0.8,1.2-1.5,1.6c-0.6,0.4-1.3,0.5-2.1,0.5c-0.8,0-1.5-0.2-2.2-0.6c-0.6-0.4-1.1-0.9-1.4-1.6  C50.7,94.7,50.6,93.9,50.6,93.2z M51.7,93.2c0,1,0.3,1.9,0.8,2.4c0.6,0.6,1.3,0.9,2.1,0.9c0.9,0,1.6-0.3,2.1-0.9  c0.6-0.6,0.8-1.5,0.8-2.6c0-0.7-0.1-1.3-0.4-1.8c-0.2-0.5-0.6-0.9-1-1.2s-1-0.4-1.5-0.4c-0.8,0-1.5,0.3-2.1,0.8  C52,91,51.7,91.9,51.7,93.2z"/>
<path d="M60.2,97.4v-8.6h3c0.7,0,1.2,0,1.5,0.1c0.5,0.1,0.9,0.3,1.3,0.6c0.5,0.4,0.8,0.9,1,1.5s0.3,1.3,0.3,2c0,0.7-0.1,1.2-0.2,1.7  s-0.3,0.9-0.6,1.3c-0.2,0.3-0.5,0.6-0.8,0.8s-0.6,0.3-1,0.4c-0.4,0.1-0.9,0.1-1.4,0.1H60.2z M61.4,96.4h1.8c0.6,0,1-0.1,1.3-0.2  c0.3-0.1,0.6-0.3,0.8-0.4c0.3-0.3,0.5-0.6,0.6-1.1s0.2-1,0.2-1.7c0-0.9-0.1-1.6-0.4-2.1s-0.7-0.8-1.1-1c-0.3-0.1-0.8-0.2-1.5-0.2  h-1.8V96.4z"/>
<path d="M68.9,97.4v-8.6h6.2v1h-5.1v2.6h4.8v1h-4.8v2.9h5.3v1H68.9z"/>
<rect x="33.6" y="73.4" fill-rule="evenodd" fill="none" width="50.3" height="27"/>
<rect x="150.7" y="26.1" fill="none" stroke="#000000" stroke-width="2.2504" width="136.9" height="42"/>
<path d="M198.5,43.1v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1c0.3-0.4,0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8  s0.5-0.9,0.5-1.3c0-0.4-0.1-0.8-0.4-1.1s-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5c-0.3,0.3-0.5,0.7-0.5,1.3l-1.1-0.1  c0.1-0.8,0.4-1.4,0.8-1.8s1.1-0.6,2-0.6c0.8,0,1.5,0.2,2,0.7c0.5,0.5,0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1s-0.4,0.7-0.7,1  s-0.9,0.9-1.6,1.5c-0.6,0.5-1,0.9-1.2,1.1s-0.3,0.4-0.4,0.6H198.5z"/>
<path d="M199.7,36.7v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  c0.3-1,0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H199.7z"/>
<path d="M208,39.5c-0.4-0.2-0.8-0.4-1-0.7s-0.3-0.7-0.3-1.1c0-0.6,0.2-1.2,0.7-1.6s1-0.6,1.8-0.6c0.8,0,1.4,0.2,1.8,0.7  c0.5,0.4,0.7,1,0.7,1.6c0,0.4-0.1,0.7-0.3,1c-0.2,0.3-0.5,0.5-1,0.7c0.5,0.2,0.9,0.4,1.2,0.8s0.4,0.8,0.4,1.4c0,0.7-0.3,1.4-0.8,1.9  c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.5-0.3-2.1-0.8c-0.5-0.5-0.8-1.1-0.8-1.9c0-0.6,0.1-1,0.4-1.4C207,39.9,207.4,39.6,208,39.5z   M207.4,41.6c0,0.3,0.1,0.6,0.2,0.9s0.4,0.5,0.6,0.7c0.3,0.2,0.6,0.2,0.9,0.2c0.5,0,0.9-0.2,1.2-0.5s0.5-0.7,0.5-1.2  c0-0.5-0.2-0.9-0.5-1.3s-0.8-0.5-1.3-0.5c-0.5,0-0.9,0.2-1.2,0.5S207.4,41.2,207.4,41.6z M207.8,37.7c0,0.4,0.1,0.7,0.4,1  c0.3,0.3,0.6,0.4,1,0.4c0.4,0,0.7-0.1,1-0.4s0.4-0.6,0.4-0.9c0-0.4-0.1-0.7-0.4-1s-0.6-0.4-1-0.4c-0.4,0-0.7,0.1-1,0.4  C207.9,37,207.8,37.3,207.8,37.7z"/>
<path d="M216.4,44.1v-2.1h-3.7v-1l3.9-5.6h0.9v5.6h1.2v1h-1.2v2.1H216.4z M216.4,41.1v-3.9l-2.7,3.9H216.4z"/>
<path d="M219.7,39.9c0-1,0.1-1.8,0.3-2.5c0.2-0.6,0.5-1.1,0.9-1.4s0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3s0.6,0.5,0.9,0.8  c0.2,0.3,0.4,0.8,0.5,1.3s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9  C220,42.7,219.7,41.5,219.7,39.9z M220.8,39.9c0,1.4,0.2,2.3,0.5,2.8c0.3,0.5,0.7,0.7,1.2,0.7s0.9-0.2,1.2-0.7s0.5-1.4,0.5-2.8  c0-1.4-0.2-2.4-0.5-2.8s-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C221,37.5,220.8,38.5,220.8,39.9z"/>
<path d="M226.4,41.9l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3s0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5s0.5-0.8,0.5-1.3c0-0.5-0.2-0.9-0.5-1.2  s-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1l0.1-0.9c0.1,0,0.1,0,0.2,0c0.4,0,0.9-0.1,1.2-0.4c0.4-0.2,0.5-0.6,0.5-1.1  c0-0.4-0.1-0.7-0.4-1s-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4s-0.4,0.6-0.5,1.2l-1.1-0.2c0.1-0.7,0.4-1.3,0.9-1.6s1-0.6,1.7-0.6  c0.5,0,0.9,0.1,1.3,0.3s0.7,0.5,0.9,0.8c0.2,0.3,0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1c-0.2,0.3-0.5,0.5-0.9,0.7  c0.5,0.1,0.9,0.4,1.2,0.7s0.4,0.8,0.4,1.4c0,0.8-0.3,1.4-0.8,1.9c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7  S226.4,42.6,226.4,41.9z"/>
<path d="M233,41.9l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2c0.3,0.3,0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6s0.5-0.9,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4s-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2c-0.3,0.2-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4l-0.5,2.3  c0.5-0.4,1.1-0.5,1.6-0.5c0.8,0,1.4,0.3,1.9,0.8c0.5,0.5,0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1  c-0.8,0-1.4-0.2-1.9-0.7C233.4,43.2,233.1,42.6,233,41.9z"/>
<path d="M239.7,39.9c0-1,0.1-1.8,0.3-2.5c0.2-0.6,0.5-1.1,0.9-1.4s0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3s0.6,0.5,0.9,0.8  c0.2,0.3,0.4,0.8,0.5,1.3s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9  C240,42.7,239.7,41.5,239.7,39.9z M240.8,39.9c0,1.4,0.2,2.3,0.5,2.8c0.3,0.5,0.7,0.7,1.2,0.7s0.9-0.2,1.2-0.7s0.5-1.4,0.5-2.8  c0-1.4-0.2-2.4-0.5-2.8s-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C241,37.5,240.8,38.5,240.8,39.9z"/>
<path d="M202.8,52.1l-0.3-1.6V49h1.2v1.4l-0.3,1.6H202.8z M204.7,52.1l-0.3-1.6V49h1.2v1.4l-0.3,1.6H204.7z"/>
<path d="M206.2,57.6l3.3-8.6h1.2l3.5,8.6h-1.3l-1-2.6h-3.6l-0.9,2.6H206.2z M208.7,54.1h2.9l-0.9-2.4c-0.3-0.7-0.5-1.3-0.6-1.8  c-0.1,0.6-0.3,1.1-0.5,1.6L208.7,54.1z"/>
<path d="M215,57.6V49h1.1v8.6H215z"/>
<path d="M217.7,50.2V49h1.1v1.2H217.7z M217.7,57.6v-6.2h1.1v6.2H217.7z"/>
<path d="M224.4,55.3l1,0.1c-0.1,0.7-0.4,1.3-0.9,1.7s-1,0.6-1.7,0.6c-0.9,0-1.5-0.3-2.1-0.8c-0.5-0.6-0.8-1.4-0.8-2.4  c0-0.7,0.1-1.3,0.3-1.8c0.2-0.5,0.6-0.9,1-1.1s1-0.4,1.5-0.4c0.7,0,1.2,0.2,1.7,0.5s0.7,0.8,0.8,1.5l-1,0.2  c-0.1-0.4-0.3-0.7-0.5-0.9c-0.2-0.2-0.5-0.3-0.9-0.3c-0.5,0-1,0.2-1.3,0.6s-0.5,1-0.5,1.8c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.3,0.6  c0.4,0,0.8-0.1,1-0.4S224.3,55.9,224.4,55.3z"/>
<path d="M230.6,55.6l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5c-0.5,0.4-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8c-0.5-0.6-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4c0.5-0.6,1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8c0.5,0.6,0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6  c0,0.7,0.2,1.2,0.6,1.6c0.3,0.4,0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3S230.4,56.1,230.6,55.6z M227.1,53.9h3.5c0-0.5-0.2-0.9-0.4-1.2  c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5C227.3,52.9,227.2,53.4,227.1,53.9z"/>
<path d="M233.1,52.1l-0.3-1.6V49h1.2v1.4l-0.3,1.6H233.1z M235,52.1l-0.3-1.6V49h1.2v1.4l-0.3,1.6H235z"/>
<rect x="158.2" y="33.6" fill-rule="evenodd" fill="none" width="122.3" height="27"/>
<path fill="none" stroke="#000000" stroke-width="2.2504" d="M192.9,105.6h52.6c0.7,0,1.4,0,2.1,0.1c0.7,0.1,1.4,0.2,2,0.3  c0.7,0.1,1.3,0.3,2,0.5s1.3,0.4,1.9,0.7c0.6,0.3,1.3,0.6,1.9,0.9c0.6,0.3,1.2,0.7,1.8,1.1c0.6,0.4,1.1,0.8,1.7,1.2  c0.5,0.4,1,0.9,1.5,1.4s0.9,1,1.4,1.5s0.8,1.1,1.2,1.7c0.4,0.6,0.7,1.2,1.1,1.8c0.3,0.6,0.6,1.2,0.9,1.9c0.3,0.6,0.5,1.3,0.7,1.9  c0.2,0.7,0.4,1.3,0.5,2s0.2,1.4,0.3,2s0.1,1.4,0.1,2.1s0,1.4-0.1,2.1s-0.2,1.4-0.3,2s-0.3,1.3-0.5,2c-0.2,0.7-0.4,1.3-0.7,1.9  c-0.3,0.6-0.6,1.3-0.9,1.9c-0.3,0.6-0.7,1.2-1.1,1.8c-0.4,0.6-0.8,1.1-1.2,1.7s-0.9,1-1.4,1.5s-1,0.9-1.5,1.4  c-0.5,0.4-1.1,0.8-1.7,1.2c-0.6,0.4-1.2,0.7-1.8,1.1c-0.6,0.3-1.2,0.6-1.9,0.9c-0.6,0.3-1.3,0.5-1.9,0.7s-1.3,0.4-2,0.5  c-0.7,0.1-1.4,0.2-2,0.3c-0.7,0.1-1.4,0.1-2.1,0.1h-52.6c-0.7,0-1.4,0-2.1-0.1c-0.7-0.1-1.4-0.2-2-0.3c-0.7-0.1-1.3-0.3-2-0.5  s-1.3-0.4-1.9-0.7c-0.6-0.3-1.3-0.6-1.9-0.9c-0.6-0.3-1.2-0.7-1.8-1.1c-0.6-0.4-1.1-0.8-1.7-1.2c-0.5-0.4-1-0.9-1.5-1.4  s-0.9-1-1.4-1.5s-0.8-1.1-1.2-1.7c-0.4-0.6-0.7-1.2-1.1-1.8c-0.3-0.6-0.6-1.2-0.9-1.9c-0.3-0.6-0.5-1.3-0.7-1.9  c-0.2-0.7-0.4-1.3-0.5-2s-0.2-1.4-0.3-2s-0.1-1.4-0.1-2.1s0-1.4,0.1-2.1s0.2-1.4,0.3-2s0.3-1.3,0.5-2c0.2-0.7,0.4-1.3,0.7-1.9  c0.3-0.6,0.6-1.3,0.9-1.9c0.3-0.6,0.7-1.2,1.1-1.8c0.4-0.6,0.8-1.1,1.2-1.7s0.9-1,1.4-1.5s1-0.9,1.5-1.4c0.5-0.4,1.1-0.8,1.7-1.2  c0.6-0.4,1.2-0.7,1.8-1.1c0.6-0.3,1.2-0.6,1.9-0.9c0.6-0.3,1.3-0.5,1.9-0.7s1.3-0.4,2-0.5c0.7-0.1,1.4-0.2,2-0.3  C191.5,105.7,192.2,105.6,192.9,105.6z"/>
<path d="M194.7,121.4l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2c0.3,0.3,0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6s0.5-0.9,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4s-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2c-0.3,0.2-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4l-0.5,2.3  c0.5-0.4,1.1-0.5,1.6-0.5c0.8,0,1.4,0.3,1.9,0.8c0.5,0.5,0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1  c-0.8,0-1.4-0.2-1.9-0.7C195,122.7,194.7,122.1,194.7,121.4z"/>
<path d="M201.3,121.4l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2c0.3,0.3,0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6s0.5-0.9,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4s-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2c-0.3,0.2-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4l-0.5,2.3  c0.5-0.4,1.1-0.5,1.6-0.5c0.8,0,1.4,0.3,1.9,0.8c0.5,0.5,0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1  c-0.8,0-1.4-0.2-1.9-0.7C201.7,122.7,201.4,122.1,201.3,121.4z"/>
<path d="M208,121.4l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2c0.3,0.3,0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6s0.5-0.9,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4s-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2c-0.3,0.2-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4l-0.5,2.3  c0.5-0.4,1.1-0.5,1.6-0.5c0.8,0,1.4,0.3,1.9,0.8c0.5,0.5,0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1  c-0.8,0-1.4-0.2-1.9-0.7C208.4,122.7,208.1,122.1,208,121.4z"/>
<path d="M220.2,117.1l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  s-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9c0.4-0.2,0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8c0.5,0.5,0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5  s-0.6,0.8-1,1.1s-0.9,0.4-1.4,0.4c-0.9,0-1.6-0.3-2.2-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6c0.5-0.7,1.3-1,2.2-1  c0.7,0,1.2,0.2,1.7,0.6C219.8,115.9,220.1,116.5,220.2,117.1z M215.9,120.8c0,0.4,0.1,0.7,0.2,1s0.4,0.6,0.6,0.8  c0.3,0.2,0.6,0.3,0.9,0.3c0.4,0,0.8-0.2,1.1-0.5s0.5-0.8,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4s-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.5  S215.9,120.3,215.9,120.8z"/>
<path d="M221.4,119.4c0-1,0.1-1.8,0.3-2.5c0.2-0.6,0.5-1.1,0.9-1.4s0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3s0.6,0.5,0.9,0.8  c0.2,0.3,0.4,0.8,0.5,1.3s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9  C221.6,122.2,221.4,121,221.4,119.4z M222.4,119.4c0,1.4,0.2,2.3,0.5,2.8c0.3,0.5,0.7,0.7,1.2,0.7s0.9-0.2,1.2-0.7s0.5-1.4,0.5-2.8  c0-1.4-0.2-2.4-0.5-2.8s-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C222.6,117,222.4,118,222.4,119.4z"/>
<path d="M229.3,123.6h-1V115h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5c-0.5,0.6-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V123.6z M229.3,120.5  c0,0.7,0.1,1.3,0.3,1.6c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C229.5,119.1,229.3,119.7,229.3,120.5z"/>
<path d="M239,123.6v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1c-0.2-0.5-0.3-1.1-0.3-1.7  c0-0.6,0.1-1.2,0.3-1.7c0.2-0.5,0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6V115h1v8.6H239z   M235.7,120.5c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6S235.7,119.7,235.7,120.5z"/>
<path d="M241.9,123.6v-5.4H241v-0.8h0.9v-0.7c0-0.4,0-0.7,0.1-0.9c0.1-0.3,0.3-0.5,0.5-0.7s0.6-0.3,1.1-0.3c0.3,0,0.6,0,1,0.1  l-0.2,0.9c-0.2,0-0.4-0.1-0.6-0.1c-0.3,0-0.5,0.1-0.7,0.2s-0.2,0.4-0.2,0.8v0.6h1.2v0.8H243v5.4H241.9z"/>
<path d="M184.6,137.1l3.3-8.6h1.2l3.5,8.6h-1.3l-1-2.6h-3.6l-0.9,2.6H184.6z M187.1,133.6h2.9l-0.9-2.4c-0.3-0.7-0.5-1.3-0.6-1.8  c-0.1,0.6-0.3,1.1-0.5,1.6L187.1,133.6z"/>
<path d="M193.2,134.4l1.1-0.1c0.1,0.4,0.2,0.8,0.4,1.1s0.5,0.5,0.9,0.7s0.8,0.3,1.3,0.3c0.4,0,0.8-0.1,1.1-0.2  c0.3-0.1,0.6-0.3,0.7-0.5s0.2-0.5,0.2-0.7c0-0.3-0.1-0.5-0.2-0.7s-0.4-0.4-0.8-0.5c-0.2-0.1-0.7-0.2-1.5-0.4  c-0.8-0.2-1.3-0.4-1.7-0.5c-0.4-0.2-0.7-0.5-0.9-0.8s-0.3-0.7-0.3-1.1c0-0.4,0.1-0.8,0.4-1.2s0.6-0.7,1.1-0.9c0.5-0.2,1-0.3,1.6-0.3  c0.6,0,1.2,0.1,1.7,0.3c0.5,0.2,0.9,0.5,1.1,0.9s0.4,0.8,0.4,1.4l-1.1,0.1c-0.1-0.5-0.3-1-0.6-1.2c-0.3-0.3-0.8-0.4-1.5-0.4  c-0.7,0-1.2,0.1-1.5,0.4c-0.3,0.3-0.5,0.6-0.5,0.9c0,0.3,0.1,0.6,0.3,0.8c0.2,0.2,0.8,0.4,1.7,0.6c0.9,0.2,1.6,0.4,1.9,0.5  c0.5,0.2,0.9,0.5,1.1,0.9c0.2,0.4,0.4,0.8,0.4,1.2c0,0.5-0.1,0.9-0.4,1.3c-0.3,0.4-0.6,0.7-1.1,0.9c-0.5,0.2-1,0.3-1.7,0.3  c-0.8,0-1.4-0.1-2-0.3c-0.5-0.2-0.9-0.6-1.2-1C193.3,135.5,193.2,134.9,193.2,134.4z"/>
<path d="M201.2,134.4l1.1-0.1c0.1,0.4,0.2,0.8,0.4,1.1s0.5,0.5,0.9,0.7s0.8,0.3,1.3,0.3c0.4,0,0.8-0.1,1.1-0.2  c0.3-0.1,0.6-0.3,0.7-0.5s0.2-0.5,0.2-0.7c0-0.3-0.1-0.5-0.2-0.7s-0.4-0.4-0.8-0.5c-0.2-0.1-0.7-0.2-1.5-0.4  c-0.8-0.2-1.3-0.4-1.7-0.5c-0.4-0.2-0.7-0.5-0.9-0.8s-0.3-0.7-0.3-1.1c0-0.4,0.1-0.8,0.4-1.2s0.6-0.7,1.1-0.9c0.5-0.2,1-0.3,1.6-0.3  c0.6,0,1.2,0.1,1.7,0.3c0.5,0.2,0.9,0.5,1.1,0.9s0.4,0.8,0.4,1.4l-1.1,0.1c-0.1-0.5-0.3-1-0.6-1.2c-0.3-0.3-0.8-0.4-1.5-0.4  c-0.7,0-1.2,0.1-1.5,0.4c-0.3,0.3-0.5,0.6-0.5,0.9c0,0.3,0.1,0.6,0.3,0.8c0.2,0.2,0.8,0.4,1.7,0.6c0.9,0.2,1.6,0.4,1.9,0.5  c0.5,0.2,0.9,0.5,1.1,0.9c0.2,0.4,0.4,0.8,0.4,1.2c0,0.5-0.1,0.9-0.4,1.3c-0.3,0.4-0.6,0.7-1.1,0.9c-0.5,0.2-1,0.3-1.7,0.3  c-0.8,0-1.4-0.1-2-0.3c-0.5-0.2-0.9-0.6-1.2-1C201.3,135.5,201.2,134.9,201.2,134.4z"/>
<path d="M209.6,137.1v-8.6h6.2v1h-5.1v2.6h4.8v1h-4.8v2.9h5.3v1H209.6z"/>
<path d="M217.6,137.1v-8.6h3.8c0.8,0,1.3,0.1,1.7,0.2s0.7,0.4,1,0.8s0.4,0.8,0.4,1.3c0,0.6-0.2,1.1-0.6,1.5c-0.4,0.4-1,0.7-1.8,0.8  c0.3,0.1,0.5,0.3,0.7,0.4c0.3,0.3,0.6,0.7,0.9,1.1l1.5,2.3h-1.4l-1.1-1.8c-0.3-0.5-0.6-0.9-0.8-1.2s-0.4-0.5-0.6-0.6  s-0.3-0.2-0.5-0.2c-0.1,0-0.3,0-0.6,0h-1.3v3.8H217.6z M218.7,132.3h2.4c0.5,0,0.9-0.1,1.2-0.2s0.5-0.3,0.7-0.5s0.2-0.5,0.2-0.8  c0-0.4-0.1-0.7-0.4-1s-0.8-0.4-1.4-0.4h-2.7V132.3z"/>
<path d="M228.2,137.1v-7.6h-2.8v-1h6.8v1h-2.8v7.6H228.2z"/>
<path d="M233.5,137.1v-8.6h1.1v8.6H233.5z"/>
<path d="M236.3,132.9c0-1.4,0.4-2.5,1.1-3.3s1.8-1.2,3-1.2c0.8,0,1.5,0.2,2.1,0.6c0.6,0.4,1.1,0.9,1.5,1.6c0.3,0.7,0.5,1.4,0.5,2.3  c0,0.9-0.2,1.7-0.5,2.3c-0.4,0.7-0.8,1.2-1.5,1.6c-0.6,0.4-1.3,0.5-2.1,0.5c-0.8,0-1.5-0.2-2.2-0.6c-0.6-0.4-1.1-0.9-1.4-1.6  C236.5,134.4,236.3,133.7,236.3,132.9z M237.5,133c0,1,0.3,1.9,0.8,2.4c0.6,0.6,1.3,0.9,2.1,0.9c0.9,0,1.6-0.3,2.1-0.9  c0.6-0.6,0.8-1.5,0.8-2.6c0-0.7-0.1-1.3-0.4-1.8c-0.2-0.5-0.6-0.9-1-1.2s-1-0.4-1.5-0.4c-0.8,0-1.5,0.3-2.1,0.8  C237.8,130.7,237.5,131.7,237.5,133z"/>
<path d="M246,137.1v-8.6h1.2l4.5,6.7v-6.7h1.1v8.6h-1.2l-4.5-6.8v6.8H246z"/>
<rect x="184.6" y="113.1" fill-rule="evenodd" fill="none" width="69" height="27"/>
<rect x="349.2" y="65.9" fill="none" stroke="#000000" stroke-width="2.2504" width="144.9" height="42"/>
<path d="M395.5,76.4v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3c-0.5,1-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  s0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H395.5z"/>
<path d="M402.1,79.6c0-1,0.1-1.8,0.3-2.5s0.5-1.1,0.9-1.4c0.4-0.3,0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3c0.3,0.2,0.6,0.5,0.9,0.8  s0.4,0.8,0.5,1.3s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4c-0.4,0.3-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9  C402.4,82.4,402.1,81.3,402.1,79.6z M403.2,79.6c0,1.4,0.2,2.3,0.5,2.8s0.7,0.7,1.2,0.7s0.9-0.2,1.2-0.7c0.3-0.5,0.5-1.4,0.5-2.8  c0-1.4-0.2-2.4-0.5-2.8c-0.3-0.5-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C403.4,77.3,403.2,78.2,403.2,79.6z"/>
<path d="M409,81.9l1-0.1c0.1,0.5,0.2,0.8,0.5,1s0.6,0.3,0.9,0.3c0.3,0,0.6-0.1,0.9-0.2s0.4-0.3,0.6-0.6s0.3-0.6,0.4-1  s0.2-0.9,0.2-1.3c0,0,0-0.1,0-0.2c-0.2,0.3-0.5,0.6-0.9,0.8s-0.8,0.3-1.2,0.3c-0.7,0-1.3-0.3-1.8-0.8c-0.5-0.5-0.7-1.2-0.7-2  c0-0.9,0.3-1.6,0.8-2.1c0.5-0.5,1.2-0.8,1.9-0.8c0.6,0,1.1,0.2,1.5,0.5c0.5,0.3,0.8,0.7,1.1,1.3s0.4,1.4,0.4,2.4  c0,1.1-0.1,2-0.4,2.6s-0.6,1.1-1.1,1.5c-0.5,0.3-1,0.5-1.7,0.5c-0.7,0-1.2-0.2-1.6-0.6C409.3,83.1,409,82.6,409,81.9z M413.3,78.1  c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.4-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.6s-0.5,0.9-0.5,1.5c0,0.5,0.2,1,0.5,1.3s0.7,0.5,1.2,0.5  c0.5,0,0.9-0.2,1.2-0.5C413.1,79.2,413.3,78.7,413.3,78.1z"/>
<path d="M421,82.9v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1s0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8  c0.3-0.4,0.5-0.9,0.5-1.3c0-0.4-0.1-0.8-0.4-1.1c-0.3-0.3-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5s-0.5,0.7-0.5,1.3l-1.1-0.1  c0.1-0.8,0.4-1.4,0.8-1.8c0.5-0.4,1.1-0.6,2-0.6c0.8,0,1.5,0.2,2,0.7s0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1s-0.4,0.7-0.7,1  s-0.9,0.9-1.6,1.5c-0.6,0.5-1,0.9-1.2,1.1s-0.3,0.4-0.4,0.6H421z"/>
<path d="M426.5,83.9v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4c-0.4-0.3-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7  c0-0.6,0.1-1.2,0.3-1.7s0.5-0.9,0.9-1.2c0.4-0.3,0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6v-3.1h1v8.6H426.5z   M423.1,80.8c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9  c-0.3-0.4-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6S423.1,79.9,423.1,80.8z"/>
<path d="M434.3,77.4l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  c-0.2,0.5-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9s0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8s0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5  s-0.6,0.8-1,1.1c-0.4,0.2-0.9,0.4-1.4,0.4c-0.9,0-1.6-0.3-2.2-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6  c0.5-0.7,1.3-1,2.2-1c0.7,0,1.2,0.2,1.7,0.6S434.2,76.7,434.3,77.4z M430,81.1c0,0.4,0.1,0.7,0.2,1s0.4,0.6,0.6,0.8s0.6,0.3,0.9,0.3  c0.4,0,0.8-0.2,1.1-0.5c0.3-0.4,0.5-0.8,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.3-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.5  S430,80.5,430,81.1z"/>
<path d="M441,82.9v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1s0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8  c0.3-0.4,0.5-0.9,0.5-1.3c0-0.4-0.1-0.8-0.4-1.1c-0.3-0.3-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5s-0.5,0.7-0.5,1.3l-1.1-0.1  c0.1-0.8,0.4-1.4,0.8-1.8c0.5-0.4,1.1-0.6,2-0.6c0.8,0,1.5,0.2,2,0.7s0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1s-0.4,0.7-0.7,1  s-0.9,0.9-1.6,1.5c-0.6,0.5-1,0.9-1.2,1.1s-0.3,0.4-0.4,0.6H441z"/>
<path d="M442.2,79.6c0-1,0.1-1.8,0.3-2.5s0.5-1.1,0.9-1.4c0.4-0.3,0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3c0.3,0.2,0.6,0.5,0.9,0.8  s0.4,0.8,0.5,1.3s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4c-0.4,0.3-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9  C442.5,82.4,442.2,81.3,442.2,79.6z M443.3,79.6c0,1.4,0.2,2.3,0.5,2.8s0.7,0.7,1.2,0.7s0.9-0.2,1.2-0.7c0.3-0.5,0.5-1.4,0.5-2.8  c0-1.4-0.2-2.4-0.5-2.8c-0.3-0.5-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C443.4,77.3,443.3,78.2,443.3,79.6z"/>
<path d="M401.2,91.8l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H401.2z M403.2,91.8l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H403.2z"/>
<path d="M405.4,97.4v-8.6h1.1v4.9l2.5-2.5h1.4l-2.4,2.3l2.6,3.9h-1.3l-2.1-3.2l-0.7,0.7v2.5H405.4z"/>
<path d="M411.4,97.4v-6.2h1V92c0.5-0.7,1.1-1,2-1c0.4,0,0.7,0.1,1,0.2c0.3,0.1,0.5,0.3,0.7,0.5s0.3,0.5,0.3,0.8c0,0.2,0.1,0.5,0.1,1  v3.8h-1.1v-3.8c0-0.4,0-0.8-0.1-1c-0.1-0.2-0.2-0.4-0.4-0.5s-0.5-0.2-0.7-0.2c-0.4,0-0.8,0.1-1.2,0.4s-0.5,0.8-0.5,1.6v3.4H411.4z"/>
<path d="M417.7,94.3c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8s0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  s-0.6,0.8-1,1.1c-0.5,0.3-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8C418,96.1,417.7,95.3,417.7,94.3z M418.8,94.3c0,0.8,0.2,1.4,0.5,1.8  c0.3,0.4,0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7c-0.4-0.4-0.8-0.6-1.3-0.6  c-0.5,0-1,0.2-1.3,0.6C419,92.9,418.8,93.5,418.8,94.3z"/>
<path d="M425.9,97.4l-1.9-6.2h1.1l1,3.6l0.4,1.3c0-0.1,0.1-0.5,0.3-1.3l1-3.6h1.1l0.9,3.6l0.3,1.2l0.4-1.2l1.1-3.6h1l-1.9,6.2h-1.1  l-1-3.7l-0.2-1.1l-1.3,4.8H425.9z"/>
<path d="M433,95.5l1-0.2c0.1,0.4,0.2,0.7,0.5,1c0.3,0.2,0.6,0.3,1.1,0.3c0.5,0,0.8-0.1,1.1-0.3s0.4-0.4,0.4-0.7  c0-0.2-0.1-0.4-0.3-0.6c-0.1-0.1-0.5-0.2-1.1-0.4c-0.8-0.2-1.3-0.4-1.6-0.5c-0.3-0.1-0.5-0.3-0.7-0.6s-0.2-0.5-0.2-0.8  c0-0.3,0.1-0.5,0.2-0.8s0.3-0.4,0.5-0.6c0.2-0.1,0.4-0.2,0.7-0.3c0.3-0.1,0.6-0.1,0.9-0.1c0.5,0,0.9,0.1,1.3,0.2s0.6,0.3,0.8,0.6  s0.3,0.6,0.4,1l-1,0.1c0-0.3-0.2-0.6-0.4-0.8s-0.5-0.3-1-0.3c-0.5,0-0.8,0.1-1,0.2c-0.2,0.2-0.3,0.3-0.3,0.6c0,0.1,0,0.3,0.1,0.4  c0.1,0.1,0.2,0.2,0.4,0.3c0.1,0,0.4,0.1,0.9,0.3c0.7,0.2,1.3,0.4,1.6,0.5c0.3,0.1,0.5,0.3,0.7,0.6s0.3,0.5,0.3,0.9  c0,0.4-0.1,0.7-0.3,1s-0.5,0.6-0.9,0.7c-0.4,0.2-0.8,0.3-1.3,0.3c-0.8,0-1.4-0.2-1.8-0.5S433.1,96.2,433,95.5z"/>
<path d="M439.5,91.8l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H439.5z M441.4,91.8l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H441.4z"/>
<rect x="356.7" y="73.4" fill-rule="evenodd" fill="none" width="129.8" height="27"/>
<rect x="355.5" y="145.4" fill="none" stroke="#000000" stroke-width="2.2504" width="132.3" height="42"/>
<path d="M395.6,161.4l1-0.1c0.1,0.5,0.2,0.8,0.5,1s0.6,0.3,0.9,0.3c0.3,0,0.6-0.1,0.9-0.2s0.4-0.3,0.6-0.6s0.3-0.6,0.4-1  s0.2-0.9,0.2-1.3c0,0,0-0.1,0-0.2c-0.2,0.3-0.5,0.6-0.9,0.8s-0.8,0.3-1.2,0.3c-0.7,0-1.3-0.3-1.8-0.8c-0.5-0.5-0.7-1.2-0.7-2  c0-0.9,0.3-1.6,0.8-2.1c0.5-0.5,1.2-0.8,1.9-0.8c0.6,0,1.1,0.2,1.5,0.5c0.5,0.3,0.8,0.7,1.1,1.3s0.4,1.4,0.4,2.4  c0,1.1-0.1,2-0.4,2.6s-0.6,1.1-1.1,1.5c-0.5,0.3-1,0.5-1.7,0.5c-0.7,0-1.2-0.2-1.6-0.6C396,162.6,395.7,162.1,395.6,161.4z   M399.9,157.6c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.4-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.6s-0.5,0.9-0.5,1.5c0,0.5,0.2,1,0.5,1.3  s0.7,0.5,1.2,0.5c0.5,0,0.9-0.2,1.2-0.5C399.8,158.7,399.9,158.2,399.9,157.6z"/>
<path d="M406.5,162.6c-0.4,0.3-0.8,0.6-1.1,0.7s-0.7,0.2-1.2,0.2c-0.7,0-1.2-0.2-1.6-0.5s-0.6-0.8-0.6-1.3c0-0.3,0.1-0.6,0.2-0.8  s0.3-0.5,0.5-0.6s0.5-0.3,0.8-0.3c0.2-0.1,0.5-0.1,0.9-0.2c0.9-0.1,1.5-0.2,1.9-0.4c0-0.1,0-0.2,0-0.3c0-0.4-0.1-0.7-0.3-0.9  c-0.3-0.2-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.1-1.1,0.3s-0.4,0.5-0.5,0.9l-1-0.1c0.1-0.4,0.2-0.8,0.5-1.1s0.5-0.5,0.9-0.6  c0.4-0.1,0.9-0.2,1.4-0.2c0.5,0,1,0.1,1.3,0.2c0.3,0.1,0.6,0.3,0.7,0.5s0.3,0.4,0.3,0.7c0,0.2,0.1,0.5,0.1,1v1.4c0,1,0,1.6,0.1,1.9  s0.1,0.5,0.3,0.7h-1.1C406.6,163.2,406.5,162.9,406.5,162.6z M406.4,160.3c-0.4,0.2-1,0.3-1.7,0.4c-0.4,0.1-0.7,0.1-0.9,0.2  s-0.3,0.2-0.4,0.3c-0.1,0.2-0.1,0.3-0.1,0.5c0,0.3,0.1,0.5,0.3,0.7c0.2,0.2,0.5,0.3,0.9,0.3c0.4,0,0.8-0.1,1.1-0.3s0.5-0.4,0.7-0.7  c0.1-0.2,0.2-0.6,0.2-1.1V160.3z"/>
<path d="M408.9,155.9v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3c-0.5,1-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  s0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H408.9z"/>
<path d="M415.6,155.9v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3c-0.5,1-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  s0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H415.6z"/>
<path d="M426.1,163.4h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1s0.8-0.8,0.9-1.1h0.7V163.4z"/>
<path d="M428.9,155.9v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3c-0.5,1-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  s0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H428.9z"/>
<path d="M439.5,163.4h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7s-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1s0.8-0.8,0.9-1.1h0.7V163.4z"/>
<path d="M442.2,161.1l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2s0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6c0.4-0.4,0.5-0.9,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.3-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2s-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1H444l-0.5,2.3  c0.5-0.4,1.1-0.5,1.6-0.5c0.8,0,1.4,0.3,1.9,0.8s0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1c-0.8,0-1.4-0.2-1.9-0.7  C442.5,162.4,442.3,161.8,442.2,161.1z"/>
<path d="M407.6,171.3l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H407.6z M409.5,171.3l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H409.5z"/>
<path d="M411.9,176.9v-8.6h3.2c0.7,0,1.2,0.1,1.6,0.3s0.7,0.4,0.9,0.8s0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1s-0.5,0.6-0.9,0.8  c0.5,0.2,0.9,0.4,1.2,0.8s0.4,0.8,0.4,1.3c0,0.4-0.1,0.8-0.3,1.1s-0.4,0.6-0.6,0.8s-0.6,0.3-0.9,0.4s-0.8,0.1-1.4,0.1H411.9z   M413,171.9h1.9c0.5,0,0.9,0,1.1-0.1c0.3-0.1,0.5-0.2,0.7-0.4s0.2-0.4,0.2-0.8c0-0.3-0.1-0.5-0.2-0.8s-0.3-0.4-0.6-0.4  c-0.3-0.1-0.7-0.1-1.3-0.1H413V171.9z M413,175.9h2.1c0.4,0,0.6,0,0.8,0c0.3,0,0.5-0.1,0.7-0.2s0.3-0.3,0.4-0.5s0.2-0.5,0.2-0.7  c0-0.3-0.1-0.6-0.2-0.8s-0.4-0.4-0.7-0.5s-0.7-0.1-1.3-0.1h-2V175.9z"/>
<path d="M419.4,173.8c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8s0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  s-0.6,0.8-1,1.1c-0.5,0.3-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8C419.6,175.6,419.4,174.8,419.4,173.8z M420.5,173.8  c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7  c-0.4-0.4-0.8-0.6-1.3-0.6c-0.5,0-1,0.2-1.3,0.6C420.6,172.4,420.5,173,420.5,173.8z"/>
<path d="M427.4,176.9h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2c0.3,0.2,0.6,0.4,0.8,0.7s0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V176.9z M427.4,173.7c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8c-0.3-0.4-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6S427.4,173,427.4,173.7z"/>
<path d="M433.2,171.3l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H433.2z M435.1,171.3l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H435.1z"/>
<rect x="363" y="152.9" fill-rule="evenodd" fill="none" width="117" height="27"/>
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
aaed47e8 WRAPPED
    27840350 subj "Alice"
~~~

### Mermaid

<artwork type="svg"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.2" baseProfile="tiny" width="352.9px" height="94.2px" viewBox="0 0 352.9 94.2" xml:space="preserve">
<path fill="none" stroke="#000000" stroke-width="1.4998" d="M120.4,47.5l6.6-0.1c6.6-0.1,19.9-0.2,31.5-0.2s21.5-0.1,26.5-0.1h5"/>
<polygon fill="black" points="181.9,42.6 190.9,47.1 181.9,51.6 "/>
<rect x="180.4" y="42.6" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path d="M149.6,49l1-0.2c0.1,0.4,0.2,0.7,0.5,1s0.6,0.3,1.1,0.3c0.5,0,0.8-0.1,1.1-0.3s0.4-0.4,0.4-0.7c0-0.2-0.1-0.4-0.3-0.6  c-0.1-0.1-0.5-0.2-1.1-0.4c-0.8-0.2-1.3-0.4-1.6-0.5s-0.5-0.3-0.7-0.6c-0.2-0.3-0.2-0.5-0.2-0.8c0-0.3,0.1-0.5,0.2-0.8  c0.1-0.2,0.3-0.4,0.5-0.6c0.2-0.1,0.4-0.2,0.7-0.3s0.6-0.1,0.9-0.1c0.5,0,0.9,0.1,1.3,0.2s0.6,0.3,0.8,0.6s0.3,0.6,0.4,1l-1,0.1  c0-0.3-0.2-0.6-0.4-0.8s-0.5-0.3-1-0.3c-0.5,0-0.8,0.1-1,0.2s-0.3,0.3-0.3,0.6c0,0.1,0,0.3,0.1,0.4c0.1,0.1,0.2,0.2,0.4,0.3  c0.1,0,0.4,0.1,0.9,0.3c0.7,0.2,1.3,0.4,1.6,0.5s0.5,0.3,0.7,0.6s0.3,0.5,0.3,0.9c0,0.4-0.1,0.7-0.3,1c-0.2,0.3-0.5,0.6-0.9,0.7  s-0.8,0.3-1.3,0.3c-0.8,0-1.4-0.2-1.8-0.5C150,50.2,149.7,49.7,149.6,49z"/>
<path d="M160.1,50.9V50c-0.5,0.7-1.1,1.1-2,1.1c-0.4,0-0.7-0.1-1-0.2s-0.6-0.3-0.7-0.5s-0.3-0.5-0.3-0.8c0-0.2-0.1-0.5-0.1-1v-3.9  h1.1v3.5c0,0.6,0,0.9,0.1,1.1c0.1,0.3,0.2,0.5,0.4,0.7s0.5,0.2,0.8,0.2c0.3,0,0.6-0.1,0.9-0.2s0.5-0.4,0.6-0.7s0.2-0.7,0.2-1.2v-3.3  h1.1v6.2H160.1z"/>
<path d="M163.7,50.9h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2s0.6,0.4,0.8,0.7s0.4,0.6,0.5,1s0.2,0.8,0.2,1.3  c0,1.1-0.3,1.9-0.8,2.5c-0.5,0.6-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V50.9z M163.6,47.7c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  S163.6,47,163.6,47.7z"/>
<path d="M168,53.3l0.2-0.9c0.2,0.1,0.4,0.1,0.5,0.1c0.2,0,0.4-0.1,0.5-0.2s0.2-0.5,0.2-1.1v-6.5h1.1v6.6c0,0.8-0.1,1.3-0.3,1.6  c-0.3,0.4-0.7,0.6-1.3,0.6C168.6,53.4,168.3,53.4,168,53.3z M169.3,43.5v-1.2h1.1v1.2H169.3z"/>
<rect x="149.2" y="40.4" fill-rule="evenodd" fill="none" width="21.7" height="13.5"/>
<polygon fill="none" stroke="#000000" stroke-width="2.2497" points="26.8,68.1 130.5,68.1 109.5,26.1 47.8,26.1 "/>
<path d="M56.8,43.4c-0.4,0.3-0.8,0.6-1.1,0.7s-0.7,0.2-1.2,0.2c-0.7,0-1.2-0.2-1.6-0.5c-0.4-0.3-0.6-0.8-0.6-1.3  c0-0.3,0.1-0.6,0.2-0.8c0.1-0.3,0.3-0.5,0.5-0.6s0.5-0.3,0.8-0.3c0.2-0.1,0.5-0.1,0.9-0.2c0.9-0.1,1.5-0.2,1.9-0.4  c0-0.1,0-0.2,0-0.3c0-0.4-0.1-0.7-0.3-0.9c-0.3-0.2-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.1-1.1,0.3s-0.4,0.5-0.5,0.9l-1-0.1  c0.1-0.4,0.2-0.8,0.5-1.1c0.2-0.3,0.5-0.5,0.9-0.6s0.9-0.2,1.4-0.2c0.5,0,1,0.1,1.3,0.2c0.3,0.1,0.6,0.3,0.7,0.5s0.3,0.4,0.3,0.7  c0,0.2,0.1,0.5,0.1,1v1.4c0,1,0,1.6,0.1,1.9s0.1,0.5,0.3,0.7H57C56.9,43.9,56.8,43.6,56.8,43.4z M56.7,41c-0.4,0.2-1,0.3-1.7,0.4  c-0.4,0.1-0.7,0.1-0.9,0.2s-0.3,0.2-0.4,0.3s-0.1,0.3-0.1,0.5c0,0.3,0.1,0.5,0.3,0.7s0.5,0.3,0.9,0.3c0.4,0,0.8-0.1,1.1-0.3  s0.5-0.4,0.7-0.7c0.1-0.2,0.2-0.6,0.2-1.1V41z"/>
<path d="M63.5,43.4c-0.4,0.3-0.8,0.6-1.1,0.7s-0.7,0.2-1.2,0.2c-0.7,0-1.2-0.2-1.6-0.5c-0.4-0.3-0.6-0.8-0.6-1.3  c0-0.3,0.1-0.6,0.2-0.8c0.1-0.3,0.3-0.5,0.5-0.6s0.5-0.3,0.8-0.3c0.2-0.1,0.5-0.1,0.9-0.2c0.9-0.1,1.5-0.2,1.9-0.4  c0-0.1,0-0.2,0-0.3c0-0.4-0.1-0.7-0.3-0.9c-0.3-0.2-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.1-1.1,0.3s-0.4,0.5-0.5,0.9l-1-0.1  c0.1-0.4,0.2-0.8,0.5-1.1c0.2-0.3,0.5-0.5,0.9-0.6s0.9-0.2,1.4-0.2c0.5,0,1,0.1,1.3,0.2c0.3,0.1,0.6,0.3,0.7,0.5s0.3,0.4,0.3,0.7  c0,0.2,0.1,0.5,0.1,1v1.4c0,1,0,1.6,0.1,1.9s0.1,0.5,0.3,0.7h-1.1C63.6,43.9,63.5,43.6,63.5,43.4z M63.4,41c-0.4,0.2-1,0.3-1.7,0.4  c-0.4,0.1-0.7,0.1-0.9,0.2s-0.3,0.2-0.4,0.3s-0.1,0.3-0.1,0.5c0,0.3,0.1,0.5,0.3,0.7s0.5,0.3,0.9,0.3c0.4,0,0.8-0.1,1.1-0.3  s0.5-0.4,0.7-0.7c0.1-0.2,0.2-0.6,0.2-1.1V41z"/>
<path d="M70.4,42.1l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5c-0.5,0.4-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8c-0.5-0.6-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4c0.5-0.6,1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8c0.5,0.6,0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6  c0,0.7,0.2,1.2,0.6,1.6s0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3S70.2,42.6,70.4,42.1z M66.9,40.4h3.5c0-0.5-0.2-0.9-0.4-1.2  c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5S66.9,39.9,66.9,40.4z"/>
<path d="M76.8,44.1v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1s-0.3-1.1-0.3-1.7c0-0.6,0.1-1.2,0.3-1.7  c0.2-0.5,0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2s0.5,0.4,0.7,0.6v-3.1h1v8.6H76.8z M73.5,41c0,0.8,0.2,1.4,0.5,1.8  s0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6  S73.5,40.2,73.5,41z"/>
<path d="M82.5,44.1v-2.1h-3.7v-1l3.9-5.6h0.9v5.6h1.2v1h-1.2v2.1H82.5z M82.5,41.1v-3.9l-2.7,3.9H82.5z"/>
<path d="M85.9,36.7v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3c-0.5,1-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  s0.6-1.9,1.1-2.8c0.5-0.9,1-1.6,1.5-2.2H85.9z"/>
<path d="M97,42.1l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5c-0.5,0.4-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8c-0.5-0.6-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4c0.5-0.6,1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8c0.5,0.6,0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6  c0,0.7,0.2,1.2,0.6,1.6s0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3S96.9,42.6,97,42.1z M93.6,40.4h3.5c0-0.5-0.2-0.9-0.4-1.2  c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5S93.6,39.9,93.6,40.4z"/>
<path d="M100.8,39.5c-0.4-0.2-0.8-0.4-1-0.7c-0.2-0.3-0.3-0.7-0.3-1.1c0-0.6,0.2-1.2,0.7-1.6s1-0.6,1.8-0.6c0.8,0,1.4,0.2,1.8,0.7  c0.5,0.4,0.7,1,0.7,1.6c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-1,0.7c0.5,0.2,0.9,0.4,1.2,0.8s0.4,0.8,0.4,1.4c0,0.7-0.3,1.4-0.8,1.9  c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.5-0.3-2.1-0.8c-0.5-0.5-0.8-1.1-0.8-1.9c0-0.6,0.1-1,0.4-1.4C99.9,39.9,100.3,39.6,100.8,39.5z   M100.2,41.6c0,0.3,0.1,0.6,0.2,0.9s0.4,0.5,0.6,0.7s0.6,0.2,0.9,0.2c0.5,0,0.9-0.2,1.2-0.5s0.5-0.7,0.5-1.2c0-0.5-0.2-0.9-0.5-1.3  c-0.3-0.3-0.8-0.5-1.3-0.5c-0.5,0-0.9,0.2-1.2,0.5S100.2,41.2,100.2,41.6z M100.6,37.7c0,0.4,0.1,0.7,0.4,1s0.6,0.4,1,0.4  c0.4,0,0.7-0.1,1-0.4s0.4-0.6,0.4-0.9c0-0.4-0.1-0.7-0.4-1s-0.6-0.4-1-0.4c-0.4,0-0.7,0.1-1,0.4S100.6,37.3,100.6,37.7z"/>
<path d="M50.7,57.6L48.5,49h1.2l1.3,5.6c0.1,0.6,0.3,1.2,0.4,1.8c0.2-0.9,0.3-1.4,0.4-1.6l1.6-5.8h1.4l1.2,4.3  c0.3,1.1,0.5,2.1,0.7,3c0.1-0.5,0.3-1.2,0.4-1.9l1.3-5.5h1.1l-2.4,8.6h-1.1l-1.8-6.5c-0.2-0.5-0.2-0.9-0.3-1c-0.1,0.4-0.2,0.7-0.3,1  l-1.8,6.5H50.7z"/>
<path d="M60.6,57.6V49h3.8c0.8,0,1.3,0.1,1.7,0.2s0.7,0.4,1,0.8s0.4,0.8,0.4,1.3c0,0.6-0.2,1.1-0.6,1.5c-0.4,0.4-1,0.7-1.8,0.8  c0.3,0.1,0.5,0.3,0.7,0.4c0.3,0.3,0.6,0.7,0.9,1.1l1.5,2.3h-1.4l-1.1-1.8c-0.3-0.5-0.6-0.9-0.8-1.2c-0.2-0.3-0.4-0.5-0.6-0.6  s-0.3-0.2-0.5-0.2c-0.1,0-0.3,0-0.6,0h-1.3v3.8H60.6z M61.7,52.8h2.4c0.5,0,0.9-0.1,1.2-0.2s0.5-0.3,0.7-0.5s0.2-0.5,0.2-0.8  c0-0.4-0.1-0.7-0.4-1S65.1,50,64.4,50h-2.7V52.8z"/>
<path d="M68.3,57.6l3.3-8.6h1.2l3.5,8.6H75L74,55h-3.6l-0.9,2.6H68.3z M70.8,54.1h2.9l-0.9-2.4c-0.3-0.7-0.5-1.3-0.6-1.8  c-0.1,0.6-0.3,1.1-0.5,1.6L70.8,54.1z"/>
<path d="M77.2,57.6V49h3.2c0.6,0,1,0,1.3,0.1c0.4,0.1,0.8,0.2,1.1,0.4s0.5,0.5,0.7,0.8c0.2,0.4,0.3,0.7,0.3,1.2  c0,0.7-0.2,1.3-0.7,1.9c-0.5,0.5-1.3,0.8-2.5,0.8h-2.2v3.5H77.2z M78.4,53.1h2.2c0.7,0,1.3-0.1,1.6-0.4s0.5-0.7,0.5-1.2  c0-0.4-0.1-0.7-0.3-0.9s-0.4-0.4-0.7-0.5c-0.2-0.1-0.5-0.1-1.1-0.1h-2.2V53.1z"/>
<path d="M85.2,57.6V49h3.2c0.6,0,1,0,1.3,0.1c0.4,0.1,0.8,0.2,1.1,0.4s0.5,0.5,0.7,0.8c0.2,0.4,0.3,0.7,0.3,1.2  c0,0.7-0.2,1.3-0.7,1.9c-0.5,0.5-1.3,0.8-2.5,0.8h-2.2v3.5H85.2z M86.4,53.1h2.2c0.7,0,1.3-0.1,1.6-0.4s0.5-0.7,0.5-1.2  c0-0.4-0.1-0.7-0.3-0.9s-0.4-0.4-0.7-0.5c-0.2-0.1-0.5-0.1-1.1-0.1h-2.2V53.1z"/>
<path d="M93.3,57.6V49h6.2v1h-5.1v2.6h4.8v1h-4.8v2.9h5.3v1H93.3z"/>
<path d="M101.2,57.6V49h3c0.7,0,1.2,0,1.5,0.1c0.5,0.1,0.9,0.3,1.3,0.6c0.5,0.4,0.8,0.9,1,1.5s0.3,1.3,0.3,2c0,0.7-0.1,1.2-0.2,1.7  s-0.3,0.9-0.6,1.3c-0.2,0.3-0.5,0.6-0.8,0.8s-0.6,0.3-1,0.4s-0.9,0.1-1.4,0.1H101.2z M102.4,56.6h1.8c0.6,0,1-0.1,1.3-0.2  c0.3-0.1,0.6-0.3,0.8-0.4c0.3-0.3,0.5-0.6,0.6-1.1s0.2-1,0.2-1.7c0-0.9-0.1-1.6-0.4-2.1s-0.7-0.8-1.1-1c-0.3-0.1-0.8-0.2-1.5-0.2  h-1.8V56.6z"/>
<rect x="48.3" y="33.6" fill-rule="evenodd" fill="none" width="60.7" height="27"/>
<rect x="190" y="26.1" fill="none" stroke="#000000" stroke-width="2.2497" width="136.8" height="42"/>
<path d="M237.8,43.1v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1s0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8s0.5-0.9,0.5-1.3  c0-0.4-0.1-0.8-0.4-1.1s-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5s-0.5,0.7-0.5,1.3l-1.1-0.1c0.1-0.8,0.4-1.4,0.8-1.8s1.1-0.6,2-0.6  c0.8,0,1.5,0.2,2,0.7c0.5,0.5,0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1s-0.4,0.7-0.7,1c-0.3,0.4-0.9,0.9-1.6,1.5c-0.6,0.5-1,0.9-1.2,1.1  s-0.3,0.4-0.4,0.6H237.8z"/>
<path d="M239,36.7v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3c-0.5,1-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  s0.6-1.9,1.1-2.8c0.5-0.9,1-1.6,1.5-2.2H239z"/>
<path d="M247.2,39.5c-0.4-0.2-0.8-0.4-1-0.7c-0.2-0.3-0.3-0.7-0.3-1.1c0-0.6,0.2-1.2,0.7-1.6s1-0.6,1.8-0.6c0.8,0,1.4,0.2,1.8,0.7  c0.5,0.4,0.7,1,0.7,1.6c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-1,0.7c0.5,0.2,0.9,0.4,1.2,0.8s0.4,0.8,0.4,1.4c0,0.7-0.3,1.4-0.8,1.9  c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.5-0.3-2.1-0.8c-0.5-0.5-0.8-1.1-0.8-1.9c0-0.6,0.1-1,0.4-1.4C246.3,39.9,246.7,39.6,247.2,39.5z   M246.6,41.6c0,0.3,0.1,0.6,0.2,0.9s0.4,0.5,0.6,0.7s0.6,0.2,0.9,0.2c0.5,0,0.9-0.2,1.2-0.5s0.5-0.7,0.5-1.2c0-0.5-0.2-0.9-0.5-1.3  c-0.3-0.3-0.8-0.5-1.3-0.5c-0.5,0-0.9,0.2-1.2,0.5S246.6,41.2,246.6,41.6z M247,37.7c0,0.4,0.1,0.7,0.4,1s0.6,0.4,1,0.4  c0.4,0,0.7-0.1,1-0.4s0.4-0.6,0.4-0.9c0-0.4-0.1-0.7-0.4-1s-0.6-0.4-1-0.4c-0.4,0-0.7,0.1-1,0.4S247,37.3,247,37.7z"/>
<path d="M255.6,44.1v-2.1h-3.7v-1l3.9-5.6h0.9v5.6h1.2v1h-1.2v2.1H255.6z M255.6,41.1v-3.9l-2.7,3.9H255.6z"/>
<path d="M258.9,39.9c0-1,0.1-1.8,0.3-2.5c0.2-0.6,0.5-1.1,0.9-1.4s0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3s0.6,0.5,0.9,0.8  s0.4,0.8,0.5,1.3s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4c-0.4,0.3-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9  C259.2,42.7,258.9,41.5,258.9,39.9z M260,39.9c0,1.4,0.2,2.3,0.5,2.8s0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7s0.5-1.4,0.5-2.8  c0-1.4-0.2-2.4-0.5-2.8s-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C260.2,37.5,260,38.5,260,39.9z"/>
<path d="M265.6,41.9l1.1-0.1c0.1,0.6,0.3,1,0.6,1.3s0.6,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.5s0.5-0.8,0.5-1.3c0-0.5-0.2-0.9-0.5-1.2  s-0.7-0.5-1.2-0.5c-0.2,0-0.4,0-0.7,0.1l0.1-0.9c0.1,0,0.1,0,0.2,0c0.4,0,0.9-0.1,1.2-0.4s0.5-0.6,0.5-1.1c0-0.4-0.1-0.7-0.4-1  s-0.6-0.4-1-0.4c-0.4,0-0.8,0.1-1,0.4s-0.4,0.6-0.5,1.2l-1.1-0.2c0.1-0.7,0.4-1.3,0.9-1.6s1-0.6,1.7-0.6c0.5,0,0.9,0.1,1.3,0.3  s0.7,0.5,0.9,0.8s0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1s-0.5,0.5-0.9,0.7c0.5,0.1,0.9,0.4,1.2,0.7s0.4,0.8,0.4,1.4  c0,0.8-0.3,1.4-0.8,1.9c-0.5,0.5-1.2,0.8-2.1,0.8c-0.8,0-1.4-0.2-1.9-0.7C265.9,43.2,265.6,42.6,265.6,41.9z"/>
<path d="M272.2,41.9l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2s0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6s0.5-0.9,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4  c-0.3-0.3-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2s-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4l-0.5,2.3c0.5-0.4,1.1-0.5,1.6-0.5  c0.8,0,1.4,0.3,1.9,0.8c0.5,0.5,0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1c-0.8,0-1.4-0.2-1.9-0.7  S272.3,42.6,272.2,41.9z"/>
<path d="M278.9,39.9c0-1,0.1-1.8,0.3-2.5c0.2-0.6,0.5-1.1,0.9-1.4s0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3s0.6,0.5,0.9,0.8  s0.4,0.8,0.5,1.3s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4s-0.5,1.1-0.9,1.4c-0.4,0.3-0.9,0.5-1.6,0.5c-0.8,0-1.5-0.3-2-0.9  C279.2,42.7,278.9,41.5,278.9,39.9z M280,39.9c0,1.4,0.2,2.3,0.5,2.8s0.7,0.7,1.2,0.7c0.5,0,0.9-0.2,1.2-0.7s0.5-1.4,0.5-2.8  c0-1.4-0.2-2.4-0.5-2.8s-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C280.2,37.5,280,38.5,280,39.9z"/>
<path d="M242,52.1l-0.3-1.6V49h1.2v1.4l-0.3,1.6H242z M243.9,52.1l-0.3-1.6V49h1.2v1.4l-0.3,1.6H243.9z"/>
<path d="M245.4,57.6l3.3-8.6h1.2l3.5,8.6h-1.3l-1-2.6h-3.6l-0.9,2.6H245.4z M247.9,54.1h2.9l-0.9-2.4c-0.3-0.7-0.5-1.3-0.6-1.8  c-0.1,0.6-0.3,1.1-0.5,1.6L247.9,54.1z"/>
<path d="M254.2,57.6V49h1.1v8.6H254.2z"/>
<path d="M256.9,50.2V49h1.1v1.2H256.9z M256.9,57.6v-6.2h1.1v6.2H256.9z"/>
<path d="M263.6,55.3l1,0.1c-0.1,0.7-0.4,1.3-0.9,1.7c-0.5,0.4-1,0.6-1.7,0.6c-0.9,0-1.5-0.3-2.1-0.8c-0.5-0.6-0.8-1.4-0.8-2.4  c0-0.7,0.1-1.3,0.3-1.8s0.6-0.9,1-1.1s1-0.4,1.5-0.4c0.7,0,1.2,0.2,1.7,0.5c0.4,0.3,0.7,0.8,0.8,1.5l-1,0.2  c-0.1-0.4-0.3-0.7-0.5-0.9s-0.5-0.3-0.9-0.3c-0.5,0-1,0.2-1.3,0.6s-0.5,1-0.5,1.8c0,0.8,0.2,1.4,0.5,1.8s0.7,0.6,1.3,0.6  c0.4,0,0.8-0.1,1-0.4S263.5,55.9,263.6,55.3z"/>
<path d="M269.8,55.6l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5c-0.5,0.4-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8c-0.5-0.6-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4c0.5-0.6,1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8c0.5,0.6,0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6  c0,0.7,0.2,1.2,0.6,1.6s0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3S269.6,56.1,269.8,55.6z M266.3,53.9h3.5c0-0.5-0.2-0.9-0.4-1.2  c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5S266.4,53.4,266.3,53.9z"/>
<path d="M272.2,52.1l-0.3-1.6V49h1.2v1.4l-0.3,1.6H272.2z M274.2,52.1l-0.3-1.6V49h1.2v1.4l-0.3,1.6H274.2z"/>
<rect x="197.5" y="33.6" fill-rule="evenodd" fill="none" width="122.2" height="27"/>
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
55560bdf ASSERTION
    7092d620 pred "knows"
    9a771715 obj "Bob"
~~~

### Mermaid

<artwork type="svg"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.2" baseProfile="tiny" width="353px" height="173.7px" viewBox="0 0 353 173.7" xml:space="preserve">
<path fill="none" stroke="#000000" stroke-width="1.4993" d="M114.6,65.9l6.1-3.1c6.1-3.1,18.4-9.4,29.7-12.5  c11.3-3.1,21.5-3.1,26.6-3.1h5.1"/>
<polygon fill="black" points="174,42.6 183,47.1 174,51.6 "/>
<rect x="172.5" y="42.6" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path fill="none" stroke="#000000" stroke-width="1.4993" d="M114.6,107.9l6.1,3.1c6.1,3.1,18.4,9.4,30.7,12.5  c12.3,3.1,24.7,3.1,30.8,3.1h6.2"/>
<polygon fill="black" points="180.4,122.1 189.4,126.6 180.4,131.1 "/>
<rect x="178.9" y="122.1" fill-rule="evenodd" fill="none" width="12" height="9"/>
<path d="M140.2,53.3v-8.6h1v0.8c0.2-0.3,0.5-0.6,0.8-0.7c0.3-0.2,0.6-0.2,1-0.2c0.5,0,1,0.1,1.4,0.4c0.4,0.3,0.7,0.7,0.9,1.2  s0.3,1,0.3,1.6c0,0.6-0.1,1.2-0.3,1.7c-0.2,0.5-0.6,0.9-1,1.2s-0.9,0.4-1.4,0.4c-0.4,0-0.7-0.1-0.9-0.2c-0.3-0.1-0.5-0.3-0.7-0.6v3  H140.2z M141.1,47.8c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.8  c0-0.8-0.2-1.4-0.5-1.8c-0.3-0.4-0.7-0.6-1.2-0.6c-0.4,0-0.8,0.2-1.2,0.6C141.3,46.4,141.1,47,141.1,47.8z"/>
<path d="M146.8,50.9v-6.2h0.9v0.9c0.2-0.4,0.5-0.7,0.7-0.9c0.2-0.1,0.4-0.2,0.7-0.2c0.4,0,0.7,0.1,1.1,0.3l-0.4,1  c-0.3-0.2-0.5-0.2-0.8-0.2c-0.2,0-0.4,0.1-0.6,0.2c-0.2,0.1-0.3,0.3-0.4,0.6c-0.1,0.4-0.2,0.8-0.2,1.2v3.3H146.8z"/>
<path d="M155.1,48.9l1.1,0.1c-0.2,0.6-0.5,1.1-1,1.5c-0.5,0.4-1.1,0.5-1.8,0.5c-0.9,0-1.6-0.3-2.2-0.8s-0.8-1.3-0.8-2.4  c0-1,0.3-1.9,0.8-2.4s1.2-0.9,2.1-0.9c0.8,0,1.5,0.3,2,0.8s0.8,1.4,0.8,2.4c0,0.1,0,0.2,0,0.3h-4.6c0,0.7,0.2,1.2,0.6,1.6  s0.8,0.5,1.3,0.5c0.4,0,0.7-0.1,1-0.3C154.7,49.6,154.9,49.3,155.1,48.9z M151.6,47.2h3.5c0-0.5-0.2-0.9-0.4-1.2  c-0.3-0.4-0.8-0.6-1.3-0.6c-0.5,0-0.9,0.2-1.2,0.5S151.7,46.6,151.6,47.2z"/>
<path d="M161.6,50.9v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1c-0.2-0.5-0.3-1.1-0.3-1.7  c0-0.6,0.1-1.2,0.3-1.7c0.2-0.5,0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6v-3.1h1v8.6H161.6z   M158.2,47.8c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9  s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6C158.4,46.3,158.2,46.9,158.2,47.8z"/>
<rect x="139.4" y="40.4" fill-rule="evenodd" fill="none" width="24" height="13.5"/>
<path d="M143.8,127.3c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8s0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  c-0.2,0.5-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8S143.8,128.3,143.8,127.3z M144.9,127.3c0,0.8,0.2,1.4,0.5,1.8  c0.3,0.4,0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7c-0.3-0.4-0.8-0.6-1.3-0.6  c-0.5,0-1,0.2-1.3,0.6C145.1,125.9,144.9,126.5,144.9,127.3z"/>
<path d="M151.8,130.4h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2c0.3,0.2,0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V130.4z M151.8,127.2c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8c-0.3-0.4-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C152,125.9,151.8,126.5,151.8,127.2z"/>
<path d="M156.2,132.8l0.2-0.9c0.2,0.1,0.4,0.1,0.5,0.1c0.2,0,0.4-0.1,0.5-0.2s0.2-0.5,0.2-1.1v-6.5h1.1v6.6c0,0.8-0.1,1.3-0.3,1.6  c-0.3,0.4-0.7,0.6-1.3,0.6C156.7,132.9,156.5,132.9,156.2,132.8z M157.5,123v-1.2h1.1v1.2H157.5z"/>
<rect x="143.4" y="119.9" fill-rule="evenodd" fill="none" width="15.7" height="13.5"/>
<path fill="none" stroke="#000000" stroke-width="2.249" d="M47.1,65.9h52.6c0.7,0,1.4,0,2.1,0.1c0.7,0.1,1.4,0.2,2,0.3  c0.7,0.1,1.3,0.3,2,0.5s1.3,0.4,1.9,0.7c0.6,0.3,1.3,0.6,1.9,0.9c0.6,0.3,1.2,0.7,1.8,1.1c0.6,0.4,1.1,0.8,1.7,1.2  c0.5,0.4,1,0.9,1.5,1.4s0.9,1,1.4,1.5s0.8,1.1,1.2,1.7c0.4,0.6,0.7,1.2,1.1,1.8c0.3,0.6,0.6,1.2,0.9,1.9c0.3,0.6,0.5,1.3,0.7,1.9  c0.2,0.7,0.4,1.3,0.5,2s0.2,1.4,0.3,2c0.1,0.7,0.1,1.4,0.1,2.1s0,1.4-0.1,2.1c-0.1,0.7-0.2,1.4-0.3,2s-0.3,1.3-0.5,2  c-0.2,0.7-0.4,1.3-0.7,1.9c-0.3,0.6-0.6,1.3-0.9,1.9c-0.3,0.6-0.7,1.2-1.1,1.8c-0.4,0.6-0.8,1.1-1.2,1.7s-0.9,1-1.4,1.5  s-1,0.9-1.5,1.4c-0.5,0.4-1.1,0.8-1.7,1.2c-0.6,0.4-1.2,0.7-1.8,1.1c-0.6,0.3-1.2,0.6-1.9,0.9c-0.6,0.3-1.3,0.5-1.9,0.7  s-1.3,0.4-2,0.5c-0.7,0.1-1.4,0.2-2,0.3c-0.7,0.1-1.4,0.1-2.1,0.1H47.1c-0.7,0-1.4,0-2.1-0.1c-0.7-0.1-1.4-0.2-2-0.3  c-0.7-0.1-1.3-0.3-2-0.5s-1.3-0.4-1.9-0.7c-0.6-0.3-1.3-0.6-1.9-0.9c-0.6-0.3-1.2-0.7-1.8-1.1c-0.6-0.4-1.1-0.8-1.7-1.2  c-0.5-0.4-1-0.9-1.5-1.4c-0.5-0.5-0.9-1-1.4-1.5s-0.8-1.1-1.2-1.7c-0.4-0.6-0.7-1.2-1.1-1.8c-0.3-0.6-0.6-1.2-0.9-1.9  c-0.3-0.6-0.5-1.3-0.7-1.9c-0.2-0.7-0.4-1.3-0.5-2c-0.1-0.7-0.2-1.4-0.3-2c-0.1-0.7-0.1-1.4-0.1-2.1s0-1.4,0.1-2.1s0.2-1.4,0.3-2  c0.1-0.7,0.3-1.3,0.5-2c0.2-0.7,0.4-1.3,0.7-1.9c0.3-0.6,0.6-1.3,0.9-1.9c0.3-0.6,0.7-1.2,1.1-1.8c0.4-0.6,0.8-1.1,1.2-1.7  s0.9-1,1.4-1.5c0.5-0.5,1-0.9,1.5-1.4c0.5-0.4,1.1-0.8,1.7-1.2c0.6-0.4,1.2-0.7,1.8-1.1c0.6-0.3,1.2-0.6,1.9-0.9  c0.6-0.3,1.3-0.5,1.9-0.7s1.3-0.4,2-0.5c0.7-0.1,1.4-0.2,2-0.3C45.7,65.9,46.4,65.9,47.1,65.9z"/>
<path d="M48.9,81.6l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2s0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6c0.4-0.4,0.5-0.9,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.3-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2c-0.3,0.2-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4  l-0.5,2.3c0.5-0.4,1.1-0.5,1.6-0.5c0.7,0,1.4,0.3,1.9,0.8s0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1  c-0.8,0-1.4-0.2-1.9-0.7C49.2,82.9,49,82.3,48.9,81.6z"/>
<path d="M55.6,81.6l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2s0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6c0.4-0.4,0.5-0.9,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.3-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2c-0.3,0.2-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4  L57,78.7c0.5-0.4,1.1-0.5,1.6-0.5c0.7,0,1.4,0.3,1.9,0.8s0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1  c-0.8,0-1.4-0.2-1.9-0.7C55.9,82.9,55.6,82.3,55.6,81.6z"/>
<path d="M62.2,81.6l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2c0.3,0.3,0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6c0.4-0.4,0.5-0.9,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.3-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2c-0.3,0.2-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4  l-0.5,2.3c0.5-0.4,1.1-0.5,1.6-0.5c0.7,0,1.4,0.3,1.9,0.8s0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1  c-0.8,0-1.4-0.2-1.9-0.7C62.6,82.9,62.3,82.3,62.2,81.6z"/>
<path d="M74.4,77.4l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  c-0.2,0.5-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9c0.4-0.2,0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8s0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5  c-0.2,0.5-0.6,0.8-1,1.1S72.3,84,71.8,84c-0.9,0-1.6-0.3-2.1-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6c0.5-0.7,1.3-1,2.2-1  c0.7,0,1.2,0.2,1.7,0.6C74,76.2,74.3,76.7,74.4,77.4z M70.1,81.1c0,0.4,0.1,0.7,0.2,1c0.2,0.3,0.4,0.6,0.6,0.8  c0.3,0.2,0.6,0.3,0.9,0.3c0.4,0,0.8-0.2,1.1-0.5c0.3-0.4,0.5-0.8,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.3-0.7-0.5-1.2-0.5  c-0.5,0-0.9,0.2-1.2,0.5S70.1,80.5,70.1,81.1z"/>
<path d="M75.6,79.6c0-1,0.1-1.8,0.3-2.5c0.2-0.6,0.5-1.1,0.9-1.4c0.4-0.3,0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3  c0.3,0.2,0.6,0.5,0.9,0.8s0.4,0.8,0.5,1.3s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4c-0.2,0.6-0.5,1.1-0.9,1.4S79,84,78.4,84  c-0.8,0-1.5-0.3-1.9-0.9C75.8,82.4,75.6,81.3,75.6,79.6z M76.6,79.6c0,1.4,0.2,2.3,0.5,2.8c0.3,0.5,0.7,0.7,1.2,0.7s0.9-0.2,1.2-0.7  c0.3-0.5,0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8c-0.3-0.5-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C76.8,77.3,76.6,78.2,76.6,79.6z"/>
<path d="M83.5,83.9h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2c0.3,0.2,0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5S86,84,85.2,84c-0.7,0-1.3-0.3-1.7-0.9V83.9z M83.5,80.7c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8c-0.3-0.4-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C83.7,79.4,83.5,80,83.5,80.7z"/>
<path d="M93.2,83.9v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1c-0.2-0.5-0.3-1.1-0.3-1.7  c0-0.6,0.1-1.2,0.3-1.7c0.2-0.5,0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6v-3.1h1v8.6H93.2z   M89.9,80.8c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9  s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6C90.1,79.3,89.9,79.9,89.9,80.8z"/>
<path d="M96.1,83.9v-5.4h-0.9v-0.8h0.9V77c0-0.4,0-0.7,0.1-0.9c0.1-0.3,0.3-0.5,0.5-0.7c0.3-0.2,0.6-0.3,1.1-0.3c0.3,0,0.6,0,1,0.1  l-0.2,0.9c-0.2,0-0.4-0.1-0.6-0.1c-0.3,0-0.5,0.1-0.7,0.2c-0.1,0.1-0.2,0.4-0.2,0.8v0.6h1.2v0.8h-1.2v5.4H96.1z"/>
<path d="M38.8,97.4l3.3-8.6h1.2l3.5,8.6h-1.3l-1-2.6H41l-0.9,2.6H38.8z M41.3,93.8h2.9l-0.9-2.4c-0.3-0.7-0.5-1.3-0.6-1.8  c-0.1,0.6-0.3,1.1-0.5,1.6L41.3,93.8z"/>
<path d="M47.4,94.6l1.1-0.1c0.1,0.4,0.2,0.8,0.4,1.1c0.2,0.3,0.5,0.5,0.9,0.7c0.4,0.2,0.8,0.3,1.3,0.3c0.4,0,0.8-0.1,1.1-0.2  c0.3-0.1,0.6-0.3,0.7-0.5c0.2-0.2,0.2-0.5,0.2-0.7c0-0.3-0.1-0.5-0.2-0.7c-0.2-0.2-0.4-0.4-0.8-0.5c-0.2-0.1-0.7-0.2-1.5-0.4  s-1.3-0.4-1.7-0.5c-0.4-0.2-0.7-0.5-0.9-0.8c-0.2-0.3-0.3-0.7-0.3-1.1c0-0.4,0.1-0.8,0.4-1.2c0.2-0.4,0.6-0.7,1.1-0.9s1-0.3,1.6-0.3  c0.6,0,1.2,0.1,1.7,0.3s0.9,0.5,1.1,0.9c0.3,0.4,0.4,0.8,0.4,1.4l-1.1,0.1c-0.1-0.5-0.3-1-0.6-1.2s-0.8-0.4-1.5-0.4  c-0.7,0-1.2,0.1-1.5,0.4c-0.3,0.3-0.5,0.6-0.5,0.9c0,0.3,0.1,0.6,0.3,0.8c0.2,0.2,0.8,0.4,1.7,0.6c0.9,0.2,1.6,0.4,1.9,0.5  c0.5,0.2,0.9,0.5,1.1,0.9s0.4,0.8,0.4,1.2c0,0.5-0.1,0.9-0.4,1.3c-0.3,0.4-0.6,0.7-1.1,0.9s-1,0.3-1.7,0.3c-0.8,0-1.4-0.1-2-0.3  s-0.9-0.6-1.2-1C47.6,95.7,47.4,95.2,47.4,94.6z"/>
<path d="M55.4,94.6l1.1-0.1c0.1,0.4,0.2,0.8,0.4,1.1c0.2,0.3,0.5,0.5,0.9,0.7c0.4,0.2,0.8,0.3,1.3,0.3c0.4,0,0.8-0.1,1.1-0.2  c0.3-0.1,0.6-0.3,0.7-0.5c0.2-0.2,0.2-0.5,0.2-0.7c0-0.3-0.1-0.5-0.2-0.7c-0.2-0.2-0.4-0.4-0.8-0.5c-0.2-0.1-0.7-0.2-1.5-0.4  s-1.3-0.4-1.7-0.5c-0.4-0.2-0.7-0.5-0.9-0.8c-0.2-0.3-0.3-0.7-0.3-1.1c0-0.4,0.1-0.8,0.4-1.2c0.2-0.4,0.6-0.7,1.1-0.9s1-0.3,1.6-0.3  c0.6,0,1.2,0.1,1.7,0.3s0.9,0.5,1.1,0.9c0.3,0.4,0.4,0.8,0.4,1.4l-1.1,0.1c-0.1-0.5-0.3-1-0.6-1.2s-0.8-0.4-1.5-0.4  c-0.7,0-1.2,0.1-1.5,0.4c-0.3,0.3-0.5,0.6-0.5,0.9c0,0.3,0.1,0.6,0.3,0.8c0.2,0.2,0.8,0.4,1.7,0.6c0.9,0.2,1.6,0.4,1.9,0.5  c0.5,0.2,0.9,0.5,1.1,0.9s0.4,0.8,0.4,1.2c0,0.5-0.1,0.9-0.4,1.3c-0.3,0.4-0.6,0.7-1.1,0.9s-1,0.3-1.7,0.3c-0.8,0-1.4-0.1-2-0.3  s-0.9-0.6-1.2-1C55.6,95.7,55.4,95.2,55.4,94.6z"/>
<path d="M63.8,97.4v-8.6H70v1h-5.1v2.6h4.7v1h-4.7v2.9h5.3v1H63.8z"/>
<path d="M71.8,97.4v-8.6h3.8c0.8,0,1.3,0.1,1.7,0.2s0.7,0.4,1,0.8c0.2,0.4,0.4,0.8,0.4,1.3c0,0.6-0.2,1.1-0.6,1.5  c-0.4,0.4-1,0.7-1.8,0.8c0.3,0.1,0.5,0.3,0.7,0.4c0.3,0.3,0.6,0.7,0.9,1.1l1.5,2.3h-1.4l-1.1-1.8c-0.3-0.5-0.6-0.9-0.8-1.2  c-0.2-0.3-0.4-0.5-0.6-0.6c-0.2-0.1-0.3-0.2-0.5-0.2c-0.1,0-0.3,0-0.6,0h-1.3v3.8H71.8z M72.9,92.6h2.4c0.5,0,0.9-0.1,1.2-0.2  c0.3-0.1,0.5-0.3,0.7-0.5s0.2-0.5,0.2-0.8c0-0.4-0.1-0.7-0.4-1c-0.3-0.3-0.8-0.4-1.4-0.4h-2.7V92.6z"/>
<path d="M82.4,97.4v-7.6h-2.8v-1h6.8v1h-2.8v7.6H82.4z"/>
<path d="M87.7,97.4v-8.6h1.1v8.6H87.7z"/>
<path d="M90.5,93.2c0-1.4,0.4-2.5,1.1-3.3c0.8-0.8,1.8-1.2,3-1.2c0.8,0,1.5,0.2,2.1,0.6c0.6,0.4,1.1,0.9,1.5,1.6  c0.3,0.7,0.5,1.4,0.5,2.3c0,0.9-0.2,1.7-0.5,2.3c-0.4,0.7-0.8,1.2-1.5,1.6c-0.6,0.4-1.3,0.5-2.1,0.5c-0.8,0-1.5-0.2-2.2-0.6  S91.3,96,91,95.3S90.5,93.9,90.5,93.2z M91.7,93.2c0,1,0.3,1.9,0.8,2.4s1.3,0.9,2.1,0.9c0.9,0,1.6-0.3,2.1-0.9s0.8-1.5,0.8-2.6  c0-0.7-0.1-1.3-0.4-1.8c-0.2-0.5-0.6-0.9-1-1.2c-0.5-0.3-1-0.4-1.5-0.4c-0.8,0-1.5,0.3-2.1,0.8S91.7,91.9,91.7,93.2z"/>
<path d="M100.2,97.4v-8.6h1.2l4.5,6.7v-6.7h1.1v8.6h-1.2l-4.5-6.8v6.8H100.2z"/>
<rect x="38.9" y="73.4" fill-rule="evenodd" fill="none" width="68.9" height="27"/>
<rect x="182.1" y="26.1" fill="none" stroke="#000000" stroke-width="2.249" width="144.7" height="42"/>
<path d="M228.4,36.7v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  c0.3-1,0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H228.4z"/>
<path d="M235,39.9c0-1,0.1-1.8,0.3-2.5c0.2-0.6,0.5-1.1,0.9-1.4c0.4-0.3,0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3  c0.3,0.2,0.6,0.5,0.9,0.8s0.4,0.8,0.5,1.3s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4c-0.2,0.6-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5  c-0.8,0-1.5-0.3-1.9-0.9C235.3,42.7,235,41.5,235,39.9z M236.1,39.9c0,1.4,0.2,2.3,0.5,2.8c0.3,0.5,0.7,0.7,1.2,0.7s0.9-0.2,1.2-0.7  c0.3-0.5,0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8c-0.3-0.5-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C236.3,37.5,236.1,38.5,236.1,39.9  z"/>
<path d="M241.8,42.1l1-0.1c0.1,0.5,0.2,0.8,0.5,1s0.6,0.3,0.9,0.3c0.3,0,0.6-0.1,0.9-0.2c0.2-0.1,0.4-0.3,0.6-0.6  c0.2-0.2,0.3-0.6,0.4-1s0.2-0.9,0.2-1.3c0,0,0-0.1,0-0.2c-0.2,0.3-0.5,0.6-0.9,0.8s-0.8,0.3-1.2,0.3c-0.7,0-1.3-0.3-1.8-0.8  s-0.7-1.2-0.7-2c0-0.9,0.3-1.6,0.8-2.1s1.2-0.8,1.9-0.8c0.6,0,1.1,0.2,1.5,0.5s0.8,0.7,1.1,1.3c0.2,0.6,0.4,1.4,0.4,2.4  c0,1.1-0.1,2-0.4,2.6c-0.2,0.7-0.6,1.1-1.1,1.5s-1,0.5-1.7,0.5c-0.7,0-1.2-0.2-1.6-0.6S241.9,42.8,241.8,42.1z M246.1,38.3  c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.4-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.6s-0.5,0.9-0.5,1.5c0,0.5,0.2,1,0.5,1.3  c0.3,0.3,0.7,0.5,1.2,0.5c0.5,0,0.9-0.2,1.2-0.5C246,39.4,246.1,39,246.1,38.3z"/>
<path d="M253.9,43.1v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1c0.3-0.4,0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8  c0.3-0.4,0.5-0.9,0.5-1.3c0-0.4-0.1-0.8-0.4-1.1c-0.3-0.3-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5c-0.3,0.3-0.5,0.7-0.5,1.3  l-1.1-0.1c0.1-0.8,0.4-1.4,0.8-1.8s1.1-0.6,1.9-0.6c0.8,0,1.5,0.2,2,0.7s0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1c-0.1,0.3-0.4,0.7-0.7,1  c-0.3,0.4-0.9,0.9-1.6,1.5c-0.6,0.5-1,0.9-1.2,1.1c-0.2,0.2-0.3,0.4-0.4,0.6H253.9z"/>
<path d="M259.3,44.1v-0.8c-0.4,0.6-1,0.9-1.7,0.9c-0.5,0-1-0.1-1.4-0.4s-0.7-0.7-1-1.1c-0.2-0.5-0.3-1.1-0.3-1.7  c0-0.6,0.1-1.2,0.3-1.7c0.2-0.5,0.5-0.9,0.9-1.2s0.9-0.4,1.4-0.4c0.4,0,0.7,0.1,1,0.2c0.3,0.2,0.5,0.4,0.7,0.6v-3.1h1v8.6H259.3z   M256,41c0,0.8,0.2,1.4,0.5,1.8c0.3,0.4,0.7,0.6,1.2,0.6c0.5,0,0.9-0.2,1.2-0.6s0.5-1,0.5-1.7c0-0.9-0.2-1.5-0.5-1.9  s-0.7-0.6-1.2-0.6c-0.5,0-0.9,0.2-1.2,0.6C256.2,39.6,256,40.2,256,41z"/>
<path d="M267.1,37.6l-1,0.1c-0.1-0.4-0.2-0.7-0.4-0.9c-0.3-0.3-0.6-0.5-1.1-0.5c-0.3,0-0.6,0.1-0.9,0.3c-0.3,0.2-0.6,0.6-0.8,1.1  c-0.2,0.5-0.3,1.1-0.3,2c0.3-0.4,0.6-0.7,0.9-0.9c0.4-0.2,0.8-0.3,1.2-0.3c0.7,0,1.3,0.3,1.8,0.8s0.7,1.2,0.7,2c0,0.5-0.1,1-0.3,1.5  c-0.2,0.5-0.6,0.8-1,1.1s-0.9,0.4-1.4,0.4c-0.9,0-1.6-0.3-2.1-1c-0.6-0.6-0.8-1.7-0.8-3.2c0-1.7,0.3-2.9,0.9-3.6  c0.5-0.7,1.3-1,2.2-1c0.7,0,1.2,0.2,1.7,0.6C266.8,36.4,267.1,37,267.1,37.6z M262.8,41.3c0,0.4,0.1,0.7,0.2,1  c0.2,0.3,0.4,0.6,0.6,0.8c0.3,0.2,0.6,0.3,0.9,0.3c0.4,0,0.8-0.2,1.1-0.5c0.3-0.4,0.5-0.8,0.5-1.5c0-0.6-0.2-1.1-0.5-1.4  c-0.3-0.3-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.5S262.8,40.8,262.8,41.3z"/>
<path d="M273.9,43.1v1h-5.7c0-0.3,0-0.5,0.1-0.7c0.1-0.4,0.4-0.8,0.7-1.1c0.3-0.4,0.8-0.8,1.4-1.3c0.9-0.8,1.6-1.4,1.9-1.8  c0.3-0.4,0.5-0.9,0.5-1.3c0-0.4-0.1-0.8-0.4-1.1c-0.3-0.3-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.2-1.2,0.5c-0.3,0.3-0.5,0.7-0.5,1.3  l-1.1-0.1c0.1-0.8,0.4-1.4,0.8-1.8s1.1-0.6,1.9-0.6c0.8,0,1.5,0.2,2,0.7s0.7,1,0.7,1.7c0,0.3-0.1,0.7-0.2,1c-0.1,0.3-0.4,0.7-0.7,1  c-0.3,0.4-0.9,0.9-1.6,1.5c-0.6,0.5-1,0.9-1.2,1.1c-0.2,0.2-0.3,0.4-0.4,0.6H273.9z"/>
<path d="M275,39.9c0-1,0.1-1.8,0.3-2.5c0.2-0.6,0.5-1.1,0.9-1.4c0.4-0.3,0.9-0.5,1.6-0.5c0.5,0,0.9,0.1,1.2,0.3  c0.3,0.2,0.6,0.5,0.9,0.8s0.4,0.8,0.5,1.3s0.2,1.2,0.2,2c0,1-0.1,1.8-0.3,2.4c-0.2,0.6-0.5,1.1-0.9,1.4s-0.9,0.5-1.6,0.5  c-0.8,0-1.5-0.3-1.9-0.9C275.3,42.7,275,41.5,275,39.9z M276.1,39.9c0,1.4,0.2,2.3,0.5,2.8c0.3,0.5,0.7,0.7,1.2,0.7s0.9-0.2,1.2-0.7  c0.3-0.5,0.5-1.4,0.5-2.8c0-1.4-0.2-2.4-0.5-2.8c-0.3-0.5-0.7-0.7-1.2-0.7c-0.5,0-0.9,0.2-1.2,0.6C276.3,37.5,276.1,38.5,276.1,39.9  z"/>
<path d="M234.1,52.1l-0.3-1.6V49h1.2v1.4l-0.3,1.6H234.1z M236,52.1l-0.3-1.6V49h1.2v1.4l-0.3,1.6H236z"/>
<path d="M238.3,57.6V49h1.1v4.9l2.5-2.5h1.4l-2.4,2.3l2.6,3.9h-1.3l-2.1-3.2l-0.7,0.7v2.5H238.3z"/>
<path d="M244.3,57.6v-6.2h0.9v0.9c0.5-0.7,1.1-1,2-1c0.4,0,0.7,0.1,1,0.2c0.3,0.1,0.5,0.3,0.7,0.5s0.3,0.5,0.3,0.8  c0,0.2,0.1,0.5,0.1,1v3.8h-1.1v-3.8c0-0.4,0-0.8-0.1-1c-0.1-0.2-0.2-0.4-0.4-0.5c-0.2-0.1-0.5-0.2-0.7-0.2c-0.4,0-0.8,0.1-1.2,0.4  c-0.3,0.3-0.5,0.8-0.5,1.6v3.4H244.3z"/>
<path d="M250.6,54.5c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8s0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  c-0.2,0.5-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8S250.6,55.6,250.6,54.5z M251.7,54.5c0,0.8,0.2,1.4,0.5,1.8  c0.3,0.4,0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7c-0.3-0.4-0.8-0.6-1.3-0.6  c-0.5,0-1,0.2-1.3,0.6C251.8,53.1,251.7,53.7,251.7,54.5z"/>
<path d="M258.8,57.6l-1.9-6.2h1.1l1,3.6l0.4,1.3c0-0.1,0.1-0.5,0.3-1.3l1-3.6h1.1l0.9,3.6l0.3,1.2l0.4-1.2l1.1-3.6h1l-1.9,6.2h-1.1  l-1-3.7l-0.2-1.1l-1.3,4.8H258.8z"/>
<path d="M265.9,55.8l1-0.2c0.1,0.4,0.2,0.7,0.5,1c0.3,0.2,0.6,0.3,1.1,0.3c0.5,0,0.8-0.1,1.1-0.3c0.2-0.2,0.4-0.4,0.4-0.7  c0-0.2-0.1-0.4-0.3-0.6c-0.1-0.1-0.5-0.2-1.1-0.4c-0.8-0.2-1.3-0.4-1.6-0.5c-0.3-0.1-0.5-0.3-0.7-0.6c-0.2-0.3-0.2-0.5-0.2-0.8  c0-0.3,0.1-0.5,0.2-0.8c0.1-0.2,0.3-0.4,0.5-0.6c0.2-0.1,0.4-0.2,0.7-0.3c0.3-0.1,0.6-0.1,0.9-0.1c0.5,0,0.9,0.1,1.3,0.2  c0.4,0.1,0.6,0.3,0.8,0.6s0.3,0.6,0.4,1l-1,0.1c0-0.3-0.2-0.6-0.4-0.8c-0.2-0.2-0.5-0.3-1-0.3c-0.5,0-0.8,0.1-1,0.2  c-0.2,0.2-0.3,0.3-0.3,0.6c0,0.1,0,0.3,0.1,0.4c0.1,0.1,0.2,0.2,0.4,0.3c0.1,0,0.4,0.1,0.9,0.3c0.7,0.2,1.3,0.4,1.6,0.5  c0.3,0.1,0.5,0.3,0.7,0.6c0.2,0.2,0.3,0.5,0.3,0.9c0,0.4-0.1,0.7-0.3,1c-0.2,0.3-0.5,0.6-0.9,0.7s-0.8,0.3-1.3,0.3  c-0.8,0-1.4-0.2-1.8-0.5C266.3,56.9,266,56.4,265.9,55.8z"/>
<path d="M272.3,52.1l-0.3-1.6V49h1.2v1.4l-0.3,1.6H272.3z M274.3,52.1l-0.3-1.6V49h1.2v1.4l-0.3,1.6H274.3z"/>
<rect x="189.6" y="33.6" fill-rule="evenodd" fill="none" width="129.6" height="27"/>
<rect x="188.5" y="105.6" fill="none" stroke="#000000" stroke-width="2.249" width="132.1" height="42"/>
<path d="M228.5,121.6l1-0.1c0.1,0.5,0.2,0.8,0.5,1s0.6,0.3,0.9,0.3c0.3,0,0.6-0.1,0.9-0.2c0.2-0.1,0.4-0.3,0.6-0.6  c0.2-0.2,0.3-0.6,0.4-1s0.2-0.9,0.2-1.3c0,0,0-0.1,0-0.2c-0.2,0.3-0.5,0.6-0.9,0.8s-0.8,0.3-1.2,0.3c-0.7,0-1.3-0.3-1.8-0.8  s-0.7-1.2-0.7-2c0-0.9,0.3-1.6,0.8-2.1s1.2-0.8,1.9-0.8c0.6,0,1.1,0.2,1.5,0.5s0.8,0.7,1.1,1.3c0.2,0.6,0.4,1.4,0.4,2.4  c0,1.1-0.1,2-0.4,2.6c-0.2,0.7-0.6,1.1-1.1,1.5s-1,0.5-1.7,0.5c-0.7,0-1.2-0.2-1.6-0.6S228.6,122.3,228.5,121.6z M232.8,117.8  c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.4-0.7-0.5-1.2-0.5c-0.5,0-0.9,0.2-1.2,0.6s-0.5,0.9-0.5,1.5c0,0.5,0.2,1,0.5,1.3  c0.3,0.3,0.7,0.5,1.2,0.5c0.5,0,0.9-0.2,1.2-0.5C232.7,118.9,232.8,118.5,232.8,117.8z"/>
<path d="M239.4,122.9c-0.4,0.3-0.8,0.6-1.1,0.7s-0.7,0.2-1.2,0.2c-0.7,0-1.2-0.2-1.6-0.5s-0.6-0.8-0.6-1.3c0-0.3,0.1-0.6,0.2-0.8  c0.1-0.3,0.3-0.5,0.5-0.6c0.2-0.2,0.5-0.3,0.8-0.3c0.2-0.1,0.5-0.1,0.9-0.2c0.9-0.1,1.5-0.2,1.9-0.4c0-0.1,0-0.2,0-0.3  c0-0.4-0.1-0.7-0.3-0.9c-0.3-0.2-0.7-0.4-1.2-0.4c-0.5,0-0.9,0.1-1.1,0.3s-0.4,0.5-0.5,0.9l-1-0.1c0.1-0.4,0.2-0.8,0.5-1.1  c0.2-0.3,0.5-0.5,0.9-0.6s0.9-0.2,1.4-0.2c0.5,0,1,0.1,1.3,0.2c0.3,0.1,0.6,0.3,0.7,0.5s0.3,0.4,0.3,0.7c0,0.2,0.1,0.5,0.1,1v1.4  c0,1,0,1.6,0.1,1.9s0.1,0.5,0.3,0.7h-1.1C239.5,123.4,239.4,123.1,239.4,122.9z M239.3,120.5c-0.4,0.2-1,0.3-1.7,0.4  c-0.4,0.1-0.7,0.1-0.9,0.2s-0.3,0.2-0.4,0.3s-0.1,0.3-0.1,0.5c0,0.3,0.1,0.5,0.3,0.7c0.2,0.2,0.5,0.3,0.9,0.3c0.4,0,0.8-0.1,1.1-0.3  c0.3-0.2,0.5-0.4,0.7-0.7c0.1-0.2,0.2-0.6,0.2-1.1V120.5z"/>
<path d="M241.7,116.2v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  c0.3-1,0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H241.7z"/>
<path d="M248.4,116.2v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  c0.3-1,0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H248.4z"/>
<path d="M259,123.6h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7c-0.4,0.2-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1c0.4-0.4,0.8-0.8,0.9-1.1  h0.7V123.6z"/>
<path d="M261.7,116.2v-1h5.6v0.8c-0.5,0.6-1.1,1.4-1.6,2.3s-1,2-1.2,3c-0.2,0.7-0.3,1.5-0.4,2.4h-1.1c0-0.7,0.1-1.5,0.4-2.4  c0.3-1,0.6-1.9,1.1-2.8s1-1.6,1.5-2.2H261.7z"/>
<path d="M272.3,123.6h-1.1v-6.7c-0.3,0.2-0.6,0.5-1,0.7c-0.4,0.2-0.8,0.4-1.1,0.5v-1c0.6-0.3,1.1-0.6,1.5-1c0.4-0.4,0.8-0.8,0.9-1.1  h0.7V123.6z"/>
<path d="M275,121.4l1.1-0.1c0.1,0.5,0.3,0.9,0.6,1.2s0.7,0.4,1.1,0.4c0.5,0,0.9-0.2,1.3-0.6c0.4-0.4,0.5-0.9,0.5-1.5  c0-0.6-0.2-1.1-0.5-1.4c-0.3-0.3-0.8-0.5-1.3-0.5c-0.3,0-0.6,0.1-0.9,0.2c-0.3,0.2-0.5,0.4-0.6,0.6l-1-0.1l0.8-4.4h4.3v1h-3.4  l-0.5,2.3c0.5-0.4,1.1-0.5,1.6-0.5c0.7,0,1.4,0.3,1.9,0.8s0.8,1.2,0.8,2c0,0.8-0.2,1.4-0.7,2c-0.6,0.7-1.3,1-2.3,1  c-0.8,0-1.4-0.2-1.9-0.7C275.4,122.7,275.1,122.1,275,121.4z"/>
<path d="M240.4,131.6l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H240.4z M242.4,131.6l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H242.4z"/>
<path d="M244.7,137.1v-8.6h3.2c0.7,0,1.2,0.1,1.6,0.3c0.4,0.2,0.7,0.4,0.9,0.8c0.2,0.4,0.3,0.7,0.3,1.1c0,0.4-0.1,0.7-0.3,1  c-0.2,0.3-0.5,0.6-0.9,0.8c0.5,0.2,0.9,0.4,1.2,0.8c0.3,0.4,0.4,0.8,0.4,1.3c0,0.4-0.1,0.8-0.3,1.1s-0.4,0.6-0.6,0.8  c-0.2,0.2-0.6,0.3-0.9,0.4c-0.4,0.1-0.8,0.1-1.4,0.1H244.7z M245.9,132.1h1.9c0.5,0,0.9,0,1.1-0.1c0.3-0.1,0.5-0.2,0.7-0.4  c0.1-0.2,0.2-0.4,0.2-0.8c0-0.3-0.1-0.5-0.2-0.8c-0.1-0.2-0.3-0.4-0.6-0.4c-0.3-0.1-0.7-0.1-1.3-0.1h-1.7V132.1z M245.9,136.1h2.1  c0.4,0,0.6,0,0.8,0c0.3,0,0.5-0.1,0.7-0.2c0.2-0.1,0.3-0.3,0.4-0.5s0.2-0.5,0.2-0.7c0-0.3-0.1-0.6-0.2-0.8s-0.4-0.4-0.7-0.5  c-0.3-0.1-0.7-0.1-1.3-0.1h-2V136.1z"/>
<path d="M252.2,134c0-1.2,0.3-2,1-2.6c0.5-0.5,1.2-0.7,2-0.7c0.9,0,1.6,0.3,2.1,0.8s0.8,1.3,0.8,2.3c0,0.8-0.1,1.4-0.4,1.9  c-0.2,0.5-0.6,0.8-1,1.1s-1,0.4-1.5,0.4c-0.9,0-1.6-0.3-2.1-0.8S252.2,135.1,252.2,134z M253.3,134c0,0.8,0.2,1.4,0.5,1.8  c0.3,0.4,0.8,0.6,1.3,0.6c0.5,0,1-0.2,1.3-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.7c-0.3-0.4-0.8-0.6-1.3-0.6  c-0.5,0-1,0.2-1.3,0.6C253.5,132.6,253.3,133.2,253.3,134z"/>
<path d="M260.3,137.1h-1v-8.6h1.1v3.1c0.4-0.6,1-0.8,1.7-0.8c0.4,0,0.7,0.1,1.1,0.2c0.3,0.2,0.6,0.4,0.8,0.7c0.2,0.3,0.4,0.6,0.5,1  s0.2,0.8,0.2,1.3c0,1.1-0.3,1.9-0.8,2.5s-1.2,0.9-1.9,0.9c-0.7,0-1.3-0.3-1.7-0.9V137.1z M260.3,134c0,0.7,0.1,1.3,0.3,1.6  c0.3,0.5,0.8,0.8,1.3,0.8c0.5,0,0.9-0.2,1.2-0.6c0.3-0.4,0.5-1,0.5-1.8c0-0.8-0.2-1.4-0.5-1.8c-0.3-0.4-0.7-0.6-1.2-0.6  c-0.5,0-0.9,0.2-1.2,0.6C260.4,132.6,260.3,133.2,260.3,134z"/>
<path d="M266,131.6l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H266z M268,131.6l-0.3-1.6v-1.4h1.2v1.4l-0.3,1.6H268z"/>
<rect x="196" y="113.1" fill-rule="evenodd" fill="none" width="116.9" height="27"/>
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

Because each element of an envelope provides a unique digest, and because changing an element in an envelope changes the digest of all elements upwards towards its root, the structure of an envelope is comparable to a {{MERKLE}}.

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

For changes that are more sweeping, like supporting a different hash algorithm to produce the merkle tree digests, it would be necessary to use a different top-level CBOR tag to represent the envelope itself. Currently the envelope tag is #6.200, and the choice of digest algorithm in our reference implementation is BLAKE3. If this version were officially released and a future version of Gordian Envelope was also released that supported SHA-256, it will need to have a different tag. However, a problem for interoperability of these two distinct formats then arises in the choice of whether a particular envelope is encoded assuming BLAKE3 or SHA-256. Whenever there is a choice about two or more ways to encode particular data, this violates the determinism requirement that Gordian Envelopes are designed to uphold. In other words, an envelope encoding certain information using BLAKE3 will not, in general, be structurally identical to the same information encoded in an envelope using SHA-256. For instance, they will both have different root hashes, and simply knowing which algorithm produced each one will not help you know whether they have equivalent content. Only two envelope cases actually encode their digest in the binary stream: ELIDED and ENCRYPTED. If an envelope doesn't use either of these cases, then you could choose to decode the envelope with either algorithm, but if it does use either of these cases then the envelope will still decode, but attempting to decrypt or unelide its contents will result in mismatched digests. This is why the envelope itself needs to declare the hashing algorithm used using its top-level CBOR tag, and why the choice of which hash algorithm to commit to should be carefully considered.

# Security Considerations

This section is informative unless noted otherwise.

## Structural Considerations

### CBOR Considerations

Generally, this document inherits the security considerations of CBOR {{-CBOR}}. Though CBOR has limited web usage, it has received strong usage in hardware, resulting in a mature specification.

## Cryptographic Considerations

### Inherited Considerations

Generally, this document inherits the security considerations of the cryptographic constructs it uses such as IETF-ChaCha20-Poly1305 {{-CHACHA}} and BLAKE3 {{BLAKE3}}.

### Choice of Cryptographic Primitives (No Set Curve)

Though envelope recommends the use of certain cryptographic algorithms, most are not required (with the exception of BLAKE3 usage, noted below). In particular, envelope has no required curve. Different choices will obviously result in different security considerations.

## Validation Requirements

Unlike HTML, envelope is intended to be conservative in both what it sends _and_ what it accepts. This means that receivers of envelope-based documents should carefully validate them. Any deviation from the validation requirements of this specification MUST result in the rejection of the entire envelope. Even after validation, envelope contents should be treated with due skepticism.

## Signature Considerations

This specification allows the signing of envelopes that are partially (or even entirely) elided. There may be use cases for this, such as when multiple users are each signing partially elided envelopes that will then be united. However, it's generally a dangerous practice. Our own tools require overrides to allow it. Other developers should take care to warn users of the dangers of signing elided envelopes.

## Hashing

### Choice of BLAKE3 Hash Primitive

Although BLAKE2 is more widely supported by IETF specifications, envelope instead makes use of BLAKE3. This is to take advantage of advances in the updated protocol: the new BLAKE3 implementation uses a Merkle Tree format that allows for streaming and for incremental updates as well as high levels of parallelism. The fact that BLAKE3 is newer should be taken into consideration, but its foundation in BLAKE2 and its support by experts such as the Zcash Foundation are considered to grant it sufficient maturity.

Whereas envelope is written to allow for the easy exchange of most of its cryptographic protocols, this is not true for BLAKE3: swapping for another hash protocol would result in incompatible envelopes. Thus, any security considerations related to BLAKE3 should be given careful attention.

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

See https://bitslog.com/2018/06/09/leaf-node-weakness-in-bitcoin-merkle-tree-design/ for the leaf-node attack.

### Forgery Attacks on Unbalanced Trees

Envelopes should also be proof against forgery attacks before of their different construction, where all nodes contain both data and hashes. Nonetheless, care must still be taken with trees, especially when also using elision, which limits visible information.

See https://bitcointalk.org/?topic=102395 for the forgery attack.

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
