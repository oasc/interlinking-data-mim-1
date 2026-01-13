# Capabilities & Requirements

## C1: Entities are identified using unique identifiers

​

* R1.1: Every entity within the system has a unique identifier
* R1.2: There exists a way to retrieve information about an entity by looking up the identifier within a system
* R1.3: if a unique identifier points to the same entity within multiple systems, it is possible to derive the way to look up information about it in each of these systems
* R1.4: if a multiple unique identifiers point to the same entity, it is possible to map them
* R1.5: It is possible to create identifiers that are persistent over time

​

## C2: Entities can be typed

When retrieving information about an entity, it should be possible to retrieve the semantics describing that informationQuestions:

1. Should this retrieval of semantics be possible in an automated way or may it be manual?
2. Can an entity have multiple Types (should this be included in this capability?)

​

* R2.1: There is a way to retreive the semantics of an entity, only using its unique identifier
* R2.2: These semantics are described in a machine-readable format

## ​C3: Entities can be (de)referenced

{% hint style="info" %}
Definition: _dereferencing._ To dereference is to access a value or object located in a memory location stored in a pointer—the pointer directs you to the stored value. In the context of Linked Data (LD), dereferencing is used in relation to Uniform Resource Identifiers (URIs) and whether or not they are dereferenceable.
{% endhint %}

* R3.1: There exists a way to dereference a relation defined on an entity
* R3.2: There exists a way to apply additional semantics to an existing ontology
