From: FAN YE <fy15309206903@gmail.com>
Date: Sun, 23 Aug 2026 00:41:18 +0000
Subject: [PATCH v2] btrfs: zstd: keep the last max level workspace out of
 reclaim
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260823-btrfs-zstd-max-level-reclaim-v2-1-2a84517cfeb4@gmail.com>
X-B4-Tracking: v=1; b=H4sIAK1BimoC/yXMwQrCMAwA0F8ZORsYVav4K+Kh7RKNdFOSOoZj/
 75Oj+/yZjBSIYNLM4PSKCavocLtGkiPMNwJpasG1zrfnt0eY1E2/FrpsA8TZhopo1LKQXo8eWb
 2R2aKB6jFW4ll+vXX29/2iU9KZTthWVYczDzegAAAAA==
X-Change-ID: 20260823-btrfs-zstd-max-level-reclaim-76fff65ffeb4
To: David Sterba <dsterba@suse.com>, Nick Terrell <terrelln@fb.com>, 
 Chris Mason <clm@fb.com>
Cc: linux-kernel@vger.kernel.org, linux-btrfs@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787445677; l=6538;
 i=fy15309206903@gmail.com; s=tbnet3; h=from:subject:message-id;
 bh=+QanFPZv1V9gqMQYN+jo/lcE8ZMOysJk3M2saAPln6w=;
 b=E5Gi1h8d4WthQVb8k2Uq6GWRq9EKGIDr3JhuCqWXwUaAtYbkUzpNJcCdz8aIUjF5vyGkL3DnX
 vRLFR7x1gliAgQ+RITxtrXr4z4LzG4qfEeburYJjCJ+1m9nyv38bC+W
X-Developer-Key: i=fy15309206903@gmail.com; a=ed25519;
 pk=6QsQIrI/kruYWIJyCH9ntPMXsHCqF5JtK/DCMtOCzdc=
X-Endpoint-Received: by B4 Relay for fy15309206903@gmail.com/tbnet3 with auth_id=929
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

zstd_put_workspace() decides whether a max level workspace should be
kept off the reclaim lru by checking whether idle_ws[MAX-1] is empty
at the moment of the put, and only for a put at the workspace's own
level. Decompression always returns at level 0, so a workspace
borrowed by a read skips that check and keeps its previous lru state;
enough readers borrowing every idle max level workspace at once leaves
none of them protected, and the reclaim timer can free them all,
leaving a task sleeping in zstd_get_workspace() with no waker.
Checking a shared list snapshot per put is also not an exclusive
decision across concurrent returns: two workspaces borrowed together
can each see idle_ws[MAX-1] empty and each get hidden, so more than
one ends up off the lru. A put at the workspace's own level puts it
back, so write traffic keeps correcting this, but a read-only workload
has no such put: whatever is off the lru when writes stop stays there,
unreachable to the reclaim timer, which walks only lru_list.

Track the reserved workspace by identity instead of a snapshot:
zwsm->pinned_ws names the one max level workspace that must never be
linked on lru_list, assigned once at manager init or on the first put
of a max level workspace and never reassigned. Every other max level
workspace, and every workspace returned below its own level, follows
the ordinary lru bookkeeping unchanged.

By construction, not just by timing: the only list_add() onto lru_list
excludes workspace == pinned_ws, and zstd_find_workspace() only ever
removes from lru_list, so the reclaim timer can never select the
pinned workspace as a victim.

zstd_find_workspace() has to use list_del_init() rather than list_del()
for this: the pinned workspace's lru_list is a self-linked node, and
poisoning it there would make the list_del_init() below dereference
LIST_POISON1 when it is returned.

Fixes: 3f93aef535c8 ("btrfs: add zstd compression level support")
Assisted-by: Claude:claude-opus-5
Signed-off-by: FAN YE <fy15309206903@gmail.com>
---
Changes since v1
(20260822-btrfs-zstd-max-level-reclaim-v1-1-0eb13c127480@gmail.com):
thanks to Sashiko for the review and to Qu Wenruo for relaying it. The
report is right that v1's idle_ws[MAX-1] snapshot is not exclusive
across concurrent returns, and it reproduces; v2 replaces the snapshot
with the pinned_ws pointer above.

Two details in that report did not survive measurement, noted so the
fix is judged on the right numbers:

  - a max level workspace is zstd_ws_mem_sizes[MAX-1] = 3277447 bytes
    (3.13 MiB), not ~8 MB;
  - it is not a one-way ratchet.  A put at the workspace's own level
    puts it back on the lru, so write traffic keeps correcting it.
    What persists is whatever is off the lru when writes stop.

Measured under QEMU/TCG, smp=4, one kernel build for all arms,
compress-force=zstd:15, reclaim interval 100ms, 6 rounds of 8 writers
+ drop_caches + 8 readers/4 writers.  "stuck" is idle max level
workspaces still off the lru once the reclaim timer has run with no
further puts, i.e. what stays until unmount; one is intended.

                      tail       stuck (3 runs)   leaked
  v1 (snapshot)   writes+sync         1 / 1 / 1        0
  v1 (snapshot)   reads only          3 / 5 / 4    up to 12.5 MiB
  v2 (pinned_ws)  reads only          1 / 1 / 1        0

Same code and concurrency in both v1 rows; only the tail differs,
which is why a mixed workload hides this.  The count is bounded by
concurrent level 15 allocations, i.e. min(nr_online_cpus + 2, 8) --
6 here, matching the observed peak -- so at most 7 x 3.13 MiB per
mount on a larger machine.

Compile-tested (W=1, x86_64 defconfig + CONFIG_BTRFS_FS=y).
---
 fs/btrfs/zstd.c | 30 ++++++++++++++++++------------
 1 file changed, 18 insertions(+), 12 deletions(-)

diff --git a/fs/btrfs/zstd.c b/fs/btrfs/zstd.c
index 86919293fd546..8bd9045da9dd9 100644
--- a/fs/btrfs/zstd.c
+++ b/fs/btrfs/zstd.c
@@ -83,6 +83,8 @@ struct zstd_workspace_manager {
 	unsigned long active_map;
 	wait_queue_head_t wait;
 	struct timer_list timer;
+	/* The one max level workspace forward progress depends on; never on lru_list. */
+	struct workspace *pinned_ws;
 };
 
 static size_t zstd_ws_mem_sizes[ZSTD_BTRFS_MAX_LEVEL];
@@ -204,6 +206,7 @@ int zstd_alloc_workspace_manager(struct btrfs_fs_info *fs_info)
 	} else {
 		set_bit(ZSTD_BTRFS_MAX_LEVEL - 1, &zwsm->active_map);
 		list_add(ws, &zwsm->idle_ws[ZSTD_BTRFS_MAX_LEVEL - 1]);
+		zwsm->pinned_ws = list_to_workspace(ws);
 	}
 	return 0;
 }
@@ -260,7 +263,7 @@ static struct list_head *zstd_find_workspace(struct btrfs_fs_info *fs_info, int
 			/* keep its place if it's a lower level using this */
 			workspace->req_level = level;
 			if (clip_level(level) == workspace->level)
-				list_del(&workspace->lru_list);
+				list_del_init(&workspace->lru_list);
 			if (list_empty(&zwsm->idle_ws[i]))
 				clear_bit(i, &zwsm->active_map);
 			spin_unlock_bh(&zwsm->lock);
@@ -335,18 +338,21 @@ void zstd_put_workspace(struct btrfs_fs_info *fs_info, struct list_head *ws)
 	ASSERT(zwsm);
 	spin_lock_bh(&zwsm->lock);
 
+	/* Forward progress depends on always keeping one max level workspace */
+	if (workspace->level == clip_level(ZSTD_BTRFS_MAX_LEVEL)) {
+		if (!zwsm->pinned_ws)
+			zwsm->pinned_ws = workspace;
+		if (workspace == zwsm->pinned_ws)
+			list_del_init(&workspace->lru_list);
+	}
 	/* A node is only taken off the lru if we are the corresponding level */
-	if (clip_level(workspace->req_level) == workspace->level) {
-		/* Hide a max level workspace from reclaim */
-		if (list_empty(&zwsm->idle_ws[ZSTD_BTRFS_MAX_LEVEL - 1])) {
-			INIT_LIST_HEAD(&workspace->lru_list);
-		} else {
-			workspace->last_used = jiffies;
-			list_add(&workspace->lru_list, &zwsm->lru_list);
-			if (!timer_pending(&zwsm->timer))
-				mod_timer(&zwsm->timer,
-					  jiffies + ZSTD_BTRFS_RECLAIM_JIFFIES);
-		}
+	if (workspace != zwsm->pinned_ws &&
+	    clip_level(workspace->req_level) == workspace->level) {
+		workspace->last_used = jiffies;
+		list_add(&workspace->lru_list, &zwsm->lru_list);
+		if (!timer_pending(&zwsm->timer))
+			mod_timer(&zwsm->timer,
+				  jiffies + ZSTD_BTRFS_RECLAIM_JIFFIES);
 	}
 
 	set_bit(workspace->level, &zwsm->active_map);

---
base-commit: 2709dd5ae32f0828f386327c76bba9f39f63a1c6
change-id: 20260823-btrfs-zstd-max-level-reclaim-76fff65ffeb4

Best regards,
--  
FAN YE <fy15309206903@gmail.com>

