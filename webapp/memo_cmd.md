# Mémo des commandes DoTS

## ENCPOS Cas 1
### Initialisation de la DB dots

```bash
bash basex ../webapp/dots/scripts/dots_db_init.xq
```

### Création de la base de données projet

```bash
 bash basex -b dbName=encpos -b projectDirPath=/home/ppons/Bureau/dots_documentation/data_test/periodiques/encpos_by_abstract ../webapp/dots/scripts/project_db_init.xq
```

### Création des registres du projet

```bash
bash basex -b dbName=encpos -b topCollectionId=ENCPOS ../webapp/dots/scripts/project_registers_create.xq
```
### Mise à jour du switcher DoTS

```bash
bash basex -b dbName=encpos ../webapp/dots/scripts/dots_switcher_update.xq
```

### Créer de nouvelles collections et y attacher des documents 

```bash
bash basex -b srcPath=/home/ppons/Bureau/dots_documentation/data_test/periodiques/encpos_by_abstract/metadata/custom_collections.tsv ../webapp/dots/scripts/create_custom_collections.xq 
```

### Lancer toutes les commandes nécessaires en une fois
```bash
bash basex ../webapp/dots/scripts/dots_db_init.xq; bash basex -b dbName=encpos -b projectDirPath=/home/ppons/Bureau/dots_documentation/data_test/periodiques/encpos_by_abstract ../webapp/dots/scripts/project_db_init.xq; bash basex -b dbName=encpos -b topCollectionId=ENCPOS ../webapp/dots/scripts/project_registers_create.xq; bash basex -b dbName=encpos ../webapp/dots/scripts/dots_switcher_update.xq; bash basex -b srcPath=/home/ppons/Bureau/dots_documentation/data_test/periodiques/encpos_by_abstract/metadata/custom_collections.tsv ../webapp/dots/scripts/create_custom_collections.xq
```



## ENCPOS Cas 2


### Création de la base de données projet


```bash
bash basex -b dbName=encpos_c2 -b projectDirPath=/home/ppons/Bureau/dots_documentation/data_test/periodiques/encpos_by_volume ../webapp/dots/scripts/project_db_init.xq
```

### Création des registres du projet

```bash
bash basex -b dbName=encpos_c2 -b topCollectionId=ENCPOS_c2 ../webapp/dots/scripts/project_registers_create.xq
```
### Mise à jour du switcher DoTS

```bash
bash basex -b dbName=encpos_c2 ../webapp/dots/scripts/dots_switcher_update.xq
```

### Lancer toutes les commandes nécessaires en une fois
```bash
bash basex -b dbName=encpos-c2 -b projectDirPath=/home/ppons/Bureau/dots_documentation/data_test/periodiques/encpos_by_volume ../webapp/dots/scripts/project_db_init.xq; bash basex -b dbName=encpos-c2 -b topCollectionId=ENCPOS_c2 ../webapp/dots/scripts/project_registers_create.xq; bash basex -b dbName=encpos-c2 ../webapp/dots/scripts/dots_switcher_update.xq
```

### Supprimer les registres DoTS d'un projet

```bash
bash basex -b dbName=encpos_c2 -b option=false ../webapp/dots/scripts/dots_registers_delete.xq
```



###############################
Commande unique pour le serveur:

Se placer dans basex, dans le dossier `bin/`

```bash

bash basex -q "db:drop('encpos')"; bash basex ../webapp/dots/scripts/dots_db_init.xq; bash basex -b dbName=encpos -b projectDirPath=/srv/webapp/api/dots/basex/webapp/dots/data_test/periodiques/encpos_by_abstract ../webapp/dots/scripts/project_db_init.xq; bash basex -b dbName=encpos -b topCollectionId=ENCPOS ../webapp/dots/scripts/project_registers_create.xq; bash basex -b dbName=encpos ../webapp/dots/scripts/dots_switcher_update.xq; bash basex -b srcPath=/srv/webapp/api/dots/basex/webapp/dots/data_test/periodiques/encpos_by_abstract/metadata/custom_collections.tsv ../webapp/dots/scripts/create_custom_collections.xq; bash basex -b dbName=encpos-c2 -b projectDirPath=/srv/webapp/api/dots/basex/webapp/dots/data_test/periodiques/encpos_by_volume ../webapp/dots/scripts/project_db_init.xq; bash basex -b dbName=encpos-c2 -b topCollectionId=ENCPOS_c2 ../webapp/dots/scripts/project_registers_create.xq; bash basex -b dbName=encpos-c2 ../webapp/dots/scripts/dots_switcher_update.xq
```

```bash
bash basex -q "db:drop('encpos')"; bash basex -q "db:drop('encpos-c2')"; bash basex ../webapp/dots/scripts/dots_db_init.xq; bash basex -b dbName=encpos -b projectDirPath=/srv/webapp/api/dots/basex/webapp/static/data_test/periodiques/encpos_by_abstract ../webapp/dots/scripts/project_db_init.xq; bash basex -b dbName=encpos -b topCollectionId=ENCPOS ../webapp/dots/scripts/project_registers_create.xq; bash basex -b dbName=encpos ../webapp/dots/scripts/dots_switcher_update.xq; bash basex -b srcPath=/srv/webapp/api/dots/basex/webapp/static/data_test/periodiques/encpos_by_abstract/metadata/custom_collections.tsv ../webapp/dots/scripts/create_custom_collections.xq; bash basex -b dbName=encpos-c2 -b projectDirPath=/srv/webapp/api/dots/basex/webapp/static/data_test/periodiques/encpos_by_volume ../webapp/dots/scripts/project_db_init.xq; bash basex -b dbName=encpos-c2 -b topCollectionId=ENCPOS_c2 ../webapp/dots/scripts/project_registers_create.xq; bash basex -b dbName=encpos-c2 ../webapp/dots/scripts/dots_switcher_update.xq
```

```bash

git pull dots;
cp theatre/ /srv/webapp/api/dots/basex/webapp/static/data_test


cd webapp/dots/scripts
## suppression des 2 db encpos et encpos-c2
bash basex -q "db:drop('encpos')"; bash basex -q "db:drop('encpos-c2')";

## (re-)création de la db encpos avec ajouts de collections multiples
dbName=encpos projectDirPath=/srv/webapp/api/dots/basex/webapp/dots/data_test/encpos_by_abstract topCollectionId=ENCPOS bash build_project.sh;
srcPath=/srv/webapp/api/dots/basex/webapp/dots/data_test/encpos_by_abstract/metadata/custom_collections.tsv bash custom_collections.sh;

## (re-)création de la db encpos-c2 
dbName=encpos-c2 projectDirPath=/srv/webapp/api/dots/basex/webapp/dots/data_test/encpos_by_volume topCollectionId=ENCPOS_c2 bash build_project.sh;

## création de la db theater
dbName=theater projectDirPath=/srv/webapp/api/dots/basex/webapp/dots/data_test/theatre topCollectionId=Theater bash build_project.sh;
srcPath=/srv/webapp/api/dots/basex/webapp/dots/data_test/theatre/metadata/custom_collections.tsv bash custom_collections.sh;
```


############
Commande pour charger un corpus de test (encpos) dans dots-CI.yml

```bash
./basex/bin/basex ./scripts/dots_db_init.xq
./basex/bin/basex -b dbName=encpos -b projectDirPath=./data_test/encpos ./scripts/project_db_init.xq
./basex/bin/basex -b dbName=encpos -b topCollectionId=ENCPOS ../scripts/project_registers_create.xq
./basex/bin/basex -b dbName=encpos ./scripts/dots_switcher_update.xq
[./basex/bin/basex ./tests/launcher.xq]
```

############
Scripts bash pour DoTS

Lancement du script bash de création d'un projet DoTS
```bash
dbName=encpos projectDirPath=/home/ppons/Bureau/dots_documentation/data_test/periodiques/encpos_by_abstract topCollectionId=ENCPOS bash build_project.sh
```

Variante avec option pour supprimer au préalable les registres DoTS d'un projet :
```bash
dbName= projectDirPath= topCollectionId=  cleanOption= bash build_project.sh
```

Variante avec option pour supprimer au préalable les registres DoTS d'un projet ET la db Projet :
```bash
dbName= projectDirPath= topCollectionId=  cleanOption= delete=true bash build_project.sh
```

Script bash pour supprimer les registres DoTS d'un projet et éventuellement la db Projet :
```bash
dbName= delete= bash dots_registers_delete.sh
```

Script bash pour créer de nouvelles collections et y ajouter des documents (déjà existants) :
```bash
srcPath= bash custom_collections.sh
```




################

```bash
project_delete.sh --db_name 'theater';
project_create.sh --project_dir_path '/srv/webapp/api/dots/basex/webapp/dots/data_test/theatre' --top_collection_id 'theater' --db_name 'theater';
custom_collections.sh --collections_tsv_path '/srv/webapp/api/dots/basex/webapp/dots/data_test/theatre/metadata/custom_collections.tsv'
```





















#################
```bash
bash project_delete.sh --db_name 'theater';
bash project_create.sh --project_dir_path '/home/ppons/Bureau/dots_documentation/data_test/theatre' --top_collection_id 'theater' --db_name 'theater';
bash custom_collections.sh --collections_tsv_path '/home/ppons/Bureau/dots_documentation/data_test/theatre/metadata/custom_collections.tsv'
```

```bash
bash project_delete.sh --db_name 'encpos';
bash project_create.sh --project_dir_path '/home/ppons/Bureau/dots_documentation/data_test/periodiques/encpos_by_abstract' --top_collection_id 'ENCPOS' --db_name 'encpos';
bash custom_collections.sh --collections_tsv_path '/home/ppons/Bureau/dots_documentation/data_test/theatre/metadata/custom_collections.tsv'
```