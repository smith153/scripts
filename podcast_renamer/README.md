Podcast Renamer
=======

Ever make a data CD full of 100's of podcast mp3's to listen to while in the car? Ever get annoyed at the order they play in?

This script will fix that issue by prepending a number to the front of the file name so it will play in what ever order you specify.

For example, say you have 3 podcasts: 20 episodes of podcastA, 10 episodes of podcastB, and 10 episodes of podcastC.

If you want to have the play-back such that you hear 2 episodes of podcastA followed by 1 each episodes of podcast B and C, then you would call the script like:

renamer.rb /path/to/files podcastA podcastA podcastB podcastC

This will append numbers to the start of the file names like so:

<pre>
1000_podcastA_episode1.mp3
1001_podcastA_episode2.mp3
1002_podcastB_episode1.mp3
1003_podcastC_episode1.mp3
1004_podcastA_episode3.mp3
1005_podcastA_episode4.mp3
1006_podcastB_episode2.mp3
1007_podcastC_episode2.mp3
</pre>

As you can see, any mp3 capable player will play them in the correct order now. The names you specify on the command line only need to represent the pattern of each filename to be renamed.

The changes that will be made to the file names will be printed to the screen for you to confirm before proceeding.

