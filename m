From: Zhiwei Liang <zhiwei.liang@zliang.me>
Date: Wed, 28 Oct 2026 02:57:22 -0400
Subject: [PATCH] btrfs: do not leak -ERESTARTSYS from FITRIM to userspace
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-btrfs-fitrim-freezer-v1-1-0ad1d58aa94d@zliang.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3Myw5AMBBG4VeRWZtESxCvIhbFX2bhkqmIEO+us
 fwW5zwUoIJATfKQ4pQg2xph0oSG2a0TWMZospktTWZr7g/1gb0cKgt7BW4oj8XQO1Oigskpprv
 Cy/Vv2+59Pw9B65ZmAAAA
X-Change-ID: 20261028-btrfs-fitrim-freezer-d4cba16e7e13
To: David Sterba <dsterba@suse.com>, Chris Mason <mason@kernel.org>, 
 Luca Stefani <luca.stefani.ge1@gmail.com>
Cc: Qu Wenruo <wqu@suse.com>, Filipe Manana <fdmanana@suse.com>, 
 Robbie Ko <robbieko@synology.com>, linux-btrfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Zhiwei Liang <zhiwei.liang@zliang.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793170644; l=3889;
 i=zhiwei.liang@zliang.me; s=20261028; h=from:subject:message-id;
 bh=Ad5ltHNBqZJjriNkGAbAzE09HDU828bU7XQWfgn5xEc=;
 b=l5aVf854cSCkVputMgv0JYK/81X4hxuZ5sdDmE3fJg7kTXs4wErv/xbLQ17SVBAyjy7nPwgFt
 R72ccD/s9QUA/elO70Yn0HB115xNrFGSHBo6jACTPusKs/MY7vSrXc8
X-Developer-Key: i=zhiwei.liang@zliang.me; a=ed25519;
 pk=+Dr+pFt7zVWal4wTkqPegKXbLTdm/ko6GA/XhKr6NO8=
X-Endpoint-Received: by B4 Relay for zhiwei.liang@zliang.me/20261028 with auth_id=1339
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a suspend starts during FITRIM, fstrim can fail with:

  fstrim: /: FITRIM ioctl failed: Unknown error 512

On a Fedora 44 laptop with kernel 7.2.7, 3 of the last 21 weekly
fstrim.service runs were in progress when an automatic suspend started.
All three failed this way and left the filesystem untrimmed.

Since commit 69313850dce3 ("btrfs: add cancellation points to trim
loops"), the trim loops return -ERESTARTSYS when
btrfs_trim_interrupted() sees freezing(current), and FITRIM returns it
to userspace. Since commit bfb670b9183b ("btrfs: handle user interrupt
properly in btrfs_trim_fs()"), btrfs_trim_fs() returns it right away.

-ERESTARTSYS is only valid while a signal is pending, because only the
signal handling on syscall exit turns it into a restart. But
freeze_processes() first sets pm_freezing, which makes freezing() true
for every user task. Then it walks the task list and sends each task a
fake signal. The trim loops check btrfs_trim_interrupted() after every
extent. If a check falls in this window, the loop returns -ERESTARTSYS
with no signal pending. Nothing restarts the syscall. On that laptop,
with a few thousand threads, freezing user space took 2 to 5 ms in each
of the three suspends above, and all three runs hit this window.

Make btrfs_trim_interrupted() treat a freeze as an interruption only
once the fake signal has arrived, i.e. when
freezing(current) && signal_pending(current). freeze_processes() sends
that signal in the same call. The trim loop stops at the next check
after it, so suspend is not delayed.

The restarted syscall re-reads struct fstrim_range from user memory.
When the device phase is interrupted, btrfs_trim_fs() has already stored
the trimmed byte count in range->len, and btrfs_ioctl_fitrim() copies
the struct back unconditionally. The restart is then asked to trim
[start, start + trimmed) instead of the requested range, or fails with
-EINVAL when nothing was counted yet. Skip the copy_to_user() for
-ERESTARTSYS. In all other cases the partial count is still copied back.

Tested in a VM with pm_test=freezer. Without the patch, 18 of 20 freezes
during a trim leaked errno 512, and 10 of 10 restarts after a
device-phase interruption failed with -EINVAL. With the patch, all 30
runs restarted and trimmed the full amount.

Fixes: 69313850dce3 ("btrfs: add cancellation points to trim loops")
CC: stable@vger.kernel.org # 5.15+
Signed-off-by: Zhiwei Liang <zhiwei.liang@zliang.me>
---
 fs/btrfs/free-space-cache.h | 3 ++-
 fs/btrfs/ioctl.c            | 7 +++++++
 2 files changed, 9 insertions(+), 1 deletion(-)

diff --git a/fs/btrfs/free-space-cache.h b/fs/btrfs/free-space-cache.h
index e22443598b..cba2f5fd6b 100644
--- a/fs/btrfs/free-space-cache.h
+++ b/fs/btrfs/free-space-cache.h
@@ -58,7 +58,8 @@ static inline bool btrfs_free_space_trimming_bitmap(
 
 static inline bool btrfs_trim_interrupted(void)
 {
-	return fatal_signal_pending(current) || freezing(current);
+	return fatal_signal_pending(current) ||
+	       (freezing(current) && signal_pending(current));
 }
 
 /*
diff --git a/fs/btrfs/ioctl.c b/fs/btrfs/ioctl.c
index ac070c745b..b02c59cbb0 100644
--- a/fs/btrfs/ioctl.c
+++ b/fs/btrfs/ioctl.c
@@ -529,6 +529,13 @@ static noinline int btrfs_ioctl_fitrim(struct btrfs_fs_info *fs_info,
 	range.minlen = max(range.minlen, minlen);
 	ret = btrfs_trim_fs(fs_info, &range);
 
+	/*
+	 * A restart re-reads the range from user space, so do not clobber it
+	 * with the partial len the rerun would otherwise take as its input.
+	 */
+	if (ret == -ERESTARTSYS)
+		return ret;
+
 	if (copy_to_user(arg, &range, sizeof(range)))
 		return -EFAULT;
 

---
base-commit: e17e64baf63f7c85bec209ed73f14c1b2a7e39fb
change-id: 20261028-btrfs-fitrim-freezer-d4cba16e7e13

Best regards,
-- 
Zhiwei Liang <zhiwei.liang@zliang.me>

