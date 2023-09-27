# DoTS

DoTS – BaseX DTS Tools

## Installation

- Télécharger et installer BaseX (https://basex.org/)
- Télécharger DoTS
- Trouver le chemin où BaseX a été installé
- Copier le dossier DoTS dans /path/to/BaseX/webapp

## Utilisation

### Création des bases de données et des fichiers de configurations

- Dans BasexGui, créer une base de données TEI
- Dans BasexGui, ouvrir `/dots/schema/manage.xq`
- Compléter les 2 variables `$db_name`avec le nom de la base de données précédemment créée et `db_title`avec le titre que vous souhaitez lui donner
- Lancer le script
- En localhost, lancer le serveur (dans le dossier /path/to/BaseX/bin): `basexhttp`

### Essai avec les données Test

- créer une base de données XML avec le contenu de `data_test` dans BaseGui

- le nom de la db proposé par BaseX est `data_test` Ce nom peut-être modifié.

- Dans BasexGui, ouvrir `/dots/schema/manage.xq`

- Compléter les 2 variables `$db_name`avec le nom de la base de données précédemment créée et `db_title`avec le titre que vous souhaitez lui donner

- Lancer le script

- En localhost, lancer le serveur (dans le dossier /path/to/BaseX/bin): `basexhttp` 

### Routeur DTS

Utiliser les routes de l'API DTS déjà disponibles:

- http://localhost:9090/api/dts/collections
- et http://localhost:9090/api/dts/document

## Usage depuis d'autres applications

En contexte Web, si d'autres applications ont besoin de faire appel aux routes de l'API DTS, il faut décommenter la partie CORS du fichier `basex/webapp/WEB-INF/web.xml`.

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
| download        | optionnel                        |                |
| citeStructure   | optionnel                        | 🔄             |

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
| `parent`       | obligatoire | 🔄             |
| `member`       |             | ✅              |

#### Propriétées JSON des `members`

cf. [Navigation Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/Navigation-Endpoint.html#scheme-for-navigation-endpoint-responses)

| Nom          | Statut                                    | Implémentation |
| ------------ | ----------------------------------------- | -------------- |
| `ref`        | obligatoire (sauf si `start` et `end`)    | ✅              |
| `start`      | obligatoire avec `end` (sauf si `ref`)    | 🔄             |
| `end`        | obligatoire avec `start`  (sauf si `ref`) | 🔄             |
| `citeType`   | optionnel                                 | ✅              |
| `dublincore` | optionnel                                 | ✅              |
| `extensions` | optionnel                                 | ✅              |

#### Paramètres de requête

cf. [Navigation Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/Navigation-Endpoint.html#query-parameters)

| Nom     | Méthode | Implémentation |
| ------- | ------- | -------------- |
| id      | GET     | ✅              |
| ref     | GET     | ✅              |
| start   | GET     | 🔄             |
| end     | GET     | 🔄             |
| down    | GET     | 🔄             |
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
| start  | GET     | 🔄             |
| end    | GET     | 🔄             |
| after  |         | 🚧             |
| before |         | 🚧             |
| token  |         | 🚧             |
| format |         | 🚧             |
