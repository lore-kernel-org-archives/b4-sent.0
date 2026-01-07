From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 07 Jan 2026 13:41:58 +0530
Subject: [PATCH v4 5/6] PCI: host-common: Add an API to check for any
 device under the Root Ports
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260107-pci-dwc-suspend-rework-v4-5-9b5f3c72df0a@oss.qualcomm.com>
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
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2003;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=kAXCOvQycBkgZ3T8qsZnSaD6+NhiYd0ZqipWoNSX5Vk=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpXhVOYVIGdtRi+M4F8h7//2lgXAskLXBIFa2BF
 GLD3I535hmJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaV4VTgAKCRBVnxHm/pHO
 9QveB/9DZrJ+fECJFPzH8rdLobYA+GeygfYwGeFxZv6tJnR09GgwnZ3A6QIPjEW3HGsmy++ZRA9
 95FDwS/bDYvmjU1cscQ8ULSEHOPLkWny0xTgjjJrnd2ji8i9bVyWflYa3FZWYyTb3eP30ajFdBo
 22Uq3RJa2rkcf8/2k3Xxu+X0G1cBOE3RUMFqaativBvyveclwgz1+IQAE62eFkP+aAk4KMC1hRX
 N5AIzJH6SqaFPeJNh4xs+bj7AAW/vc06Q0mh8jhdtd9EJZLg5ctzOpgqOuuwof3+8tvPPy6PCn2
 Z8SC1idM0irQ+T27K3kQ6jTKVPHhLzGBcGlPWkRgd5YKOnbW
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some controller drivers need to check if there is any device available
under the Root Ports. So add an API that returns 'true' if a device is
found under any of the Root Ports, 'false' otherwise.

Reviewed-by: Frank Li <Frank.Li@nxp.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/pci-host-common.c | 21 +++++++++++++++++++++
 drivers/pci/controller/pci-host-common.h |  2 ++
 2 files changed, 23 insertions(+)

diff --git a/drivers/pci/controller/pci-host-common.c b/drivers/pci/controller/pci-host-common.c
index c473e7c03bac..a88622203227 100644
--- a/drivers/pci/controller/pci-host-common.c
+++ b/drivers/pci/controller/pci-host-common.c
@@ -17,6 +17,27 @@
 
 #include "pci-host-common.h"
 
+/**
+ * pci_root_ports_have_device - Check if the Root Ports under the Root bus have
+ *				any device underneath
+ * @root_bus: Root bus to check for
+ *
+ * Return: true if a device is found, false otherwise
+ */
+bool pci_root_ports_have_device(struct pci_bus *root_bus)
+{
+	struct pci_bus *child;
+
+	/* Iterate over the Root Port busses and look for any device */
+	list_for_each_entry(child, &root_bus->children, node) {
+		if (!list_empty(&child->devices))
+			return true;
+	}
+
+	return false;
+}
+EXPORT_SYMBOL_GPL(pci_root_ports_have_device);
+
 static void gen_pci_unmap_cfg(void *ptr)
 {
 	pci_ecam_free((struct pci_config_window *)ptr);
diff --git a/drivers/pci/controller/pci-host-common.h b/drivers/pci/controller/pci-host-common.h
index b5075d4bd7eb..8088faf94282 100644
--- a/drivers/pci/controller/pci-host-common.h
+++ b/drivers/pci/controller/pci-host-common.h
@@ -20,4 +20,6 @@ void pci_host_common_remove(struct platform_device *pdev);
 
 struct pci_config_window *pci_host_common_ecam_create(struct device *dev,
 	struct pci_host_bridge *bridge, const struct pci_ecam_ops *ops);
+
+bool pci_root_ports_have_device(struct pci_bus *root_bus);
 #endif

-- 
2.48.1

