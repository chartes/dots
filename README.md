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

### Routeur DTS
Utiliser les routes de l'API DTS déjà disponibles:
- http://localhost:9090/api/dts/collections
- et http://localhost:9090/api/dts/document

## Todo
- pouvoir ajouter un fichier `declaration.xml` pour compléter les métadonnées
