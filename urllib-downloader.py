#!/usr/bin/env python

# Script that will take a URL and filename and download a file of any size
# Without a full path, it will save in same directory as script
# stdout write the download progress in percent to console during download


import urllib


url = 'http://www.toolswatch.org/vfeed/vfeed.db.tgz'
filename = url.split('/')[-1]

class AppURLOpener(urllib.FancyURLopener):
    version = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X 10.5; en-US; rv:1.9.2.15) Gecko/20110303 Firefox/3.6.15"


def myhook(count, block_sz, total_sz):
    print("[ Total Received: {!s}, Chunks: {!s}, File Size: {!s}".format(count, block_sz, total_sz))
    percent = int(count * block_sz * 100 / total_sz)
    sys.stdout.write("\r[Downloading %s:      %d%%]" % (filename, percent))
    sys.stdout.flush()



# Assign the subclassed object to this function before using urllib
urllib._urlopener = AppURLOpener()

# Now we can make requests with our own user agent
# The hook will call our custom function until the complete file is downloaded
urllib.urlretrieve(url, filename, reporthook=myhook)

