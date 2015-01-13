Projet: http://www.labri.fr/perso/barthou/projet.html 
Extension objet

Lancement des fichiers de test (vérifie que l'executable ne génère pas d'erreurs) :

> cd src
> make tests

Compilation d'un fichier spécifique (exemple t1.c) :

> cd src
> gcc -c compiler_lib.c
> ./compiler ../tests/t1.c
> gcc compiler_lib.o ../tests/t1.s
> cd ../tests
> ./a.out 

Fonctionnalités implémentées :

- Déclaration de variables
- Affectation de variables
- Evaluation d'expressions
- Définition de fonctions
- Appel de fonctions avec arguments
- Structures conditionnelles et itératives
- Vérification des types lors de l'affectation
- Gestion des espaces de nommage

Fonctionnalités non implémentées :

- Partie extension.
- Test des types des paramètres d'une fonction 
- Calcul des flottants

Auteurs: Vivien Achet, Charretier Vincent, Erwan Le Masson, Sha Lu
