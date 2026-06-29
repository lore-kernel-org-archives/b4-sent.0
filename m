From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 29 Jun 2026 10:45:16 +0200
Subject: [PATCH 2/3] bus: mhi: ep: Add mhi_cntrl->flush_async() callback to
 flush the async read/write
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260629-mhi-ep-flush-v1-2-714e0d56e87c@oss.qualcomm.com>
References: <20260629-mhi-ep-flush-v1-0-714e0d56e87c@oss.qualcomm.com>
In-Reply-To: <20260629-mhi-ep-flush-v1-0-714e0d56e87c@oss.qualcomm.com>
To: Manivannan Sadhasivam <mani@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Frank Li <Frank.Li@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>
Cc: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 mhi@lists.linux.dev, linux-arm-msm@vger.kernel.org, 
 linux-pci@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 stable+noautosel@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3321;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=DoH7hPNg0fHxC+lCNJKTY0zrXTBD6EGE6jTVdxWvpPg=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqQjCgCNY3QvJvJ3yi452OlMzvaFYQkyelWNvE2
 wmHLWypum2JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCakIwoAAKCRBVnxHm/pHO
 9ZcxB/sEO2M7/DGIBby1khnchghmcOOW+znPZqa3/ba+LaIW//D5fMczex/cU9+nrl1Pk0oOQ4f
 2/zx3Hlw/8FUXc/NE/tXEnS0+mdmyxgwo00QwPiB7ZfFoAVSx+e48LVXLTeuG5+6EjaF0zxAUVb
 urbcc6zLiIBM81spRUYFR/CqYsBxgT1bFhL+IAcIMf4f+RUMjLmUga7059uQsMP1e6hJgshj4ez
 4EXsZZ9B1A4W+iHJc9ZZqLsl7AkkKGFZWkLHHgwfcQ8mX0izqLfSMTBj6N7m6wEXPXWriNhkR2l
 gGNJ+bMxHHy8qWCjOuC7zf0ADAchZ1UyBOsRZNER4RmXIrzf
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
call it in mhi_ep_remove() before setting xfer_cb to NULL.

Note that flush_async() blocks until all the in-flight async transfers are
completed, so calling it with the chan->lock held would needlessly stall
the transfer paths on that channel for the whole duration of the drain. So
drop chan->lock around the flush and clear xfer_cb() only afterwards, once
all the pending completions are drained.

Cc: <stable+noautosel@kernel.org> # Needs dmaengine driver fix as well
Fixes: 2547beb00ddb ("bus: mhi: ep: Add support for async DMA read operation")
Fixes: ee08acb58fe4 ("bus: mhi: ep: Add support for async DMA write operation")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/bus/mhi/ep/main.c | 7 +++++++
 include/linux/mhi_ep.h    | 2 ++
 2 files changed, 9 insertions(+)

diff --git a/drivers/bus/mhi/ep/main.c b/drivers/bus/mhi/ep/main.c
index 0277e1ab1198..329a4855d397 100644
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
@@ -1636,6 +1637,12 @@ static void mhi_ep_remove(struct device *dev)
 		}
 
 		mhi_chan->state = MHI_CH_STATE_DISABLED;
+		mutex_unlock(&mhi_chan->lock);
+
+		if (mhi_cntrl->flush_async)
+			mhi_cntrl->flush_async(mhi_cntrl);
+
+		mutex_lock(&mhi_chan->lock);
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

