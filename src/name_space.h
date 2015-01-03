#ifndef NAME_SPACE_H
#define NAME_SPACE_H

#include <search.h>
#include <sys/queue.h>

#include "variable_type.h"

#define HSIZE 50 /* limité à 50 variables par espace de nommage */

/*
 * Ce module définie une pile d'espace de nommage pour pouvoir stocker les types des variables définies
 */

typedef struct name_space_s name_space_t;
typedef struct name_space_stack_s name_space_stack_t;
typedef struct hsearch_data class_name_space_t;

TAILQ_HEAD(name_space_stack_s, name_space_s);

struct name_space_s {
  struct hsearch_data *htab;
  TAILQ_ENTRY(name_space_s) pointers;
};

int hcreate_r(size_t nel, struct hsearch_data *htab);
int hsearch_r(ENTRY item, ACTION action, ENTRY **retval, struct hsearch_data *htab);
void hdestroy_r(struct hsearch_data *htab);

/*
 * Instancie une nouvelle pile d'espace de nommage avec un espace de nommage empilé
 */
name_space_stack_t *newNameSpaceStack();

/*
 * Empile un nouvel espace de nommage
 */
void stackNewNameSpace(name_space_stack_t *nsp);

/*
 * Dépile un espace de nommage
 */
void popNameSpace(name_space_stack_t *nsp);

/*
 * Insert une entrée dans l'espace de nommage courrant
 */
void insertInCurrentNameSpace(char *name, variable_t *type, name_space_stack_t *nsp);

/*
 * Indique si l'espace de nommage courrant et le premier
 */
int isCurrentNameSpaceRoot(name_space_stack_t *nsp);

/*
 * Retourne le type de la variable de nom name dans tous les espace de nommages
 * Retourne NULL si la variable n'est pas définie
 */
variable_t *findInNameSpace(char *name, name_space_stack_t *nsp);

/*
 * Désalloue la pile d'espaces de nommage (ne désalloue pas les éléments pointés par les entrées dans les tables, les éléments dont les pointeurs sont ajoutés à un espace de nommage ne sont jamais libérés)
 */
void freeNameSpaceStack(name_space_stack_t *nsp);

/*
 * Table de hachage pour les définitions de classes
 */
class_name_space_t *newClassNameSpace();

void insertInClassNameSpace(char *name, class_definition_t *class, class_name_space_t *cnp);

class_definition_t *findInClassNameSpace(char *name, class_name_space_t *cnp);

void freeClassNameSpace(class_name_space_t *cnp);

#endif
