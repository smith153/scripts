#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <string.h>

#define SIZE 10

typedef struct List List;

struct List {
  int *a;
  struct List *next;
};

void print_memStats()
{
  char com[30] = "ps u -p ";
  pid_t pid = getpid();
  sprintf(com, "ps u -p %d", pid);
  system("cat /proc/meminfo |grep \"^MemFree\\|^Cached\\|^Committed_AS\"");
  system(com);
}


List * addNode(List **tail, List **new)
{
  (*tail)->next = *new;
  (*new)->next = NULL;
  return *new;
}

void print(List * ptr)
{
  if(ptr == NULL){
	return;
  }
  while(ptr->next != NULL){
	printf("%d\n", *(ptr->a));
	ptr = ptr->next;
  }
  return;
}

int main()
{
  List * head = (List *) malloc(sizeof(List));
  List * tail = head;
  List * tmp;
  int i;
  

  for(i = 0;i < SIZE; i++){
	tmp = malloc(sizeof(List));
	tail  = (List *) addNode(&tail, &tmp);
  } 
  
 
  print(head);
  
  return 0;
 
}
