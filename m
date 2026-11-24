From: Devin Armstrong <darmstrong@tantalus.com>
Date: Tue, 24 Nov 2026 13:39:03 -0700
Subject: [PATCH] ubifs: Bound lpt_gc() retries when LPT GC makes no
 progress
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-lpt-gc-send-v1-1-eb975487c6d5@tantalus.com>
X-B4-Tracking: v=1; b=H4sIAOb1BWsC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQyMT3ZyCEt30ZN3i1LwUXePURIO0VGMjs1RzAyWgjoKi1LTMCrBp0bG
 1tQAIzFwvXQAAAA==
To: Richard Weinberger <richard@nod.at>, 
 Zhihao Cheng <chengzhihao1@huawei.com>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 jpark@tantalus.com, Devin Armstrong <darmstrong@tantalus.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795552754; l=5288;
 i=darmstrong@tantalus.com; s=20261124; h=from:subject:message-id;
 bh=/APDOkmanJBs/tnInr58Zk1KaxVRxZjJZmeUMLvn5JQ=;
 b=nCJvdjKmd/7IGz0Eyo0KaP6OdxT/90Rp5R95HUB8I6nuQUAlH0cuHQEhjkZbONRbVRinyvg6B
 Et9fxBPSAutDhX7tXpAt1/DmqC827XJX/Fx1UdnTi4bNvJ/T0K2wBZt
X-Developer-Key: i=darmstrong@tantalus.com; a=ed25519;
 pk=jD9P/SgqHx/uS8fXsiq6ZAlPE3b8spE6dAOF7r+On3Y=
X-Endpoint-Received: by B4 Relay for darmstrong@tantalus.com/20261124 with auth_id=1630
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ubifs_lpt_start_commit() and ubifs_lpt_post_commit() call lpt_gc() in a
"while (need_write_all(c))" loop. If lpt_gc_lnum() cannot dirty every
node of the LEB it was given, that LEB's free + dirty space never
reaches leb_size, need_write_all() keeps returning 1, lpt_gc() keeps
selecting the same LEB, and the loop never ends.

One way to get there is the LPT scanning problem reported in the link
below: the 0xff padding at the end of an LPT commit followed by the
first bytes of the next commit's lsave node can form a valid-looking
node (the 16-bit CRC matches by chance). When this happens, a read-write
mount or remount spins in the kernel at 100% CPU and can't be killed.
Read-only mounts never commit, so they are not affected.

Track the LEB and its dirty space selected by lpt_gc() in the caller's
loop. If the same LEB is selected UBIFS_LPT_GC_MAX_RETRIES times in a
row with unchanged dirty space, return -EUCLEAN. Any pass that makes
progress changes the dirty space and restarts the count, so the normal
GC retry cycle is unaffected.

The error makes the commit fail, which puts UBIFS in read-only mode, so
the mount or remount fails with an error instead of hanging. This does
not repair the LPT, it only turns an endless loop into a failure.

Link: https://lore.kernel.org/linux-mtd/97ca7fe4-4ad4-edd1-e97a-1d540aeabe2d@huawei.com/

Signed-off-by: Devin Armstrong <darmstrong@tantalus.com>
---
Tested on a v7.0 based kernel (out-of-tree ubifs.ko built with this patch).
Remounting a volume with the linked issue as read-write now fails
immediately with -EUCLEAN and UBIFS goes read-only, instead of spinning 
in the kernel.

Also tested on a 4.19 based kernel on SPI NOR hardware with the same result.

On a healthy volume, 2 million commits of mixed xattr/utime workload
showed no change in behavior and no "LPT GC" errors.
---
 fs/ubifs/lpt_commit.c | 51 +++++++++++++++++++++++++++++++++++++++++++++++----
 1 file changed, 47 insertions(+), 4 deletions(-)

diff --git a/fs/ubifs/lpt_commit.c b/fs/ubifs/lpt_commit.c
index f2cb214581..1e583f070c 100644
--- a/fs/ubifs/lpt_commit.c
+++ b/fs/ubifs/lpt_commit.c
@@ -1140,14 +1140,39 @@ static int lpt_gc_lnum(struct ubifs_info *c, int lnum)
 	return 0;
 }
 
+/*
+ * Maximum number of times in a row 'lpt_gc()' may select the same LPT LEB
+ * without its dirty space changing, before LPT GC is considered stuck.
+ */
+#define UBIFS_LPT_GC_MAX_RETRIES 10
+
+/**
+ * struct lpt_gc_leb_retry - state for detecting LPT GC that makes no progress.
+ * @lnum: LEB selected by the previous 'lpt_gc()' call (-1 if none)
+ * @dirty: dirty space of @lnum when it was selected
+ * @count: number of consecutive times @lnum was selected with @dirty unchanged
+ *
+ * The caller keeps this on its stack for the duration of its GC loop.
+ */
+struct lpt_gc_leb_retry {
+	int lnum;
+	int dirty;
+	int count;
+};
+
 /**
  * lpt_gc - LPT garbage collection.
  * @c: UBIFS file-system description object
+ * @retry: LPT GC progress tracking, see 'struct lpt_gc_leb_retry'
  *
  * Select a LPT LEB for LPT garbage collection and call 'lpt_gc_lnum()'.
+ * If the same LEB keeps being selected and its dirty space does not change,
+ * the LPT is damaged and collecting it again cannot help, so give up instead
+ * of looping forever.
+ *
  * Returns %0 on success and a negative error code on failure.
  */
-static int lpt_gc(struct ubifs_info *c)
+static int lpt_gc(struct ubifs_info *c, struct lpt_gc_leb_retry *retry)
 {
 	int i, lnum = -1, dirty = 0;
 
@@ -1165,6 +1190,19 @@ static int lpt_gc(struct ubifs_info *c)
 	mutex_unlock(&c->lp_mutex);
 	if (lnum == -1)
 		return -ENOSPC;
+
+	if (lnum == retry->lnum && dirty == retry->dirty) {
+		if (++retry->count >= UBIFS_LPT_GC_MAX_RETRIES) {
+			ubifs_err(c, "LPT GC of LEB %d made no progress after %d attempts",
+				  lnum, retry->count);
+			return -EUCLEAN;
+		}
+	} else {
+		retry->count = 0;
+	}
+	retry->lnum = lnum;
+	retry->dirty = dirty;
+
 	return lpt_gc_lnum(c, lnum);
 }
 
@@ -1193,6 +1231,8 @@ int ubifs_lpt_start_commit(struct ubifs_info *c)
 		goto out;
 
 	if (c->check_lpt_free) {
+		struct lpt_gc_leb_retry retry = { .lnum = -1 };
+
 		/*
 		 * We ensure there is enough free space in
 		 * ubifs_lpt_post_commit() by marking nodes dirty. That
@@ -1202,7 +1242,7 @@ int ubifs_lpt_start_commit(struct ubifs_info *c)
 		c->check_lpt_free = 0;
 		while (need_write_all(c)) {
 			mutex_unlock(&c->lp_mutex);
-			err = lpt_gc(c);
+			err = lpt_gc(c, &retry);
 			if (err)
 				return err;
 			mutex_lock(&c->lp_mutex);
@@ -1315,14 +1355,17 @@ int ubifs_lpt_post_commit(struct ubifs_info *c)
 	err = lpt_tgc_end(c);
 	if (err)
 		goto out;
-	if (c->big_lpt)
+	if (c->big_lpt) {
+		struct lpt_gc_leb_retry retry = { .lnum = -1 };
+
 		while (need_write_all(c)) {
 			mutex_unlock(&c->lp_mutex);
-			err = lpt_gc(c);
+			err = lpt_gc(c, &retry);
 			if (err)
 				return err;
 			mutex_lock(&c->lp_mutex);
 		}
+	}
 out:
 	mutex_unlock(&c->lp_mutex);
 	return err;

---
base-commit: a5e0055eac837a1168c781653943d4a0d9920af3
change-id: 20261124-lpt-gc-send-3ea0fe326e70

Best regards,
-- 
Devin Armstrong <darmstrong@tantalus.com>

