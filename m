From: Mostafa Amin <mostafa.amin@windriver.com>
Date: Thu, 26 Nov 2026 17:12:39 -0500
Subject: [PATCH] fs/ntfs3: serialize size changes with
 mapping->invalidate_lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-fix-krn-ntfs3-inline-read-v1-1-30d32e60a4f5@windriver.com>
X-B4-Tracking: v=1; b=H4sIANauCGsC/x2MQQqAMAzAviI9W3CbDvQr4kFmp0Wp0okI4t8dH
 gNJHkikTAm64gGlixPvksGUBYRllJmQp8xgK+uNsR4j37iqoJwxOWTZWAiVxglb52NT2RBq00D
 uD6Us/+9+eN8P3b/+DGsAAAA=
To: Konstantin Komarov <almaz.alexandrovich@paragon-software.com>
Cc: ntfs3@lists.linux.dev, 
 syzbot+079e16bc964fb91acb4a@syzkaller.appspotmail.com, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Mostafa Amin <mostafa.amin@windriver.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795731160; l=5919;
 i=mostafa.amin@windriver.com; s=20261126; h=from:subject:message-id;
 bh=XmeI61S+G6pjD7VI+NxHnOwVHDxsLsOyxgnSQMrMyvQ=;
 b=OLuKjlFUHKqs6hefA7Vlu5Qxgeab18KkjBAxvZuyo37JMXNgduh/qVX8CwXSwvIwMG+i6yYFD
 DzrpjlndoJ+AyE2G2+A/wicLzLl4Cd/yNp9zfU/KIcTvnha5KzNEQEK
X-Developer-Key: i=mostafa.amin@windriver.com; a=ed25519;
 pk=miyC6GYBn9SqytJ6Cgwe1MLT98rhnwuFEIO8ErmAetY=
X-Endpoint-Received: by B4 Relay for mostafa.amin@windriver.com/20261126 with auth_id=1656
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

syzbot reported a WARNING in iomap_read_inline_data() ("size >
iomap->length") triggered by concurrent ftruncate() and mmap() page
faults on a resident NTFS3 file:

  CPU0 (filemap_fault)               CPU1 (ntfs_setattr / write_iter)
  --------------------               --------------------------------
  filemap_invalidate_lock_shared()
  ntfs_read_folio()
    ntfs_iomap_begin()
      attr_data_get_block()
        iomap->length = 5
                                     truncate_setsize(inode, 20)
                                       i_size_write(inode, 20)
                                     ntfs_set_size(inode, 20)
    iomap_read_inline_data()
      size = i_size_read(inode) = 20
      WARN_ON_ONCE(20 > 5) -> -EIO

iomap_read_inline_data() copies i_size_read(inode) - iomap->offset bytes
out of iomap->inline_data and warns with -EIO if that exceeds
iomap->length.  In ntfs3, attr_data_get_block_locked() snapshots a
resident $DATA attribute into an allocated page under ni_lock and sets
iomap->length to res.data_size, dropping ni_lock before returning from
ntfs_iomap_begin().

Meanwhile, ntfs_setattr() updates inode->i_size via truncate_setsize()
before ntfs_set_size() grows res.data_size and without holding
mapping->invalidate_lock.  Extending writes in ntfs_file_write_iter()
and preallocation in ntfs_fallocate() likewise resize the attribute and
inode->i_size via ntfs_set_size() without mapping->invalidate_lock,
allowing a concurrent page fault or buffered read to observe the new
inode->i_size against an inline iomap built from the old resident size.

Serialize regular-file size and resident/non-resident layout changes
against pagecache readers and faults with filemap_invalidate_lock():

  - In ntfs_setattr(), hold mapping->invalidate_lock across ATTR_SIZE
    updates; when extending, truncate any stray pagecache beyond oldsize
    and run ntfs_set_size() before pagecache_isize_extended() so i_size
    never leads res.data_size or transiently changes on error.
  - In ntfs_file_write_iter(), reject extending IOCB_NOWAIT writes with
    -EAGAIN and hold mapping->invalidate_lock around ntfs_set_size().
  - In ntfs_fallocate(), hold mapping->invalidate_lock across all modes,
    including default preallocation which converts resident files to
    non-resident and extends i_size.

Fixes: 099ef9ab9203 ("fs/ntfs3: implement iomap-based file operations")
Reported-by: syzbot+079e16bc964fb91acb4a@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=079e16bc964fb91acb4a
Cc: stable@vger.kernel.org
Signed-off-by: Mostafa Amin <mostafa.amin@windriver.com>
---
Tested on v7.4-rc4 (x86_64 QEMU/KVM, 4 vCPUs, CONFIG_KASAN=y,
CONFIG_PROVE_LOCKING=y, CONFIG_UBSAN=y, CONFIG_DEBUG_ATOMIC_SLEEP=y,
CONFIG_DEBUG_KMEMLEAK=y, panic_on_warn=1):
  - syzbot C reproducer (ftruncate vs mmap + MADV_DONTNEED): 3/3
    crashes before fix, 0/10 crashes after fix, 3/3 crashes with fix
    reverted.
  - Extending pwrite + fsync + POSIX_FADV_DONTNEED race and
    resident-to-nonresident data-integrity suite: 1/1 crash before
    fix, 0/3 after fix.
  - W=1 build of fs/ntfs3/ on debug (CONFIG_NTFS3_FS=y) and
    allmodconfig (CONFIG_NTFS3_FS=m): 0 warnings.

Not tested: sparse/smatch/coccinelle, non-x86_64 runtime, full xfstests.
---
 fs/ntfs3/file.c | 34 ++++++++++++++++++++++++----------
 1 file changed, 24 insertions(+), 10 deletions(-)

diff --git a/fs/ntfs3/file.c b/fs/ntfs3/file.c
index 6c84a3e1c7fe..33fb6dd91503 100644
--- a/fs/ntfs3/file.c
+++ b/fs/ntfs3/file.c
@@ -518,12 +518,9 @@ static long ntfs_fallocate(struct file *file, int mode, loff_t vbo, loff_t len)
 		goto out;
 	}
 
-	if (mode & (FALLOC_FL_PUNCH_HOLE | FALLOC_FL_COLLAPSE_RANGE |
-		    FALLOC_FL_INSERT_RANGE)) {
-		inode_dio_wait(inode);
-		filemap_invalidate_lock(mapping);
-		map_locked = true;
-	}
+	inode_dio_wait(inode);
+	filemap_invalidate_lock(mapping);
+	map_locked = true;
 
 	if (mode & FALLOC_FL_PUNCH_HOLE) {
 		u32 frame_size;
@@ -736,15 +733,25 @@ int ntfs_setattr(const struct mnt_idmap *idmap, struct dentry *dentry,
 			goto out;
 		}
 		inode_dio_wait(inode);
+		filemap_invalidate_lock(inode->i_mapping);
 		oldsize = i_size_read(inode);
 		newsize = attr->ia_size;
 
 		if (newsize != oldsize) {
-			truncate_setsize(inode, newsize);
-
-			err = ntfs_set_size(inode, newsize);
+			if (newsize > oldsize) {
+				truncate_pagecache(inode, oldsize);
+				err = ntfs_set_size(inode, newsize);
+				if (!err)
+					pagecache_isize_extended(inode, oldsize,
+								 newsize);
+			} else {
+				truncate_setsize(inode, newsize);
+				err = ntfs_set_size(inode, newsize);
+				if (err)
+					i_size_write(inode, oldsize);
+			}
 			if (err) {
-				i_size_write(inode, oldsize);
+				filemap_invalidate_unlock(inode->i_mapping);
 				goto out;
 			}
 
@@ -753,6 +760,7 @@ int ntfs_setattr(const struct mnt_idmap *idmap, struct dentry *dentry,
 			inode_set_mtime_to_ts(inode,
 					      inode_set_ctime_current(inode));
 		}
+		filemap_invalidate_unlock(inode->i_mapping);
 	}
 
 	setattr_copy(idmap, inode, attr);
@@ -1288,11 +1296,17 @@ static ssize_t ntfs_file_write_iter(struct kiocb *iocb, struct iov_iter *from)
 	endbyte = vbo + ret;
 
 	if (endbyte > inode->i_size) {
+		if (iocb->ki_flags & IOCB_NOWAIT) {
+			ret = -EAGAIN;
+			goto out;
+		}
 		/*
 		 * Normal files: increase file size, allocate space.
 		 * Sparse/Compressed: increase file size. No space allocated.
 		 */
+		filemap_invalidate_lock(inode->i_mapping);
 		ret = ntfs_set_size(inode, endbyte);
+		filemap_invalidate_unlock(inode->i_mapping);
 		if (ret)
 			goto out;
 	}

---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261126-fix-krn-ntfs3-inline-read-936f502cc415

Best regards,
-- 
Mostafa Amin <mostafa.amin@windriver.com>

