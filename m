From: Richard Leitner <richard.leitner@linux.dev>
Date: Tue, 10 Nov 2026 13:29:08 +0100
Subject: [PATCH] remoteproc: imx_rproc: revert channel freeing order in
 imx_rproc_free_mbox
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-imx-rproc-free-mbox-v1-1-3e33ff98570d@linux.dev>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrDuQBBHSq4iLGCc6BROZtBIQ7
 260y7f4/4BMwpTh3RwgtHPmFCv0qwG/uDgT8lQNRplOa2WR14KySfIYhAjXMRV0Thk7ta23RkM
 tN6HA5bn2w9/5N37If+8VnOcFBhEig3cAAAA=
X-Change-ID: 20261109-imx-rproc-free-mbox-aa029d44c921
To: Bjorn Andersson <andersson@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>, Frank Li <Frank.Li@nxp.com>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Peng Fan <peng.fan@nxp.com>
Cc: linux-remoteproc@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 weinshec@holodeck2.de, stable@vger.kernel.org, 
 Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794313767; l=4029;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=rNNJZEDgaW7DJ4fiz5yErnGrwanLKG16YmYo4n8oobc=;
 b=lM3N39GVUUMurY+eD75Pypflu4aRSAT1B8iVo7IH+Qj9zTH0nazkdyFmU6YAeo5NHOgpAQdH9
 4MuKUHhmeiRDWufv8cIUK2p2C+fuOS6+WsPXZ3VHLbozgvV5jEGyIFR
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The imx_rproc driver is affected by a race condition in the shutdown
ordering in imx_rproc_free_mbox(). A received message might cause a
virtqueue_kick resulting in tx_ch access. When imx_rproc_free_mbox() is
triggered between the if (!priv->tx_ch) check and the mbox_send_message()
call in the imx_rproc_kick() function the mbox_send_message() then tries
to dereference a NULL pointer on the tx_ch (as seen in the call trace
below).

Therefore fix this behaviour by first freeing the rx channel, so no new
messages are received and therefore no kicking on tx_ch can happen.
Afterwards release the tx channel.

This problem was encountered on a fleet of i.MX8MP devices on about 1 in
500 system shutdowns, resulting in Oops below. This Oops was recorded
from a v7.3.0 kernel before the work-queue removal.

    remoteproc remoteproc0: stopped remote processor imx8mp-cm7
    Unable to handle kernel NULL pointer dereference at virtual address 0000000000000008
    Internal error: Oops: 0000000096000004 [#1]  SMP
    CPU: 0 UID: 0 PID: 32710 Comm: kworker/0:1 Not tainted 7.3.0-XXX #1 PREEMPT
    Hardware name: XXX (DT)
    Workqueue: imx8mp-cm7 imx_rproc_vq_work [imx_rproc]
    pstate: 40000005 (nZcv daif -PAN -UAO -TCO -DIT -SSBS BTYPE=--)
    pc : mbox_send_message+0x8c/0x178
    lr : mbox_send_message+0x88/0x178
    sp : ffff8000897f3b70
    x29: ffff8000897f3b70 x28: ffff80007a07b248 x27: ffff0000d90e1a20
    x26: ffff80007a07b328 x25: ffff0000c1d31300 x24: ffff0000d90e1a40
    x23: 0000000000000001 x22: 0000000000000005 x21: ffff8000897f3ba4
    x20: 000000000000000b x19: ffff0000c1b24240 x18: 0000000000000000
    x17: ffff80006a453000 x16: ffff800081ac8000 x15: 0000000000000000
    x14: 0000000000000040 x13: 0000000000000228 x12: ffff0000c115a3e8
    x11: 0000000000000000 x10: 0000000000000001 x9 : ffff800080cd6570
    x8 : ffff8000897f3ba0 x7 : 0000000000000002 x6 : 0000000000000000
    x5 : 000000000000000c x4 : 0000000004400000 x3 : 0000000000000000
    x2 : 0000000000000000 x1 : ffff0000cb268000 x0 : 0000000000000000
    Call trace:
     mbox_send_message+0x8c/0x178 (P)
     imx_rproc_kick+0x50/0xc0 [imx_rproc]
     rproc_virtio_notify+0x3c/0xa0
     virtqueue_kick+0x4c/0x68
     rpmsg_recv_done+0x224/0x658 [virtio_rpmsg_bus]
     vring_interrupt+0xbc/0x158
     rproc_vq_interrupt+0x40/0xb0
     imx_rproc_notified_idr_cb+0x20/0x40 [imx_rproc]
     idr_for_each+0x74/0x100
     imx_rproc_vq_work+0x2c/0x40 [imx_rproc]
     process_one_work+0x194/0x520
     worker_thread+0x19c/0x320
     kthread+0x134/0x148
     ret_from_fork+0x10/0x20
    Code: 37f80574 aa1303e0 97ffff39 f9400a60 (39402001)

Fixes: 99b142cf7191 ("remoteproc: imx_rproc: Request mbox channel later")
Cc: stable@vger.kernel.org
Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
Backport notice: For kernel versions before the work queue removal
(<=7.3.y) a cancel_work_sync() should be called on the queue after
freeing the rx_ch.
---
 drivers/remoteproc/imx_rproc.c | 11 ++++++-----
 1 file changed, 6 insertions(+), 5 deletions(-)

diff --git a/drivers/remoteproc/imx_rproc.c b/drivers/remoteproc/imx_rproc.c
index 581bb07f5893f..232da31a56ebe 100644
--- a/drivers/remoteproc/imx_rproc.c
+++ b/drivers/remoteproc/imx_rproc.c
@@ -920,15 +920,16 @@ static void imx_rproc_free_mbox(void *data)
 	struct rproc *rproc = data;
 	struct imx_rproc *priv = rproc->priv;
 
-	if (priv->tx_ch) {
-		mbox_free_channel(priv->tx_ch);
-		priv->tx_ch = NULL;
-	}
-
+	/* First release rx channel as its callback may kick vqs via tx_ch. */
 	if (priv->rx_ch) {
 		mbox_free_channel(priv->rx_ch);
 		priv->rx_ch = NULL;
 	}
+
+	if (priv->tx_ch) {
+		mbox_free_channel(priv->tx_ch);
+		priv->tx_ch = NULL;
+	}
 }
 
 static void imx_rproc_put_scu(void *data)

---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261109-imx-rproc-free-mbox-aa029d44c921

Best regards,
--  
Richard Leitner <richard.leitner@linux.dev>

