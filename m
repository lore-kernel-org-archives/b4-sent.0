From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Thu, 18 Dec 2025 17:34:52 +0530
Subject: [PATCH v2 1/2] PCI: dwc: Skip PME_Turn_Off broadcast and L2/L3
 transition during suspend if link is not up
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251218-pci-dwc-suspend-rework-v2-1-5a7778c6094a@oss.qualcomm.com>
References: <20251218-pci-dwc-suspend-rework-v2-0-5a7778c6094a@oss.qualcomm.com>
In-Reply-To: <20251218-pci-dwc-suspend-rework-v2-0-5a7778c6094a@oss.qualcomm.com>
To: Jingoo Han <jingoohan1@gmail.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 vincent.guittot@linaro.org, zhangsenchuan@eswincomputing.com, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Frank Li <Frank.Li@nxp.com>, Shawn Lin <shawn.lin@rock-chips.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1250;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=zzm1js4g/wb9/28LZoMBiDrVq1+JGQ8PgCaGDVkxvSs=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpQ+3laZ2TdGjXY+TPWcrdGBRDdPW7B7FcXIp27
 DNrZqWM4bmJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaUPt5QAKCRBVnxHm/pHO
 9XTZB/4yPHL8Wjn52iy6qP+I1K8EXtv1sxI3nuQ+NSmi0q+YIqM8E04b/xCOgf6pvOLmcp+W3yV
 E7oNEl4+Eh0jGpJBUd2tueucmVGYODQDMBnNYAOAzHI7a/Q9y9QJ0Ax6czPZ4zP52tDpfpnlFp8
 h+8tuIf/L5DprSvFHPbYjxpmP/Tgrqbl8OZbo+hCVqLkWLmXZuRMXzbI0z26ywwWDdmkPANCt66
 qd9l6IWynASqsOntET8UJHhbMl5Rt6A0Qz2gf3lXW8WrUJf2zN7Giui7N5Llv7EGD0gV9M8Smcv
 PA7xqPWJ2SeJ6gL5j7O4N+fg2325R2HGbshrc3y2SIsEv70/
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

During system suspend, if the PCIe link is not up, then there is no need
to broadcast PME_Turn_Off message and wait for L2/L3 transition. So skip
them.

Tested-by: Vincent Guittot <vincent.guittot@linaro.org>
Reviewed-by: Frank Li <Frank.Li@nxp.com>
Reviewed-by: Shawn Lin <shawn.lin@rock-chips.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-designware-host.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/pci/controller/dwc/pcie-designware-host.c b/drivers/pci/controller/dwc/pcie-designware-host.c
index 372207c33a85..43d091128ef7 100644
--- a/drivers/pci/controller/dwc/pcie-designware-host.c
+++ b/drivers/pci/controller/dwc/pcie-designware-host.c
@@ -1161,6 +1161,9 @@ int dw_pcie_suspend_noirq(struct dw_pcie *pci)
 	u32 val;
 	int ret;
 
+	if (!dw_pcie_link_up(pci))
+		goto stop_link;
+
 	/*
 	 * If L1SS is supported, then do not put the link into L2 as some
 	 * devices such as NVMe expect low resume latency.
@@ -1194,6 +1197,7 @@ int dw_pcie_suspend_noirq(struct dw_pcie *pci)
 	 */
 	udelay(1);
 
+stop_link:
 	dw_pcie_stop_link(pci);
 	if (pci->pp.ops->deinit)
 		pci->pp.ops->deinit(&pci->pp);

-- 
2.48.1

