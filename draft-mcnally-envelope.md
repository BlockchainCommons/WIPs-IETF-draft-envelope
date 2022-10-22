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
    IANA-CBOR-TAGS:
        title: IANA, Concise Binary Object Representation (CBOR) Tags
        target: https://www.iana.org/assignments/cbor-tags/cbor-tags.xhtml

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

--- abstract

TODO Abstract


--- middle

# Introduction

This document describes the `envelope` protocol for hierarchical structured binary data. Envelope has a number of features that distinguish it from other forms of structured data formats, for example JSON {{RFC8259}} (envelopes are binary, not text), JSON-LD {{JSONLD}} (envelopes require no normalization because they are always in canonical form), and protocol buffers {{PROTOBUF}} (envelopes allow for, but do not require a pre-existing schema.)

## Feature: Digest Tree

One of the key features of envelope is that it structurally provides a tree of digests for all its elements, similar to a Merkle Tree {{MERKLE}}. Additionally, each element in an envelope's hierarchy is itself an envelope, making it a recursive structure. Each element in an envelope MAY be abitrary CBOR, or one of several other types of elements that provide the envelope's structure.

## Feature: Semantic Structure

Envelope is designed to facilitate the encoding semantic triples {{TRIPLE}}, i.e., "subject-predicate-object", e.g. "Alice knows Bob". At its top structural level, an envelope encodes a single `subject` and a set of zero or more assertions about the subject, which are `predicate-object` pairs:

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

Envelopes are a binary structure built on CBOR {{RFC8949}}, and MUST adhere to the requirements in section 4.2., "Deterministically Encoded CBOR". This requirement is one factor ensuring that two envelopes that have the same top-level digest, and therefore contain the same digest tree, MUST contain exactly the same information. This holds true even if the two identical envelopes were assembled by different parties, at different times, and particularly in different orders.

## Feature: Digest-Preserving Encryption and Elision

Envelope supports two digest-tree preserving transformations for any of its elements: encryption and elision.

When an element is encrypted, its ciphertext remains in the envelope, and the transformation can be reversed using the symmetric key used to perform the encryption. The encrypted envelope declares the digest of its unencrypted content using HMAC authentication. More sophisticated cryptographic constructs such as encryption to a set of public keys are easily supported.

When an element is elided, only its digest remains in the envelope as a placeholder, and the transformation can only be reversed by subsitution with the envelope having the same root digest. Elision can be used as a form of redaction, where the holder of a document reveals part of it while deliberately withholding other parts, or as a form of referencing, where the digest is used as the unique identifier of a digital object that can be found outside the envelope, or as a form of compression where many identical sub-elements of an envelope (except one) are elided.

These digest-tree preserving transformations allow the holder of an envelope-based document to selectively reveal parts of it to third parties without invalidating its signatures. It is also possible to produce proofs that one envelope (or even just the root digest of an envelope) contains another envelope by revealing only a minimum spanning set of digests.

# Conventions and Definitions

{::boilerplate bcp14-tagged}

# Envelope Hierarchy

TODO This section describes envelopes from the perspective of their hierachical structure and the semantic constructs it supports.

~~~
subject [
    predicate1: object2
    predicate2: object2
    ...
]
~~~

In the diagram above, there are five distinct positions of elements, each of which is itself an enveope and which therefore produces its own digest:

1. envelope
2. subject
3. predicate
4. object
5. assertion

Note that the envelope digest is not the same as the subject's digest, as it includes the digests of the envelope's assertions as well. Also note that while the predicate and object of an assertion are distinct envelopes, the assertion as a whole is also a distinct envelope.


# Envelope Format

TODO This section describes the binary format of envelopes in terms of its CBOR components and their sequencing.


# Reference Implementation

TODO This section describes the current reference implementations.


# Security Considerations

TODO Security


# IANA Considerations

TODO This section describes a request that IANA allocated specific CBOR tags in its CBOR tag registry {{IANA-CBOR-TAGS}} to the purpose of encoding the envelope type.


--- back

# Acknowledgments
{:numbered="false"}

TODO acknowledge.
