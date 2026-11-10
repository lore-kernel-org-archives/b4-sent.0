From: "Eric A. Stalee" <mail@eric-stalee.eu>
Date: Tue, 10 Nov 2026 03:38:13 +0100
Subject: [PATCH] fs/ntfs3: load index allocation runs before use in
 indx_new()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-ntfs3-indx-new-load-runs-v1-1-061378c2d45e@eric-stalee.eu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ6CQAxA4auQrm0yHZCoVzEsBqZgjSlmyl9Cu
 LujLr/FezsYJ2GDW7FD4kVMRs2gUwHdI+jAKDEbvPM1ETnUqbcSReOGyiu+xhAxzWrI/hyrQO5
 6cRXk/J24l+23vjd/29w+uZu+PziOD4eJcGZ8AAAA
X-Change-ID: 20261110-ntfs3-indx-new-load-runs-e25d4a109804
To: Konstantin Komarov <almaz.alexandrovich@paragon-software.com>
Cc: ntfs3@lists.linux.dev, linux-kernel@vger.kernel.org, 
 "Eric A. Stalee" <mail@eric-stalee.eu>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794278328; l=4039;
 i=mail@eric-stalee.eu; s=20261110; h=from:subject:message-id;
 bh=ljuOubNiF29ICM1zvurt0a9eMhRnzv4IXWbSHt8+7bE=;
 b=j7DyAqOo5H3uyh0znlxbg1uT5qlRDSALeA+akNO7C9t4HbQ7T8vA2ilU7MbVT6eJ2Hy9EvcQA
 amFDJ15gImBDXPS8lH70g6YMN7uniUfonI0u7ZRkKA9Aj3rY824w0n2
X-Developer-Key: i=mail@eric-stalee.eu; a=ed25519;
 pk=Vp3vCG+vzRAtKQmuxwsKy8/XIbX003wXmany+Up3BfY=
X-Endpoint-Received: by B4 Relay for mail@eric-stalee.eu/20261110 with auth_id=1473
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

indx_new() maps a new index buffer through indx->alloc_run with
ntfs_get_bh(). The runs of $INDEX_ALLOCATION in alloc_run are loaded on
demand: indx_read() loads the missing range with attr_load_runs_range()
and retries when ntfs_read_bh() returns -ENOENT, but indx_new() does not.

When indx_add_allocate() finds a free bit in the index $BITMAP, it
reuses that buffer without touching $INDEX_ALLOCATION, so no runs are
loaded on that path either. If the reused buffer lies in a range whose
runs have not been loaded during the current mount, run_lookup_entry()
fails in ntfs_get_bh(), indx_new() returns -ENOENT and the insertion
that needed the split fails.

This was seen on a 1.7 TiB NTFS volume that is also used by Windows.
Its $Extend/$Reparse index has $INDEX_ALLOCATION:$R split over two MFT
records through an attribute list, with 149 index buffers allocated and
148 in use. Every symlink() on the volume failed with ENOENT, while
creating files and directories worked and the other NTFS volumes on the
same system were not affected. The failure persisted across remounts
and reboots, and did not depend on the MFT record number of the new
inode.

Return values from a kretprobe trace of one failing symlink():

  indx_add_allocate()   <- indx_insert_into_buffer()  =  0
  ntfs_get_bh()         <- indx_new()                 = -2
  indx_new()            <- indx_insert_into_buffer()  = -2
  indx_insert_entry()   <- ntfs_insert_reparse()      = -2
  ntfs_insert_reparse() <- ntfs_create_inode()        = -2
  ntfs_create_inode()   <- ntfs_symlink()             = -2

Load the missing runs and retry when ntfs_get_bh() returns -ENOENT, as
indx_read() does. With this change, symlink creation on the affected
volume works.

The analysis and this patch were produced with an AI coding assistant
(Claude Opus 5.5 in Claude Code) under my direction. It read the ntfs3
source, wrote the kprobe script I ran to get the trace above, wrote the
fix and drafted this changelog. I reviewed the change and tested it as
described below.

Fixes: 82cae269cfa9 ("fs/ntfs3: Add initialization of super block")
Signed-off-by: Eric A. Stalee <mail@eric-stalee.eu>
---
Testing:
 - Built as an out-of-tree module without warnings for 6.18.60 (CachyOS
   kernel, gcc 16.2.1) and 7.3.3 (CachyOS kernel, clang 23.1.4 with
   ThinLTO). The CachyOS tree's fs/ntfs3 at 6.18.60 is identical to
   v6.18.60.
 - With the patched module on 6.18.60, symlink() on the affected volume
   succeeds for absolute and relative targets and for names containing
   ':'. With the unpatched module it fails every time.
 - Not run on mainline. The patch applies to current mainline with a
   5 line offset.
 - No reproducer from a freshly formatted volume: I could not recreate
   the on-disk state from scratch, so the affected volume is the only
   test case.
---
 fs/ntfs3/index.c | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/fs/ntfs3/index.c b/fs/ntfs3/index.c
index c06b36760..4970188a0 100644
--- a/fs/ntfs3/index.c
+++ b/fs/ntfs3/index.c
@@ -987,6 +987,23 @@ static struct indx_node *indx_new(struct ntfs_index *indx,
 	}
 
 	err = ntfs_get_bh(ni->mi.sbi, &indx->alloc_run, vbo, bytes, &r->nb);
+	if (err == -ENOENT) {
+		/*
+		 * A reused index buffer can lie in a part of $INDEX_ALLOCATION
+		 * whose runs were never loaded. Load them and retry, as
+		 * indx_read() does.
+		 */
+		const struct INDEX_NAMES *name = &s_index_names[indx->type];
+
+		down_write(&indx->run_lock);
+		err = attr_load_runs_range(ni, ATTR_ALLOC, name->name,
+					   name->name_len, &indx->alloc_run,
+					   vbo, vbo + bytes);
+		up_write(&indx->run_lock);
+		if (!err)
+			err = ntfs_get_bh(ni->mi.sbi, &indx->alloc_run, vbo,
+					  bytes, &r->nb);
+	}
 
 	if (err) {
 		kfree(index);

---
base-commit: b3dfbde62cf1981c4638939c159dfd087b7a72e9
change-id: 20261110-ntfs3-indx-new-load-runs-e25d4a109804

Best regards,
--  
Eric A. Stalee <mail@eric-stalee.eu>

