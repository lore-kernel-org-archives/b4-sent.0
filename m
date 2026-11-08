From: DelaySystem <DelaySystem@tubot.lat>
Date: Sat, 07 Nov 2026 21:21:46 -0800
Subject: [PATCH RFC 1/2] gpu: host1x: add uninterruptible syncpoint wait
 variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-batch1-b1-host1x-wait-v1-1-8c8198adf600@tubot.lat>
References: <20261107-batch1-b1-host1x-wait-v1-0-8c8198adf600@tubot.lat>
In-Reply-To: <20261107-batch1-b1-host1x-wait-v1-0-8c8198adf600@tubot.lat>
To: mperttunen@nvidia.com, thierry.reding@kernel.org
Cc: DelaySystem <DelaySystem@tubot.lat>, dri-devel@lists.freedesktop.org, 
 luca.ceresoli@bootlin.com, gregkh@linuxfoundation.org, mchehab@kernel.org, 
 linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 clamor95@gmail.com, jonathanh@nvidia.com, linux-tegra@vger.kernel.org, 
 skomatineni@nvidia.com, linux-media@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=4248; i=DelaySystem@tubot.lat;
 h=from:subject:message-id; bh=0A6QGb/AL7pj5kvHCFetL7bFYrncJD8MkYGrpSZhLV0=;
 b=owGbwMvMwCH2SNl4+SzWXm/G02pJDFkf2F4ZHJkuuW+B8QuxGyZJ9+Y4a591z9NRsrfIv9TD6
 bz5Y8imjlIWBjEOBlkxRRYxGZ739fd14qyt5pyAmcPKBDKEgYtTACYSXsXwP+D8P60Awb97bkVK
 SHBOmi/WXS3W89113sKp/ZO5Sn8Yv2P4Z2NtVFQTOEnSfq/lN72OuPWTcmc7JHnd7eVdW1raXBr
 ICwA=
X-Developer-Key: i=DelaySystem@tubot.lat; a=openpgp;
 fpr=161C0CEF7FDF2C5E3B3A9CC8E22333A79A058D4B
X-Endpoint-Received: by B4 Relay for DelaySystem@tubot.lat/default with auth_id=1447
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

host1x_syncpt_wait() is unconditionally interruptible: any signal
aborts the wait with -ERESTARTSYS.  Kernel threads that wait on
syncpoints, such as the Tegra video capture threads, then need
retry loops to survive spurious wakeups.

Refactor the implementation into __host1x_syncpt_wait() with an
interruptible flag, keep host1x_syncpt_wait() behavior-identical for
its existing callers (including two DRM ioctls that must stay
interruptible), and add host1x_syncpt_wait_uninterruptible() for
in-kernel users that must not fail spuriously.  The wait stays
bounded by the caller's timeout in both cases.

Signed-off-by: DelaySystem <DelaySystem@tubot.lat>
---
 drivers/gpu/host1x/syncpt.c | 46 +++++++++++++++++++++++++++++++++++----------
 include/linux/host1x.h      |  2 ++
 2 files changed, 38 insertions(+), 10 deletions(-)

diff --git a/drivers/gpu/host1x/syncpt.c b/drivers/gpu/host1x/syncpt.c
index 5cc3cd46d321..393f50d3be33 100644
--- a/drivers/gpu/host1x/syncpt.c
+++ b/drivers/gpu/host1x/syncpt.c
@@ -215,15 +215,8 @@ int host1x_syncpt_incr(struct host1x_syncpt *sp)
 }
 EXPORT_SYMBOL(host1x_syncpt_incr);
 
-/**
- * host1x_syncpt_wait() - wait for a syncpoint to reach a given value
- * @sp: host1x syncpoint
- * @thresh: threshold
- * @timeout: maximum time to wait for the syncpoint to reach the given value
- * @value: return location for the syncpoint value
- */
-int host1x_syncpt_wait(struct host1x_syncpt *sp, u32 thresh, long timeout,
-		       u32 *value)
+static int __host1x_syncpt_wait(struct host1x_syncpt *sp, u32 thresh,
+				long timeout, u32 *value, bool intr)
 {
 	struct dma_fence *fence;
 	long wait_err;
@@ -246,7 +239,7 @@ int host1x_syncpt_wait(struct host1x_syncpt *sp, u32 thresh, long timeout,
 	if (IS_ERR(fence))
 		return PTR_ERR(fence);
 
-	wait_err = dma_fence_wait_timeout(fence, true, timeout);
+	wait_err = dma_fence_wait_timeout(fence, intr, timeout);
 	if (wait_err == 0)
 		host1x_fence_cancel(fence);
 	dma_fence_put(fence);
@@ -271,8 +264,41 @@ int host1x_syncpt_wait(struct host1x_syncpt *sp, u32 thresh, long timeout,
 		return 0;
 	}
 }
+
+/**
+ * host1x_syncpt_wait() - wait for a syncpoint to reach a given value
+ * @sp: host1x syncpoint
+ * @thresh: threshold
+ * @timeout: maximum time to wait for the syncpoint to reach the given value
+ * @value: return location for the syncpoint value
+ *
+ * The wait is interruptible: a signal aborts it with -ERESTARTSYS.
+ */
+int host1x_syncpt_wait(struct host1x_syncpt *sp, u32 thresh, long timeout,
+		       u32 *value)
+{
+	return __host1x_syncpt_wait(sp, thresh, timeout, value, true);
+}
 EXPORT_SYMBOL(host1x_syncpt_wait);
 
+/**
+ * host1x_syncpt_wait_uninterruptible() - wait for a syncpoint, uninterruptibly
+ * @sp: host1x syncpoint
+ * @thresh: threshold
+ * @timeout: maximum time to wait for the syncpoint to reach the given value
+ * @value: return location for the syncpoint value
+ *
+ * Like host1x_syncpt_wait(), but signals do not abort the wait. For use by
+ * kernel threads that must not fail spuriously with -ERESTARTSYS, such as
+ * the Tegra video capture threads. The wait is still bounded by @timeout.
+ */
+int host1x_syncpt_wait_uninterruptible(struct host1x_syncpt *sp, u32 thresh,
+				       long timeout, u32 *value)
+{
+	return __host1x_syncpt_wait(sp, thresh, timeout, value, false);
+}
+EXPORT_SYMBOL(host1x_syncpt_wait_uninterruptible);
+
 /*
  * Returns true if syncpoint is expired, false if we may need to wait
  */
diff --git a/include/linux/host1x.h b/include/linux/host1x.h
index e7ba601b2afb..40d4024ca04e 100644
--- a/include/linux/host1x.h
+++ b/include/linux/host1x.h
@@ -221,6 +221,8 @@ int host1x_syncpt_incr(struct host1x_syncpt *sp);
 u32 host1x_syncpt_incr_max(struct host1x_syncpt *sp, u32 incrs);
 int host1x_syncpt_wait(struct host1x_syncpt *sp, u32 thresh, long timeout,
 		       u32 *value);
+int host1x_syncpt_wait_uninterruptible(struct host1x_syncpt *sp, u32 thresh,
+				       long timeout, u32 *value);
 struct host1x_syncpt *host1x_syncpt_request(struct host1x_client *client,
 					    unsigned long flags);
 void host1x_syncpt_put(struct host1x_syncpt *sp);

-- 
2.34.1

