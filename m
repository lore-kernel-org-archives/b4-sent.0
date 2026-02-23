From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 23 Feb 2026 20:15:59 +0530
Subject: [PATCH v2 1/2] PCI/pwrctrl: Ensure that the remote endpoint node
 parent has the supply requirement
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260223-pwrctrl-fixes-7-0-v2-1-97566dfb1809@oss.qualcomm.com>
References: <20260223-pwrctrl-fixes-7-0-v2-0-97566dfb1809@oss.qualcomm.com>
In-Reply-To: <20260223-pwrctrl-fixes-7-0-v2-0-97566dfb1809@oss.qualcomm.com>
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Raj Kumar Bhagat <raj.bhagat@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3390;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=zL6q6aa6T9+a57GlUxi/PAtdLbRswIWN6ZLfXidZ7Q8=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpnGgqcQz/SmdNbOAft2OTz/RwIC84RgfBJxwfz
 G7NxzmzcsKJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaZxoKgAKCRBVnxHm/pHO
 9XiAB/4rnXUUEsitsCwNIEuW1CO/iWey8nmy942zlu/cuwLxk6PTedT3+CPg0MDKMiaps7/56++
 cu5WkHFNsTBH07AF10tlb07+IMQql+pjp5FA8A+iAkKUzpGvFe4B1uXAY/FAE1EDnbgF07d78B/
 kv6QjAlweLWy7/+5h2M4TI7nmxOcXQUKldz1f+qDlOdo/gJVw6LGRmUTuxvDaNA6IhW/1egVfAN
 km1pp4sCDLL28fpwQHzn7ULWsw/gxkIMUaYlP1QhnCLIeVzL0GTJo9Rc9CcjU3X+7+U/0wBGl9c
 yColalMKCbc6K1Qc15b2uZFcmOzCo8UTTIetMHL1NGkHvcFG
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
Tested-by: Raj Kumar Bhagat <raj.bhagat@oss.qualcomm.com>
Reviewed-by: Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>
Reviewed-by: Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>
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

