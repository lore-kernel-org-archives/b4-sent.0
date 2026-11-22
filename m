From: David Heidelberg <david@ixit.cz>
Date: Sun, 22 Nov 2026 21:24:19 +0100
Subject: [PATCH v2 2/2] rpmsg: char: Support waking up on endpoint rx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-rpmsg-qcom-glink-v2-2-d60419793095@ixit.cz>
References: <20261122-rpmsg-qcom-glink-v2-0-d60419793095@ixit.cz>
In-Reply-To: <20261122-rpmsg-qcom-glink-v2-0-d60419793095@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>
Cc: Dylan Van Assche <git@dylanvanassche.be>, 
 Casey Connolly <casey.connolly@linaro.org>, linux-arm-msm@vger.kernel.org, 
 linux-remoteproc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1867; i=david@ixit.cz;
 h=from:subject:message-id; bh=eIZGJEV5bvpHjBlQtn566xL+dxDC7tO9ywu0q8X1cHQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrA09ysuizp1NKtYdtgBIsteeqYI5UrgT3HaQue
 IP+ojKIP5CJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawNPcgAKCRBgAj/E00kg
 crObD/9zET8uD6rfp8sfJFqtGbV3/CcevOxnetsfGUZo3RHF24I6lulXMol7gNp6GETdPj/7+uh
 RZ3yCeOIID5XCnyNRbc87mtmPiBf33AC4jQv339fKgq2j8BVeea6NlGvx7e5874tvkTfRUy/KXJ
 Lvv65lH3cFe8Ho7MOpPX2bokJKVaGq7N9DGkqGUMkQPx8E2zmZUxkkhA6L9hnf7dff8obGIX7SQ
 xHSRok0FD3Uf6sYu/vMAi47qdF8F+W+GFXj7vA1EUbJtSFTVvZr05O0/hhsLSYDHW2zwt7d4Mn3
 BVJfMuyGDHoyMXIrRdKg4zlJ68Ts8mi1yLcU5SQI9BNg6mR/TZ/y0FoLDE7wUcXHpfm4lwMd+nW
 Iw4OedRlqSdfhUpQvDNgtxYozC+unhBFF3GK096OsDygeaMvFKFTJmeo/DiGhQpTJIYjwQhqB90
 ahbXpEr5v2yLNRmAS9CsFZjdqLL7lGH+QD7cJ2cBP+zmuUUAb0yhVIEF5vzkhN50JU4QJCsIjWe
 OF+apRKxBDtWjkOM0vbio7g5DM1NDXW83j3Xbgai1LeXn/l/Axrc+AkXAKUpxCghjc0jR47IgiE
 abdJhMSUXej45fI+5AnbyiMS50tro9bfkdpRRhQOO9XmLH0iQOSTAtOu68++GPk/mLRWlS8GjgF
 VejIIXG768DhhFw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Configure rpmsg character endpoint devices (/dev/rpmsgX) as wakeup
capable and report a wakeup event when a message is received in
rpmsg_ept_cb().

This allows userspace to opt in to system wakeups per endpoint via
sysfs (/sys/class/rpmsg/rpmsgX/power/wakeup), covering dynamically
created endpoints opened through /dev/rpmsg_ctrlX across all rpmsg
transports without enabling wakeup by default.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/rpmsg/rpmsg_char.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/rpmsg/rpmsg_char.c b/drivers/rpmsg/rpmsg_char.c
index d8868faacdc3a..94307d1e0338b 100644
--- a/drivers/rpmsg/rpmsg_char.c
+++ b/drivers/rpmsg/rpmsg_char.c
@@ -119,16 +119,17 @@ static int rpmsg_ept_cb(struct rpmsg_device *rpdev, void *buf, int len,
 	skb_put_data(skb, buf, len);
 
 	spin_lock(&eptdev->queue_lock);
 	skb_queue_tail(&eptdev->queue, skb);
 	spin_unlock(&eptdev->queue_lock);
 
 	/* wake up any blocking processes, waiting for new data */
 	wake_up_interruptible(&eptdev->readq);
+	pm_wakeup_hard_event(&eptdev->dev);
 
 	return 0;
 }
 
 static int rpmsg_ept_flow_cb(struct rpmsg_device *rpdev, void *priv, bool enable)
 {
 	struct rpmsg_eptdev *eptdev = priv;
 
@@ -446,16 +447,17 @@ static struct rpmsg_eptdev *rpmsg_chrdev_eptdev_alloc(struct rpmsg_device *rpdev
 	skb_queue_head_init(&eptdev->queue);
 	init_waitqueue_head(&eptdev->readq);
 
 	device_initialize(dev);
 	dev->class = &rpmsg_class;
 	dev->parent = parent;
 	dev->groups = rpmsg_eptdev_groups;
 	dev_set_drvdata(dev, eptdev);
+	device_set_wakeup_capable(dev, true);
 
 	cdev_init(&eptdev->cdev, &rpmsg_eptdev_fops);
 	eptdev->cdev.owner = THIS_MODULE;
 
 	return eptdev;
 }
 
 static int rpmsg_chrdev_eptdev_add(struct rpmsg_eptdev *eptdev, struct rpmsg_channel_info chinfo)

-- 
2.55.0

