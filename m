From: Mikko Rapeli <mikko.rapeli@linaro.org>
Date: Tue, 17 Nov 2026 10:51:37 +0200
Subject: [PATCH] lttng-modules: fix build with kernel 7.4-rc2 and newer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-lttng-modules_fix_new-v1-1-6140fe249a6b@linaro.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMUQrCMBCE4auUfTbQjdKCVxEpTTLWlZpKNrWF0
 rsb9fFjmH8jRRIonauNEt6iMsUCPlTk730cYCQUk61tw8ytGXOOg3lOYR6h3U3WLmIxfHKuZ49
 wtA2V7yuhTL/u5fq3zu4Bn78x2vcPiLg3znkAAAA=
X-Change-ID: 20261117-lttng-modules_fix_new-14bba1ced326
To: openembedded-core@lists.openembedded.org
Cc: Mikko Rapeli <mikko.rapeli@linaro.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794905502; l=3879;
 i=mikko.rapeli@linaro.org; s=20261117; h=from:subject:message-id;
 bh=AZk0kaXbyoytOhkO0HUOQUStW3Cr7dk1az8kHCeWFC0=;
 b=dM+WmlCpBJMkT5Ywi7AHvYQYipHK8kZ498TWV114aJOZYRXo2OnepxIDx1mNmtoagWH+2U8JQ
 TGmyGAyzl/GCKG8xrDFcIwFD8NU62aRQx3bRkdOg90ftSIeEJSCv5jB
X-Developer-Key: i=mikko.rapeli@linaro.org; a=ed25519;
 pk=O/vKh6bzDKoUD69mWlhfQ7Q15tHYZkbu91i+XwMsm/o=
X-Endpoint-Received: by B4 Relay for mikko.rapeli@linaro.org/20261117 with auth_id=1547
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With upstream patch.

Signed-off-by: Mikko Rapeli <mikko.rapeli@linaro.org>
---
Tested with genericarm64, linux-yocto-dev and kernel tree at
Linus master branch 7.4-rc3.
---
 ...x-splice-remove-pipe-buffer-stealing-v7.4.patch | 56 ++++++++++++++++++++++
 meta/recipes-kernel/lttng/lttng-modules_2.16.0.bb  |  1 +
 2 files changed, 57 insertions(+)

diff --git a/meta/recipes-kernel/lttng/lttng-modules/0001-fix-splice-remove-pipe-buffer-stealing-v7.4.patch b/meta/recipes-kernel/lttng/lttng-modules/0001-fix-splice-remove-pipe-buffer-stealing-v7.4.patch
new file mode 100644
index 0000000000..14cf110904
--- /dev/null
+++ b/meta/recipes-kernel/lttng/lttng-modules/0001-fix-splice-remove-pipe-buffer-stealing-v7.4.patch
@@ -0,0 +1,56 @@
+From a03326efb3ae2f3ebc6c8016535f34aa58b1623c Mon Sep 17 00:00:00 2001
+From: Michael Jeanson <mjeanson@efficios.com>
+Date: Mon, 16 Nov 2026 08:54:42 -0500
+Subject: [PATCH] fix: splice: remove pipe buffer stealing (v7.4)
+
+See upstream commit:
+
+  commit 0f76da93e5c7d41ccf1376e715278c1d474ed181
+  Author: Kiryl Shutsemau (Meta) <kas@kernel.org>
+  Date:   Tue Nov 10 14:52:38 2026 +0000
+
+    splice: remove pipe buffer stealing
+
+    Nothing calls pipe_buf_try_steal() any more.  Remove ->try_steal() from
+    struct pipe_buf_operations, its implementations and the exported
+    generic_pipe_buf_try_steal().
+
+    PIPE_BUF_FLAG_LRU and PIPE_BUF_FLAG_GIFT were set only for stealing, and
+    go too.  page_cache_pipe_buf_release() did nothing but drop the page and
+    the LRU flag, so page cache and user page buffers use
+    generic_pipe_buf_release().
+
+    vmsplice() still accepts SPLICE_F_GIFT, and splice() SPLICE_F_MOVE.
+    Both were hints, and nothing acts on them now.
+
+Upstream-Status: Backport [24b630e62dfe3465ac9a2bb19c89fdd10f5bd1c7]
+
+Change-Id: Ie1d0bddc3aa7d1af186e195c712746c0d3b358c0
+Reported-by: Mikko Rapeli <mikko.rapeli@linaro.org>
+Signed-off-by: Michael Jeanson <mjeanson@efficios.com>
+Signed-off-by: Mathieu Desnoyers <mathieu.desnoyers@efficios.com>
+---
+ src/lib/ringbuffer/ring_buffer_splice.c | 7 ++++++-
+ 1 file changed, 6 insertions(+), 1 deletion(-)
+
+diff --git a/src/lib/ringbuffer/ring_buffer_splice.c b/src/lib/ringbuffer/ring_buffer_splice.c
+index f34bc355..7e470cfc 100644
+--- a/src/lib/ringbuffer/ring_buffer_splice.c
++++ b/src/lib/ringbuffer/ring_buffer_splice.c
+@@ -47,7 +47,12 @@ static void lib_ring_buffer_pipe_buf_release(struct pipe_inode_info *pipe,
+ 	__free_page(pbuf->page);
+ }
+ 
+-#if (LTTNG_LINUX_VERSION_CODE >= LTTNG_KERNEL_VERSION(5,8,0))
++#if (LTTNG_LINUX_VERSION_CODE >= LTTNG_KERNEL_VERSION(7,4,0))
++static const struct pipe_buf_operations ring_buffer_pipe_buf_ops = {
++	.release = lib_ring_buffer_pipe_buf_release,
++	.get = generic_pipe_buf_get
++};
++#elif (LTTNG_LINUX_VERSION_CODE >= LTTNG_KERNEL_VERSION(5,8,0))
+ static const struct pipe_buf_operations ring_buffer_pipe_buf_ops = {
+ 	.release = lib_ring_buffer_pipe_buf_release,
+ 	.try_steal = generic_pipe_buf_try_steal,
+-- 
+2.55.0
+
diff --git a/meta/recipes-kernel/lttng/lttng-modules_2.16.0.bb b/meta/recipes-kernel/lttng/lttng-modules_2.16.0.bb
index bc1d50a8b3..1d4dba73f7 100644
--- a/meta/recipes-kernel/lttng/lttng-modules_2.16.0.bb
+++ b/meta/recipes-kernel/lttng/lttng-modules_2.16.0.bb
@@ -16,6 +16,7 @@ inherit upstream-stable-release-point
 include lttng-platforms.inc
 
 SRC_URI = "https://lttng.org/files/${BPN}/${BPN}-${PV}.tar.bz2 \
+           file://0001-fix-splice-remove-pipe-buffer-stealing-v7.4.patch \
            "
 
 # Use :append here so that the patch is applied also when using devupstream

---
base-commit: 34991d0ce3cc5f38dd29e824af7579512d2b917e
change-id: 20261117-lttng-modules_fix_new-14bba1ced326

Best regards,
--  
Mikko Rapeli <mikko.rapeli@linaro.org>

