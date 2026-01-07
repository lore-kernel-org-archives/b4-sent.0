From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 07 Jan 2026 13:41:54 +0530
Subject: [PATCH v4 1/6] PCI: dwc: Return -ENODEV from
 dw_pcie_wait_for_link() if device is not found
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260107-pci-dwc-suspend-rework-v4-1-9b5f3c72df0a@oss.qualcomm.com>
References: <20260107-pci-dwc-suspend-rework-v4-0-9b5f3c72df0a@oss.qualcomm.com>
In-Reply-To: <20260107-pci-dwc-suspend-rework-v4-0-9b5f3c72df0a@oss.qualcomm.com>
To: Jingoo Han <jingoohan1@gmail.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 vincent.guittot@linaro.org, zhangsenchuan@eswincomputing.com, 
 Shawn Lin <shawn.lin@rock-chips.com>, Richard Zhu <hongxing.zhu@nxp.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2146;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=o/5Daxo7XavRGG4F5ekAsfAm4FYtHGKP45ahA68HQwY=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpXhVNsiYqYPnHrsxF4Lzs40U2nUYrjnT+ssLTe
 YDmlgNzKRCJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaV4VTQAKCRBVnxHm/pHO
 9RJ2CACHGLq4GrQ/ZaYw12uJqQNtll4VHVYi8UWhFUujmPCX23Mu8VPyTa0omkvA8b0xy7Rgqw6
 8mOoUxHWK+san0A6DCXd7G6Zhue3rcesnQTy10cuVKtU+UrqoIjXNftr3tdQelaKMzWU1MiWuWd
 DNkpGWs5ABVOufoiZAlej46i99BhZn6tg1mEv7X0yQTfkheioiSOpR4dJ89d6rFlLALor/8s3ix
 g7tDx7dk/ySHbDgKQ0Z6mHTdzG5KdsWANLYvYylcUiCphlp5IiqMm7lFy0rOrWpZfKy0FwNasMe
 gUQhpRfxbWvups/aE7VNIOBfZmqFssR0xAe9c/O22YzHLktH
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The dw_pcie_wait_for_link() function waits up to 1 second for the PCIe link
to come up and returns -ETIMEDOUT for all failures without distinguishing
cases where no device is present on the bus. But the callers may want to
just skip the failure if the device is not found on the bus and handle
failure for other reasons.

So after timeout, if the LTSSM is in Detect.Quiet or Detect.Active state,
return -ENODEV to indicate the callers that the device is not found on the
bus and return -ETIMEDOUT otherwise.

Also add kernel doc to document the parameter and return values.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-designware.c | 20 +++++++++++++++++++-
 1 file changed, 19 insertions(+), 1 deletion(-)

diff --git a/drivers/pci/controller/dwc/pcie-designware.c b/drivers/pci/controller/dwc/pcie-designware.c
index 345365ea97c7..55c1c60f7f8f 100644
--- a/drivers/pci/controller/dwc/pcie-designware.c
+++ b/drivers/pci/controller/dwc/pcie-designware.c
@@ -692,9 +692,16 @@ void dw_pcie_disable_atu(struct dw_pcie *pci, u32 dir, int index)
 	dw_pcie_writel_atu(pci, dir, index, PCIE_ATU_REGION_CTRL2, 0);
 }
 
+/**
+ * dw_pcie_wait_for_link - Wait for the PCIe link to be up
+ * @pci: DWC instance
+ *
+ * Returns: 0 if link is up, -ENODEV if device is not found, -ETIMEDOUT if the
+ * link fails to come up for other reasons.
+ */
 int dw_pcie_wait_for_link(struct dw_pcie *pci)
 {
-	u32 offset, val;
+	u32 offset, val, ltssm;
 	int retries;
 
 	/* Check if the link is up or not */
@@ -706,6 +713,17 @@ int dw_pcie_wait_for_link(struct dw_pcie *pci)
 	}
 
 	if (retries >= PCIE_LINK_WAIT_MAX_RETRIES) {
+		/*
+		 * If the link is in Detect.Quiet or Detect.Active state, it
+		 * indicates that no device is detected.
+		 */
+		ltssm = dw_pcie_get_ltssm(pci);
+		if (ltssm == DW_PCIE_LTSSM_DETECT_QUIET ||
+		    ltssm == DW_PCIE_LTSSM_DETECT_ACT) {
+			dev_info(pci->dev, "Device not found\n");
+			return -ENODEV;
+		}
+
 		dev_info(pci->dev, "Phy link never came up\n");
 		return -ETIMEDOUT;
 	}

-- 
2.48.1

