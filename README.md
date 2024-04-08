# DoTS

![](https://img.shields.io/badge/BaseX-10+-red)

## Description

DoTS est une implémentation XQuery de la spécification d'API DTS (Distributed Text Services - <a href="https://distributed-text-services.github.io/specifications/" target="_blank">https://distributed-text-services.github.io/specifications/</a>), adossé au logiciel de base de données XML BaseX (<a href="https://basex.org/" target="_blank">https://basex.org/</a>).

## Installation

### BaseX

- télécharger et installer BaseX (>= 10.0)
  - Prérequis : https://docs.basex.org/wiki/Startup#Startup
  - Lien de téléchargement : https://basex.org/download/

### DoTS

DoTS doit être installé directement dans le dossier de BaseX.

```bash
cd path/to/basex/webapp
```

```bash
git clone https://github.com/chartes/dots.git
```

## Démarrer le résolveur DTS

```Bash
cd path/to/basex/bin
```

```Bash
bash basexhttp
```
Par défaut, le point d'entrée de l'API DTS est disponible à <a href="http://localhost:8080/api/dts/" target="_blank">http://localhost:8080/api/dts/</a>.

## Documentation

L'installation et l'utilisation de DoTS sont documentées plus précisément ici : https://chartes.github.io/dots_documentation/.

## État d'avancement de l'implémentation de DTS dans DoTS

Les différents tableaux rendent compte de l'implémentation actuelle de l'API DTS (version 1-draft2) de DoTS pour la méthode GET.

### Endpoint Collection

#### Propriétés JSON

cf. [Collection Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/1-alpha/#collection-endpoint)

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

cf. [Collections Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/1-alpha/#uri-for-collection-endpoint-request)

| Nom  | Méthode | Implémentation |
| ---- | ------- | -------------- |
| id   | GET     | ✅              |
| page | GET     | 🚧             |
| nav  | GET     | ✅              |

### Endpoint Navigation

#### Propriétés JSON

cf. [Navigation Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/1-alpha/#navigation-endpoint)

| Nom            | Statut      | Implémentation |
| -------------- | ----------- | -------------- |
| `@id`          | obligatoire | ✅              |
| `maxCiteDepth` | obligatoire | ✅              |
| `citeType`     | optionnel   | ✅              |
| `level`        | obligatoire | ✅              |
| `passage`      | obligatoire | ✅              |
| `parent`       | obligatoire | ✅              |
| `member`       |             | ✅              |

#### Propriétés JSON des `members`

| Nom          | Statut                                    | Implémentation |
| ------------ | ----------------------------------------- | -------------- |
| `ref`        | obligatoire (sauf si `start` et `end`)    | ✅              |
| `start`      | obligatoire avec `end` (sauf si `ref`)    | ✅              |
| `end`        | obligatoire avec `start`  (sauf si `ref`) | ✅              |
| `citeType`   | optionnel                                 | ✅              |
| `dublincore` | optionnel                                 | ✅              |
| `extensions` | optionnel                                 | ✅              |

#### Paramètres de requête

cf. [Navigation Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/1-alpha/#uri-for-navigation-endpoint-requests)

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

cf. [Document Endpoint - Distributed Text Services](https://distributed-text-services.github.io/specifications/versions/1-alpha/#document-endpoint)

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