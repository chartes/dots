![](https://img.shields.io/badge/BaseX-10+-red)

# DoTS

DoTS - BaseX DTS Tools

## Documentation

L'installation et l'utilisation de DoTS sont documentées plus précisément ici : https://chartes.github.io/dots_documentation/.

## État d'avancement de l'implémentation de DTS dans DoTS

### Endpoint Collections

#### Propriétées JSON

cf. [Collections Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/Collections-Endpoint.html#scheme)

| Nom             | Statut                           | Implémentation |
| --------------- | -------------------------------- | -------------- |
| `title`         | obligatoire                      | ✅              |
| `@id`           | obligatoire                      | ✅              |
| `@type`         | obligatoire                      | ✅              |
| `totalItems`    | obligatoire                      | ✅              |
| `totalChildren` | obligatoire                      | ✅              |
| `totalParents`  | obligatoire                      | ✅              |
| `maxCiteDepth`  | obligatoire (pour les resources) | ✅              |
| `description`   | optionnel                        | 🚧             |
| `member`        | optionnel                        | ✅              |
| `dublincore`    | optionnel                        | ✅              |
| `extensions`    | optionnel                        | ✅              |
| `references`    | optionnel                        | ✅              |
| `passage`       | optionnel                        | ✅              |
| download        | optionnel                        | 🚧          |
| citeStructure   | optionnel                        | ✅             |

#### Paramètres de requête

cf. [Collections Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/Collections-Endpoint.html#uri)

| Nom  | Méthode | Implémentation |
| ---- | ------- | -------------- |
| id   | GET     | ✅              |
| page | GET     | 🚧             |
| nav  | GET     | ✅              |

### Endpoint Navigation

#### Propriétées JSON

cf. [Navigation Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/Navigation-Endpoint.html#scheme-for-navigation-endpoint-responses)

| Nom            | Statut      | Implémentation |
| -------------- | ----------- | -------------- |
| `@id`          | obligatoire | ✅              |
| `maxCiteDepth` | obligatoire | ✅              |
| `citeType`     | optionnel   | ✅              |
| `level`        | obligatoire | ✅              |
| `passage`      | obligatoire | ✅              |
| `parent`       | obligatoire | ✅              |
| `member`       |             | ✅              |

#### Propriétées JSON des `members`

cf. [Navigation Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/Navigation-Endpoint.html#scheme-for-navigation-endpoint-responses)

| Nom          | Statut                                    | Implémentation |
| ------------ | ----------------------------------------- | -------------- |
| `ref`        | obligatoire (sauf si `start` et `end`)    | ✅              |
| `start`      | obligatoire avec `end` (sauf si `ref`)    | ✅              |
| `end`        | obligatoire avec `start`  (sauf si `ref`) | ✅              |
| `citeType`   | optionnel                                 | ✅              |
| `dublincore` | optionnel                                 | ✅              |
| `extensions` | optionnel                                 | ✅              |

#### Paramètres de requête

cf. [Navigation Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/Navigation-Endpoint.html#query-parameters)

| Nom     | Méthode | Implémentation |
| ------- | ------- | -------------- |
| id      | GET     | ✅              |
| ref     | GET     | ✅              |
| start   | GET     | ✅              |
| end     | GET     | ✅              |
| down    | GET     | ✅              |
| groupBy | GET     | 🚧             |
| max     | GET     | 🚧             |
| exclud` | GET     | 🚧             |

### Endpoint Document

#### Paramètres de requête

cf. [Document Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/Documents-Endpoint.html#uri)

| Nom    | Méthode | Implémentation |
| ------ | ------- | -------------- |
| id     | GET     | ✅              |
| ref    | GET     | ✅              |
| start  | GET     | ✅              |
| end    | GET     | ✅              |
| after  |         | 🚧             |
| before |         | 🚧             |
| token  |         | 🚧             |
| format |         | 🚧             |

## Usage depuis d'autres applications

En contexte Web, si d'autres applications ont besoin de faire appel aux routes de l'API DTS, il faut décommenter la partie CORS du fichier `basex/webapp/WEB-INF/web.xml`.