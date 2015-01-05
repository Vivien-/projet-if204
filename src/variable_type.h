#ifndef VARIABLE_TYPE_H
#define VARIABLE_TYPE_H

#include <sys/queue.h>

#include "generic_list.h"

/*
 * Ce module définie des meta-types ainsi que les structures utilisées par l'analyseur syntaxique
 */

enum BASIC_TYPE { TYPE_VOID, TYPE_INT, TYPE_FLOAT, TYPE_CLASS };

typedef struct variable_type_s variable_type_t;
typedef struct class_definition_s class_definition_t;

typedef struct param_s param_t;
typedef struct member_s member_t;
typedef struct declaration_s declaration_t;
typedef struct variable_s variable_t;

struct variable_type_s {
  enum BASIC_TYPE basic;
  int array_size; /* not an array if -1 */
  int nb_param; /* not a function if -1 */
  int pointer;
  generic_list_t *params;
  char *class_name;
};

struct class_definition_s {
  char *class_name;
  generic_list_t *members;
};

struct param_s {
  variable_type_t *type;
  TAILQ_ENTRY(param_s) pointers;
};

struct member_s {
  char *name;
  variable_type_t *type;
  TAILQ_ENTRY(member_s) pointers;
};

struct declaration_s {
  int pointer;
  int array_size;
  char *name;
  TAILQ_ENTRY(declaration_s) pointers;
};

struct variable_s {
  variable_type_t *type;
  int addr;
};

/*
 * Constructeur de types de base, leurs pointeurs et tableaux
 */
variable_type_t *getType(enum BASIC_TYPE, declaration_t *declaration);
variable_type_t *getTypeVoid();
variable_type_t *getTypeVoidP();
variable_type_t *getTypeInt();
variable_type_t *getTypeFloat();
variable_type_t *getTypeIntP();
variable_type_t *getTypeFloatP();
variable_type_t *getTypeVoidArray(int size);
variable_type_t *getTypeVoidPArray(int size);
variable_type_t *getTypeIntArray(int size);
variable_type_t *getTypeFloatArray(int size);
variable_type_t *getTypeIntPArray(int size);
variable_type_t *getTypeFloatPArray(int size);
variable_type_t *getTypeClass(char *name);
variable_type_t *getTypeClassArray(int size, char *name);

/*
 * Constructeur de types de fonctions (aucun paramètres copié)
 */
variable_type_t *getTypeFunction(variable_type_t *return_type, generic_list_t *param_list);

/*
 * Retourne 1 si les deux types spécifiés sont identiques (y compris prototypes de fonctions)
 */
int areSameType(variable_type_t *t1, variable_type_t *t2);

/*
 * Retourne la taille en mémoire du type passé en paramètre
 */
int getSize(variable_type_t *t);

/*
 * Désalloue un type variavle_type_t
 */
void freeVariableType(void *type);

/*
 * Définit une classe (name est copié, pas member_list)
 */
class_definition_t *getClassDefinition(char *name, generic_list_t *member_list);

/*
 * Retourne la taille en mémoire d'une classe
 */
int getClassSize(class_definition_t *class);

/*
 * Désalloue un type class_definition_t
 */
void freeClassDefinition(void *class);

/*
 * Retourne l'offset du membre dans la classe ou -1 si il n'existe pas
 */
int memberOffset(class_definition_t *class, char *member_name);

/*
 * Instancie une nouvelle variable (type non copié)
 */
variable_t *newVariable(variable_type_t *type, int addr);

/*
 * Libère une variable
 */
void freeVariable(void *var);

#endif
