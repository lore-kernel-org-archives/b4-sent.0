From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 22 Jul 2026 07:54:46 +0200
Subject: [PATCH v3 3/3] PCI: epf-mhi: Implement mhi_cntrl->flush_async() to
 flush DMA read/write
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260722-mhi-ep-flush-v3-3-d855e715264e@oss.qualcomm.com>
References: <20260722-mhi-ep-flush-v3-0-d855e715264e@oss.qualcomm.com>
In-Reply-To: <20260722-mhi-ep-flush-v3-0-d855e715264e@oss.qualcomm.com>
To: Manivannan Sadhasivam <mani@kernel.org>, Frank Li <Frank.Li@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-kernel@vger.kernel.org, mhi@lists.linux.dev, 
 linux-arm-msm@vger.kernel.org, linux-pci@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1534;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=qLqfbvmjnz3X26mpqAuThVFaSvP9MX15HVPTE+SgzCA=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqYFsuC5PTByf4wCyyQefH6+dH7fRf88dhESowk
 g8bnZx4gV2JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCamBbLgAKCRBVnxHm/pHO
 9fPIB/4tKg/A7Sh52QXah2k7JDw+eLTsYikqwlLXwhDPptp7RQX/qFLQ0DgVysZpfZcZckmyA5S
 6nk5qorgHBaBKqaxK11czAOEyCLCce/g3WU8L509g6PdgKAol0YiwIMHH9zzJ7b2f7RhDD8w/UE
 M3RxgU+XEGTL1eQ5t6BCrVQwHYFcHI3OBxVtWVCgmr/OveC5cBafP/aMBEJm/fWBLgE0X/8RX8m
 1HyCQqzKl5hMoqMOendaQvux0lpehBvwm3EJDuXfSKtuUqQ7wmTnKyqxKXYaReRxSChlkFfV3xu
 lcOSlcIn4g9ayftzxSN8PAH5hgasKJR+jImIlazUaMicwUJk
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Manivannan Sadhasivam <mani@kernel.org>

The MHI core needs to make sure that all the current DMA transactions are
completed before removing the channels. So implement the
mhi_cntrl->flush_async() callback by first making sure all the in-flight
DMA operations are completed and then flushing the DMA workqueue.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/endpoint/functions/pci-epf-mhi.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/drivers/pci/endpoint/functions/pci-epf-mhi.c b/drivers/pci/endpoint/functions/pci-epf-mhi.c
index 7f5326925ed5..8d2d9d01cfd2 100644
--- a/drivers/pci/endpoint/functions/pci-epf-mhi.c
+++ b/drivers/pci/endpoint/functions/pci-epf-mhi.c
@@ -644,6 +644,15 @@ static int pci_epf_mhi_edma_write_async(struct mhi_ep_cntrl *mhi_cntrl,
 	return ret;
 }
 
+static void pci_epf_mhi_edma_flush_async(struct mhi_ep_cntrl *mhi_cntrl)
+{
+	struct pci_epf_mhi *epf_mhi = to_epf_mhi(mhi_cntrl);
+
+	dmaengine_synchronize(epf_mhi->dma_chan_rx);
+	dmaengine_synchronize(epf_mhi->dma_chan_tx);
+	flush_workqueue(epf_mhi->dma_wq);
+}
+
 struct epf_dma_filter {
 	struct device *dev;
 	u32 dma_mask;
@@ -812,6 +821,7 @@ static int pci_epf_mhi_link_up(struct pci_epf *epf)
 		mhi_cntrl->write_sync = pci_epf_mhi_edma_write;
 		mhi_cntrl->read_async = pci_epf_mhi_edma_read_async;
 		mhi_cntrl->write_async = pci_epf_mhi_edma_write_async;
+		mhi_cntrl->flush_async = pci_epf_mhi_edma_flush_async;
 	}
 
 	/* Register the MHI EP controller */

-- 
2.43.0

