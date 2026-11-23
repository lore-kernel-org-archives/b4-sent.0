From: Mani Tofigh <mt4022@columbia.edu>
Date: Mon, 23 Nov 2026 01:07:56 -0500
Subject: [PATCH v2] btrfs: fix loss of fsynced file after link into new dir
 and unlink
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-btrfs-link-unlink-fsync-v2-1-ed3f9f63fbd7@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CQAyF4auQrm1iZwIJXsW4GMYOVE01UyAQw
 t0dcfXyLd6/gXEWNrhUG2SexeStBe5UQRyC9oxyLwZ3dg2R89iNORm+RJ846THJVo0YfGiprol
 800J5fzInWY7y9fa3Td2D4/jLwb5/AXziXF57AAAA
X-Change-ID: 20261123-btrfs-link-unlink-fsync-a3a915511369
To: David Sterba <dsterba@suse.com>
Cc: Chris Mason <mason@kernel.org>, Filipe Manana <fdmanana@suse.com>, 
 linux-btrfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 tz2294@columbia.edu, stable@vger.kernel.org, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795414075; l=3112;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=Tc91JtfYmxCuiF0usK0qEfcZgYz3hGtDsKZfAKcD+5w=;
 b=M7IgzntfDd/wqtPf0wHciUSB5SEDcweEyRSuqVzvtgtZRBku0pV6oB/3gj7A9c0e+R8+QD24H
 +L4yLy5ZV6TDAbcEUoc727CvBKhH0JdCYH7tWSZvejEMSzKI+lyIgtq
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
  fsync(fd)
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
from the inode refs in the subvolume tree and logs B and A.  Also return
early for an inode with a link count of 0, which has no parents to log.

The problem is old, e.g., v7.1 has it.  It was hidden by a transaction
commit fallback between commit 0f24ea456ae1 ("btrfs: tracepoints: add
trace event for btrfs_log_all_parents()") and
commit 36f9aafa46f5 ("btrfs: fix unnecessary transaction commit fallback
from btrfs_log_all_parents()").

With the fix, the file survives log replay.

CC: stable@vger.kernel.org
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
Changes in v2:
- Return early from log_all_new_ancestors() for an inode with a link
  count of 0, to avoid a transaction commit (Filipe)
- Drop the fdatasync mention and the reproducer paragraph (Filipe)
- Rebase on btrfs for-next
- Link to v1: https://lore.kernel.org/r/20261111-btrfs-link-unlink-fsync-v1-1-a817d4a890af@columbia.edu
---
 fs/btrfs/tree-log.c | 12 ++++++++++--
 1 file changed, 10 insertions(+), 2 deletions(-)

diff --git a/fs/btrfs/tree-log.c b/fs/btrfs/tree-log.c
index 763487114f85..445374b06ee8 100644
--- a/fs/btrfs/tree-log.c
+++ b/fs/btrfs/tree-log.c
@@ -7541,11 +7541,19 @@ static int log_all_new_ancestors(struct btrfs_trans_handle *trans,
 
 	trace_btrfs_log_all_new_ancestors_enter(trans, inode);
 
+	if (inode->vfs_inode.i_nlink == 0) {
+		ret = 0;
+		goto out;
+	}
+
 	/*
 	 * For a single hard link case, go through a fast path that does not
-	 * need to iterate the fs/subvolume tree.
+	 * need to iterate the fs/subvolume tree. But not if the inode had a
+	 * link, unlink or rename in the current transaction, since the dentry
+	 * used for the fsync may then be an unlinked one.
 	 */
-	if (inode->vfs_inode.i_nlink < 2) {
+	if (inode->vfs_inode.i_nlink < 2 &&
+	    inode->last_unlink_trans < trans->transid) {
 		ret = log_new_ancestors_fast(trans, inode, parent, ctx);
 		goto out;
 	}

---
base-commit: 845c6105edd82f5d0aa72377ef6eb8592ac4e00a
change-id: 20261123-btrfs-link-unlink-fsync-a3a915511369

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

