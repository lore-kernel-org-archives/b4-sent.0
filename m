From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 30 Dec 2025 20:37:35 +0530
Subject: [PATCH v3 4/4] PCI: dwc: Only skip the dw_pcie_wait_for_link()
 failure if it returns -ENODEV
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251230-pci-dwc-suspend-rework-v3-4-40cd485714f5@oss.qualcomm.com>
References: <20251230-pci-dwc-suspend-rework-v3-0-40cd485714f5@oss.qualcomm.com>
In-Reply-To: <20251230-pci-dwc-suspend-rework-v3-0-40cd485714f5@oss.qualcomm.com>
To: Jingoo Han <jingoohan1@gmail.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 vincent.guittot@linaro.org, zhangsenchuan@eswincomputing.com, 
 Shawn Lin <shawn.lin@rock-chips.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1204;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=CClkmOJOF6jdGk3GCx6uryCHLsqrAzBQPUqzwqi9zYU=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpU+q61ZwmA12k0gctA5+P95OGdr4n6fxaFZeCz
 A8XkQzl0ziJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaVPqugAKCRBVnxHm/pHO
 9dXJB/9Ss2PGxk0OVINcrmeDre6/hDbM6zBt2dMRWud6SNfN2XSafS6Ha1km6Rd9ed0iBQJMJxI
 S6Cu8DVrMTCfn1wlzrzXd2fl3jEh4yWoF1dB50k4rTGpebBFUVJ91MtQqheXdHXZ5rKWQk/pF51
 GjcJIGjgZuczOkTi7+kP4yQeTW0O9gmjkuNKt85WSPaa772s4mq+7ulhRKnpLDU8OLk4CvxBCHe
 r9VcAFOjS9G6RSIruuEq69jnY4ti/RDtfpAZKYHbtnd4vI7vxX+e6viFwB6btMY4N6TARjR2ts+
 xJZHMMQZMmIpn0DbYDqrFJ16P1xUQThz3AMo46xG0dQQ2YrP
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dw_pcie_wait_for_link() now returns -ENODEV if the device is not found on
the bus and -ETIMEDOUT if the link fails to come up for any other reasons.
And it is incorrect to skip the link up failures other than device not
found. So only skip the failure for device not found case and handle
failure for other reasons.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-designware-host.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/pci/controller/dwc/pcie-designware-host.c b/drivers/pci/controller/dwc/pcie-designware-host.c
index fad0cbedefbc..ccde12b85463 100644
--- a/drivers/pci/controller/dwc/pcie-designware-host.c
+++ b/drivers/pci/controller/dwc/pcie-designware-host.c
@@ -675,8 +675,10 @@ int dw_pcie_host_init(struct dw_pcie_rp *pp)
 			goto err_remove_edma;
 	}
 
-	/* Ignore errors, the link may come up later */
-	dw_pcie_wait_for_link(pci);
+	/* Skip failure if the device is not found as it may show up later */
+	ret = dw_pcie_wait_for_link(pci);
+	if (ret && ret != -ENODEV)
+		goto err_stop_link;
 
 	ret = pci_host_probe(bridge);
 	if (ret)

-- 
2.48.1

