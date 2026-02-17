From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 17 Feb 2026 15:48:46 +0530
Subject: [PATCH 1/2] PCI/pwrctrl: Ensure that the remote endpoint node
 parent has the supply requirement
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260217-pwrctrl-fixes-7-0-v1-1-b5671e58934f@oss.qualcomm.com>
References: <20260217-pwrctrl-fixes-7-0-v1-0-b5671e58934f@oss.qualcomm.com>
In-Reply-To: <20260217-pwrctrl-fixes-7-0-v1-0-b5671e58934f@oss.qualcomm.com>
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Raj Kumar Bhagat <raj.bhagat@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3183;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=wlUdzqhUB+4RSVFnFt3JdaNgR823BmqPihuUjPSyvCg=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBplECJGPIaTD783PRTfVgJdYa5+qi82Ix9SRBSJ
 FXoVzz+hfqJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaZRAiQAKCRBVnxHm/pHO
 9TqUCACAkMlYjYzu3Cpq8XdMbIOgBAL7h7hf5td1dFYNIvr3Xf0U5DJYlzpsePy/2sYWeHwpZDU
 zbFPGcUbfGtmouqA66H8m61Uq+oRLBToNrcXkvYCZdc15zboj7gArP0RyeKz/4CLlE5v7fg8zYm
 Qx8caf+bhwYTNg1ZvKWmtmC/sroFxtatru8bFbQz/5wbHDcdVJNx7iQ0zetrL6T+A+zjP2WXlAx
 rHyU7gVEPgPVjjdj9IyAAEHufMdZUGGP+8LhfgtQrb9a9fsCUHemnaCS3W+774FWPxAGzJhU9X/
 WzUGwYplXsi8+Vy7RMEJ1UmBX73pqZIdD9rNH2Q1WuRudMPS
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If OF graph is used in the PCI device node, pwrctrl core currently creates
the pwrctrl device even if the remote endpoint doesn't have the power
supply requirements. Since the device doesn't have any power supply
requirements, there was no pwrctrl driver to probe, leading to PCI
controller driver probe deferral as it waits for all pwrctrl drivers to
probe before starting bus scan.

This issue happens with Qcom ath12k devices with WSI interface attached to
the Qcom IPQ platforms.

Fix this issue by checking for the existence of at least one power supply
property in the remote endpoint parent node. To consolidate all the checks,
create a new helper pci_pwrctrl_is_required() and move all the checks
there.

Fixes: 9db826206f9b ("PCI/pwrctrl: Create pwrctrl device if graph port is found")
Reported-by: Raj Kumar Bhagat <raj.bhagat@oss.qualcomm.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/pwrctrl/core.c | 47 +++++++++++++++++++++++++++++++++-------------
 1 file changed, 34 insertions(+), 13 deletions(-)

diff --git a/drivers/pci/pwrctrl/core.c b/drivers/pci/pwrctrl/core.c
index 6f7dea6746e0..8325858cc379 100644
--- a/drivers/pci/pwrctrl/core.c
+++ b/drivers/pci/pwrctrl/core.c
@@ -268,6 +268,39 @@ int pci_pwrctrl_power_on_devices(struct device *parent)
 }
 EXPORT_SYMBOL_GPL(pci_pwrctrl_power_on_devices);
 
+/*
+ * Check whether the pwrctrl device really needs to be created or not. The
+ * pwrctrl device will only be created if the node satisfies below requirements:
+ *
+ * 1. Presence of compatible property to match against the pwrctrl driver (AND)
+ * 2. At least one of the power supplies defined in the devicetree node of the
+ *    device (OR) in the remote endpoint parent node to indicate pwrctrl
+ *    requirement.
+ */
+static bool pci_pwrctrl_is_required(struct device_node *np)
+{
+	struct device_node *endpoint;
+
+	if (!of_property_present(np, "compatible"))
+		return false;
+
+	if (of_pci_supply_present(np))
+		return true;
+
+	if (of_graph_is_present(np)) {
+		for_each_endpoint_of_node(np, endpoint) {
+			struct device_node *remote __free(device_node) =
+				of_graph_get_remote_port_parent(endpoint);
+			if (remote) {
+				if (of_pci_supply_present(remote))
+					return true;
+			}
+		}
+	}
+
+	return false;
+}
+
 static int pci_pwrctrl_create_device(struct device_node *np,
 				     struct device *parent)
 {
@@ -287,19 +320,7 @@ static int pci_pwrctrl_create_device(struct device_node *np,
 		return 0;
 	}
 
-	/*
-	 * Sanity check to make sure that the node has the compatible property
-	 * to allow driver binding.
-	 */
-	if (!of_property_present(np, "compatible"))
-		return 0;
-
-	/*
-	 * Check whether the pwrctrl device really needs to be created or not.
-	 * This is decided based on at least one of the power supplies defined
-	 * in the devicetree node of the device or the graph property.
-	 */
-	if (!of_pci_supply_present(np) && !of_graph_is_present(np)) {
+	if (!pci_pwrctrl_is_required(np)) {
 		dev_dbg(parent, "Skipping OF node: %s\n", np->name);
 		return 0;
 	}

-- 
2.51.0

