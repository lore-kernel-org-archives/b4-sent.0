From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 29 Jun 2026 10:45:15 +0200
Subject: [PATCH 1/3] dmaengine: dw-edma: Implement device_synchronize()
 callback
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260629-mhi-ep-flush-v1-1-714e0d56e87c@oss.qualcomm.com>
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
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1945;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=hQSiKt+DNfGzyAL3snbZtztP7N+TSbM085MMV32AHtw=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqQjCfKFX7tpWNiAcsZIBLqWMIfqMi/XcLd8EZQ
 x8pk8EcVC+JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCakIwnwAKCRBVnxHm/pHO
 9R58B/9n4zDHmztGUSMgrebIhTpoSBiCabO1Vh+Fu+C0wHQds9aX4chegxjY1M0iNW3gqpg8Pyz
 oLo44Y8i+yOdjw0CZ95N/LlvQkaQJqarsMG1xHdDJI+7A4TBx/2FTlEaVZ5z6xl1s7jWx53vWdT
 fXxaWce4bBmqgCzYdqSOvw2F9rBe5DsMXQVo8HgR8i6klcHR3ClDiG0sRKJoqEX8dL9G1peSXGS
 shKqnhq4m5qJwPf3nWrlS4gUS8rzk8qFleWqvGXDNYfM9WapqfjfrgN90RC6PLHTCTrzE++5oeN
 DPLlD+9r26V1uPpsadhTlHux2kGl1MVdc43R30S9ZsYkdzCv
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

device_synchronize() callback is required by the client drivers to ensure
all the DMA operations are completed so that they can free the memory
associated with the complete callbacks.

So implement this callback by first making sure that all the in-flight DMA
operations are completed and then call vchan_synchronize() to drain the
DMA tasklet.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/dma/dw-edma/dw-edma-core.c | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/drivers/dma/dw-edma/dw-edma-core.c b/drivers/dma/dw-edma/dw-edma-core.c
index c2feb3adc79f..7b12dfe8cfd3 100644
--- a/drivers/dma/dw-edma/dw-edma-core.c
+++ b/drivers/dma/dw-edma/dw-edma-core.c
@@ -331,6 +331,21 @@ static int dw_edma_device_terminate_all(struct dma_chan *dchan)
 	return err;
 }
 
+static void dw_edma_device_synchronize(struct dma_chan *dchan)
+{
+	struct dw_edma_chan *chan = dchan2dw_edma_chan(dchan);
+	unsigned long timeout = jiffies + msecs_to_jiffies(5000);
+
+	/*
+	 * Make sure all the in-flight DMA operations are completed before
+	 * draining the tasklet using vchan_synchronize().
+	 */
+	while (chan->status == EDMA_ST_BUSY && time_before(jiffies, timeout))
+		cpu_relax();
+
+	vchan_synchronize(&chan->vc);
+}
+
 static void dw_edma_device_issue_pending(struct dma_chan *dchan)
 {
 	struct dw_edma_chan *chan = dchan2dw_edma_chan(dchan);
@@ -968,6 +983,7 @@ static int dw_edma_channel_setup(struct dw_edma *dw, u32 wr_alloc, u32 rd_alloc)
 	dma->device_pause = dw_edma_device_pause;
 	dma->device_resume = dw_edma_device_resume;
 	dma->device_terminate_all = dw_edma_device_terminate_all;
+	dma->device_synchronize = dw_edma_device_synchronize;
 	dma->device_issue_pending = dw_edma_device_issue_pending;
 	dma->device_tx_status = dw_edma_device_tx_status;
 	dma->device_prep_slave_sg = dw_edma_device_prep_slave_sg;

-- 
2.43.0

