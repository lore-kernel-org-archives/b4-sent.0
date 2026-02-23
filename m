From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 23 Feb 2026 20:16:00 +0530
Subject: [PATCH v2 2/2] PCI/pwrctrl: Only create pwrctrl device if the
 device node belongs to a PCI device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260223-pwrctrl-fixes-7-0-v2-2-97566dfb1809@oss.qualcomm.com>
References: <20260223-pwrctrl-fixes-7-0-v2-0-97566dfb1809@oss.qualcomm.com>
In-Reply-To: <20260223-pwrctrl-fixes-7-0-v2-0-97566dfb1809@oss.qualcomm.com>
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1922;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=C+DZSejy79J+txqGCNv0wX73UYcOZysDCQlY4IL7Iwk=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpnGgqzSl5jRV8X8rKF8Q9KRccqVgEhgq/xbbmM
 xWDhExESTOJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaZxoKgAKCRBVnxHm/pHO
 9TO9B/9IRnAAzaAi2ocvJBj+ICEUmVjCXX7kNpexpHjyGteK51xJQCj5Me6fpQT6w/dgf2zAIiP
 9xv1D5aEUAz3hd5y8MD08TDoYdE3Id5YKuxtAJTN5brvNAfdggQI7B4TOwqBuabcaI4znQS9+NL
 TPqLXkxnjNi8oLZ1mI13pi9fCe1cbHMsJDQag+bVBusQjMXzF1xN+YuXkZFhTufUW6JwDfxua2l
 qU6B+JBpnDhHaT7bkGWgl1sEE0y246QPz25zxXmVZBmzYg2D2lXHxjQWo86L85G15dHGhtlLgae
 qs+maqeAPwG9RbnbhtLA+gtXWYc4mbw30kxNSZxIrcox64hE
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PCI host bridge node can have non-PCI child nodes as well, like OPP
tables, USB hub etc... So the pwrctrl core must ensure that the pwrctrl
device is only created for PCI device nodes by checking for the 'pci'
prefix in the compatible property.

Fixes: 4c4132489201 ("PCI/pwrctrl: Add APIs to create, destroy pwrctrl devices")
Reported-by: Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>
Closes: https://lore.kernel.org/all/20260212-rb3gen2-upd-gl3590-v1-1-18fb04bb32b0@oss.qualcomm.com
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/pwrctrl/core.c | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/drivers/pci/pwrctrl/core.c b/drivers/pci/pwrctrl/core.c
index 8325858cc379..7754baed67f2 100644
--- a/drivers/pci/pwrctrl/core.c
+++ b/drivers/pci/pwrctrl/core.c
@@ -272,7 +272,8 @@ EXPORT_SYMBOL_GPL(pci_pwrctrl_power_on_devices);
  * Check whether the pwrctrl device really needs to be created or not. The
  * pwrctrl device will only be created if the node satisfies below requirements:
  *
- * 1. Presence of compatible property to match against the pwrctrl driver (AND)
+ * 1. Presence of compatible property with "pci" prefix to match against the
+ *    pwrctrl driver (AND)
  * 2. At least one of the power supplies defined in the devicetree node of the
  *    device (OR) in the remote endpoint parent node to indicate pwrctrl
  *    requirement.
@@ -280,8 +281,14 @@ EXPORT_SYMBOL_GPL(pci_pwrctrl_power_on_devices);
 static bool pci_pwrctrl_is_required(struct device_node *np)
 {
 	struct device_node *endpoint;
+	const char *compat;
+	int ret;
+
+	ret = of_property_read_string(np, "compatible", &compat);
+	if (ret < 0)
+		return false;
 
-	if (!of_property_present(np, "compatible"))
+	if (!strstarts(compat, "pci"))
 		return false;
 
 	if (of_pci_supply_present(np))

-- 
2.51.0

