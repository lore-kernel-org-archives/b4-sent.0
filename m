From: FAN YE <fy15309206903@gmail.com>
Date: Sun, 23 Aug 2026 09:28:25 +0000
Subject: [PATCH] btrfs: scrub: wake up cancel_dev waiters after clearing
 dev->scrub_ctx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260823-btrfs-scrub-cancel-dev-wakeup-v1-1-374d618ab25f@gmail.com>
X-B4-Tracking: v=1; b=H4sIADi9imoC/yXMOw7CMAwA0KtUnrEUXFE+V0EdEteBAAqV3RSkq
 ncnwPiWt4CJJjE4NQuozMnSM1dsNw3w1eeLYBqqgRx17kAthkmjobGWgOwzywMHmfHl71JGjIH
 k2FK3jzsH9RhVYnr//nP/t5VwE56+KazrBzXfgIyBAAAA
X-Change-ID: 20260823-btrfs-scrub-cancel-dev-wakeup-fb2e93267f50
To: Chris Mason <clm@fb.com>, David Sterba <dsterba@suse.com>
Cc: linux-kernel@vger.kernel.org, linux-btrfs@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787477305; l=2575;
 i=fy15309206903@gmail.com; s=tbnet3; h=from:subject:message-id;
 bh=xdBeUrOdCn8ylb7MLha5PMKpDHCyFGYa0B8rXagVhfI=;
 b=jLklhCiaNoRe3Z8PESXyLhw//+kfc6CWifs9QTWqXLIQs/D1boASK1id5bwbss+8S7pACduFW
 jfGTkVxSSs/CTZPF3HU7tgu0vAsQtG2kTqpVg4DhMv8heiEGZlFEprl
X-Developer-Key: i=fy15309206903@gmail.com; a=ed25519;
 pk=6QsQIrI/kruYWIJyCH9ntPMXsHCqF5JtK/DCMtOCzdc=
X-Endpoint-Received: by B4 Relay for fy15309206903@gmail.com/tbnet3 with auth_id=929
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

btrfs_scrub_cancel_dev() waits on fs_info->scrub_pause_wait for
dev->scrub_ctx to become NULL.  btrfs_scrub_dev() wakes that queue right
after dropping scrubs_running, several statements before it clears the
pointer, and never wakes it again.  The canceller is already queued by
then: it sets sctx->cancel_req before waiting, and the scrub only starts
finishing once should_cancel_scrub() observes that flag.  So the wakeup it
gets is the early one, its recheck still finds dev->scrub_ctx set, and it
goes back to sleep before the store it is waiting for.

Nothing wakes the queue after the store.  scrubs_running is already zero,
and btrfs_rm_device() reaches btrfs_scrub_cancel_dev() holding a
transaction handle, so the commit that would call btrfs_scrub_continue()
blocks behind the sleeping canceller.  Device removal, the transaction
kthread and any fsync() on the filesystem hang indefinitely.  Wake the
queue after the store as well.

Fixes: a2de733c78fa ("btrfs: scrub")
Assisted-by: Claude:claude-opus-5 sashiko
Signed-off-by: FAN YE <fy15309206903@gmail.com>
---
Reproduced on unmodified kernels in a VM: a scrub running on the device
btrfs_rm_device() removes.  Upstream hangs in all 7 attempts where the
canceller actually slept - 4 with transaction commits forced back to back,
3 at the default commit interval - and 0 of 16 with this patch.  ftrace
records no sched_wakeup at all for the blocked task after dev->scrub_ctx is
seen NULL, while btrfs-transacti and a plain BTRFS_IOC_SYNC block behind
it.  Attempts where the cancel returned -ENOTCONN, or returned 0 without
ever sleeping, are not counted either way.  Moving the existing wakeup
after the store instead of adding one also works (0 of 9) and is not
measurably cheaper; this keeps each wakeup next to the store it publishes.
Compile-tested (W=1, x86_64 defconfig + CONFIG_BTRFS_FS=y).
---
 fs/btrfs/scrub.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/fs/btrfs/scrub.c b/fs/btrfs/scrub.c
index f209e75f0ff5..43fee426fdab 100644
--- a/fs/btrfs/scrub.c
+++ b/fs/btrfs/scrub.c
@@ -3177,6 +3177,7 @@ int btrfs_scrub_dev(struct btrfs_fs_info *fs_info, u64 devid, u64 start,
 	mutex_lock(&fs_info->scrub_lock);
 	dev->scrub_ctx = NULL;
 	mutex_unlock(&fs_info->scrub_lock);
+	wake_up(&fs_info->scrub_pause_wait);
 
 	scrub_workers_put(fs_info);
 	scrub_put_ctx(sctx);

---
base-commit: 2709dd5ae32f0828f386327c76bba9f39f63a1c6
change-id: 20260823-btrfs-scrub-cancel-dev-wakeup-fb2e93267f50

Best regards,
--  
FAN YE <fy15309206903@gmail.com>

