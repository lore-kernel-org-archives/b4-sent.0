From: Bryanna Marihugh <bryannamarihugh@manhattantech.edu>
Date: Thu, 29 Oct 2026 12:29:05 -0500
Subject: [PATCH RFC] fat: use write_inode_now() on flush to avoid racing
 the flusher
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-fat-flush-isync-v1-1-69c02c258d0c@manhattantech.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAyNL3bTEEt20nNLiDN3M4sq8ZN3EVAsji1QDQ4vUVAMloK6CotS0zAq
 widFKQW7OSrG1tQCHLP/2ZgAAAA==
X-Change-ID: 20261029-fat-flush-isync-ae828e018ee0
To: OGAWA Hirofumi <hirofumi@mail.parknet.co.jp>
Cc: Andrew Morton <akpm@linux-foundation.org>, Jan Kara <jack@suse.cz>, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Bryanna Marihugh <bryannamarihugh@manhattantech.edu>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793294953; l=3920;
 i=bryannamarihugh@manhattantech.edu; s=20261029; h=from:subject:message-id;
 bh=0RAv1HEugH48i+Dam1TLaXkZ+tl9I43PsY6T9wrT1v8=;
 b=rau0TUVnf2bOyxOi17O7tp/tmHxUESLTnAw5OlPs2m1LHOW3t/lLx5DnrRY7lIXJ13jgSVB/n
 S1IpmXd9FBqAFyI3Z8B4wyhKPwBsePsB6qSU1BTIZxZEK5ExsIAlkV1
X-Developer-Key: i=bryannamarihugh@manhattantech.edu; a=ed25519;
 pk=9KJhRQBfRNks2S9TlKp7eVVyWBMuygW2+Zzy+kMGOZw=
X-Endpoint-Received: by B4 Relay for bryannamarihugh@manhattantech.edu/20261029 with auth_id=1355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On cheap USB 3.0 sticks, copying a large file to one formatted FAT
slows down badly when the background flusher runs at the same time.
This only impacts performance; it does not corrupt data.

udisks mounts FAT with the flush option, so closing a written file
calls fat_flush_inodes(), which starts writeback of the data with
filemap_fdatawrite(). That does not set I_SYNC, so the flusher starts
at the same time, which causes lots of small requests.

Cheap controllers handle small writes poorly and sometimes stall for
seconds. I have found this to be a problem on many cheap USB 3 drives.
Older USB2 hardware, better drives and ones that support UASP
don't show this behavior.

Use write_inode_now(inode, 1) instead. It goes through
writeback_single_inode(), which sets I_SYNC while it writes.
Close now also waits for the data and the directory entry to be written.

Benchmark copying a 3 GiB file to a USB 3 stick (PNY, 154b:00ed),
default writeback settings: 11.6-16.3 MB/s before, 17.6-18.0 MB/s after.

Signed-off-by: Bryanna Marihugh <bryannamarihugh@manhattantech.edu>
---
This is a performance fix for cheap USB 3 sticks on FAT mounted with
flush (the udisks default). It stops close and the flusher from writing
the same file at the same time.

Tested on v7.2.12 (stock and patched) and mainline c339f4010dea
(patched), bare metal, same stick. With the flusher kept busy
(dirty_background_bytes=256M, dirty_writeback_centisecs=100) cp goes
from 6.8-8.7 to 13.5-17.4 MB/s. With the patch one task writes the file
and 96-100% of data bios are 768 KiB or larger (4-16% before).

Only measured on one usb-storage stick. UAS drives I have used did not
show the slowdown, but I haven't traced them.

fsync() and sync_bdevs() can race the flusher the same way on other
filesystems. I kept this patch to FAT, but have numbers for exFAT, ext4
and btrfs if useful.

I am a sysadmin not a C dev haven't written it much since school and so
did use an LLM for help reading the writeback code, analysing the block
traces and drafting the patch and text and who to email. I typed,
reviewed and tested the change myself and feel confident that I
understand it and can answer questions.
---
 fs/fat/inode.c | 21 +++++----------------
 1 file changed, 5 insertions(+), 16 deletions(-)

diff --git a/fs/fat/inode.c b/fs/fat/inode.c
index d85c8fbdcca4..0643244223c5 100644
--- a/fs/fat/inode.c
+++ b/fs/fat/inode.c
@@ -1911,28 +1911,17 @@ EXPORT_SYMBOL_GPL(fat_fill_super);
 
 /*
  * helper function for fat_flush_inodes.  This writes both the inode
- * and the file data blocks, waiting for in flight data blocks before
- * the start of the call.  It does not wait for any io started
- * during the call
+ * and the file data blocks, waiting for in flight data blocks and
+ * ones it starts. write_inode_now() takes I_SYNC, so the flusher
+ * does not try to write at the same time.
  */
 static int writeback_inode(struct inode *inode)
 {
-
-	int ret;
-
-	/* if we used wait=1, sync_inode_metadata waits for the io for the
-	* inode to finish.  So wait=0 is sent down to sync_inode_metadata
-	* and filemap_fdatawrite is used for the data blocks
-	*/
-	ret = sync_inode_metadata(inode, 0);
-	if (!ret)
-		ret = filemap_fdatawrite(inode->i_mapping);
-	return ret;
+	return write_inode_now(inode, 1);
 }
 
 /*
- * write data and metadata corresponding to i1 and i2.  The io is
- * started but we do not wait for any of it to finish.
+ * write data and metadata corresponding to i1 and i2 and wait for them.
  *
  * filemap_flush is used for the block device, so if there is a dirty
  * page for a block already in flight, we will not wait and start the

---
base-commit: c339f4010dea8b0d754f84ace70cd1b089878ef8
change-id: 20261029-fat-flush-isync-ae828e018ee0

Best regards,
-- 
Bryanna Marihugh <bryannamarihugh@manhattantech.edu>

