Investigating how, when and why malloc will return memory and yet that memory is not seen as used by normal userland tools (ps,top,htop,ect).

Logic is as follows:  
Create giant linked list with each element containing an uninitialized integer pointer variable.  
Print mem stats  
Transverse linked list, call malloc for each integer pointer.  
Print mem stats  
Transverse linked list, dereference and set integer pointer to a valid value.  
Print mem stats  

Apparently, userland tools do not report an increase in memory usage when only malloc is called.  
To increase memory usage, one must not only call malloc, but also **write** to that memory space too.
