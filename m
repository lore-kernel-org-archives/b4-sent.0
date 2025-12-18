From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Thu, 18 Dec 2025 17:34:53 +0530
Subject: [PATCH v2 2/2] PCI: dwc: Do not return failure if link is in
 Detect.Quiet/Active states
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251218-pci-dwc-suspend-rework-v2-2-5a7778c6094a@oss.qualcomm.com>
References: <20251218-pci-dwc-suspend-rework-v2-0-5a7778c6094a@oss.qualcomm.com>
In-Reply-To: <20251218-pci-dwc-suspend-rework-v2-0-5a7778c6094a@oss.qualcomm.com>
To: Jingoo Han <jingoohan1@gmail.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 vincent.guittot@linaro.org, zhangsenchuan@eswincomputing.com, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3023;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=D2MBlxbTAfw057cQLiitH+T4lD/EKzE736CiStKl0vQ=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpQ+3lWTFs8FC7hQKkTIRIHEtEPIQGu0zYHqUgo
 wDtrFZH+7aJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaUPt5QAKCRBVnxHm/pHO
 9QdoB/9jpC+5JFgFx4xfgXRsSqBywS7cW4VhUKTHW7wjwnU/3eM9Dd9+L4redzxZZn1DwVxxPVd
 Pyb7HzxWOUrUJW1Kz9syDYn5IvB1PxsPe+kXHotiEjuGVVkmBFC1XlKqcfyKMC2K/bbVwVYwQGi
 I26J8rxxub/pgVM0Sjo3isN10WiREH1hLFYoej7JdRUm0yoS2/aeS1WeiA4v0hWiArhHzkFcIDz
 mji7x/2E2/9vpmOSyZnoAx9Gx/XFV8am5NFLiIarVnT/lUneNMUW0a/G9bmZnzR96YkNstbaRF2
 bn0fd9ua5oqePX8jqdc/979LH2qbOc+IqZAr8EZHYQ3yzs6Y
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dw_pcie_wait_for_link() API waits for the link to be up and returns failure
if the link is not up within the 1 second interval. But if there was no
device connected to the bus, then the link up failure would be expected.
In that case, the callers might want to skip the failure in a hope that the
link will be up later when a device gets connected.

One of the callers, dw_pcie_host_init() is currently skipping the failure
irrespective of the link state, in an assumption that the link may come up
later. But this assumption is wrong, since LTSSM states other than
Detect.Quiet and Detect.Active during link training phase are considered to
be fatal and the link needs to be retrained.

So to avoid callers making wrong assumptions, skip returning failure from
dw_pcie_wait_for_link() only if the link is in Detect.Quiet or
Detect.Active states after timeout and also check the return value of the
API in dw_pcie_host_init().

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-designware-host.c |  8 +++++---
 drivers/pci/controller/dwc/pcie-designware.c      | 12 +++++++++++-
 2 files changed, 16 insertions(+), 4 deletions(-)

diff --git a/drivers/pci/controller/dwc/pcie-designware-host.c b/drivers/pci/controller/dwc/pcie-designware-host.c
index 43d091128ef7..ef6d9ae6eddb 100644
--- a/drivers/pci/controller/dwc/pcie-designware-host.c
+++ b/drivers/pci/controller/dwc/pcie-designware-host.c
@@ -670,9 +670,11 @@ int dw_pcie_host_init(struct dw_pcie_rp *pp)
 	 * If there is no Link Up IRQ, we should not bypass the delay
 	 * because that would require users to manually rescan for devices.
 	 */
-	if (!pp->use_linkup_irq)
-		/* Ignore errors, the link may come up later */
-		dw_pcie_wait_for_link(pci);
+	if (!pp->use_linkup_irq) {
+		ret = dw_pcie_wait_for_link(pci);
+		if (ret)
+			goto err_stop_link;
+	}
 
 	ret = pci_host_probe(bridge);
 	if (ret)
diff --git a/drivers/pci/controller/dwc/pcie-designware.c b/drivers/pci/controller/dwc/pcie-designware.c
index 75fc8b767fcc..b58baf26ce58 100644
--- a/drivers/pci/controller/dwc/pcie-designware.c
+++ b/drivers/pci/controller/dwc/pcie-designware.c
@@ -641,7 +641,7 @@ void dw_pcie_disable_atu(struct dw_pcie *pci, u32 dir, int index)
 
 int dw_pcie_wait_for_link(struct dw_pcie *pci)
 {
-	u32 offset, val;
+	u32 offset, val, ltssm;
 	int retries;
 
 	/* Check if the link is up or not */
@@ -653,6 +653,16 @@ int dw_pcie_wait_for_link(struct dw_pcie *pci)
 	}
 
 	if (retries >= PCIE_LINK_WAIT_MAX_RETRIES) {
+		/*
+		 * If the link is in Detect.Quiet or Detect.Active state, it
+		 * indicates that no device is detected. So return success to
+		 * allow the device to show up later.
+		 */
+		ltssm = dw_pcie_get_ltssm(pci);
+		if (ltssm == DW_PCIE_LTSSM_DETECT_QUIET ||
+		    ltssm == DW_PCIE_LTSSM_DETECT_ACT)
+			return 0;
+
 		dev_info(pci->dev, "Phy link never came up\n");
 		return -ETIMEDOUT;
 	}

-- 
2.48.1

