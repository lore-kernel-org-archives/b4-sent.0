From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 29 Dec 2025 22:56:55 +0530
Subject: [PATCH v3 4/7] PCI/pwrctrl: Add APIs to power on/off the pwrctrl
 devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251229-pci-pwrctrl-rework-v3-4-c7d5918cd0db@oss.qualcomm.com>
References: <20251229-pci-pwrctrl-rework-v3-0-c7d5918cd0db@oss.qualcomm.com>
In-Reply-To: <20251229-pci-pwrctrl-rework-v3-0-c7d5918cd0db@oss.qualcomm.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Chen-Yu Tsai <wens@kernel.org>, 
 Brian Norris <briannorris@chromium.org>, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 Niklas Cassel <cassel@kernel.org>, Alex Elder <elder@riscstar.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Chen-Yu Tsai <wenst@chromium.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=6552;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=ZfyoHV3eBTTTy49+8YJN4CFzzABZZKIHkD1PNtfqSlk=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpUrnmt1eOywy+gleGJ0XStLhkaCTq699IqQGgr
 P7cuc5ZIwSJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaVK55gAKCRBVnxHm/pHO
 9XgWB/45/gzgEsxVkRl085YygQuCGMQlEr+GbHHt6O9AQU9aUBxj42aqJmoh0T4Nmy1n9dzNM+h
 ibS8m0jRHMVI+8WOJ+Vz3gpkuXymlw71cmlRTJMqPxc6tF83fxoHXvusqpNU0hEJY2GCxry9XpS
 co5lQfAUxEzrWQMiskBCSujpfDYyY5ZPAlJyzydCdOxHpdXaBXCCXFXFLAErkVWY0LO7iwSRWqx
 7WSU/97VDrHopjFBlagvsRH03BHUg1MlmcyC60xKUAeLlQ0oZ9vvNLdHfEzG/2xQ11Mcwjb8tgg
 3oag2eoc7U4RlqONpD9VybHd6W7I891M30YxkpXgTmQRXfBp
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To fix PCIe bridge resource allocation issues when powering PCIe
switches with the pwrctrl driver, introduce APIs to explicitly power
on and off all related devices simultaneously.

Previously, the individual pwrctrl drivers powered on/off the PCIe devices
autonomously, without any control from the controller drivers. But to
enforce ordering w.r.t powering on the devices, these APIs will power
on/off all the devices at the same time.

The pci_pwrctrl_power_on_devices() API recursively scans the PCI child
nodes, makes sure that pwrctrl drivers are bind to devices, and calls their
power_on() callbacks. If any of the pwrctrl driver is not bound, it will
return -EPROBE_DEFER.

Similarly, pci_pwrctrl_power_off_devices() API powers off devices
recursively via their power_off() callbacks.

These APIs are expected to be called during the controller probe and
suspend/resume time to power on/off the devices. But before calling these
APIs, the pwrctrl devices should've been created beforehand using the
pci_pwrctrl_{create/destroy}_devices() APIs.

Co-developed-by: Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>
Signed-off-by: Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>
Tested-by: Chen-Yu Tsai <wenst@chromium.org>
Reviewed-by: Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/pwrctrl/core.c  | 132 ++++++++++++++++++++++++++++++++++++++++++++
 include/linux/pci-pwrctrl.h |   4 ++
 2 files changed, 136 insertions(+)

diff --git a/drivers/pci/pwrctrl/core.c b/drivers/pci/pwrctrl/core.c
index 844b5649b663..0ca448f3bea8 100644
--- a/drivers/pci/pwrctrl/core.c
+++ b/drivers/pci/pwrctrl/core.c
@@ -65,6 +65,7 @@ void pci_pwrctrl_init(struct pci_pwrctrl *pwrctrl, struct device *dev)
 {
 	pwrctrl->dev = dev;
 	INIT_WORK(&pwrctrl->work, rescan_work_func);
+	dev_set_drvdata(dev, pwrctrl);
 }
 EXPORT_SYMBOL_GPL(pci_pwrctrl_init);
 
@@ -152,6 +153,137 @@ int devm_pci_pwrctrl_device_set_ready(struct device *dev,
 }
 EXPORT_SYMBOL_GPL(devm_pci_pwrctrl_device_set_ready);
 
+static void __pci_pwrctrl_power_off_device(struct device *dev)
+{
+	struct pci_pwrctrl *pwrctrl = dev_get_drvdata(dev);
+
+	if (!pwrctrl)
+		return;
+
+	return pwrctrl->power_off(pwrctrl);
+}
+
+static int pci_pwrctrl_power_off_device(struct device_node *np)
+{
+	struct platform_device *pdev;
+
+	for_each_available_child_of_node_scoped(np, child)
+		pci_pwrctrl_power_off_device(child);
+
+	pdev = of_find_device_by_node(np);
+	if (pdev) {
+		if (device_is_bound(&pdev->dev))
+			__pci_pwrctrl_power_off_device(&pdev->dev);
+
+		put_device(&pdev->dev);
+	}
+
+	return 0;
+}
+
+/**
+ * pci_pwrctrl_power_off_devices - Power off the pwrctrl devices
+ *
+ * @parent: Parent PCI device for which the pwrctrl devices need to be powered
+ * off.
+ *
+ * This function recursively traverses all pwrctrl devices for the child nodes
+ * of the specified PCI parent device, and powers them off in a depth first
+ * manner.
+ *
+ * Returns: 0 on success, negative error number on error.
+ */
+void pci_pwrctrl_power_off_devices(struct device *parent)
+{
+	struct device_node *np = parent->of_node;
+
+	for_each_available_child_of_node_scoped(np, child)
+		pci_pwrctrl_power_off_device(child);
+}
+EXPORT_SYMBOL_GPL(pci_pwrctrl_power_off_devices);
+
+static int __pci_pwrctrl_power_on_device(struct device *dev)
+{
+	struct pci_pwrctrl *pwrctrl = dev_get_drvdata(dev);
+
+	if (!pwrctrl)
+		return 0;
+
+	return pwrctrl->power_on(pwrctrl);
+}
+
+/*
+ * Power on the devices in a depth first manner. Before powering on the device,
+ * make sure its driver is bound.
+ */
+static int pci_pwrctrl_power_on_device(struct device_node *np)
+{
+	struct platform_device *pdev;
+	int ret;
+
+	for_each_available_child_of_node_scoped(np, child) {
+		ret = pci_pwrctrl_power_on_device(child);
+		if (ret)
+			return ret;
+	}
+
+	pdev = of_find_device_by_node(np);
+	if (pdev) {
+		if (!device_is_bound(&pdev->dev)) {
+			/* FIXME: Use blocking wait instead of probe deferral */
+			dev_dbg(&pdev->dev, "driver is not bound\n");
+			ret = -EPROBE_DEFER;
+		} else {
+			ret = __pci_pwrctrl_power_on_device(&pdev->dev);
+		}
+		put_device(&pdev->dev);
+
+		if (ret)
+			return ret;
+	}
+
+	return 0;
+}
+
+/**
+ * pci_pwrctrl_power_on_devices - Power on the pwrctrl devices
+ *
+ * @parent: Parent PCI device for which the pwrctrl devices need to be powered
+ * on.
+ *
+ * This function recursively traverses all pwrctrl devices for the child nodes
+ * of the specified PCI parent device, and powers them on in a depth first
+ * manner. On error, all powered on devices will be powered off.
+ *
+ * Returns: 0 on success, -EPROBE_DEFER if any pwrctrl driver is not bound, an
+ * appropriate error code otherwise.
+ */
+int pci_pwrctrl_power_on_devices(struct device *parent)
+{
+	struct device_node *np = parent->of_node;
+	struct device_node *child = NULL;
+	int ret;
+
+	for_each_available_child_of_node(np, child) {
+		ret = pci_pwrctrl_power_on_device(child);
+		if (ret)
+			goto err_power_off;
+	}
+
+	return 0;
+
+err_power_off:
+	for_each_available_child_of_node_scoped(np, tmp) {
+		if (tmp == child)
+			break;
+		pci_pwrctrl_power_off_device(tmp);
+	}
+	of_node_put(child);
+
+	return ret;
+}
+EXPORT_SYMBOL_GPL(pci_pwrctrl_power_on_devices);
+
 static int pci_pwrctrl_create_device(struct device_node *np, struct device *parent)
 {
 	struct platform_device *pdev;
diff --git a/include/linux/pci-pwrctrl.h b/include/linux/pci-pwrctrl.h
index 5590ffec0bea..1b77769eebbe 100644
--- a/include/linux/pci-pwrctrl.h
+++ b/include/linux/pci-pwrctrl.h
@@ -57,8 +57,12 @@ int devm_pci_pwrctrl_device_set_ready(struct device *dev,
 #if IS_ENABLED(CONFIG_PCI_PWRCTRL)
 int pci_pwrctrl_create_devices(struct device *parent);
 void pci_pwrctrl_destroy_devices(struct device *parent);
+int pci_pwrctrl_power_on_devices(struct device *parent);
+void pci_pwrctrl_power_off_devices(struct device *parent);
 #else
 static inline int pci_pwrctrl_create_devices(struct device *parent) { return 0; }
 static void pci_pwrctrl_destroy_devices(struct device *parent) { }
+static inline int pci_pwrctrl_power_on_devices(struct device *parent) { return 0; }
+static void pci_pwrctrl_power_off_devices(struct device *parent) { }
 #endif
 #endif /* __PCI_PWRCTRL_H__ */

-- 
2.48.1

