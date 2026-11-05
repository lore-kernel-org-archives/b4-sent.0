From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 05 Nov 2026 11:49:00 +0900
Subject: [PATCH] dm-log-writes: log earlier flushes' writes when a later
 flush completes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-dmlw-flush-order-v1-1-4f154e06bc78@samsung.com>
X-B4-Tracking: v=1; b=H4sIAJvu62oC/x3MSQqAMAxA0auUrA3YguNVxIW0qQbUSooDFO9uc
 fkW/yeIJEwRepVA6OLIYc/QhQK7TPtMyC4bTGlqrcsK3bbe6NczLhjEkeBETdcaWzlvasjZIeT
 5+ZfD+L4fp3Lx02IAAAA=
To: Alasdair Kergon <agk@redhat.com>, Mike Snitzer <snitzer@kernel.org>, 
 Mikulas Patocka <mpatocka@redhat.com>, 
 Benjamin Marzinski <bmarzins@redhat.com>, dm-devel@lists.linux.dev
Cc: Josef Bacik <josef@toxicpanda.com>, fstests@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793846939; l=5569;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=QMRPbrKH67WwaocGnLh1SuH2BjgDRIWTU01gSB6rW3k=;
 b=tqLmSXBijEpYe5T4s0jo8SrtcUdu54mPjNscxK+IvpTmPO+zaxGm2962Y69S4Y0hU5qGV/HEb
 us+23pU/duUDY/1bGrXInEfptTzvY5eKlV5MdiRw8qNavJFmTaKqhzH
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Each flush takes the writes that completed since the previous flush
was issued, and logs them when it completes. If a later flush
completes first, the earlier flush's writes are logged after anything
logged in between, such as a mark. A replay to that mark then misses
writes that were already stable. Crash consistency tests report this
as data loss.

Those writes completed before the later flush was issued, so its
completion makes them stable. Log them when it completes, and document
this in log-writes.rst.

Fixes: 0e9cebe72459 ("dm: add log writes target")
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
Found on XFS (xfs for-next, QEMU guest, loop devices on tmpfs) with 8
writers that each write a block, fsync it and log a mark. A replay to
the mark missed the fsynced block at 3 of 1408 marks without this
patch and at none of 1408 with it. generic/455 457 482 757 pass with
and without it, and KASAN and lockdep report nothing.
---
 .../admin-guide/device-mapper/log-writes.rst       |  6 +++++
 drivers/md/dm-log-writes.c                         | 30 ++++++++++++++++++++++
 2 files changed, 36 insertions(+)

diff --git a/Documentation/admin-guide/device-mapper/log-writes.rst b/Documentation/admin-guide/device-mapper/log-writes.rst
index 23141f2ffb7..1223803684e 100644
--- a/Documentation/admin-guide/device-mapper/log-writes.rst
+++ b/Documentation/admin-guide/device-mapper/log-writes.rst
@@ -36,6 +36,12 @@ Again this is to simulate what is actually on disk, this allows us to detect
 cases where a power failure at a particular point in time would create an
 inconsistent file system.
 
+If a later REQ_PREFLUSH request completes while an earlier one is still in
+flight, the WRITEs attached to the earlier request are logged then, ahead of the
+later request's own WRITEs. They completed before the later REQ_PREFLUSH was
+issued, so they are on disk as well. The earlier FLUSH is logged when it
+completes.
+
 Any REQ_FUA requests bypass this flushing mechanism and are logged as soon as
 they complete as those requests will obviously bypass the device cache.
 
diff --git a/drivers/md/dm-log-writes.c b/drivers/md/dm-log-writes.c
index c72e07c3f5a..982a240f031 100644
--- a/drivers/md/dm-log-writes.c
+++ b/drivers/md/dm-log-writes.c
@@ -115,6 +115,7 @@ struct log_writes_c {
 	spinlock_t blocks_lock;
 	struct list_head unflushed_blocks;
 	struct list_head logging_blocks;
+	struct list_head inflight_flushes;
 	wait_queue_head_t wait;
 	struct task_struct *log_kthread;
 	struct completion super_done;
@@ -128,6 +129,7 @@ struct pending_block {
 	char *data;
 	u32 datalen;
 	struct list_head list;
+	struct list_head flush_list;
 	struct bio_vec vecs[];
 };
 
@@ -526,6 +528,7 @@ static int log_writes_ctr(struct dm_target *ti, unsigned int argc, char **argv)
 	}
 	spin_lock_init(&lc->blocks_lock);
 	INIT_LIST_HEAD(&lc->unflushed_blocks);
+	INIT_LIST_HEAD(&lc->inflight_flushes);
 	INIT_LIST_HEAD(&lc->logging_blocks);
 	init_waitqueue_head(&lc->wait);
 	init_completion(&lc->super_done);
@@ -629,6 +632,7 @@ static void log_writes_dtr(struct dm_target *ti)
 
 	WARN_ON(!list_empty(&lc->logging_blocks));
 	WARN_ON(!list_empty(&lc->unflushed_blocks));
+	WARN_ON(!list_empty(&lc->inflight_flushes));
 	dm_put_device(ti, lc->dev);
 	dm_put_device(ti, lc->logdev);
 	kfree(lc);
@@ -688,6 +692,7 @@ static int log_writes_map(struct dm_target *ti, struct bio *bio)
 		spin_unlock_irq(&lc->blocks_lock);
 		return DM_MAPIO_KILL;
 	}
+	INIT_LIST_HEAD(&block->flush_list);
 	INIT_LIST_HEAD(&block->list);
 	pb->block = block;
 	atomic_inc(&lc->pending_blocks);
@@ -717,6 +722,7 @@ static int log_writes_map(struct dm_target *ti, struct bio *bio)
 	if (flush_bio && !bio_sectors(bio)) {
 		spin_lock_irq(&lc->blocks_lock);
 		list_splice_init(&lc->unflushed_blocks, &block->list);
+		list_add_tail(&block->flush_list, &lc->inflight_flushes);
 		spin_unlock_irq(&lc->blocks_lock);
 		goto map_bio;
 	}
@@ -764,6 +770,29 @@ static int log_writes_map(struct dm_target *ti, struct bio *bio)
 	return DM_MAPIO_REMAPPED;
 }
 
+/*
+ * A flush mapped before @block holds writes that completed before @block was
+ * mapped, so @block's completion makes them stable. Queue them ahead of
+ * @block's own writes. inflight_flushes holds the empty flushes, in map order,
+ * whose writes are not yet queued.
+ */
+static void log_earlier_flushes(struct log_writes_c *lc,
+				struct pending_block *block)
+{
+	struct pending_block *prev;
+
+	lockdep_assert_held(&lc->blocks_lock);
+	if (list_empty(&block->flush_list))
+		return;
+	while ((prev = list_first_entry(&lc->inflight_flushes,
+					struct pending_block,
+					flush_list)) != block) {
+		list_splice_tail_init(&prev->list, &lc->logging_blocks);
+		list_del_init(&prev->flush_list);
+	}
+	list_del_init(&block->flush_list);
+}
+
 static int normal_end_io(struct dm_target *ti, struct bio *bio,
 		blk_status_t *error)
 {
@@ -776,6 +805,7 @@ static int normal_end_io(struct dm_target *ti, struct bio *bio,
 
 		spin_lock_irqsave(&lc->blocks_lock, flags);
 		if (block->flags & LOG_FLUSH_FLAG) {
+			log_earlier_flushes(lc, block);
 			list_splice_tail_init(&block->list, &lc->logging_blocks);
 			list_add_tail(&block->list, &lc->logging_blocks);
 			wake_up_process(lc->log_kthread);

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261105-dmlw-flush-order-ae7982c5df26

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

