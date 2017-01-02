A basic process stopper using UNIX SIGSTOP and SIGCONT signals

Works great for laptops when you are running on batteries and you want to keep a web browser open but not using resources when not in use.

The **stop_** script works by symlinking to it using the process name that you want to control.

```
ln -s stop_ stop_firefox
```

Then you can just run **./stop_firefox**:

```
    
    user@t61:~$ 
    user@t61:~$ ./stop_firefox 
    
    Getting all Pids for 'firefox'
    Stopping 8305
    Stopping 17707

    user@t61:~$ ./stop_firefox 

    Getting all Pids for 'firefox'
    Resuming 8305
    Resuming 17707
    user@t61:~$ 
    
```

