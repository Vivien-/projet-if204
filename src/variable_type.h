#ifndef VARIABLE_TYPE_H
#define VARIABLE_TYPE_H

#include <stdarg.h>
#include <sys/queue.h>

enum BASIC_TYPE { VOID, VOIDP, INT, INTP, FLOAT, FLOATP, CLASS };

typedef struct variable_type_s variable_type_t;
typedef struct param_list_s param_list_t;
typedef struct param_s param_t;
typedef struct class_definition_s class_definition_t;
typedef struct member_list_s member_list_t;
typedef struct member_s member_t;

struct param_s {
  variable_type_t *type;
  TAILQ_ENTRY(param_s) pointers;
};

TAILQ_HEAD(param_list_s, param_s);

struct variable_type_s {
  enum BASIC_TYPE basic;
  int array_size; /* not an array if -1 */
  int nb_param; /* not a function if -1 */
  param_list_t *params;
  char *class_name;
};

struct member_s {
  variable_type_t *type;
  TAILQ_ENTRY(member_s) pointers;
};

TAILQ_HEAD(member_list_s, member_s);

struct class_definition_s {
  char *class_name;
  int nb_member;
  member_list_t *members;
};

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
variable_type_t *getTypeFunction(variable_type_t *return_type, int nb_param, ...);

int areSameType(variable_type_t *t1, variable_type_t *t2);

void freeVariableType(variable_type_t *type);

class_definition_t *getClassDefinition(char *name, int nb_member, ...);

void freeClassDefinition(class_definition_t *class);

#endif
