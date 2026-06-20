# DoTS

DoTS – BaseX DTS Tools est une implémentation en XQuery de la spécification d'API <a href="https://distributed-text-services.github.io/specifications/" target="_blank">DTS</a> (Distributed Text Services), adossée au logiciel de base de données XML BaseX.

## 1. Installation

La procédure d'installation est documentée <a href="https://dots-suite.github.io/dots_documentation/installation/" target="_blank">ici</a>.

## 2. Utilisation de DoTS

Pour avoir plus d'informations sur l'installation et l'utilisation de DoTS, vous pouvez consulter la <a href="https://dots-suite.github.io/dots_documentation/" target="_blank">documentation</a>.

## 3. Usage depuis d'autres applications

En contexte Web, si d'autres applications ont besoin de faire appel aux routes de l'API DTS, il faut ajouter 

```xml
  !-- Set Access-Control-Allow-Origin: * -->
  <filter>
    <filter-name>cross-origin</filter-name>
    <filter-class>org.eclipse.jetty.servlets.CrossOriginFilter</filter-class>
  </filter>
  <filter-mapping>
    <filter-name>cross-origin</filter-name>
    <url-pattern>/*</url-pattern>
  </filter-mapping>
 ```

 à la fin du fichier`basex/webapp/WEB-INF/web.xml`.

## 4. État d'avancement de l'implémentation de DTS

L'implémentation actuelle est conforme à la version <a href="https://distributed-text-services.github.io/specifications/versions/1-alpha/" target="_blank">1-alpha</a> de la spécification DTS.

### 4.1 Endpoint Collections

#### Propriétées JSON

cf. [Collections Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/1-alpha/#collection-endpoint)

| Nom             | Statut                           | Implémentation |
| --------------- | -------------------------------- | -------------- |
| `@id`           | obligatoire                      | ✅             |
| `@type`         | obligatoire                      | ✅             |
| `dtsVersion`    | obligatoire                      | ✅             |
| `title`         | obligatoire                      | ✅             |
| `totalItems`    | obligatoire                      | ✅             |
| `totalChildren` | obligatoire                      | ✅             |
| `totalParents`  | obligatoire                      | ✅             |
| `maxCiteDepth`  | obligatoire (pour les resources) | ✅             |
| `description`   | optionnel                        | ✅             |
| `member`        | optionnel                        | ✅             |
| `dublincore`    | optionnel                        | ✅             |
| `extensions`    | optionnel                        | ✅             |
| `collection`    | obligatoire (pour les resources) | ✅             |
| `navigation`    | obligatoire (pour les resources) | ✅             |
| `document`      | obligatoire (pour les resources) | ✅             |
| `download`      | optionnel                        | 🚧             |
| `citationTrees` | optionnel                        | 🚧             |
| `mediaTypes`    | optionnel (pour les resources)   | ✅             |

#### Paramètres de requête

cf. [Collections Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/1-alpha/#uri-for-collection-endpoint-request)

| Nom  | Méthode | Implémentation |
| ---- | ------- | -------------- |
| id   | GET     | ✅             |
| page | GET     | 🚧             |
| nav  | GET     | ✅             |

### 4.2 Endpoint Navigation

#### Propriétées JSON

cf. [Navigation Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/1-alpha/#navigation-endpoint)

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

#### Propriétées JSON de `resource`

| Nom            | Statut      | Implémentation  |
| -------------- | ----------- | --------------- |
| `@id`          | obligatoire | ✅              |
| `@type`        | obligatoire | ✅              |
| `collection`   | obligatoire | ✅              |
| `navigation`   | obligatoire | ✅              |
| `document`     | obligatoire | ✅              |
| `citationTrees`| obligatoire | 🔄              |
| `mediaTypes`    | optionnel  | ✅              |

#### Propriétées JSON de `CitationTree`

| Nom            | Statut      | Implémentation  |
| -------------- | ----------- | --------------- |
| `identifier`   | optionnel   | 🚧              |
| `@type`        | obligatoire | ✅              |
| `citeStructure`| optionnel   | ✅              |
| `maxCiteDepth` | obligatoire | ✅              |
| `description`  | optionnel   | 🚧              |

#### Propriétées JSON de `CiteStructure`

| Nom            | Statut      | Implémentation  |
| -------------- | ----------- | --------------- |
| `@type`        |             | ✅              |
| `citeType`     | optionnel   | ✅              |
| `citeStructure`| optionnel   | ✅              |


#### Propriétées JSON de `citableUnit`

| Nom          | Statut      | Implémentation |
| ------------ | ----------- | -------------- |
| `identifier` | obligatoire | ✅             |
| `@type`      | obligatoire | ✅             |
| `level`      | obligatoire | ✅             |
| `parent`     | obligatoire | ✅             |
| `citeType`   | optionnel   | ✅             |
| `dublincore` | optionnel   | ✅             |
| `extensions` | optionnel   | ✅             |

#### Paramètres de requête

cf. [Navigation Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/1-alpha/#uri-for-navigation-endpoint-requests)

| Nom       | Méthode | Implémentation |
| -------   | ------- | -------------- |
| `resource`| GET     | ✅             |
| `ref`     | GET     | ✅             |
| `start`   | GET     | ✅             |
| `end`     | GET     | ✅             |
| `down`    | GET     | ✅             |
| `tree`    | GET     | 🔄             |
| `page`    | GET     | 🚧             |

### 4.3 Endpoint Document

#### Paramètres de requête

cf. [Document Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/1-alpha/#document-endpoint)

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

DoTS – BaseX DTS Tools is an XQuery implementation of the <a href="https://distributed-text-services.github.io/specifications/" target="_blank">DTS</a> (Distributed Text Services) API specification, integrated with the XML database software BaseX.

## 1. Installation

The installation procedure is documented <a href="https://dots-suite.github.io/dots_documentation/installation/" target="_blank">here</a>.

## 2. Using DoTS

For more details on installing and using DoTS, see the <a href="https://dots-suite.github.io/dots_documentation/" target="_blank">documentation</a>.

## 3. Usage depuis d'autres applications

In a web context, if other applications need to call the DTS API routes, you should add : 

```xml
  !-- Set Access-Control-Allow-Origin: * -->
  <filter>
    <filter-name>cross-origin</filter-name>
    <filter-class>org.eclipse.jetty.servlets.CrossOriginFilter</filter-class>
  </filter>
  <filter-mapping>
    <filter-name>cross-origin</filter-name>
    <url-pattern>/*</url-pattern>
  </filter-mapping>
 ```

 at the end of the file `basex/webapp/WEB-INF/web.xml`.

## 4. Progress of the DTS implementation

The current implementation is compliant with version <a href="https://distributed-text-services.github.io/specifications/versions/1-alpha/" target="_blank">1-alpha</a> of the DTS specification.

### 4.1 Endpoint Collections

#### JSON properties

cf. [Collections Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/1-alpha/#collection-endpoint)

| Name            | Statut                           | Implementation |
| --------------- | -------------------------------- | -------------- |
| `@id`           | mandatory                        | ✅             |
| `@type`         | mandatory                        | ✅             |
| `dtsVersion`    | mandatory                        | ✅             |
| `title`         | mandatory                        | ✅             |
| `totalItems`    | mandatory                        | ✅             |
| `totalChildren` | mandatory                        | ✅             |
| `totalParents`  | mandatory                        | ✅             |
| `maxCiteDepth`  | mandatory (for resources)        | ✅             |
| `description`   | optional                         | ✅             |
| `member`        | optional                         | ✅             |
| `dublincore`    | optional                         | ✅             |
| `extensions`    | optional                         | ✅             |
| `collection`    | mandatory (for resources)        | ✅             |
| `navigation`    | mandatory (for resources)        | ✅             |
| `document`      | mandatory (for resources)        | ✅             |
| `download`      | optional                         | 🚧             |
| `citationTrees` | optional                         | 🚧             |
| `mediaTypes`    | optional (for resources)         | ✅             |

#### Request parameters

cf. [Collections Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/1-alpha/#uri-for-collection-endpoint-request)

| Name | Method  | Implementation |
| ---- | ------- | -------------- |
| id   | GET     | ✅             |
| page | GET     | 🚧             |
| nav  | GET     | ✅             |

### 4.2 Endpoint Navigation

#### JSON properties

cf. [Navigation Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/1-alpha/#navigation-endpoint)

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
| `maxCiteDepth` | mandatory   | ✅              |
| `description`  | optional    | 🚧              |

#### JSON Properties of `CiteStructure`

| Name           | Statut      | Implementation  |
| -------------- | ----------- | --------------- |
| `@type`        |             | ✅              |
| `citeType`     | optional    | ✅              |
| `citeStructure`| optional    | ✅              |

#### JSON Properties of `citableUnit`

| Name           | Statut    | Implementation |
| ------------ | ----------- | -------------- |
| `identifier` | mandatory   | ✅             |
| `@type`      | mandatory   | ✅             |
| `level`      | mandatory   | ✅             |
| `parent`     | mandatory   | ✅             |
| `citeType`   | optional    | ✅             |
| `dublincore` | optional    | ✅             |
| `extensions` | optional    | ✅             |

#### Request parameters

cf. [Navigation Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/1-alpha/#uri-for-navigation-endpoint-requests)

| Name      | Method  | Implementation |
| -------   | ------- | -------------- |
| `resource`| GET     | ✅             |
| `ref`     | GET     | ✅             |
| `start`   | GET     | ✅             |
| `end`     | GET     | ✅             |
| `down`    | GET     | ✅             |
| `tree`    | GET     | 🔄             |
| `page`    | GET     | 🚧             |

### 4.3 Endpoint Document

#### Request parameters

cf. [Document Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/1-alpha/#document-endpoint)

| Name       | Method  | Implementation |
| ------     | ------- | -------------- |
| `resource` | GET     | ✅             |
| `ref`      | GET     | ✅             |
| `start`    | GET     | ✅             |
| `end`      | GET     | ✅             |
| `tree`     | GET     | 🔄             |
| `mediaType`| GET     | ✅             |