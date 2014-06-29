Benchmarking Perl LWP Based Modules
=======

Results:

Loading LWP::UserAgent
Before 1000 iterations: Size in kbytes: 8.2744140625

emily     9495 20.0  0.6  28180  5744 pts/10   S+   14:37   0:00 perl test1.pl


After iterations: Size in kbytes: 8.3759765625
emily     9495 72.2  1.2  49800 11176 pts/10   S+   14:37   0:10 perl test1.pl
Ended after 14 seconds
Loading LWP::Curl
Before 1000 iterations: Size in kbytes: 0.70703125
emily     9505  0.0  0.6  74420  5564 pts/10   S+   14:38   0:00 perl test1.pl
After iterations: Size in kbytes: 0.70703125
emily     9505 17.6  0.6  78580  6096 pts/10   S+   14:38   0:00 perl test1.pl
Ended after 5 seconds
Loading WWW::Mechanize
Before 1000 iterations: Size in kbytes: 13.6337890625
emily     9514 65.0  1.3  50884 12004 pts/10   S+   14:38   0:00 perl test1.pl
After iterations: Size in kbytes: 4083.9208984375
emily     9514 80.9  2.1  61712 19128 pts/10   S+   14:38   0:20 perl test1.pl
Ended after 25 seconds
Loading HTTP::Tiny
Before 1000 iterations: Size in kbytes: 0.412109375
emily     9525  0.0  0.4  26992  4488 pts/10   S+   14:38   0:00 perl test1.pl
After iterations: Size in kbytes: 0.5068359375
emily     9525 60.0  0.5  29220  4888 pts/10   S+   14:38   0:04 perl test1.pl
Ended after 8 seconds
