From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 03 Sep 2025 12:43:23 +0530
Subject: [PATCH v2 1/5] PCI: qcom: Wait for PCIE_RESET_CONFIG_WAIT_MS after
 PERST# deassert
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250903-pci-pwrctrl-perst-v2-1-2d461ed0e061@oss.qualcomm.com>
References: <20250903-pci-pwrctrl-perst-v2-0-2d461ed0e061@oss.qualcomm.com>
In-Reply-To: <20250903-pci-pwrctrl-perst-v2-0-2d461ed0e061@oss.qualcomm.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Saravana Kannan <saravanak@google.com>
Cc: linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 Brian Norris <briannorris@chromium.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 stable+noautosel@kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2070;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=9ldRJtoT9M8aIUvYrNpDc1xJbqnMXRAhHx884nJXoBk=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBot+qbui6myA5xhx7BATXkqArIl0o8QxQQnuK7Z
 cRMxOQwU8aJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaLfqmwAKCRBVnxHm/pHO
 9VegB/9Zeph4VheLjB+IkKOTL0NC98YO8yp/4Y7o5Br7lKcS1HBWFZym4tMuSvJ+3R5h1WjAqSx
 sUnTb43WgIAKjNjUcnp6KwHC05keIiJ47/d/aPLZAZi4QU8X6fKCvzmWYzWrO4eRBGYRUz7dynP
 Q3QzgU/dB9UiFCHmY3bEDAesLv5BcgHaU7fegwZepA2r1DVv7/mc2J61H4BVy/iv6qGMYuteHFN
 0z8ouEe4TqxQl+3EnK8aDerbeZ25hfem1mM177TgX1DPqVHru29t7i/uN9YLaqmhKaQWM7ggepi
 8SErUATmakiKAp26iHqDdepifCgMxOf0ns1bplB2vn3rrdHK
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

PCIe spec r6.0, sec 6.6.1 mandates waiting for 100ms before deasserting
PERST# if the downstream port does not support Link speeds greater than
5.0 GT/s. But in practice, this delay seem to be required irrespective of
the supported link speed as it gives the endpoints enough time to
initialize.

Hence, add the delay by reusing the PCIE_RESET_CONFIG_WAIT_MS definition if
the linkup_irq is not supported. If the linkup_irq is supported, the driver
already waits for 100ms in the IRQ handler post link up.

Also, remove the redundant comment for PCIE_T_PVPERL_MS. Finally, the
PERST_DELAY_US sleep can be moved to PERST# assert where it should be.

Cc: stable+noautosel@kernel.org # non-trivial dependency
Fixes: 82a823833f4e ("PCI: qcom: Add Qualcomm PCIe controller driver")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-qcom.c | 8 +++++---
 1 file changed, 5 insertions(+), 3 deletions(-)

diff --git a/drivers/pci/controller/dwc/pcie-qcom.c b/drivers/pci/controller/dwc/pcie-qcom.c
index 294babe1816e4d0c2b2343fe22d89af72afcd6cd..bcd080315d70e64eafdefd852740fe07df3dbe75 100644
--- a/drivers/pci/controller/dwc/pcie-qcom.c
+++ b/drivers/pci/controller/dwc/pcie-qcom.c
@@ -302,20 +302,22 @@ static void qcom_perst_assert(struct qcom_pcie *pcie, bool assert)
 	else
 		list_for_each_entry(port, &pcie->ports, list)
 			gpiod_set_value_cansleep(port->reset, val);
-
-	usleep_range(PERST_DELAY_US, PERST_DELAY_US + 500);
 }
 
 static void qcom_ep_reset_assert(struct qcom_pcie *pcie)
 {
 	qcom_perst_assert(pcie, true);
+	usleep_range(PERST_DELAY_US, PERST_DELAY_US + 500);
 }
 
 static void qcom_ep_reset_deassert(struct qcom_pcie *pcie)
 {
-	/* Ensure that PERST has been asserted for at least 100 ms */
+	struct dw_pcie_rp *pp = &pcie->pci->pp;
+
 	msleep(PCIE_T_PVPERL_MS);
 	qcom_perst_assert(pcie, false);
+	if (!pp->use_linkup_irq)
+		msleep(PCIE_RESET_CONFIG_WAIT_MS);
 }
 
 static int qcom_pcie_start_link(struct dw_pcie *pci)

-- 
2.45.2

