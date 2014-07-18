#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <string.h>
#include <time.h>

#define SIZE 80000000

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
  printf("####################################\n");
  system("cat /proc/meminfo |grep \"^MemFree\\|^Cached\\|^Committed_AS\"");
  system(com);
  printf("####################################\n");
}

/*
Add new element to tail of list
*/
List * addNode(List **tail, List **new)
{
  (*tail)->next = *new;
  (*new)->next = NULL;
  return *new;
}

/*
Print list from head
*/
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

/*
Call malloc for every int member in list
*/
void call_malloc(List * ptr)
{
   if(ptr == NULL){
	return;
  }
  while(ptr->next != NULL){
	ptr->a = malloc(sizeof(int));
	ptr = ptr->next;
  }
  return;
 
}

/*
Write an integer to every int member in list
*/
void init_int(List * ptr)
{
  if(ptr == NULL){
	return;
  }
  while(ptr->next != NULL){
	*(ptr->a) = rand() % 10000;
	ptr = ptr->next;
  }
  return;

}



int main()
{
  srand(time(NULL));
  List * head = malloc(sizeof(List));
  List * tail = head;
  List * tmp;
  int i;
  

  for(i = 0;i < SIZE; i++){
	tmp = malloc(sizeof(List));
	tail  = (List *) addNode(&tail, &tmp);
  } 
  
  printf("list of size: %d is built\n",SIZE);
  print_memStats();
  call_malloc(head);
  //print(head);
 
  printf("called malloc on every int pointer in list\n");
  print_memStats();
  init_int(head);
  //print(head);
  
  printf("wrote an int to every int pointer in list\n");
  print_memStats();
  
  
  return 0;
 
}
