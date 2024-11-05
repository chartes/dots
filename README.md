# DoTS

DoTS – BaseX DTS Tools is an XQuery implementation of the <a href="https://distributed-text-services.github.io/specifications/" target="_blank">DTS</a> (Distributed Text Services) API specification, integrated with the XML database software BaseX.

## 1. Installation

- Download and install BaseX (>= 11.XX) (https://basex.org/)
- Download DoTS (https://github.com/chartes/dots)
- Find the installation path of BaseX
- Copy the DoTS folder into /path/to/BaseX/webapp

## 2. Using DoTS

For more details on installing and using DoTS, see the <a href="https://chartes.github.io/dots_documentation/" target="_blank">documentation</a>.

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

The current implementation is compliant with version 1-alpha of the DTS specification.

### 4.1 Endpoint Collections

#### JSON properties

cf. [Collections Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/unstable/#collection-endpoint)

| Name            | Statut                           | Implementation |
| --------------- | -------------------------------- | -------------- |
| `@id`           | mandatory                        | ✅              |
| `@type`         | mandatory                        | ✅              |
| `dtsVersion`    | mandatory                        | ✅              |
| `title`         | mandatory                        | ✅              |
| `totalParents`  | mandatory                        | ✅              |
| `totalChildren` | mandatory                        | ✅              |
| `description`   | optional                         | ✅              |
| `maxCiteDepth`  | mandatory (for resources)        | ✅              |
| `member`        | optional                         | ✅              |
| `dublincore`    | optional                         | ✅              |
| `extensions`    | optional                         | ✅              |
| `collection`    | obligatoire                      | ✅              |
| `navigation`    | mandatory (for resources)        | ✅              |
| `document`      | mandatory (for resources)        | ✅              |
| `download`      | optional                         | 🚧              |
| `citationTrees` | optional                         | 🚧              |
| `view`          | optional                         | 🚧              |

#### Request parameters

cf. [Collections Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/unstable/#uri-for-collection-endpoint-request)

| Name | Method  | Implementation |
| ---- | ------- | -------------- |
| id   | GET     | ✅             |
| page | GET     | 🚧             |
| nav  | GET     | ✅             |

### 4.2 Endpoint Navigation

#### JSON properties

cf. [Navigation Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/unstable/#navigation-endpoint)

| Name           | Statut     | Implementation  |
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

| Name           | Statut     | Implementation  |
| -------------- | ----------- | --------------- |
| `@id`          | mandatory   | ✅              |
| `@type`        | mandatory   | ✅              |
| `collection`   | mandatory   | ✅              |
| `navigation`   | mandatory   | ✅              |
| `document`     | mandatory   | ✅              |
| `citationTrees`| mandatory   | 🔄              |

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
| `@type`        | mandatory   | ✅              |
| `citeType`     | mandatory   | ✅              |
| `citeStructure`| optional    | ✅              |


#### JSON Properties of `citableUnit`

| Name           | Statut    | Implementation |
| ------------ | ----------- | -------------- |
| `identifier` | mandatory   | ✅             |
| `@type`      | mandatory   | ✅             |
| `level`      | mandatory   | ✅             |
| `parent`     | mandatory   | ✅             |
| `citeType`   | mandatory   | ✅             |
| `dublincore` | optional    | ✅             |
| `extensions` | optional    | ✅             |

#### Request parameters

cf. [Navigation Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/unstable/#uri-for-navigation-endpoint-requests)

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

cf. [Document Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/unstable/#document-endpoint)

| Name       | Method  | Implementation |
| ------     | ------- | -------------- |
| `resource` | GET     | ✅             |
| `ref`      | GET     | ✅             |
| `start`    | GET     | ✅             |
| `end`      | GET     | ✅             |
| `tree`     | GET     | 🔄             |
| `mediaType`| GET     | 🚧             |
