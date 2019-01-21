# Change Management

Changes to these ontologies SHALL be made by approval and publication of a new version of this document.  A new version SHALL be one of the following:

## Errata Version

An errata version makes corrections to the normative content of the standard (excluding corrections which would change the data schema) and/or makes changes to non-normative content such as explanatory material. An errata version does not change the ontology definitions, only the documentation parts, and so does not affect the interoperability of systems implementing the standard. An errata version is indicated by incrementing the third version number; e.g., 1.0 to 1.0.1, or 1.0.1 to 1.0.2.

## Minor Version

An errata version makes corrections to the normative content of the standard (excluding corrections which would change the data schema) and/or makes changes to non-normative content such as explanatory material. An errata version does not change the ontology definitions, only the documentation parts, and so does not affect the interoperability of systems implementing the standard. An errata version is indicated by incrementing the third version number; e.g., 1.0 to 1.0.1, or 1.0.1 to 1.0.2.
A minor version may include all changes permitted in an errata version, and in addition may define new properties, classes or named individuals (e.g. codes in a code list representing "enum" data types).  A minor version changes the ontologies.  Minor changes to schema MUST provide for forward and backward compatibility.  This allows existing implementations to continue to interoperate even if they are using different minor versions.  A minor version is indicated by incrementing the second version number; e.g., 1.0 to 1.1 or 1.1.3 to 1.2.

## Major Version

A major version may make any change at all, including incompatible changes to the ontologies. This requires existing implementations to separately understand both the old and new versions during a period of transition. A major version is indicated by incrementing the first version number; e.g., 1.1 to 2.0. 
The release of a new minor or major version shall always be accompanied by a transition plan for LOUs and GLEIF, to ensure a smooth and time-bounded migration to the new version.

# Characterizations of Change

The normative content of these ontologies is dependent upon the data schema that underlies the related LEI specifications and XML schema definitions.  These ontologies are versioned independently of those specifications to allow for independent change management.  Reasons why these ontologies might issue a new version include:
- an Errata or Minor Version of the underlying specification has been proposed, and the corresponding changes need to be implemented in an Errata or Minor version of these ontologies.
- a Major Version of the underlying specification has been proposed, and a Minor or Major version of these ontologies needs to be issued to implement those changes.  Note that the open-world nature of RDF means that even some Major Versions of the underlying specification would not require a Major Version of these ontologies to be issued.
- a discrepancy between these ontologies and the corresponding concepts in the underlying specification requires that an Errata, Minor, or Major version of these ontologies be issued to address the discrepancies.  Note that it would be an extremely unlikely and impactful situation to have to issue a Major Version of these ontologies to account for such a discrepancy - in virtually every case, an Errata or Minor version would suffice, and the possibility of a Major Version increment in this case is only included for completeness
- a Minor Version could be issued to enrich these ontologies with definitions that further align the properties and classes defined within other ontologies and RDF vocabularies.

Note that code lists, or "enum" types, are implemented in these ontologies as named individuals with membership to a defined class.  This allows for forward and backward compatibility between versions in the presence of added values, because the determination of validity for data that references these ontologies is based upon those classes and not on specific instances.  New named instances can be added in a Minor Version with no impact to the ability for previous versions to validate data. 
