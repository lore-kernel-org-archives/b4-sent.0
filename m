From: FAN YE <fy15309206903@gmail.com>
Date: Sat, 22 Aug 2026 12:45:13 +0000
Subject: [PATCH] btrfs: zstd: keep the last max level workspace out of
 reclaim
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260822-btrfs-zstd-max-level-reclaim-v1-1-0eb13c127480@gmail.com>
X-B4-Tracking: v=1; b=H4sIANiZiWoC/yXMwQ6CMAwA0F8hPdsEZlD0VwyHbnRaM9C0kxAJ/
 +7U47u8FYxV2OBcraA8i8ljKmh2FYQbTVdGGYrB1e5Qd86hzxoN35YHHGnBxDMnVA6JZMSWfHu
 iYxO7PUMpnspRll9/6f+2l79zyN8Ttu0DoSZbzYAAAAA=
X-Change-ID: 20260822-btrfs-zstd-max-level-reclaim-5ab59a71f83e
To: David Sterba <dsterba@suse.com>, Nick Terrell <terrelln@fb.com>, 
 Chris Mason <clm@fb.com>
Cc: linux-kernel@vger.kernel.org, linux-btrfs@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787402712; l=4571;
 i=fy15309206903@gmail.com; s=tbnet3; h=from:subject:message-id;
 bh=OtLQ/8I9vVwdtLcOdjYllHgpwfHXTt1umssx95LsQ5I=;
 b=hvDFP+R94dxoHaf3IoWxwvL9AeZaYtUCWHx4GpEe2Xy6GP97zgTjY5NRkQzQV10amzSG4A8ka
 CRDy6eIl4MxAPti7K9F08ZdZYk0rz+UqvtmEh7lc2YVgiiKkP5z/z+w
X-Developer-Key: i=fy15309206903@gmail.com; a=ed25519;
 pk=6QsQIrI/kruYWIJyCH9ntPMXsHCqF5JtK/DCMtOCzdc=
X-Endpoint-Received: by B4 Relay for fy15309206903@gmail.com/tbnet3 with auth_id=929
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

zstd_put_workspace() makes the "hide this workspace from the reclaim timer"
decision only when the workspace is returned at its own level.
Decompression always asks for level 0, so a max level workspace borrowed by
a read skips the whole block and the test for being the last max level
workspace is never made: it goes back to idle_ws[] still linked on the lru.
A read borrowing one while a write holds the other is enough to leave every
max level workspace on the lru, where the reclaim timer can then free them
all and clear the level bit.

Once no max level workspace is left, zstd_put_workspace() never reaches
cond_wake_up() and a task sleeping in zstd_get_workspace() after a failed
allocation has no possible waker.  Make the decision on every put of a max
level workspace and unlink it from the lru when it is the last one;
list_del_init() in zstd_find_workspace() keeps the entry usable for that.
The test also no longer hides workspaces of other levels, which it did
whenever no max level workspace happened to be idle.

Fixes: 3f93aef535c8 ("btrfs: add zstd compression level support")
Assisted-by: Claude:claude-opus-5
Signed-off-by: FAN YE <fy15309206903@gmail.com>
---
Reproduced under QEMU/TCG.  Both arms are the same kernel with the reclaim
interval shortened to 100ms and a module param picking the old or the new
zstd_put_workspace(); the workload is compress-force=zstd:15, three rounds
of four concurrent writers followed by drop_caches, four readers and two
writers.  "unprotected" counts puts of a max level workspace after which
nothing left in idle_ws[] is off the lru; "borrowed" counts a max level
workspace taken and returned by a lower level request, the path this patch
changes.

                    borrowed   unprotected   timer cleared the level bit
  current code       245/339       118/216                          1/0
  this patch         300/379           0/0                          0/0

borrowed is of the same order in both arms, so the zeroes are not "the code
was never reached".  The last column needs the reclaim timer to tick inside
the window, so it is a coincidence rather than the criterion.

Compile-tested (W=1, x86_64 defconfig + CONFIG_BTRFS_FS=y).  Independent of
and applies without my lost wakeup fix for zstd_get_workspace(),
20260821-btrfs-zstd-lost-wakeup-v1-1-84f358d4ea67@gmail.com.
---
 fs/btrfs/zstd.c | 25 ++++++++++++-------------
 1 file changed, 12 insertions(+), 13 deletions(-)

diff --git a/fs/btrfs/zstd.c b/fs/btrfs/zstd.c
index 86919293fd54..8abc4e456f32 100644
--- a/fs/btrfs/zstd.c
+++ b/fs/btrfs/zstd.c
@@ -260,7 +260,7 @@ static struct list_head *zstd_find_workspace(struct btrfs_fs_info *fs_info, int
 			/* keep its place if it's a lower level using this */
 			workspace->req_level = level;
 			if (clip_level(level) == workspace->level)
-				list_del(&workspace->lru_list);
+				list_del_init(&workspace->lru_list);
 			if (list_empty(&zwsm->idle_ws[i]))
 				clear_bit(i, &zwsm->active_map);
 			spin_unlock_bh(&zwsm->lock);
@@ -335,18 +335,17 @@ void zstd_put_workspace(struct btrfs_fs_info *fs_info, struct list_head *ws)
 	ASSERT(zwsm);
 	spin_lock_bh(&zwsm->lock);
 
-	/* A node is only taken off the lru if we are the corresponding level */
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
+	/* Forward progress depends on always keeping one max level workspace */
+	if (workspace->level == clip_level(ZSTD_BTRFS_MAX_LEVEL) &&
+	    list_empty(&zwsm->idle_ws[ZSTD_BTRFS_MAX_LEVEL - 1])) {
+		list_del_init(&workspace->lru_list);
+	} else if (clip_level(workspace->req_level) == workspace->level) {
+		/* A node is only taken off the lru if we are the corresponding level */
+		workspace->last_used = jiffies;
+		list_add(&workspace->lru_list, &zwsm->lru_list);
+		if (!timer_pending(&zwsm->timer))
+			mod_timer(&zwsm->timer,
+				  jiffies + ZSTD_BTRFS_RECLAIM_JIFFIES);
 	}
 
 	set_bit(workspace->level, &zwsm->active_map);

---
base-commit: 26260251022fbc2f248a3d747a9b2b961b18d2d8
change-id: 20260822-btrfs-zstd-max-level-reclaim-5ab59a71f83e

Best regards,
--  
FAN YE <fy15309206903@gmail.com>

