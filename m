From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Fri, 12 Sep 2025 14:05:01 +0530
Subject: [PATCH v3 1/4] PCI/pwrctrl: Add support for asserting/deasserting
 PERST#
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250912-pci-pwrctrl-perst-v3-1-3c0ac62b032c@oss.qualcomm.com>
References: <20250912-pci-pwrctrl-perst-v3-0-3c0ac62b032c@oss.qualcomm.com>
In-Reply-To: <20250912-pci-pwrctrl-perst-v3-0-3c0ac62b032c@oss.qualcomm.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Saravana Kannan <saravanak@google.com>
Cc: linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 Brian Norris <briannorris@chromium.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4251;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=jCv+iKeOMcKQiy+sgTT5FskEFZPk4zscRN+1zwZTLe8=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBow9tHNza8f0jG3b+AspCiBV7VAMWXAy5GxYIcV
 +W5YLUQLBWJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaMPbRwAKCRBVnxHm/pHO
 9TV+B/0Sb2Sb+ByTUWUhwh9Jb8VcxsX+SYLJX5HFb3MYZsh7tHjpaa+Q6rEIJq4+5aciNw4iOj5
 v5FCy4gvVNsws1rRHvO9/lT+hav92CuRXJvDCiGfImYYLERBX2O4q5rn5l4Ms+r3BTMdUFZB2na
 zR+6Fqa3vKD3CjqSSbRB04VeBMT9HwmFamrMpDwDHh6r/alWJ+0F67epE0UJfFtO2dzcWCdeuji
 6pZ7OoUMllq66vwvcgByO5hx8ntSpGfzO036H0CGBcJTKKEc8AdjddiLBLFKkYkNLqqRsJECb50
 8CL6tomfbk7Pd+ZMZsSdVf8dxnZF4NVVPcZl4wStPvZTAID4
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As per PCIe spec r6.0, sec 6.6.1, PERST# is an auxiliary signal provided by
the system to a component as a Fundamental Reset. This signal if available,
should conform to the rules defined by the Electromechanical form factor
specifications like PCIe CEM spec r4.0, sec 2.2.

Since pwrctrl driver is meant to control the power supplies to the PCI
components, it should also control the PERST# signal if available. But
traditionally, the host bridge (controller) drivers are the ones parsing
and controlling the PERST# signal. They also sometimes need to assert
PERST# during their own hardware initialization. So it is not possible to
move the PERST# control away from the controller drivers and it must be
shared logically.

Hence, add a new callback 'pci_host_bridge::perst_assert', that allows the
pwrctrl core to assert/deassert PERST# with the help of the controller
drivers. But care must be taken care by the controller drivers to not
deassert the PERST# signal if this callback is populated.

This callback if available, will be called by the pwrctrl core during the
device power up and power down scenarios. Controller drivers should
identify the device using the 'struct device_node' passed during the
callback and assert/deassert PERST# accordingly.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/pwrctrl/core.c | 27 +++++++++++++++++++++++++++
 include/linux/pci.h        |  3 +++
 2 files changed, 30 insertions(+)

diff --git a/drivers/pci/pwrctrl/core.c b/drivers/pci/pwrctrl/core.c
index 6bdbfed584d6d79ce28ba9e384a596b065ca69a4..54d3dbc24020e979f668bb294448e8429cd8bdd3 100644
--- a/drivers/pci/pwrctrl/core.c
+++ b/drivers/pci/pwrctrl/core.c
@@ -6,6 +6,7 @@
 #include <linux/device.h>
 #include <linux/export.h>
 #include <linux/kernel.h>
+#include <linux/of.h>
 #include <linux/pci.h>
 #include <linux/pci-pwrctrl.h>
 #include <linux/property.h>
@@ -61,6 +62,28 @@ void pci_pwrctrl_init(struct pci_pwrctrl *pwrctrl, struct device *dev)
 }
 EXPORT_SYMBOL_GPL(pci_pwrctrl_init);
 
+static void pci_pwrctrl_perst_deassert(struct pci_pwrctrl *pwrctrl)
+{
+	struct pci_host_bridge *host_bridge = to_pci_host_bridge(pwrctrl->dev->parent);
+	struct device_node *np = dev_of_node(pwrctrl->dev);
+
+	if (!host_bridge->perst_assert)
+		return;
+
+	host_bridge->perst_assert(host_bridge, np, false);
+}
+
+static void pci_pwrctrl_perst_assert(struct pci_pwrctrl *pwrctrl)
+{
+	struct pci_host_bridge *host_bridge = to_pci_host_bridge(pwrctrl->dev->parent);
+	struct device_node *np = dev_of_node(pwrctrl->dev);
+
+	if (!host_bridge->perst_assert)
+		return;
+
+	host_bridge->perst_assert(host_bridge, np, true);
+}
+
 /**
  * pci_pwrctrl_device_set_ready() - Notify the pwrctrl subsystem that the PCI
  * device is powered-up and ready to be detected.
@@ -82,6 +105,8 @@ int pci_pwrctrl_device_set_ready(struct pci_pwrctrl *pwrctrl)
 	if (!pwrctrl->dev)
 		return -ENODEV;
 
+	pci_pwrctrl_perst_deassert(pwrctrl);
+
 	pwrctrl->nb.notifier_call = pci_pwrctrl_notify;
 	ret = bus_register_notifier(&pci_bus_type, &pwrctrl->nb);
 	if (ret)
@@ -103,6 +128,8 @@ void pci_pwrctrl_device_unset_ready(struct pci_pwrctrl *pwrctrl)
 {
 	cancel_work_sync(&pwrctrl->work);
 
+	pci_pwrctrl_perst_assert(pwrctrl);
+
 	/*
 	 * We don't have to delete the link here. Typically, this function
 	 * is only called when the power control device is being detached. If
diff --git a/include/linux/pci.h b/include/linux/pci.h
index 59876de13860dbe50ee6c207cd57e54f51a11079..08007ef244c0a8bc2be27496bea7249ce3e00935 100644
--- a/include/linux/pci.h
+++ b/include/linux/pci.h
@@ -605,6 +605,9 @@ struct pci_host_bridge {
 	void (*release_fn)(struct pci_host_bridge *);
 	int (*enable_device)(struct pci_host_bridge *bridge, struct pci_dev *dev);
 	void (*disable_device)(struct pci_host_bridge *bridge, struct pci_dev *dev);
+#if IS_ENABLED(CONFIG_PCI_PWRCTRL)
+	void (*perst_assert)(struct pci_host_bridge *bridge, struct device_node *np, bool assert);
+#endif
 	void		*release_data;
 	unsigned int	ignore_reset_delay:1;	/* For entire hierarchy */
 	unsigned int	no_ext_tags:1;		/* No Extended Tags */

-- 
2.45.2

