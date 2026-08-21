From: FAN YE <fy15309206903@gmail.com>
Date: Fri, 21 Aug 2026 17:50:09 +0000
Subject: [PATCH] btrfs: zstd: fix lost wakeup when waiting for a workspace
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-btrfs-zstd-lost-wakeup-v1-1-84f358d4ea67@gmail.com>
X-B4-Tracking: v=1; b=H4sIANCPiGoC/yXMQQ6CMBBG4auQWTNJaaJpvIphQelfGTRAOgWNh
 Ltbdfkt3ttJkQRKl2qnhE1U5qmgqSvqh266gSUUkzX2bJxt2OcUld+aAz9mzfzs7lgXNt4AziG
 cbKQSLwlRXr/xtf1bVz+iz98bHccHfodvq3oAAAA=
X-Change-ID: 20260821-btrfs-zstd-lost-wakeup-0b0ee88ed52f
To: Nick Terrell <terrelln@fb.com>, David Sterba <dsterba@suse.com>, 
 Chris Mason <clm@fb.com>
Cc: linux-btrfs@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787334608; l=2450;
 i=fy15309206903@gmail.com; s=tbnet3; h=from:subject:message-id;
 bh=xjp6D6qYqD4sH3kdwjEXE5HNqQTOU/ZER6nYWo6V4fQ=;
 b=oTTEQiFrnwMvoXn6fNy305piYFD2kAgBKEWI3a4LR68vmuRFhjQ3gPNrWLMMFB9ruLR1wrtcj
 ocnfgNU0kM1DLvZJQR3U4RfhCOpo5fw/Qa3rc1mt5LtUDt8uwhljYhs
X-Developer-Key: i=fy15309206903@gmail.com; a=ed25519;
 pk=6QsQIrI/kruYWIJyCH9ntPMXsHCqF5JtK/DCMtOCzdc=
X-Endpoint-Received: by B4 Relay for fy15309206903@gmail.com/tbnet3 with auth_id=929
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A writer can sleep forever in zstd_get_workspace() even though a workspace
is free.  When zstd_alloc_workspace() fails, the task is queued on
zwsm->wait and schedules unconditionally, never re-testing the pool.
zstd_put_workspace() publishes the workspace and then calls cond_wake_up(),
which only wakes when a sleeper is already visible, so a workspace returned
between the failed allocation and prepare_to_wait() wakes nobody.  The
window is wide: zstd_alloc_workspace() goes through kvmalloc() and may
enter reclaim.

Only a max level workspace triggers the wakeup and one is deliberately kept
allocated as the fallback every waiter waits for, so once its wakeup is
lost the writer stays in TASK_UNINTERRUPTIBLE until some other task happens
to return one.  Re-check the pool after prepare_to_wait() has published the
waiter, and use the workspace if one turned up.

Fixes: 3f93aef535c8 ("btrfs: add zstd compression level support")
Assisted-by: Claude:claude-opus-5
Signed-off-by: FAN YE <fy15309206903@gmail.com>
---
Reproduced under QEMU/TCG: CONFIG_FAULT_INJECTION_STACKTRACE_FILTER forces
zstd_alloc_workspace() to fail exactly once and widens the pre-wait window
to 400ms while six concurrent zstd:15 writers race it. Unpatched, a
btrfs-delalloc kworker hangs in zstd_get_workspace()'s schedule() (hung_task
warning, >120s); the identical race against the patched code does not hang.
Compile-tested (W=1, x86_64 defconfig + CONFIG_BTRFS_FS=y).
---
 fs/btrfs/zstd.c | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)

diff --git a/fs/btrfs/zstd.c b/fs/btrfs/zstd.c
index 86919293fd54..cb15cbd737c4 100644
--- a/fs/btrfs/zstd.c
+++ b/fs/btrfs/zstd.c
@@ -307,8 +307,17 @@ struct list_head *zstd_get_workspace(struct btrfs_fs_info *fs_info, int level)
 		DEFINE_WAIT(wait);
 
 		prepare_to_wait(&zwsm->wait, &wait, TASK_UNINTERRUPTIBLE);
-		schedule();
+		/*
+		 * Re-check after being queued: zstd_put_workspace() only
+		 * wakes a queue that already has a sleeper, so a workspace
+		 * returned since the failed allocation woke nobody.
+		 */
+		ws = zstd_find_workspace(fs_info, level);
+		if (!ws)
+			schedule();
 		finish_wait(&zwsm->wait, &wait);
+		if (ws)
+			return ws;
 
 		goto again;
 	}

---
base-commit: 531ed942bb0df04f6747983fecdedce76a22d07f
change-id: 20260821-btrfs-zstd-lost-wakeup-0b0ee88ed52f

Best regards,
--  
FAN YE <fy15309206903@gmail.com>

