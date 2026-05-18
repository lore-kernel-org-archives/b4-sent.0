From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 18 May 2026 20:29:15 +0530
Subject: [PATCH v8 3/5] PCI: host-common: Add link down handling for Root
 Ports
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260518-pci-port-reset-v8-3-eb5a7d331dfc@oss.qualcomm.com>
References: <20260518-pci-port-reset-v8-0-eb5a7d331dfc@oss.qualcomm.com>
In-Reply-To: <20260518-pci-port-reset-v8-0-eb5a7d331dfc@oss.qualcomm.com>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Mahesh J Salgaonkar <mahesh@linux.ibm.com>, 
 Oliver O'Halloran <oohall@gmail.com>, Will Deacon <will@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linuxppc-dev@lists.ozlabs.org, linux-arm-kernel@lists.infradead.org, 
 linux-arm-msm@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 Niklas Cassel <cassel@kernel.org>, 
 Wilfred Mallawa <wilfred.mallawa@wdc.com>, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 mani@kernel.org, Lukas Wunner <lukas@wunner.de>, 
 Richard Zhu <hongxing.zhu@nxp.com>, Brian Norris <briannorris@chromium.org>, 
 Wilson Ding <dingwei@marvell.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Frank Li <Frank.Li@nxp.com>, Manivannan Sadhasivam <mani@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=4994;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=sUUM3qfYFHtLCvQ6F4TpKK8xkq87A6dqKTUi0wYFy8I=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqCylVsyXmrLzrL4HM6RZ5tQgjTnDWSo1IJbmqH
 9kH3iIqszOJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCagspVQAKCRBVnxHm/pHO
 9e0bB/9vke3MyQywmKGA3GJHkJV+dxOGWWN8YoNw/Rzn7XiOr8oQzUBq/Gh+PpQnY3OXbjrSHHM
 CLayK3+F3LYkQK0C62kPt1fTq8AF9xkddaAWCxZcjQITehj/TowyK4qSoR+Fz2zywNIHSU7sYfl
 9yN5CLJTC4qVfpAjD6sqhSj0Wd0EmV+/YmH6G1LtwouYbzl/VB5nyTADdgtcoEAHjYFiJvXUvNd
 E/sNZNw307LUx+VQsasfhyN5X67ZAOoQZUx/I0KYkwpGGyFmMCPn4EmvYtnVXx/flktEjT8H4H/
 j8bdKy9/1wCveS3bTpctzjVo7fcy3RsQRFLIdAl9GI48QJO2
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Manivannan Sadhasivam <mani@kernel.org>

The PCI link, when down, needs to be recovered to bring it back. But on
some platforms, that cannot be done in a generic way as link recovery
procedure is platform specific. So add a new API
pci_host_handle_link_down() that could be called by the host bridge drivers
for a specific Root Port when the link goes down.

The API accepts the 'pci_dev' corresponding to the Root Port which observed
the link down event. If CONFIG_PCIEAER is enabled, the API calls
pcie_do_recovery() function with 'pci_channel_io_frozen' as the state. This
will result in the execution of the AER Fatal error handling code. Since
the link down recovery is pretty much the same as AER Fatal error handling,
pcie_do_recovery() helper is reused here. First, the AER error_detected()
callback will be triggered for the bridge and then for the downstream
devices. Finally, pci_host_reset_root_port() will be called for the Root
Port, which will reset the Root Port using 'reset_root_port' callback to
recover the link. Once that's done, resume message will be broadcasted to
the bridge and the downstream devices, indicating successful link recovery.

But if CONFIG_PCIEAER is not enabled in the kernel, only
pci_host_reset_root_port() API will be called, which will in turn call
pci_bus_error_reset() to just reset the Root Port as there is no way we
could inform the drivers about link recovery.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Tested-by: Brian Norris <briannorris@chromium.org>
Tested-by: Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>
Tested-by: Richard Zhu <hongxing.zhu@nxp.com>
Reviewed-by: Frank Li <Frank.Li@nxp.com>
---
 drivers/pci/controller/pci-host-common.c | 35 ++++++++++++++++++++++++++++++++
 drivers/pci/controller/pci-host-common.h |  1 +
 drivers/pci/pci.c                        |  1 +
 drivers/pci/pcie/err.c                   |  1 +
 4 files changed, 38 insertions(+)

diff --git a/drivers/pci/controller/pci-host-common.c b/drivers/pci/controller/pci-host-common.c
index d6258c1cffe5..15ebff8a542a 100644
--- a/drivers/pci/controller/pci-host-common.c
+++ b/drivers/pci/controller/pci-host-common.c
@@ -12,9 +12,11 @@
 #include <linux/of.h>
 #include <linux/of_address.h>
 #include <linux/of_pci.h>
+#include <linux/pci.h>
 #include <linux/pci-ecam.h>
 #include <linux/platform_device.h>
 
+#include "../pci.h"
 #include "pci-host-common.h"
 
 static void gen_pci_unmap_cfg(void *ptr)
@@ -106,5 +108,38 @@ void pci_host_common_remove(struct platform_device *pdev)
 }
 EXPORT_SYMBOL_GPL(pci_host_common_remove);
 
+static pci_ers_result_t pci_host_reset_root_port(struct pci_dev *dev)
+{
+	int ret;
+
+	pci_lock_rescan_remove();
+	ret = pci_bus_error_reset(dev);
+	pci_unlock_rescan_remove();
+	if (ret) {
+		pci_err(dev, "Failed to reset Root Port: %d\n", ret);
+		return PCI_ERS_RESULT_DISCONNECT;
+	}
+
+	pci_info(dev, "Root Port has been reset\n");
+
+	return PCI_ERS_RESULT_RECOVERED;
+}
+
+static void pci_host_recover_root_port(struct pci_dev *port)
+{
+#if IS_ENABLED(CONFIG_PCIEAER)
+	pcie_do_recovery(port, pci_channel_io_frozen, pci_host_reset_root_port);
+#else
+	pci_host_reset_root_port(port);
+#endif
+}
+
+void pci_host_handle_link_down(struct pci_dev *port)
+{
+	pci_info(port, "Recovering Root Port due to Link Down\n");
+	pci_host_recover_root_port(port);
+}
+EXPORT_SYMBOL_GPL(pci_host_handle_link_down);
+
 MODULE_DESCRIPTION("Common library for PCI host controller drivers");
 MODULE_LICENSE("GPL v2");
diff --git a/drivers/pci/controller/pci-host-common.h b/drivers/pci/controller/pci-host-common.h
index b5075d4bd7eb..dd12dd1a1b23 100644
--- a/drivers/pci/controller/pci-host-common.h
+++ b/drivers/pci/controller/pci-host-common.h
@@ -17,6 +17,7 @@ int pci_host_common_init(struct platform_device *pdev,
 			 struct pci_host_bridge *bridge,
 			 const struct pci_ecam_ops *ops);
 void pci_host_common_remove(struct platform_device *pdev);
+void pci_host_handle_link_down(struct pci_dev *port);
 
 struct pci_config_window *pci_host_common_ecam_create(struct device *dev,
 	struct pci_host_bridge *bridge, const struct pci_ecam_ops *ops);
diff --git a/drivers/pci/pci.c b/drivers/pci/pci.c
index 651505b3bd60..35dc9f54a8ef 100644
--- a/drivers/pci/pci.c
+++ b/drivers/pci/pci.c
@@ -5669,6 +5669,7 @@ int pci_bus_error_reset(struct pci_dev *bridge)
 {
 	return pci_reset_bridge(bridge, PCI_RESET_NO_RESTORE);
 }
+EXPORT_SYMBOL_GPL(pci_bus_error_reset);
 
 int pci_try_reset_bridge(struct pci_dev *bridge)
 {
diff --git a/drivers/pci/pcie/err.c b/drivers/pci/pcie/err.c
index 13b9d9eb714f..d77403d8855b 100644
--- a/drivers/pci/pcie/err.c
+++ b/drivers/pci/pcie/err.c
@@ -292,3 +292,4 @@ pci_ers_result_t pcie_do_recovery(struct pci_dev *dev,
 
 	return status;
 }
+EXPORT_SYMBOL_GPL(pcie_do_recovery);

-- 
2.48.1

