From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 19 May 2026 13:41:22 +0530
Subject: [PATCH v2 3/4] PCI: qcom: Indicate broken L1ss exit during resume
 from system suspend
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260519-l1ss-fix-v2-3-b2c3a4bdeb15@oss.qualcomm.com>
References: <20260519-l1ss-fix-v2-0-b2c3a4bdeb15@oss.qualcomm.com>
In-Reply-To: <20260519-l1ss-fix-v2-0-b2c3a4bdeb15@oss.qualcomm.com>
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
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2479;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=y499Pb7zoLK+/udVcJtznAhDtKMFUzOh5Tw56dDMzxk=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqDBsvNeZWUkJrvgPF7k+PNMJzHdHt/RSCZqK8x
 Qf+xyUOgQiJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCagwbLwAKCRBVnxHm/pHO
 9Xk5B/92+ApuG55mF/aPaeTLK+7CrJ7fvmHEBpTfY9oqxuv8czAP/eFwmjC9+E8FjZLdbupYSa0
 nFtuwlnXzbXAbKJA1QgWgKz66AwR0S+dOfN/M9umM1UcGDGvdVWweXXK8vxnIKpauOK21+RpuXh
 2p6PvOju2h8egnqj2wuYPx7GGHIlsClgRGB8bmJ2iOQ2GjVLsksf3LF5ImAZR5Xwz0IAmY/SWfZ
 dMJxXraK5vN4CQYDhiftL85bv1iKT36K/qgibj26kX15a8pvdtz6bPV2EN/+ZeFi2iodHfpff4a
 uz468V+gXcSzofs30BVZyoU8r0lWrqLboPfi8nrHlbi7rBZK
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
the strict L1ss exit latency time to be exceeded (roughly L10_REFCLK_ON +
T_COMMONMODE). If the RC driver were to retain all votes during suspend,
L1ss exit would succeed without issue, but at the expense of higher power
consumption.

So when the host fails to move the link from L1ss to L0 within the
L10_REFCLK_ON + T_COMMONMODE time, the endpoint may treat it as a fatal
condition and trigger Link Down (LDn) during resume. This LDn can crash the
OS if the endpoint hosts the RootFS, and for other types of devices, it may
result in a full device reset/recovery.

So to ensure that the client drivers can properly handle this scenario, let
them know about this platform limitation by setting the
'pci_host_bridge::broken_l1ss_resume' flag.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-qcom.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/drivers/pci/controller/dwc/pcie-qcom.c b/drivers/pci/controller/dwc/pcie-qcom.c
index af6bf5cce65b..75bb6cb5e35e 100644
--- a/drivers/pci/controller/dwc/pcie-qcom.c
+++ b/drivers/pci/controller/dwc/pcie-qcom.c
@@ -1368,6 +1368,18 @@ static void qcom_pcie_host_post_init(struct dw_pcie_rp *pp)
 	struct dw_pcie *pci = to_dw_pcie_from_pp(pp);
 	struct qcom_pcie *pcie = to_qcom_pcie(pci);
 
+	/*
+	 * During system suspend, the Qcom RC driver may turn off the analog
+	 * circuitry of PHY and remove controller votes to save power. If the
+	 * link is in L1ss and the endpoint asserts CLKREQ# to exit L1ss, the
+	 * time required to wake the system and restore the PHY/refclk will
+	 * exceed the strict L1ss exit timing (L10_REFCLK_ON + T_COMMONMODE),
+	 * resulting in Link Down (LDn) condition. Set this flag to indicate
+	 * this limitation to client drivers so that they can avoid relying on
+	 * L1ss during system suspend.
+	 */
+	pp->bridge->broken_l1ss_resume = true;
+
 	if (pcie->cfg->ops->host_post_init)
 		pcie->cfg->ops->host_post_init(pcie);
 }

-- 
2.48.1

