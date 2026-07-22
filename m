From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 22 Jul 2026 07:54:44 +0200
Subject: [PATCH v3 1/3] bus: mhi: ep: Add mhi_cntrl->flush_async() callback
 to flush the async read/write
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260722-mhi-ep-flush-v3-1-d855e715264e@oss.qualcomm.com>
References: <20260722-mhi-ep-flush-v3-0-d855e715264e@oss.qualcomm.com>
In-Reply-To: <20260722-mhi-ep-flush-v3-0-d855e715264e@oss.qualcomm.com>
To: Manivannan Sadhasivam <mani@kernel.org>, Frank Li <Frank.Li@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-kernel@vger.kernel.org, mhi@lists.linux.dev, 
 linux-arm-msm@vger.kernel.org, linux-pci@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 stable+noautosel@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4161;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=IkrbWGlEQbOAWg2OT7ZSXhgox1wLJ33VB3lenmrtVfU=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqYFstS4YEGfK7bEHRXulskXth3Z0HuQ9M++/yg
 k7gJDJJu/mJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCamBbLQAKCRBVnxHm/pHO
 9awgB/9qYahMC116DbL/9d4r9BuLADg1kry3tQmQ2yh5aCX4fcJ8TScMN7HJtNeUH+eCmKgws6D
 Oef3i+V2BSP3ZKEjcFkHLm1h2E3EHhxZtSzT2JSyI9hRUJgn4pmMnneoiGsJPUakDoB2pyCmwn8
 mAzPVfk8qj8CghMJ+0n8CUQxJYhULuJPqwd6LoL1SS6qQ0y1BYbFG2EszaVj5ZKikzvvmkHsFdw
 S+AsXQxrul5BFUrqTr7BOW65acuAniJPv7/ZfuE7czX0Aob4PgGMsub4auNg3edLeq72ijcDrsW
 uhgJM4wd/QMi3BAxgGRi2UZKaZ1/rDJK7E8e0IJYH812gfRp
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MHI EP stack makes use of the MHI controller drivers like MHI EPF to do
read/write to the host memory. And that driver is free to use mechanisms
like DMA to offload the read/write operations.

So if DMA is used for offload, then there is no guarantee that those DMA
operations would be completed by the time mhi_ep_remove() gets called. This
can lead to UAF (Use-After-Free) issues as the DMA callback can trigger
xfer_cb() even after mhi_ep_remove() has returned.

So to fix this issue, introduce the mhi_cntrl->flush_async() callback and
call it in mhi_ep_remove() to drain all the in-flight async transfers
before disconnecting the channels.

The completion handlers keep triggering xfer_cb() as long as it is set. So
flushing the transfers after notifying the client about the disconnect
(-ENOTCONN) would still let a success callback slip through afterwards and
lead to the same UAF. So disable the channels first to prevent new
transfers, then flush the in-flight transfers so that their completions are
delivered while xfer_cb() is still valid and only then notify the
disconnect and clear xfer_cb().

Cc: <stable+noautosel@kernel.org> # Needs dmaengine driver fix as well
Fixes: 2547beb00ddb ("bus: mhi: ep: Add support for async DMA read operation")
Fixes: ee08acb58fe4 ("bus: mhi: ep: Add support for async DMA write operation")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/bus/mhi/ep/main.c | 18 +++++++++++++++++-
 include/linux/mhi_ep.h    |  2 ++
 2 files changed, 19 insertions(+), 1 deletion(-)

diff --git a/drivers/bus/mhi/ep/main.c b/drivers/bus/mhi/ep/main.c
index 0277e1ab1198..b94c571f01d8 100644
--- a/drivers/bus/mhi/ep/main.c
+++ b/drivers/bus/mhi/ep/main.c
@@ -1612,6 +1612,7 @@ static void mhi_ep_remove(struct device *dev)
 {
 	struct mhi_ep_device *mhi_dev = to_mhi_ep_device(dev);
 	struct mhi_ep_driver *mhi_drv = to_mhi_ep_driver(dev->driver);
+	struct mhi_ep_cntrl *mhi_cntrl = mhi_dev->mhi_cntrl;
 	struct mhi_result result = {};
 	struct mhi_ep_chan *mhi_chan;
 	int dir;
@@ -1620,6 +1621,22 @@ static void mhi_ep_remove(struct device *dev)
 	if (mhi_dev->dev_type == MHI_DEVICE_CONTROLLER)
 		return;
 
+	/* Disable the channels to prevent new transfers */
+	for (dir = 0; dir < 2; dir++) {
+		mhi_chan = dir ? mhi_dev->ul_chan : mhi_dev->dl_chan;
+
+		if (!mhi_chan)
+			continue;
+
+		mutex_lock(&mhi_chan->lock);
+		mhi_chan->state = MHI_CH_STATE_DISABLED;
+		mutex_unlock(&mhi_chan->lock);
+	}
+
+	/* Flush in-flight transfers before notifying disconnect */
+	if (mhi_cntrl->flush_async)
+		mhi_cntrl->flush_async(mhi_cntrl);
+
 	/* Disconnect the channels associated with the driver */
 	for (dir = 0; dir < 2; dir++) {
 		mhi_chan = dir ? mhi_dev->ul_chan : mhi_dev->dl_chan;
@@ -1635,7 +1652,6 @@ static void mhi_ep_remove(struct device *dev)
 			mhi_chan->xfer_cb(mhi_chan->mhi_dev, &result);
 		}
 
-		mhi_chan->state = MHI_CH_STATE_DISABLED;
 		mhi_chan->xfer_cb = NULL;
 		mutex_unlock(&mhi_chan->lock);
 	}
diff --git a/include/linux/mhi_ep.h b/include/linux/mhi_ep.h
index 7b40fc8cbe77..f6383a57a872 100644
--- a/include/linux/mhi_ep.h
+++ b/include/linux/mhi_ep.h
@@ -107,6 +107,7 @@ struct mhi_ep_buf_info {
  * @write_sync: CB function for writing to host memory synchronously
  * @read_async: CB function for reading from host memory asynchronously
  * @write_async: CB function for writing to host memory asynchronously
+ * @flush_async: CB function for flushing asynchronous read/writes
  * @mhi_state: MHI Endpoint state
  * @max_chan: Maximum channels supported by the endpoint controller
  * @mru: MRU (Maximum Receive Unit) value of the endpoint controller
@@ -164,6 +165,7 @@ struct mhi_ep_cntrl {
 	int (*write_sync)(struct mhi_ep_cntrl *mhi_cntrl, struct mhi_ep_buf_info *buf_info);
 	int (*read_async)(struct mhi_ep_cntrl *mhi_cntrl, struct mhi_ep_buf_info *buf_info);
 	int (*write_async)(struct mhi_ep_cntrl *mhi_cntrl, struct mhi_ep_buf_info *buf_info);
+	void (*flush_async)(struct mhi_ep_cntrl *mhi_cntrl);
 
 	enum mhi_state mhi_state;
 

-- 
2.43.0

