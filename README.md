# DoTS

DoTS – BaseX DTS Tools est une implémentation en XQuery de la spécification d'API <a href="https://distributed-text-services.github.io/specifications/" target="_blank">DTS</a> (Distributed Text Services), adossée au logiciel de base de données XML BaseX.

## 1. Installation

- Télécharger et installer BaseX (>= 11.XX) (https://basex.org/)
- Télécharger DoTS (https://github.com/chartes/dots)
- Trouver le chemin où BaseX a été installé
- Copier le dossier DoTS dans /path/to/BaseX/webapp

## 2. Utilisation de DoTS

Pour avoir plus d'informations sur l'installation et l'utilisation de DoTS, vous pouvez consulter la <a href="https://chartes.github.io/dots_documentation/" target="_blank">documentation</a>.

## 3. Usage depuis d'autres applications

En contexte Web, si d'autres applications ont besoin de faire appel aux routes de l'API DTS, il faut décommenter la partie CORS du fichier `basex/webapp/WEB-INF/web.xml`.

## 4. État d'avancement de l'implémentation de DTS

L'implémentation actuelle est en accord avec la version **1-alpha** de la spécification DTS.

### 4.1 Endpoint Collections

#### Propriétées JSON

cf. [Collections Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/unstable/#collection-endpoint)

| Nom             | Statut                           | Implémentation |
| --------------- | -------------------------------- | -------------- |
| `@id`           | obligatoire                      | ✅              |
| `@type`         | obligatoire                      | ✅              |
| `dtsVersion`    | obligatoire                      | ✅              |
| `title`         | obligatoire                      | ✅              |
| `totalParents`  | obligatoire                      | ✅              |
| `totalChildren` | obligatoire                      | ✅              |
| `description`   | optionnel                        | ✅              |
| `maxCiteDepth`  | obligatoire (pour les resources) | ✅              |
| `member`        | optionnel                        | ✅              |
| `dublincore`    | optionnel                        | ✅              |
| `extensions`    | optionnel                        | ✅              |
| `collection`    | obligatoire                      | ✅              |
| `navigation`    | obligatoire (pour les resources) | ✅              |
| `document`      | obligatoire (pour les resources) | ✅              |
| `download`      | optionnel                        | 🚧              |
| `citationTrees` | optionnel                        | 🚧              |
| `view`          | optionnel                        | 🚧              |

#### Paramètres de requête

cf. [Collections Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/unstable/#uri-for-collection-endpoint-request)

| Nom  | Méthode | Implémentation |
| ---- | ------- | -------------- |
| id   | GET     | ✅             |
| page | GET     | 🚧             |
| nav  | GET     | ✅             |

### 4.2 Endpoint Navigation

#### Propriétées JSON

cf. [Navigation Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/unstable/#navigation-endpoint)

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
| `@type`        | obligatoire | ✅              |
| `citeType`     | obligatoire | ✅              |
| `citeStructure`| optionnel   | ✅              |


#### Propriétées JSON de `citableUnit`

| Nom          | Statut      | Implémentation |
| ------------ | ----------- | -------------- |
| `identifier` | obligatoire | ✅             |
| `@type`      | obligatoire | ✅             |
| `level`      | obligatoire | ✅             |
| `parent`     | obligatoire | ✅             |
| `citeType`   | obligatoire | ✅             |
| `dublincore` | optionnel   | ✅             |
| `extensions` | optionnel   | ✅             |

#### Paramètres de requête

cf. [Navigation Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/unstable/#uri-for-navigation-endpoint-requests)

| Nom     | Méthode | Implémentation |
| ------- | ------- | -------------- |
| `resource`| GET     | ✅             |
| `ref`     | GET     | ✅             |
| `start`   | GET     | ✅             |
| `end`     | GET     | ✅             |
| `down`    | GET     | ✅             |
| `tree`    | GET     | 🔄             |
| `page`    | GET     | 🚧             |

### 4.3 Endpoint Document

#### Paramètres de requête

cf. [Document Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/unstable/#document-endpoint)

| Nom      | Méthode | Implémentation |
| ------   | ------- | -------------- |
| resource | GET     | ✅             |
| ref      | GET     | ✅             |
| start    | GET     | ✅             |
| end      | GET     | ✅             |
| tree     | GET     | 🔄             |
| mediaType| GET     | 🚧             |
