From: "Josh Lafleur (Zipline)" <josh.lafleur@outlook.com>
Date: Wed, 30 Sep 2026 13:29:45 -0700
Subject: [PATCH] hte: Dont queue work on line being released
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-hte-crash-v1-1-baf61530800a@outlook.com>
X-B4-Tracking: v=1; b=H4sIADhxvWoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDCwMj3YySVN3kosTiDF1Ls+TkxLTkZMsUIwsloPqCotS0zAqwWdGxtbU
 AG7bhwVsAAAA=
To: Dipen Patel <dipenp@nvidia.com>, Thierry Reding <treding@nvidia.com>
Cc: timestamp@lists.linux.dev, linux-kernel@vger.kernel.org, 
 "Jafet Garcia (RidgeRun)" <ridgerun-linux@flyzipline.com>, 
 "Josh Lafleur (Zipline)" <josh.lafleur@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790800206; l=2557;
 i=josh.lafleur@outlook.com; s=20260930; h=from:subject:message-id;
 bh=bRDDy0i27/YJcTeNUr0wPapEBzqq1hItrkyQnzulKxE=;
 b=1chzITqd6fPgQ6upaSLk8wzlb8T+eeamrb8joI1988vSkHY1pXIgsYNZmi0Dnt3JBkSK/qpCg
 e/BXH9mvvn9AehWIYjsiGj9R/jb6rFFQjCk6HkBVUOLHGZA79aPNIR0
X-Developer-Key: i=josh.lafleur@outlook.com; a=ed25519;
 pk=slf3cskRg11vRnFROP6D9bMBKyvvRNsP2Msvm4/qpmM=
X-Endpoint-Received: by B4 Relay for josh.lafleur@outlook.com/20260930 with auth_id=1090
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Correct the race condition by adding the HTE_TS_RELEASING flag which
will serialize the application consumer with the hardware producers
under the slock. If the consumer is releasing the line, the producer
shall not queue anymore work as they do not expect to see any more
edges.

Fixes: 31ab09b "drivers: Add hardware timestamp engine (HTE) subsystem"
Suggested-by: Jafet Garcia (RidgeRun) <ridgerun-linux@flyzipline.com>
Signed-off-by: Josh Lafleur (Zipline) <josh.lafleur@outlook.com>
---
A race condition exists where call back work can be cleared by a line
release inbetween the IRQ queueing work and the workqueue handler
completing execution which have identified to be the root cause of
crashed kernels.

A repro case was successfully completed wherein an application
continuously registering and releasing HTE lines can trigger a list_add
failure on the queue_work() and subsequent Oops in the kworker during
the hte_do_cb_work.

CPU0                        CPU1                         CPU2

hte_ts_put()
hte_push_ts_ns()
  flush_work()
                                                           queue_work()
  ei->cb = NULL             hte_do_cb_work()
  ei->tcb = NULL              racy ei->tcb(ei->cl_data)
  ei->cl_data = NULL
---
 drivers/hte/hte.c | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/drivers/hte/hte.c b/drivers/hte/hte.c
index a423503482132..ae4b2093d58b7 100644
--- a/drivers/hte/hte.c
+++ b/drivers/hte/hte.c
@@ -26,6 +26,7 @@ enum {
 	HTE_TS_REQ,
 	HTE_TS_DISABLE,
 	HTE_TS_QUEUE_WK,
+	HTE_TS_RELEASING,
 };
 
 /**
@@ -190,6 +191,10 @@ int hte_ts_put(struct hte_ts_desc *desc)
 		goto mod_put;
 	}
 
+	spin_lock_irqsave(&ei->slock, flag);
+	set_bit(HTE_TS_RELEASING, &ei->flags);
+	spin_unlock_irqrestore(&ei->slock, flag);
+
 	ret = gdev->chip->ops->release(gdev->chip, desc, ei->xlated_id);
 	if (ret) {
 		dev_err(gdev->sdev, "id: %d free failed\n",
@@ -817,7 +822,8 @@ int hte_push_ts_ns(const struct hte_chip *chip, u32 xlated_id,
 	data->seq = ei->seq++;
 
 	if (!test_bit(HTE_TS_REGISTERED, &ei->flags) ||
-	    test_bit(HTE_TS_DISABLE, &ei->flags)) {
+	    test_bit(HTE_TS_DISABLE, &ei->flags) ||
+	    test_bit(HTE_TS_RELEASING, &ei->flags)) {
 		dev_dbg(chip->dev, "Unknown timestamp push\n");
 		atomic_inc(&ei->dropped_ts);
 		st = -EINVAL;

---
base-commit: 8cd9520d35a6c38db6567e97dd93b1f11f185dc6
change-id: 20260802-hte-crash-96ccafcc9d28

Best regards,
-- 
Josh Lafleur (Zipline) <josh.lafleur@outlook.com>

