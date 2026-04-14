From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 14 Apr 2026 21:29:41 +0530
Subject: [PATCH 3/4] PCI: qcom: Indicate broken L1ss exit during resume
 from system suspend
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260414-l1ss-fix-v1-3-adbb4555b5ab@oss.qualcomm.com>
References: <20260414-l1ss-fix-v1-0-adbb4555b5ab@oss.qualcomm.com>
In-Reply-To: <20260414-l1ss-fix-v1-0-adbb4555b5ab@oss.qualcomm.com>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Keith Busch <kbusch@kernel.org>, 
 Jens Axboe <axboe@kernel.dk>, Christoph Hellwig <hch@lst.de>, 
 Sagi Grimberg <sagi@grimberg.me>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-nvme@lists.infradead.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2251;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=4DYEP1zauw4orkCeJPQ0uZzhSR/jxYVrTX9FZ5rhz18=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBp3mSJljvX2vawbgDmc0ySB7J1BxqOQETumjAom
 wNG3QoD26iJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCad5kiQAKCRBVnxHm/pHO
 9bvaB/4oVZcPWtoaiBUEUXLan1VGwV1vrK0hc99d4fh1ddJGcWisR+kxmzUyky+BJJpPBnoT3ef
 5PeuljVd9HnNz+Nv+Ik5keS/N+FGKfZr9n7Cu4CLc472+00oPb8wnWxXWpa6/xhNe5G7iqCHSEn
 6wYL5AtnXz4CL2zs+oZwk7xAf+DY3EkbrJlhxy6B2W9hBF+0ZK0Zw7zamLuLmgyRvKs07zOtkUf
 Y2arFkHTFH9deHbELWtMtHckak0wBO+opSqpprijj/g6iEVEpi/mFDIrxjZdwGuIce96deoHSYQ
 8K/B2aQnL9YPi9b0KFoTmoCVyuNfaTCdhVKGKaQkMeuEmUeb
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Qcom PCIe RCs can successfully exit from L1ss during OS runtime. However,
during system suspend, the Qcom PCIe RC driver may remove all resource
votes and turns off the PHY to maximize power savings.

Consequently, when the host is in system suspend with the link in L1ss and
the endpoint asserts CLKREQ#, the OS must first wake up and the RC driver
must restore the PHY and enable the refclk. This recovery process causes
the strict L1ss exit latency time to be exceeded. (If the RC driver were to
retain all votes during suspend, L1ss exit would succeed without issue, but
at the expense of higher power consumption).

This latency violation leads to an L1ss exit timeout, followed by a Link
Down (LDn) condition during resume. This LDn can crash the OS if the
endpoint hosts the RootFS, and for other types of devices, it may result in
a full device reset/recovery.

So to ensure that the client drivers can properly handle this scenario, let
them know about this platform limitation by setting the
'pci_host_bridge::broken_l1ss_resume' flag.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-qcom.c | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/drivers/pci/controller/dwc/pcie-qcom.c b/drivers/pci/controller/dwc/pcie-qcom.c
index 67a16af69ddc..01afffd384f2 100644
--- a/drivers/pci/controller/dwc/pcie-qcom.c
+++ b/drivers/pci/controller/dwc/pcie-qcom.c
@@ -1363,6 +1363,17 @@ static void qcom_pcie_host_post_init(struct dw_pcie_rp *pp)
 	struct dw_pcie *pci = to_dw_pcie_from_pp(pp);
 	struct qcom_pcie *pcie = to_qcom_pcie(pci);
 
+	/*
+	 * During system suspend, the Qcom RC driver may turn off the PHY and
+	 * remove votes to save power. If the endpoint asserts CLKREQ# to
+	 * exit L1ss, the time required to wake the system and restore the
+	 * PHY/refclk exceeds the strict L1ss exit timing, resulting in Link
+	 * Down (LDn). Set this flag to indicate this limitation to client
+	 * drivers so that they will avoid relying on L1ss during system
+	 * suspend.
+	 */
+	pp->bridge->broken_l1ss_resume = true;
+
 	if (pcie->cfg->ops->host_post_init)
 		pcie->cfg->ops->host_post_init(pcie);
 }

-- 
2.51.0

