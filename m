From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 20 Jan 2026 23:17:44 +0530
Subject: [PATCH v4 5/5] PCI: dwc: Fail dw_pcie_host_init() if
 dw_pcie_wait_for_link() returns -ETIMEDOUT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260120-pci-dwc-suspend-rework-v4-5-2f32d5082549@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1459;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=qQ9TgqyVy5+ZTMoD8oCUDVOXgBhw/z7F/8O2CrsfxGk=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpb7/ApmJnuN5uPTosvZeuM/G6OR1nnq7vDyZvz
 i8+w4UuP3KJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaW+/wAAKCRBVnxHm/pHO
 9do2B/4iXc3dd2qBrw5IsFyIssJUCFEvU7mpL7O8sXt23kvxu57GexIV5okRsT3/prQX11SZVQq
 jkkNZkfQ3aJStFEcIrBEWeI39UjAnDhAhYf3Zx/uKXq7eGvTzLBkN1OLEKHD8y2i6k3Exiz0vA6
 ByA+pK+IuGVrV6eCAKfrpyjm/hL/HklwePmncueNp1SuKHH1X6PU0sr04ZwfjriGk4nhT2eQPa9
 TPuPmKWjN4pgjsL8wZyePT+qcB18cNJx/K98qJq97H66NjY7QPYYizLY3ElS5pB0tqnIdagD15Q
 laDIpfBoa3v9NVGsd/2gHGl0hjDXjlqHHZr/gqjM5iZeGcW7
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The dw_pcie_wait_for_link() API now distinguishes link failures more
precisely:

-ENODEV: Device not found on the bus.
-EIO: Device found but inactive.
-ETIMEDOUT: Link failed to come up.

Out of these three errors, only -ETIMEDOUT represents a definitive link
failure since it signals that something is wrong with the link. For the
other two errors, there is a possibility that the link might come up later.
So fail dw_pcie_host_init() if -ETIMEDOUT is returned and skip the failure
otherwise.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-designware-host.c | 9 +++++++--
 1 file changed, 7 insertions(+), 2 deletions(-)

diff --git a/drivers/pci/controller/dwc/pcie-designware-host.c b/drivers/pci/controller/dwc/pcie-designware-host.c
index fad0cbedefbc..a72406ef7e26 100644
--- a/drivers/pci/controller/dwc/pcie-designware-host.c
+++ b/drivers/pci/controller/dwc/pcie-designware-host.c
@@ -675,8 +675,13 @@ int dw_pcie_host_init(struct dw_pcie_rp *pp)
 			goto err_remove_edma;
 	}
 
-	/* Ignore errors, the link may come up later */
-	dw_pcie_wait_for_link(pci);
+	/*
+	 * Only fail on timeout error. Other errors indicate the device may
+	 * become available later, so continue without failing.
+	 */
+	ret = dw_pcie_wait_for_link(pci);
+	if (ret == -ETIMEDOUT)
+		goto err_stop_link;
 
 	ret = pci_host_probe(bridge);
 	if (ret)

-- 
2.51.0

