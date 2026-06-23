# DoTS

DoTS est une implémentation en XQuery de la spécification d'API <a href="https://distributed-text-services.github.io/specifications/" target="_blank">DTS</a> (Distributed Text Services), adossée au logiciel de base de données XML BaseX.

## 1. Installation

La procédure d'installation est documentée <a href="https://dots-suite.github.io/dots_documentation/installation/" target="_blank">ici</a>.

## 2. Utilisation de DoTS

Pour avoir plus d'informations sur l'installation et l'utilisation de DoTS, vous pouvez consulter la <a href="https://dots-suite.github.io/dots_documentation/" target="_blank">documentation</a>.

## 3. État d'avancement de l'implémentation de DTS

L'implémentation actuelle est conforme à la version <a href="https://dtsapi.org/specifications/versions/v1.0/" target="_blank">v1.0</a> de la spécification DTS.

### 3.1 Endpoint Collections

#### Propriétées JSON

cf. [Collection Endpoint - Distributed Text Services](https://dtsapi.org/specifications/versions/v1.0/#collection-endpoint)

| Nom             | Statut                           | Implémentation |
| --------------- | -------------------------------- | -------------- |
| `@id`           | obligatoire                      | ✅             |
| `@type`         | obligatoire                      | ✅             |
| `dtsVersion`    | obligatoire                      | ✅             |
| `title`         | obligatoire                      | ✅             |
| `totalParents`  | obligatoire                      | ✅             |
| `totalChildren` | obligatoire                      | ✅             |
| `maxCiteDepth`  | obligatoire (pour les resources) | ✅             |
| `description`   | optionnel                        | ✅             |
| `member`        | optionnel                        | ✅             |
| `dublinCore`    | optionnel                        | ✅             |
| `extensions`    | optionnel                        | ✅             |
| `collection`    | obligatoire (pour les resources) | ✅             |
| `navigation`    | obligatoire (pour les resources) | ✅             |
| `document`      | obligatoire (pour les resources) | ✅             |
| `download`      | optionnel                        | ✅             |
| `citationTrees` | optionnel                        | 🔄             |
| `view`          | optionnel                        | 🚧             |
| `mediaTypes`    | optionnel (pour les resources)   | ✅             |

#### Paramètres de requête

cf. [Collections Endpoint - Distributed Text Services](https://dtsapi.org/specifications/versions/v1.0/#uri-for-collection-endpoint-request)

| Nom  | Méthode | Implémentation |
| ---- | ------- | -------------- |
| id   | GET     | ✅             |
| page | GET     | 🚧             |
| nav  | GET     | ✅             |

### 4.2 Endpoint Navigation

#### Propriétées JSON

cf. [Navigation Endpoint - Distributed Text Services](https://dtsapi.org/specifications/versions/v1.0/#navigation-endpoint)

| Nom            | Statut      | Implémentation  |
| -------------- | ----------- | --------------- |
| `@id`          | obligatoire | ✅              |
| `@type`        | obligatoire | ✅              |
| `dtsVersion`   | obligatoire | ✅              |
| `resource`     | obligatoire | ✅              |
| `ref`          | optionnel   | ✅              |
| `start`        | optionnel   | ✅              |
| `end`          | optionnel   | ✅              |
| `member`       | optionnel   | ✅              |
| `view`         | optionnel   | 🚧              |

#### Propriétées JSON de `resource`

| Nom            | Statut      | Implémentation  |
| -------------- | ----------- | --------------- |
| `@id`          | obligatoire | ✅              |
| `@type`        | obligatoire | ✅              |
| `collection`   | obligatoire | ✅              |
| `navigation`   | obligatoire | ✅              |
| `document`     | obligatoire | ✅              |
| `citationTrees`| obligatoire | 🔄              |
| `mediaTypes`   | optionnel   | ✅              |

#### Propriétées JSON de `CitationTree`

| Nom            | Statut      | Implémentation  |
| -------------- | ----------- | --------------- |
| `identifier`   | optionnel   | 🚧              |
| `@type`        | obligatoire | ✅              |
| `citeStructure`| optionnel   | ✅              |
| `description`  | optionnel   | 🚧              |

#### Propriétées JSON de `CiteStructure`

| Nom            | Statut      | Implémentation  |
| -------------- | ----------- | --------------- |
| `citeStructure`| optionnel   | ✅              |
| `citeType`     | obligatoire | ✅              |


#### Propriétées JSON de `citableUnit`

| Nom          | Statut      | Implémentation |
| ------------ | ----------- | -------------- |
| `identifier` | obligatoire | ✅             |
| `@type`      | obligatoire | ✅             |
| `level`      | obligatoire | ✅             |
| `parent`     | obligatoire | ✅             |
| `@id`        | optionnel   | 🚧             |
| `citeType`   | optionnel   | ✅             |
| `dublinCore` | optionnel   | ✅             |
| `extensions` | optionnel   | ✅             |

#### Paramètres de requête

cf. [Navigation Endpoint - Distributed Text Services](https://dtsapi.org/specifications/versions/v1.0/#uri-for-navigation-endpoint-requests)

| Nom       | Méthode | Implémentation |
| -------   | ------- | -------------- |
| `resource`| GET     | ✅             |
| `ref`     | GET     | ✅             |
| `start`   | GET     | ✅             |
| `end`     | GET     | ✅             |
| `down`    | GET     | ✅             |
| `tree`    | GET     | 🔄             |
| `page`    | GET     | 🚧             |

### 3.3 Endpoint Document

#### Paramètres de requête

cf. [Document Endpoint - Distributed Text Services](https://dtsapi.org/specifications/versions/v1.0/#document-endpoint)

| Nom        | Méthode | Implémentation |
| ------     | ------- | -------------- |
| `resource` | GET     | ✅             |
| `ref`      | GET     | ✅             |
| `start`    | GET     | ✅             |
| `end`      | GET     | ✅             |
| `tree`     | GET     | 🔄             |
| `mediaType`| GET     | ✅             |


#######################
### English version ###
#######################

# DoTS

DoTS is an XQuery implementation of the <a href="https://distributed-text-services.github.io/specifications/" target="_blank">DTS</a> (Distributed Text Services) API specification, integrated with the XML database software BaseX.

## 1. Installation

The installation procedure is documented <a href="https://dots-suite.github.io/dots_documentation/installation/" target="_blank">here</a>.

## 2. Using DoTS

For more details on installing and using DoTS, see the <a href="https://dots-suite.github.io/dots_documentation/" target="_blank">documentation</a>.

## 3. Progress of the DTS implementation

The current implementation is compliant with version <a href="https://dtsapi.org/specifications/versions/v1.0/" target="_blank">v1.0</a> of the DTS specification.

### 3.1 Endpoint Collections

#### JSON properties

cf. [Collection Endpoint - Distributed Text Services](https://dtsapi.org/specifications/versions/v1.0/#collection-endpoint)

| Name            | Statut                           | Implementation |
| --------------- | -------------------------------- | -------------- |
| `@id`           | mandatory                        | ✅             |
| `@type`         | mandatory                        | ✅             |
| `dtsVersion`    | mandatory                        | ✅             |
| `title`         | mandatory                        | ✅             |
| `totalParents`  | mandatory                        | ✅             |
| `totalChildren` | mandatory                        | ✅             |
| `maxCiteDepth`  | mandatory (for resources)        | ✅             |
| `description`   | optional                         | ✅             |
| `member`        | optional                         | ✅             |
| `dublinCore`    | optional                         | ✅             |
| `extensions`    | optional                         | ✅             |
| `collection`    | mandatory (for resources)        | ✅             |
| `navigation`    | mandatory (for resources)        | ✅             |
| `document`      | mandatory (for resources)        | ✅             |
| `download`      | optional                         | ✅             |
| `citationTrees` | optional                         | 🔄             |
| `view`          | optional (for resources)         | 🚧             |
| `mediaTypes`    | optional (for resources)         | ✅             |

#### Request parameters

cf. [Collections Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/1-alpha/#uri-for-collection-endpoint-request)

| Name | Method  | Implementation |
| ---- | ------- | -------------- |
| id   | GET     | ✅             |
| page | GET     | 🚧             |
| nav  | GET     | ✅             |

### 3.2 Endpoint Navigation

#### JSON properties

cf. [Navigation Endpoint - Distributed Text Services](https://dtsapi.org/specifications/versions/v1.0/#navigation-endpoint)

| Name           | Statut      | Implementation  |
| -------------- | ----------- | --------------- |
| `@id`          | mandatory   | ✅              |
| `@type`        | mandatory   | ✅              |
| `dtsVersion`   | mandatory   | ✅              |
| `resource`     | mandatory   | ✅              |
| `ref`          | optional    | ✅              |
| `start`        | optional    | ✅              |
| `end`          | optional    | ✅              |
| `member`       | optional    | ✅              |
| `view`         | optional    | 🚧              |

#### JSON Properties of `resource`

| Name           | Statut      | Implementation  |
| -------------- | ----------- | --------------- |
| `@id`          | mandatory   | ✅              |
| `@type`        | mandatory   | ✅              |
| `collection`   | mandatory   | ✅              |
| `navigation`   | mandatory   | ✅              |
| `document`     | mandatory   | ✅              |
| `citationTrees`| mandatory   | 🔄              |
| `mediaTypes`   | optional    | ✅              |

#### JSON Properties of `CitationTree`

| Name           | Statut      | Implementation  |
| -------------- | ----------- | --------------- |
| `identifier`   | optional    | 🚧              |
| `@type`        | mandatory   | ✅              |
| `citeStructure`| optional    | ✅              |
| `description`  | optional    | 🚧              |

#### JSON Properties of `CiteStructure`

| Name           | Statut      | Implementation  |
| -------------- | ----------- | --------------- |
| `citeStructure`| optional    | ✅              |
| `citeType`     | mandatory   | ✅              |

#### JSON Properties of `citableUnit`

| Name           | Statut    | Implementation |
| ------------ | ----------- | -------------- |
| `identifier` | mandatory   | ✅             |
| `@type`      | mandatory   | ✅             |
| `level`      | mandatory   | ✅             |
| `parent`     | mandatory   | ✅             |
| `@id`        | optional    | 🚧             |
| `citeType`   | optional    | ✅             |
| `dublinCore` | optional    | ✅             |
| `extensions` | optional    | ✅             |

#### Request parameters

cf. [Navigation Endpoint - Distributed Text Services](https://dtsapi.org/specifications/versions/v1.0/#uri-for-navigation-endpoint-requests)

| Name      | Method  | Implementation |
| -------   | ------- | -------------- |
| `resource`| GET     | ✅             |
| `ref`     | GET     | ✅             |
| `start`   | GET     | ✅             |
| `end`     | GET     | ✅             |
| `down`    | GET     | ✅             |
| `tree`    | GET     | 🔄             |
| `page`    | GET     | 🚧             |

### 3.3 Endpoint Document

#### Request parameters

cf. [Document Endpoint - Distributed Text Services](https://dtsapi.org/specifications/versions/v1.0/#document-endpoint)

| Name       | Method  | Implementation |
| ------     | ------- | -------------- |
| `resource` | GET     | ✅             |
| `ref`      | GET     | ✅             |
| `start`    | GET     | ✅             |
| `end`      | GET     | ✅             |
| `tree`     | GET     | 🔄             |
| `mediaType`| GET     | ✅             |

