From: FAN YE <fy15309206903@gmail.com>
Date: Sat, 22 Aug 2026 14:44:24 +0000
Subject: [PATCH] btrfs: dev-replace: fix missing barrier before waking bio
 counter waiters
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260822-btrfs-dev-replace-bio-counter-barrier-v1-1-e718ae7d25e5@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMe1iWoC/yXNQQrCMBBG4auUWTuQxqrFq4iLJP2rI5KUSVqE0
 rub6vJtvrdShgoyXZuVFItkSbFGe2goPF18gGWoTdbYs+mtZV90zDxgYcX0dgHsJXFIcyxQ9k4
 rp9w5a+CPp7a/OKrWpBjl8/vc7v/Os38hlB2nbfsCHhFJZokAAAA=
X-Change-ID: 20260822-btrfs-dev-replace-bio-counter-barrier-4a20eb35187a
To: Chris Mason <clm@fb.com>, David Sterba <dsterba@suse.com>
Cc: linux-btrfs@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787409863; l=2519;
 i=fy15309206903@gmail.com; s=tbnet3; h=from:subject:message-id;
 bh=MZdHDlm2NoubleaR5CcL9kU8Zazoy0BZ4w/oT8hYfK4=;
 b=TYHwrSYqdvBqnyDqX8JTn+QTV8E8AUhK13T1o30O7XM/D5iMY5bgWiWkRW/gme8KV8Tgs/oBj
 XNps9AtG5l+AK42Jou2+EsVFzhuI0vYWcdj/u575/CbyDfgCrN5JgbT
X-Developer-Key: i=fy15309206903@gmail.com; a=ed25519;
 pk=6QsQIrI/kruYWIJyCH9ntPMXsHCqF5JtK/DCMtOCzdc=
X-Endpoint-Received: by B4 Relay for fy15309206903@gmail.com/tbnet3 with auth_id=929
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

btrfs_bio_counter_sub() gates the wakeup on cond_wake_up_nomb(), whose
bare waitqueue_active() requires a full barrier from the preceding code.
percpu_counter_sub() does not provide one, its fast path is a plain
per-cpu update, so the waitqueue_active() load can be hoisted over the
counter update.  btrfs_rm_dev_replace_blocked() waits for
percpu_counter_sum() to reach zero and can then be left sleeping by the
very decrement that reaches it.  It stays asleep until some unrelated
later decrement wakes it, with BTRFS_FS_STATE_DEV_REPLACING set the whole
time, so every bio submitter on the filesystem blocks as well.
Use cond_wake_up(), which has the barrier.

Fixes: 4245215d6a8d ("Btrfs, raid56: fix use-after-free problem in the final device replace procedure on raid56")
Assisted-by: Claude:claude-opus-5
Signed-off-by: FAN YE <fy15309206903@gmail.com>
---
Two independent checks.  A litmus test of the same shape: herd7 with the LKMM
allows the interleaving and forbids it with smp_mb(); built with klitmus7 it
hits 349326 times in 64000000 iterations on x86_64, 0 times with the barrier.
With that interleaving staged in the dev-replace path in a VM (the last
in-flight bio released while the finishing waiter is queueing), the wakeup is
lost in 3/3 runs and the filesystem stalls for 24.5s until an unrelated
decrement arrives, 0/3 with this patch.  Gating the barrier on
BTRFS_FS_STATE_DEV_REPLACING to keep it off the common path does not work:
that test_bit() is unordered as well, and hoisting it over the decrement drops
the wakeup in 3/3 runs.  Compile-tested (W=1, x86_64 defconfig +
CONFIG_BTRFS_FS=y).
---
 fs/btrfs/dev-replace.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/fs/btrfs/dev-replace.c b/fs/btrfs/dev-replace.c
index dc0834f920c3..b2791480e263 100644
--- a/fs/btrfs/dev-replace.c
+++ b/fs/btrfs/dev-replace.c
@@ -1353,7 +1353,7 @@ bool __pure btrfs_dev_replace_is_ongoing(struct btrfs_dev_replace *dev_replace)
 void btrfs_bio_counter_sub(struct btrfs_fs_info *fs_info, s64 amount)
 {
 	percpu_counter_sub(&fs_info->dev_replace.bio_counter, amount);
-	cond_wake_up_nomb(&fs_info->dev_replace.replace_wait);
+	cond_wake_up(&fs_info->dev_replace.replace_wait);
 }
 
 void btrfs_bio_counter_inc_blocked(struct btrfs_fs_info *fs_info)

---
base-commit: 26260251022fbc2f248a3d747a9b2b961b18d2d8
change-id: 20260822-btrfs-dev-replace-bio-counter-barrier-4a20eb35187a

Best regards,
--  
FAN YE <fy15309206903@gmail.com>

