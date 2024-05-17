# DoTS

DoTS – BaseX DTS Tools

## Installation

- Télécharger et installer BaseX (https://basex.org/)
- Télécharger DoTS (https://github.com/chartes/dots)
- Trouver le chemin où BaseX a été installé
- Copier le dossier DoTS dans /path/to/BaseX/webapp

## Prérequis DoTS

### Arborescence des fichiers à fournir

- un dossier `/data` regroupant tous les documents TEI du corpus
- un dossier `/metadata` regroupant les documents utiles au builder DoTS pour créer les registres DoTS (TSV et dots_metadata_mapping.xml). Ces documents sont facultatifs.

#### Cas 1: Projet sans collection

```
Dir Project (exemple: ENDP)

├── /theatre
│    ├── /data
│        ├── TEI1.xml
│        ├── TEI2.xml
│        ├── TEI3.xml
│        ├── (...)

│    ├── /metadata
│        ├── (metadata.tsv)
│        ├── (dots_metadata_mapping.xml)
```

#### Cas 2: Projet avec collections

```
Dir Project (exemple: ENDP)

├── /ENDP
│    ├── /data
│        ├── /id_collection1
│            ├── TEI1.xml
│            ├── TEI2.xml
│            ├── TEI3.xml
│            ├── (...)
│        ├── /id_collection2
│            ├── TEI1.xml
│            ├── TEI2.xml
│            ├── TEI3.xml
│            ├── (...)
│        ├── /id_collection3
│            ├── TEI1.xml
│            ├── TEI2.xml
│            ├── TEI3.xml
│            ├── (...)

│    ├── /metadata
│        ├── (metadata.tsv)
│        ├── (dots_metadata_mapping.xml)
```
Dans ce cas, un tableur TSV et un `metadata_mapping.xml` sont obligatoires pour déclarer *a minima* les métadonnées des collections (au moins un **dc:title**).
Le TSV doit disposer d'une colonne avec les identifiants des collections dont le nom est similaire à celui proposé dans l'arborescence des fichiers.


### Prérequis des fichiers TEI

- Le fichier TEI doit correspondre à l'unité documentaire que l'utilisateur souhaite éditer. Si le fichier TEI correspond à une collection regroupant plusieurs document, il est préconisé de séparer en amont le fichier TEI collection en autant de documents que nécessaire.
- il est aussi recommandé que chaque fichier TEI dispose d'un attribut `@xml:id` sur l'élément racine `TEI`.
- pour pouvoir lister des fragments sur les endpoints DTS **Navigation** (cf. https://distributed-text-services.github.io/specifications/versions/1-alpha/#navigation-endpoint) et **Document** (cf. https://distributed-text-services.github.io/specifications/versions/1-alpha/#document-endpoint), la structure hiérarchique doit être explicité dans le teiHeader dans `citeStructure` (cf. le modèle `dots_metadata_mapping.xml` dans la documentation DoTS : https://chartes.github.io/dots_documentation/dots-project-folder/#passages et dans les guidelines TEI  https://tei-c.org/release/doc/tei-p5-doc/en/html/ref-citeStructure.html)

### Modèle `dots_metadata_mapping.xml`

cf. pour exemple: `https://github.com/chartes/dots_documentation/blob/dev/data_test/periodiques/encpos_by_abstract/metadata/dots_metadata_mapping.xml` ou `https://github.com/chartes/dots_documentation/blob/dev/data_test/theatre/metadata/dots_metadata_mapping.xml`

L'élément `mapping` contient toutes les métadonnées que l'utilisateur souhaite intégrer aux registres. 

Le fonctionnement général est le suivant:
- le nom de l'élément XML servira de clef json pour la réponse d'API.
- un attribut `@scope` permet de spécifier la portée de la métadonnée, selon qu'elle concerne une **collection** (ressource de type collection) ou un **document** (ressource de type ressource).

Dans le cas où les métadonnées sont issues d'un fichier TEI:
- un attribut `@xpath` permet de spécifier où collecter la métadonnée.
- un attribut `@scope` permet d'indiquer la portée. Logiquement, il s'agit ici plutôt des métadonnées des **documents**.

Dans le cas où les métadonnées sont issues d'un document TSV:
- pour l'instant, seul le cas des TSV est pris en charge.
- l'attribut `@source` permet de trouver le document TSV à utiliser dans le dossier /dots (cf. arborescence des fichiers à fournir)
- l'attribut `@resourceId` permet d'indiquer la colonne du TSV qui donne l'identifiant de la ressource
- l'attribut `@content` permet d'indiquer le nom de la colonne qui contient la métadonnée à ajouter.

### Modèle TSV

Le document TSV doit simplement:
- disposer d'une colonne pour renseigner l'identifiant de la ressource à laquelle appartiennent les métadonnées.


## Utilisation

- Dans BasexGui, créer une base de données TEI
- Dans BasexGui, ouvrir `/dots/schema/manage.xq` et suivre les recommandations en commentaire.
Pour tester, deux corpus d'essai sont disponibles dans `/dots/data_test`:
	- **endp**: corpus avec deux collections des registres de Notre-Dame de Paris
	- **theatre**: corpus "à plat"

### Routeur DTS

Utiliser les routes de l'API DTS disponibles:

- http://localhost:8080/api/dts/collections
- http://localhost:8080/api/dts/navigation
- et http://localhost:8080/api/dts/document

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
