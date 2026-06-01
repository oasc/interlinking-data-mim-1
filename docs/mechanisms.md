# Mechanisms

## MIM2 Mechanism Draft: Linked Data with RDF, OWL, and SHACL

#### 1. Overview

This Mechanism defines how public sector data systems can interlink and identify entities in an interoperable, machine-interpretable way using **RDF 1.2, OWL 2, SHACL 1.2, and SPARQL 1.2**. It fulfils all capabilities and requirements of MIM2 (Interlinking Data) and is grounded in the W3C Semantic Web standards stack, which provides the most mature and widely deployed foundation for entity identification, typing, dereferencing, and cross-system identity mapping on the Web.

The Mechanism is technology-neutral with respect to the domain model: it mandates _how_ entities are named, typed, described, and linked — not _what_ domain ontology is used. It is applicable to any smart city data domain: infrastructure assets, sensors, persons, organisations, administrative units, events, and more.

***

#### 2. Core Standards Referenced

| Standard                                     | Role in this Mechanism                                                                                                                               |
| -------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| **RDF 1.2** (W3C CR, April 2026)             | Core data model: all entities and their properties are expressed as subject–predicate–object triples using IRIs and literals                         |
| **RDF Schema (RDFS) 1.1** (W3C Rec)          | Lightweight class and property hierarchies, `rdfs:label`, `rdfs:comment`, `rdfs:seeAlso` for human- and machine-readable descriptions                |
| **OWL 2** (W3C Rec)                          | Formal ontology language for entity typing, equivalence (`owl:sameAs`, `owl:equivalentClass`), and logical constraints enabling automated reasoning  |
| **SHACL 1.2** (W3C CR, 2025)                 | Closed-world constraint language for validating RDF graphs against shape definitions; used to enforce data quality and schema compliance             |
| **SPARQL 1.2** (W3C WD, 2026)                | Query and update language over RDF datasets; used for entity lookup, federation, and programmatic access                                             |
| **JSON-LD 1.1** (W3C Rec)                    | JSON serialisation of RDF with `@context` mappings; the recommended exchange format for developer-friendly consumption                               |
| **Turtle 1.1** (W3C Rec)                     | Compact, human-readable RDF serialisation; recommended for ontology authoring and static publishing                                                  |
| **SKOS** (W3C Rec)                           | Simple Knowledge Organisation System; used for concept alignment and lightweight cross-vocabulary mappings (`skos:exactMatch`, `skos:broadMatch`)    |
| **Linked Data Platform 1.0 (LDP)** (W3C Rec) | HTTP-based protocol for reading and writing RDF resources; governs how entity IRIs are resolved and how containers expose collections of resources   |
| **RFC 9110** – HTTP Semantics (IETF)         | Foundation for IRI dereferencing, content negotiation (`Accept`/`Content-Type`), and `303 See Other` redirect patterns for non-information resources |
| **W3C Cool URIs for the Semantic Web**       | Best-practice guidance for persistent, dereferenceable, hash- or slash-based IRI design                                                              |

***

#### 3. Mechanism Description

**3.1 Entity Identification with Globally Unique IRIs (C1)**

Every entity exposed by a system conforming to this Mechanism is identified by an **IRI (Internationalised Resource Identifier)** — the RDF-native form of URI, as defined in RDF 1.2. IRIs serve simultaneously as the unique identifier and as the retrieval address for the entity's description.

IRI design follows the W3C _Cool URIs for the Semantic Web_ guidance. Two patterns are supported:

**Hash URIs** (preferred for ontologies and small datasets):

```
https://data.city.example/ontology/building#Building
```

The document at `https://data.city.example/ontology/building` describes all resources in that namespace. The fragment `#Building` identifies the specific entity within it.

**Slash URIs** (preferred for large instance datasets):

```
https://data.city.example/resource/sensor/S-00421
```

An HTTP `GET` on this IRI returns a description of that sensor. For non-information resources (physical objects, people), the server issues a `303 See Other` redirect to a document IRI, following the _httpRange-14_ pattern, so that the IRI consistently identifies the real-world thing while a separate document describes it.

**Persistence** is guaranteed by minting IRIs under a domain or path prefix that is under long-term governance control (e.g., a city's official data domain, a national URI authority, or a handle/ARK resolver that redirects to current locations). The IRI is treated as the canonical identifier in all downstream systems; implementations MUST NOT generate IRIs that embed volatile implementation details such as database row IDs or server hostnames.

**3.2 Entity Lookup by IRI (C1 — R1.2)**

The Mechanism uses **HTTP content negotiation** (RFC 9110) to serve the description of an entity based on the client's `Accept` header. When a client dereferences an entity IRI, the server returns a machine-readable RDF description in the requested serialisation:

| `Accept` Header         | Format Returned                                                 |
| ----------------------- | --------------------------------------------------------------- |
| `application/ld+json`   | JSON-LD 1.1 (recommended default)                               |
| `text/turtle`           | Turtle 1.1                                                      |
| `application/rdf+xml`   | RDF/XML                                                         |
| `application/n-triples` | N-Triples                                                       |
| `text/html`             | Human-readable HTML (with embedded JSON-LD in a `<script>` tag) |

The returned RDF document contains at minimum:

* The entity's IRI as subject
* An `rdf:type` triple declaring the entity's class
* A `rdfs:label` in at least one language
* Any `owl:sameAs` or `skos:exactMatch` links to equivalent entities in other systems
* An `rdfs:isDefinedBy` link pointing to the governing ontology

This makes every entity self-describing and machine-processable without prior bilateral agreements, which is the core interoperability property of Linked Data.

**3.3 Cross-System IRI Mapping (C1 — R1.3, R1.4)**

Where the same real-world entity is identified by different IRIs in different systems (e.g., a building described both in a municipal GIS and in a national cadastre), this Mechanism provides two complementary mapping approaches:

**Strong identity (`owl:sameAs`)**: Asserts that two IRIs refer to the exact same individual. An OWL reasoner will infer that all triples about one IRI also hold for the other. This is appropriate when both IRIs provably refer to the same unique real-world entity:

```turtle
<https://data.city.example/resource/building/B-001>
    owl:sameAs <https://cadastre.national.example/parcel/BRU-2021-00877> .
```

**Concept alignment (`skos:exactMatch`, `skos:closeMatch`)**: A lighter-weight alignment used when entities are considered equivalent in meaning but maintained independently, or when full logical entailment is not desired. `skos:exactMatch` is appropriate for controlled vocabulary terms; `skos:closeMatch` for near-equivalents. This follows the SKOS recommendation's explicit guidance on preferring `skos:exactMatch` over `owl:sameAs` for concept-level mappings to avoid unintended entailment closure.

**Mapping datasets**: Identity links are published as named RDF graphs within an RDF dataset, allowing them to be managed, versioned, and queried independently from the entity description graphs. The SPARQL 1.2 Protocol enables federated queries that traverse `owl:sameAs` links across endpoints, enabling a client to retrieve all known descriptions of an entity from multiple systems using a single query.

**3.4 Entity Typing and Semantic Retrieval (C2)**

Every entity is typed using `rdf:type`, pointing to a class defined in a published OWL 2 ontology. The governing ontology is accessible at a stable IRI and is itself a dereferenceable RDF document. This means that a client can:

1. Receive an entity description containing `rdf:type ex:TrafficSensor`
2. Dereference `ex:TrafficSensor` to retrieve the OWL class definition
3. From that definition, discover the class's superclasses, equivalent classes, and applicable properties via `rdfs:subClassOf`, `owl:equivalentClass`, `rdfs:domain`, `rdfs:range`
4. Optionally run an OWL 2 reasoner to infer additional facts (e.g. that a `ex:TrafficSensor` is also a `sosa:Sensor` via a declared equivalence with the W3C SOSA/SSN ontology)

This entire chain is automated using only HTTP GETs and standard RDF tooling — no out-of-band documentation is needed. This satisfies R2.1 (semantics retrievable using only the IRI) and R2.2 (machine-readable format).

**Ontology publishing requirements**: OWL 2 ontologies used in this Mechanism MUST be published at their namespace IRI, MUST include `rdfs:label` and `rdfs:comment` for every class and property, MUST declare an `owl:versionIRI` for versioning, and SHOULD declare alignments to upper or domain ontologies (e.g. W3C SOSA/SSN for sensors, schema.org for general-purpose entities, INSPIRE for spatial features) using `owl:equivalentClass` or `rdfs:subClassOf`.

**3.5 Dereferencing Relations and Extending Semantics (C3)**

**Relation dereferencing (R3.1)**: Every property used on an entity is itself an IRI, the description of which is retrievable via HTTP. Dereferencing a property IRI yields its OWL definition, including `rdfs:domain`, `rdfs:range`, inverse properties (`owl:inverseOf`), and any SHACL shapes that constrain its use. This means that a client encountering an unknown predicate can always look it up and understand its semantics programmatically.

**Extending existing ontologies (R3.2)**: The Mechanism supports extending an existing ontology without modifying it, using two standard patterns:

_OWL extension_: A new ontology declares `owl:imports` against the base ontology and adds subclasses, subproperties, or restrictions. For example, a city might extend the W3C SOSA ontology with a city-specific `ex:MunicipalAirSensor` subclass:

```turtle
ex:MunicipalAirSensor
    a owl:Class ;
    rdfs:subClassOf sosa:Sensor ;
    rdfs:label "Municipal Air Quality Sensor"@en ;
    rdfs:isDefinedBy <https://ontology.city.example/sensors> .
```

_SHACL profiling_: Rather than altering the ontology, SHACL 1.2 shape graphs are used to impose additional constraints on existing vocabulary terms within a specific deployment context. For example, a city can declare that within its data space, every `sosa:Observation` must have a `sosa:resultTime` and a `geo:hasGeometry` — without changing the upstream SOSA specification. SHACL shapes are published as named RDF graphs and referenced from the entity's JSON-LD context, so consumers know which validation profile applies.

SHACL 1.2's new `sh:ShapesGraph` grouping (a specialised subclass of `owl:Ontology`) is used to package and version shape sets, with `owl:imports` expressing dependencies between shape graphs.

**3.6 SPARQL Endpoint for Programmatic Access**

The Mechanism includes a **SPARQL 1.2 endpoint** (`/sparql`) as the structured query interface over the full RDF dataset. This complements per-entity dereferencing with:

* Pattern-matching queries across all entities and properties
* Federated queries (`SERVICE` keyword) to traverse `owl:sameAs` links across external endpoints
* Construct queries to materialise subgraphs in any RDF serialisation
* Update operations (SPARQL Update, access-controlled) for systems that write linked data

The SPARQL endpoint accepts queries via HTTP GET and POST as specified in SPARQL 1.2 Protocol, and returns results in SPARQL JSON Results format, SPARQL XML, CSV/TSV, or RDF serialisations, based on content negotiation.

**3.7 Why This Mechanism Is Interoperable**

**Identifier interoperability**: IRIs are globally unique by construction (scoped to a DNS domain under the authority's control) and dereferenceable over standard HTTP. Any system anywhere on the Internet can resolve an entity IRI without registration or prior agreement.

**Semantic interoperability**: Because types and properties are themselves dereferenceable IRIs with formal OWL definitions, the meaning of every statement is machine-interpretable. OWL 2 reasoners can infer equivalences across ontologies, enabling automatic bridging between data models from different cities or systems. This is qualitatively different from REST APIs where field names are opaque strings requiring bilateral documentation.

**Cross-system identity**: `owl:sameAs` and `skos:exactMatch` are W3C-standard mechanisms for expressing that two IRIs from independent systems refer to the same entity. This enables data integration without a centralised identifier registry: each system publishes its own IRIs and declares mappings to others.

**Extensibility without breakage**: OWL's open-world assumption and the SHACL profiling pattern allow any party to add semantics to an existing vocabulary without modifying it, and without invalidating existing consumers. New subclasses, new constraints, and new alignment axioms are additive.

**Format universality**: JSON-LD 1.1 as the default serialisation means that any JSON toolchain can consume linked data with minimal adaptation. The `@context` document is the machine-readable bridge between JSON field names and globally unique IRIs, making linked data accessible to the REST API ecosystem.

***

#### 4. Requirements Mapping Table

| Req. ID  | Requirement Text                                                                                                                                                     | How This Mechanism Implements It                                                                                                                                                                                                                                                                                                                                               |
| -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **R1.1** | Every entity within the system has a unique identifier.                                                                                                              | Every entity is assigned a globally unique IRI under a domain controlled by the publishing authority, following W3C Cool URI design patterns. IRIs are unique by construction via DNS scoping and do not embed volatile implementation details.                                                                                                                                |
| **R1.2** | There exists a way to retrieve information about an entity by looking up the identifier within a system.                                                             | Entity IRIs are dereferenceable via HTTP GET (RFC 9110). The server uses content negotiation to return an RDF description (JSON-LD, Turtle, RDF/XML) or a human-readable HTML page. Non-information resources use `303 See Other` redirects to document IRIs.                                                                                                                  |
| **R1.3** | If a unique identifier points to the same entity within multiple systems, it is possible to derive the way to look up information about it in each of those systems. | `owl:sameAs` triples published in named RDF graphs link IRIs across systems. A client dereferencing any of the linked IRIs receives the full description from that system. SPARQL federated queries (`SERVICE`) can traverse these links programmatically.                                                                                                                     |
| **R1.4** | If multiple unique identifiers point to the same entity, it is possible to map them.                                                                                 | Identity mappings are expressed as `owl:sameAs` (for logically identical individuals) or `skos:exactMatch` / `skos:closeMatch` (for concept-level equivalence). These triples are published in versioned, named RDF mapping graphs that can be queried, maintained, and updated independently.                                                                                 |
| **R1.5** | It is possible to create identifiers that are persistent over time.                                                                                                  | IRI persistence is enforced through governance (stable DNS domain, path prefix under long-term stewardship) and optionally through redirect resolvers (e.g. handle.net, ARK, w3id.org) that decouple the canonical IRI from the physical server location. `owl:deprecated` is used to mark retired IRIs while preserving them, and `owl:versionIRI` tracks ontology evolution. |
| **R2.1** | There is a way to retrieve the semantics of an entity, using only its unique identifier.                                                                             | Dereferencing the `rdf:type` value of any entity returns the full OWL 2 class definition, from which `rdfs:subClassOf`, `owl:equivalentClass`, `rdfs:domain`, and `rdfs:range` axioms are machine-readable. No out-of-band documentation is required; the IRI is sufficient as an entry point.                                                                                 |
| **R2.2** | These semantics are described in a machine-readable format.                                                                                                          | OWL 2 ontologies are serialised as Turtle or JSON-LD and served with the appropriate MIME type (`text/turtle`, `application/ld+json`). They are fully parseable by standard RDF tooling. SHACL 1.2 shape graphs complement the ontology with closed-world validation constraints, also in machine-readable RDF.                                                                |
| **R3.1** | There exists a way to dereference a relation defined on an entity.                                                                                                   | Every predicate used on an entity is an IRI. Dereferencing that IRI via HTTP returns its OWL property definition, including domain, range, inverse, and any SHACL `sh:PropertyShape` constraints. This is guaranteed by the requirement that all properties used in instance data are defined in a published, dereferenceable ontology.                                        |
| **R3.2** | There exists a way to apply additional semantics to an existing ontology.                                                                                            | Two standard patterns are supported: (1) OWL 2 extension via `owl:imports`, allowing new subclasses and subproperties to be declared without modifying the original ontology; and (2) SHACL 1.2 profiling, where deployment-specific constraints are added as a separate, versioned shapes graph that references but does not alter the upstream vocabulary.                   |



