From: Peter Lamberg <kernel@pelam.fi>
Date: Tue, 03 Nov 2026 22:29:43 +0200
Subject: [PATCH] btrfs: keep drop_progress when resuming snapshot deletion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-drop-progress-v1-1-16e345565109@pelam.fi>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ5AMBBA0avIrDVpSxBXEQtlMBbazCAScXfF8
 i3+v0CQCQXq5ALGg4T8GmHSBPq5WydUNESD1bYwRmdqYB9UYD8xiqhurFxpcquz0kFsAuNI5/d
 r2t+yuwX77Z3AfT8ePSggcQAAAA==
X-Change-ID: 20261103-drop-progress-af8b7142037b
To: linux-btrfs@vger.kernel.org
Cc: linux-kernel@vger.kernel.org, josef@toxicpanda.com, dsterba@suse.com, 
 fdmanana@suse.com, mason@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793737797; l=3991;
 i=kernel@pelam.fi; s=20261103; h=from:subject:message-id;
 bh=+0hMPVJNrK3nqWmVIXPLZTc0fOhJ6F352/cjiqMYRHc=;
 b=vFBm9fFlMCurRCtUXizufaul/ytO7E0YikFCAQNrIGucv93R4TOKbJryHovwmYukTt2LeuomY
 Y9MaFlBnphwBEsdsV3o1mTkHerUmzCTlrppVB+Xtq3BlYl0moU0CLHr
X-Developer-Key: i=kernel@pelam.fi; a=ed25519;
 pk=qpD/xh/xwDGEMdfQk/5prChHF0mXHXDTrs35FxiJgrk=
X-Endpoint-Received: by B4 Relay for kernel@pelam.fi/20261103 with auth_id=1398
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When btrfs_drop_snapshot() resumes a partially dropped subvolume, it
copies the saved resume key from the root item into wc->update_progress
only. wc is kzalloc'ed, so wc->drop_progress and wc->drop_level stay
zero. The main loop writes both back into the root item on every
iteration, and wc->drop_progress is only updated once this run drops a
reference itself (DROP_REFERENCE stage).

If the child at the resume slot is shared and the walk is still in
UPDATE_BACKREF when a checkpoint happens (an unmount or commit before
the first drop), the root item gets drop_progress (0 0 0) and
drop_level 0 while the root item still exists. The next mount then
restarts the drop from the left edge of the tree. Children that the
earlier run already finished now have refs == 1, held by the surviving
snapshot only, so the restarted walk treats them as exclusively owned
and tries to free the dropped tree's reference again:

  unable to find ref byte nr ... parent 0 root N owner L offset 0
  BTRFS: error ... in __btrfs_free_extent: errno=-117 Filesystem corrupted

and the transaction aborts.

Before the commit below, the root item's drop_progress was left alone
while in UPDATE_BACKREF. Restore that behaviour by seeding
wc->drop_progress and wc->drop_level from the root item on resume, so a
checkpoint before the first drop rewrites the same resume point instead
of zeroing it.

Fixes: aea6f028d01d ("btrfs: save drop_progress if we drop refs at all")
Cc: stable@vger.kernel.org # 5.1+
Assisted-by: LLM
Signed-off-by: Peter Lamberg <kernel@pelam.fi>
---
Test notes (not for the commit log):

Reproducer: subvolume S1 with a level-3 tree, read-only snapshot S2,
delete S1, unmount after the first root child is dropped, mount and
unmount right away, then let the drop finish. fstests test sent
separately (btrfs/355).

Reproducers and logs: https://pelam.fi/btrfs-drop-progress/

Tested on Ubuntu 26.10, kernel 7.3.0-9-generic (v7.3-rc6 based), with
btrfs.ko rebuilt from the matching Ubuntu source, 3 runs per module of
the same sequence on a loop image with dm-delay plus btrfs check
--readonly:

  module              drop key zeroed  abort  btrfs check  snapshot S2
  stock               3/3              3/3    errors 3/3   EIO 3/3
  built, unpatched    3/3              3/3    errors 3/3   EIO 3/3
  built, patched      0/3              0/3    clean 3/3    intact 3/3

Unpatched and patched were built from the same tree with the same
toolchain. With the patch the drop key kept the resume point over 20
mount/unmount cycles and the following mount finished the drop.

fstests -g quick (btrfs): 765 of 766 pass with and without the patch;
generic/574 (fs-verity, 1K block size) fails in both runs, unrelated
to this change.

btrfs/355 (no dm-delay, checks the drop key after each resume): fails
3/3 on stock and 3/3 unpatched, passes 3/3 with the patch, ~15 s per
run; same result with the devices on tmpfs.

The patch applies to v7.0.14 through v7.4-rc1; v7.4-rc1 still has the
unpatched resume code. Upstream tags were built (v7.3.1, W=1 clean on
extent-tree.o) but not run.
---

---
 fs/btrfs/extent-tree.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/fs/btrfs/extent-tree.c b/fs/btrfs/extent-tree.c
index 9b0a5c6b96f3..41a8b25c6e0f 100644
--- a/fs/btrfs/extent-tree.c
+++ b/fs/btrfs/extent-tree.c
@@ -6333,9 +6333,12 @@ int btrfs_drop_snapshot(struct btrfs_root *root, bool update_ref, bool for_reloc
 		btrfs_disk_key_to_cpu(&key, &root_item->drop_progress);
 		memcpy(&wc->update_progress, &key,
 		       sizeof(wc->update_progress));
+		/* keep the resume point until this run drops something itself */
+		memcpy(&wc->drop_progress, &key, sizeof(wc->drop_progress));
 
 		level = btrfs_root_drop_level(root_item);
 		BUG_ON(level == 0);
+		wc->drop_level = level;
 		path->lowest_level = level;
 		ret = btrfs_search_slot(NULL, root, &key, path, 0, 0);
 		path->lowest_level = 0;



