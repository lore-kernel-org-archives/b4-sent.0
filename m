From: Mani Tofigh <mt4022@columbia.edu>
Date: Wed, 11 Nov 2026 16:41:12 -0500
Subject: [PATCH] btrfs: fix loss of fsynced file after link into new dir
 and unlink
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-btrfs-link-unlink-fsync-v1-1-a817d4a890af@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQqDMBBFryKz7oAGDOJVpAsTJ3baMi0ZFUW8u
 zH+zect3ttBKTIptMUOkRZW/kmC6lGAf/UyEvKQGExpbJWGbopB8cvywVnyBd3Eo2mobwzVvrY
 Okv2PFHjN5e55s87uTX66cnAcJ0LpL317AAAA
X-Change-ID: 20261111-btrfs-link-unlink-fsync-28ea82e5c56b
To: David Sterba <dsterba@suse.com>
Cc: Chris Mason <mason@kernel.org>, Filipe Manana <fdmanana@suse.com>, 
 linux-btrfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 tz2294@columbia.edu, stable@vger.kernel.org, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794433272; l=3107;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=JJHTvU9AbtLdmkks3pC7kN08S+SdKLTMH7tvu3/atzo=;
 b=bVSKpsrlub2NsW242Dk1cjS+F/kB9pGV3rKL6fP/Jr72Ud+/xnaTg2lBFDFY8BOTMnk1QQRr+
 /mm/LylOVivAvTfGxPAEx5+vQZFHW16vBMJjewAFTkfzys/Sh6L63aX
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If we create a file, add a hard link to it in a new directory, remove
its old name and then fsync the file through a file descriptor opened
before the unlink, the file is gone after a power failure.  Example:

  mkdir /mnt/A
  fd = open("/mnt/A/foo", O_CREAT | O_WRONLY)
  mkdir /mnt/A/B
  ln /mnt/A/foo /mnt/A/B/bar
  unlink /mnt/A/foo
  fsync(fd)                     /* or fdatasync(fd) */
  <power fail>

After log replay, B and B/bar don't exist and the file is gone.

The fsync uses the file's dentry, which is still the unlinked A/foo.
The inode is new, so btrfs_log_all_parents() finds no parent in the
commit root, and log_all_new_ancestors() then takes the fast path for a
single link.  That path walks up from the dentry's parent A and never
logs B.  On log replay the inode ref for B/bar is skipped because B
doesn't exist, and the inode ends up with no links.

Fix this by not taking the fast path when the inode had a link, unlink
or rename in the current transaction.  The slow path finds the parents
from the inode refs in the subvolume tree and logs B and A.  That only
adds a search of the subvolume tree.

The problem is old, e.g., v7.1 loses the file as well.  It was only
hidden, by a fallback to a transaction commit, between
commit 0f24ea456ae1 ("btrfs: tracepoints: add trace event for
btrfs_log_all_parents()") and commit 36f9aafa46f5 ("btrfs: fix
unnecessary transaction commit fallback from btrfs_log_all_parents()").

With the fix, the file and its data survive.

This bug was identified and confirmed with the help of a deterministic
hypervisor currently under development.  The C reproducer below however
hits it every time.

CC: stable@vger.kernel.org
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/btrfslink.c

It uses dm-flakey to drop all writes once fsync returns.

No Fixes: tag since this looks older than the single link fast path.
---
 fs/btrfs/tree-log.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/fs/btrfs/tree-log.c b/fs/btrfs/tree-log.c
index 85ef3c26e0e4..4f24b277f1b7 100644
--- a/fs/btrfs/tree-log.c
+++ b/fs/btrfs/tree-log.c
@@ -7543,9 +7543,13 @@ static int log_all_new_ancestors(struct btrfs_trans_handle *trans,
 
 	/*
 	 * For a single hard link case, go through a fast path that does not
-	 * need to iterate the fs/subvolume tree.
+	 * need to iterate the fs/subvolume tree. But not if the inode had a
+	 * link, unlink or rename in the current transaction, since then the
+	 * dentry used for the fsync may be an unlinked one, whose parent is
+	 * not the parent of the remaining link.
 	 */
-	if (inode->vfs_inode.i_nlink < 2) {
+	if (inode->vfs_inode.i_nlink < 2 &&
+	    inode->last_unlink_trans < trans->transid) {
 		ret = log_new_ancestors_fast(trans, inode, parent, ctx);
 		goto out;
 	}

---
base-commit: 4c34f0909344e48d917afac0eeffb6e1c2681524
change-id: 20261111-btrfs-link-unlink-fsync-28ea82e5c56b

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

