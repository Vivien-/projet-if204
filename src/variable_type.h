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

typedef struct declarator_s declarator_t;
typedef struct variable_s variable_t;
typedef struct function_s function_t;
typedef struct identifier_s identifier_t;
typedef struct expression_s expression_t;

struct variable_type_s {
  enum BASIC_TYPE basic;
  int array_size;
  int nb_param;
  int pointer;
  generic_list_t params;
  char *class_name;
};

union FloatInt {
  int i;
  float f;
};

struct expression_s {
  char *reg;
  char *body;
};

struct identifier_s {
  char *name;
  expression_t offset;
  generic_list_t params;
};

struct function_s {
  char *name;
  char *body;
  char *ret;
  variable_type_t type;
};

struct class_definition_s {
  char *class_name;
  generic_list_t members;
};

struct declarator_s {
  char *name;
  variable_type_t type;
};

struct variable_s {
  int addr;
  variable_type_t type;
};

int is_function(variable_type_t *type);

int id_pointer(variable_type_t *type);

/*
 * Retourne 1 si les deux types spécifiés sont identiques (y compris prototypes de fonctions)
 */
int are_same_type(variable_type_t *t1, variable_type_t *t2);

/*
 * Retourne la taille en mémoire du type passé en paramètre
 */
int get_size(variable_type_t *t);

/*
 * Désalloue un type variavle_type_t
 */
void free_variable_type(void *type);

/*
 * Retourne la taille en mémoire d'une classe
 */
int get_class_size(class_definition_t *class);

/*
 * Désalloue un type class_definition_t
 */
void free_class_definition(void *class);

/*
 * Retourne l'offset du membre dans la classe ou -1 si il n'existe pas
 */
int member_offset(class_definition_t *class, char *member_name);

/*
 * Instancie une nouvelle variable (type non copié)
 */
variable_t *new_variable(variable_type_t type, int addr);

/*
 * Libère une variable
 */
void free_variable(void *var);

#endif
