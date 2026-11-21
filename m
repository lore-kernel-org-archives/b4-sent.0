From: =?utf-8?q?Aykut_C=C4=B1nc=C4=B1k?= <aykutcincik@ogr.eskisehir.edu.tr>
Date: Sat, 21 Nov 2026 16:09:40 +0300
Subject: [PATCH] ext4: discard inode preallocations when indirect block
 allocation fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261121-ext4-ind-discard-pa-v1-1-ee92928f7797@ogr.eskisehir.edu.tr>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMPQ6DMAxA4asgz7WEI/6vUnUIiQPuEFBMERLi7
 k3L+A3vnaCchBWG4oTEu6gsMYMeBbjZxolRfDaY0jREhpCPrUKJHr2os8njarHrQ1VTHXrbtpD
 LNXGQ4399vm7rZ3yz234ruK4vugv123cAAAA=
X-Change-ID: 20261121-ext4-ind-discard-pa-89f4515f9a77
To: Theodore Ts'o <tytso@mit.edu>, 
 Andreas Dilger <adilger.kernel@dilger.ca>
Cc: Jan Kara <jack@suse.cz>, Baokun Li <libaokun@linux.alibaba.com>, 
 Ojaswin Mujoo <ojaswin@linux.ibm.com>, 
 "Ritesh Harjani (IBM)" <ritesh.list@gmail.com>, 
 Zhang Yi <yi.zhang@huawei.com>, linux-ext4@vger.kernel.org, 
 syzbot+d79019213609e7056a19@syzkaller.appspotmail.com, 
 stable@vger.kernel.org, 
 =?utf-8?q?Aykut_C=C4=B1nc=C4=B1k?= <aykutcincik@ogr.eskisehir.edu.tr>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795266579; l=5732;
 i=aykutcincik@ogr.eskisehir.edu.tr; s=20261121; h=from:subject:message-id;
 bh=u2mp19xud4/0B/he8gKsRnxVzIf7SqxhCwexE7gjAkI=;
 b=jvo/6FBjNLAM0qCcxCqG6yF3tGE/Bv4Rm08gWTz5D56f2ECKbkB54ESwzFkyb4oB5cLve0xAD
 T3i5HTF05NWBpyH5eeyQHzEdh/jcwzDQHLC7KLKocJFT/HxC8PlIdVW
X-Developer-Key: i=aykutcincik@ogr.eskisehir.edu.tr; a=ed25519;
 pk=0VzUGJI+NLEekrIgYW4SWfh5kCTg8XsSWzEwmTagNes=
X-Endpoint-Received: by B4 Relay for aykutcincik@ogr.eskisehir.edu.tr/20261121 with auth_id=1593
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When ext4_alloc_branch() or ext4_splice_branch() fails after the data
blocks have been allocated, the blocks are released with
ext4_free_blocks().  For an indirect-mapped inode these blocks usually
come from the inode preallocation (PA), and ext4_mb_use_inode_pa() has
already subtracted them from pa_free.  Freeing them does not return
them to the PA, so the PA still covers the logical range while pa_free
no longer accounts for it.

Writeback retries the same logical range after such a failure, for
example after sb_getblk() returns NULL with -ENOMEM for an indirect
block that lies beyond the end of a shrunk loop device, and
ext4_mb_use_preallocated() picks the same PA again.  This time pa_free
is smaller than the requested length and the BUG_ON() in
ext4_mb_use_inode_pa() fires:

  kernel BUG at fs/ext4/mballoc.c:4779!
  RIP: 0010:ext4_mb_use_inode_pa+0x557/0x890
  Call Trace:
   ext4_mb_use_preallocated+0xd96/0x1440
   ext4_mb_new_blocks+0x72d/0x4900
   ext4_ind_map_blocks+0x142c/0x2210
   ext4_map_create_blocks+0x2be/0x5c0
   ext4_map_blocks+0xbb2/0x1480
   ext4_do_writepages+0x1dba/0x3a60
   ext4_writepages+0x370/0x770
   do_writepages+0x288/0x600
   filemap_writeback+0x203/0x290
   file_write_and_wait_range+0xf7/0x170
   ext4_sync_file+0x418/0xdb0
   do_fsync+0xda/0x240

If the BUG_ON() is not reached, the mismatch shows up later as
"freeing already freed block" and "ext4_mb_release_inode_pa: free N,
pa_free M" errors when the PA is released.

The extent-mapped path has handled this since mballoc was added by
discarding the inode PAs before freeing the blocks in
ext4_ext_map_blocks().  Do the same in both indirect error paths.

An AI coding assistant (Claude Code with Claude Opus) was used to
analyse the syzbot report, write a reproducer, trace the root cause with
temporary printk instrumentation, and draft both the fix and this
changelog.  I have reviewed the change and verified it as follows:
without the fix the reproducer hits the BUG_ON() deterministically in
QEMU (virtme-ng, KASAN and lockdep enabled); with the fix it ran 3/3
times without BUG, KASAN or pa_free reports.  The ext4 KUnit tests pass,
and a copy/write/delete workload on a no-extents filesystem leaves
e2fsck clean.

Reported-by: syzbot+d79019213609e7056a19@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=d79019213609e7056a19
Fixes: c9de560ded61 ("ext4: Add multi block allocator for ext4")
Cc: stable@vger.kernel.org
Signed-off-by: Aykut Cıncık <aykutcincik@ogr.eskisehir.edu.tr>
---
The syzbot reproducers no longer mount on current kernels (bigalloc with
s_first_data_block != 0 is now rejected), so I used this reproducer instead:

  truncate -s 4M img
  mkfs.ext4 -q -F -b 1024 -O ^extents,^huge_file,^has_journal,^metadata_csum,^64bit,^flex_bg img
  losetup /dev/loop0 img
  mount -o errors=continue /dev/loop0 /mnt
  touch /mnt/f
  ./shrink /mnt/f /dev/loop0

shrink.c writes 64 KiB, shrinks the loop device to 32 KiB with
LOOP_SET_STATUS64 (lo_sizelimit), then rewrites and calls fsync().  The
indirect block now lies beyond the end of the device, so sb_getblk() fails
and ext4_alloc_branch() returns -ENOMEM.

shrink.c:

  #include <fcntl.h>
  #include <linux/loop.h>
  #include <stdio.h>
  #include <string.h>
  #include <sys/ioctl.h>
  #include <unistd.h>

  int main(int argc, char **argv)
  {
  	static char buf[64 * 1024];
  	struct loop_info64 li;
  	int fd = open(argv[1], O_RDWR);
  	int lfd = open(argv[2], O_RDWR);

  	if (fd < 0 || lfd < 0) { perror("open"); return 1; }
  	memset(buf, 'a', sizeof(buf));
  	pwrite(fd, buf, sizeof(buf), 0);
  	if (ioctl(lfd, LOOP_GET_STATUS64, &li)) { perror("get"); return 1; }
  	li.lo_sizelimit = 32 * 1024;
  	if (ioctl(lfd, LOOP_SET_STATUS64, &li)) { perror("set"); return 1; }
  	for (int r = 0; r < 8; r++) {
  		pwrite(fd, buf, sizeof(buf), 0);
  		printf("fsync %d: %d\n", r, fsync(fd));
  	}
  	return 0;
  }

With the fix applied, fsync() in this reproducer still does not return,
because writeback treats -ENOMEM as transient and keeps retrying.  That
behaviour predates this patch and is not changed by it.

Two related problems in the same error paths are not addressed here and
can be sent separately if wanted:
 - ext4_splice_branch() does not undo *where->p = where->key on failure.
 - The blocks are freed with a quota update even for delalloc-reserved
   blocks, which can underflow i_blocks.
---
 fs/ext4/indirect.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/fs/ext4/indirect.c b/fs/ext4/indirect.c
index a495080df710..3b4ec1c3d5ec 100644
--- a/fs/ext4/indirect.c
+++ b/fs/ext4/indirect.c
@@ -389,6 +389,11 @@ static int ext4_alloc_branch(handle_t *handle,
 	return 0;
 failed:
 	if (i == indirect_blks) {
+		/*
+		 * The data blocks may come from the inode PA, which already
+		 * counts them as used; drop the PA so they are not handed out twice.
+		 */
+		ext4_discard_preallocations(ar->inode);
 		/* Free data blocks */
 		ext4_free_blocks(handle, ar->inode, NULL, new_blocks[i],
 				 ar->len, 0);
@@ -493,6 +498,8 @@ static int ext4_splice_branch(handle_t *handle,
 		ext4_free_blocks(handle, ar->inode, where[i].bh, 0, 1,
 				 EXT4_FREE_BLOCKS_FORGET);
 	}
+	/* See ext4_alloc_branch(): the data blocks may belong to the inode PA. */
+	ext4_discard_preallocations(ar->inode);
 	ext4_free_blocks(handle, ar->inode, NULL, le32_to_cpu(where[num].key),
 			 ar->len, 0);
 

---
base-commit: c44104f3642da720164042623e4832836aefdd8e
change-id: 20261121-ext4-ind-discard-pa-89f4515f9a77

Best regards,
--  
Aykut Cıncık <aykutcincik@ogr.eskisehir.edu.tr>

