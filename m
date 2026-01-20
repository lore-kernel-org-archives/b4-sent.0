From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 20 Jan 2026 23:17:41 +0530
Subject: [PATCH v4 2/5] PCI: dwc: Return -EIO from dw_pcie_wait_for_link()
 if device is not active
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260120-pci-dwc-suspend-rework-v4-2-2f32d5082549@oss.qualcomm.com>
References: <20260120-pci-dwc-suspend-rework-v4-0-2f32d5082549@oss.qualcomm.com>
In-Reply-To: <20260120-pci-dwc-suspend-rework-v4-0-2f32d5082549@oss.qualcomm.com>
To: Jingoo Han <jingoohan1@gmail.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 vincent.guittot@linaro.org, zhangsenchuan@eswincomputing.com, 
 Shawn Lin <shawn.lin@rock-chips.com>, Niklas Cassel <cassel@kernel.org>, 
 Richard Zhu <hongxing.zhu@nxp.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2234;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=lJs2RDxnLG6iq+YlIuSttT/5SGXBjIWrnLIyz20iOiw=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpb7/A0Z/hHcog/Tj52mcEMvbyI30KwG25mDnHY
 EgKLBn4PYeJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaW+/wAAKCRBVnxHm/pHO
 9cDxB/92DSlhtWBAH6buRsxQAx6Dykvjva6+MO7NInFxA63xXOUb3f6ouifoWUrh4vEYQd1Z2WQ
 ynshL9xbNpxxTeqJD3GAUGljVOreDusYW6UKaRE8TsOu+AgpbMvG922Wxi86//lTz+59vuM2svk
 9xMQpmr8C6xAhqLatkD2BieP4xs3RizxVZX5YH9J7ZcZ6tjSMbiemYjorfyoP1vC8AMjntoztP4
 62c9K8m3XS4tl9A8NucNx1P6UQFZSQ2HvP6i7KWScwlPMqsulVN1u9Rwpx/skSR18hvPaagn19+
 WqfYVOPGi3gFn3n1SCneC6+GZK87qcwKBFHnpAqqgdNjakGe
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There are cases where the PCIe device would be physically connected to the
bus, but the device firmware might not be active. So the LTSSM will
get stuck in POLL.{Active/Compliance} states.

This behavior is common with endpoint devices controlled by the PCI
Endpoint framework, where the device will wait for the user to start its
operation through configfs.

For those cases, print the relevant log and return -EIO to indicate that
the device is present, but not active. This will allow the callers to skip
the failure as the device might become active in the future.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-designware.c | 15 +++++++++++++--
 1 file changed, 13 insertions(+), 2 deletions(-)

diff --git a/drivers/pci/controller/dwc/pcie-designware.c b/drivers/pci/controller/dwc/pcie-designware.c
index 55c1c60f7f8f..aca5bbeade03 100644
--- a/drivers/pci/controller/dwc/pcie-designware.c
+++ b/drivers/pci/controller/dwc/pcie-designware.c
@@ -696,8 +696,9 @@ void dw_pcie_disable_atu(struct dw_pcie *pci, u32 dir, int index)
  * dw_pcie_wait_for_link - Wait for the PCIe link to be up
  * @pci: DWC instance
  *
- * Returns: 0 if link is up, -ENODEV if device is not found, -ETIMEDOUT if the
- * link fails to come up for other reasons.
+ * Returns: 0 if link is up, -ENODEV if device is not found, -EIO if the device
+ * is found but not active and -ETIMEDOUT if the link fails to come up for other
+ * reasons.
  */
 int dw_pcie_wait_for_link(struct dw_pcie *pci)
 {
@@ -722,6 +723,16 @@ int dw_pcie_wait_for_link(struct dw_pcie *pci)
 		    ltssm == DW_PCIE_LTSSM_DETECT_ACT) {
 			dev_info(pci->dev, "Device not found\n");
 			return -ENODEV;
+
+		/*
+		 * If the link is in POLL.{Active/Compliance} state, then the
+		 * device is found to be connected to the bus, but it is not
+		 * active i.e., the device firmware might not yet initialized.
+		 */
+		} else if (ltssm == DW_PCIE_LTSSM_POLL_ACTIVE ||
+			   ltssm == DW_PCIE_LTSSM_POLL_COMPLIANCE) {
+			dev_info(pci->dev, "Device found, but not active\n");
+			return -EIO;
 		}
 
 		dev_info(pci->dev, "Phy link never came up\n");

-- 
2.51.0

