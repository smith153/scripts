#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <string.h>



typedef struct List List;

struct List{
  int * a;
  List * next;
};

void print_memStats()
{
  char com[30] = "ps u -p ";
  pid_t pid = getpid();
  sprintf(com, "ps u -p %d", pid);
  system("cat /proc/meminfo |grep \"^MemFree\\|^Cached\\|^Committed_AS\"");
  system(com);
}


List * addNode(List ** tail)
{


}


int main()
{
  List * head;
   
  print_memStats();

 
}
