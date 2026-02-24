From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 24 Feb 2026 11:00:48 +0530
Subject: [PATCH v5 2/9] serdev: Add an API to find the serdev controller
 associated with the devicetree node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260224-pci-m2-e-v5-2-dd9b9501d33c@oss.qualcomm.com>
References: <20260224-pci-m2-e-v5-0-dd9b9501d33c@oss.qualcomm.com>
In-Reply-To: <20260224-pci-m2-e-v5-0-dd9b9501d33c@oss.qualcomm.com>
To: Rob Herring <robh@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Nathan Chancellor <nathan@kernel.org>, 
 Nicolas Schier <nicolas.schier@linux.dev>, Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Mark Pearson <mpearson-lenovo@squebb.ca>, 
 "Derek J. Clark" <derekjohn.clark@gmail.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-serial@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, platform-driver-x86@vger.kernel.org, 
 linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-bluetooth@vger.kernel.org, 
 linux-pm@vger.kernel.org, Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 linux-acpi@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Hans de Goede <johannes.goede@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2175;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=ZvwvgoFlf4z/ag5/olaI5ILEIEPSFo6zg+vO7wuanOo=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpnTeIa56ffrPgmNucV18RPYqRHO94dF3VIWvvp
 Zp7yqucqEWJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaZ03iAAKCRBVnxHm/pHO
 9QihB/4pXR5cfUc1yznfMiQgbOZgzBXVtinCek2mr0WZVDia+3o/PbEyb03v5G1SyzX7+yxoOKA
 UNAe/ugQlDvJuSaXmmKeZ2dnbghjwiqQpVGdTH6He1icNr0ieEQLGk/kk0g2R8SsIiP6DfF6bdd
 aIF71gAd45wbJE5TTyrtEzID7oTSxBeBxBq45T1pSxXD+gATuUn8RC8BJ3i74DL4xg0Oz1dUkGi
 5KHBd3mSW7rwzoBPSseevM7nCO4+l9fw/LN2hiVA17m9J1mA9gA4qxX4AMGPM0hogrrkE6GO9gw
 gwle1YNRoxaCtGCSnMvsfLTYLHl+pX58DEkQFkEnANIR9Kws
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add of_find_serdev_controller_by_node() API to find the serdev controller
device associated with the devicetree node.

Tested-by: Hans de Goede <johannes.goede@oss.qualcomm.com> # ThinkPad T14s gen6 (arm64)
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/tty/serdev/core.c | 19 +++++++++++++++++++
 include/linux/serdev.h    |  9 +++++++++
 2 files changed, 28 insertions(+)

diff --git a/drivers/tty/serdev/core.c b/drivers/tty/serdev/core.c
index 8f25510f89b6..bf88b95f7458 100644
--- a/drivers/tty/serdev/core.c
+++ b/drivers/tty/serdev/core.c
@@ -514,6 +514,25 @@ struct serdev_controller *serdev_controller_alloc(struct device *host,
 }
 EXPORT_SYMBOL_GPL(serdev_controller_alloc);
 
+#ifdef CONFIG_OF
+/**
+ * of_find_serdev_controller_by_node() - Find the serdev controller associated
+ *					 with the devicetree node
+ * @node:	Devicetree node
+ *
+ * Return: Pointer to the serdev controller associated with the node. NULL if
+ * the controller is not found. Caller is responsible for calling
+ * serdev_controller_put() to drop the reference.
+ */
+struct serdev_controller *of_find_serdev_controller_by_node(struct device_node *node)
+{
+	struct device *dev = bus_find_device_by_of_node(&serdev_bus_type, node);
+
+	return (dev && dev->type == &serdev_ctrl_type) ? to_serdev_controller(dev) : NULL;
+}
+EXPORT_SYMBOL_GPL(of_find_serdev_controller_by_node);
+#endif
+
 static int of_serdev_register_devices(struct serdev_controller *ctrl)
 {
 	struct device_node *node;
diff --git a/include/linux/serdev.h b/include/linux/serdev.h
index 0c7d3c27d1f8..188c0ba62d50 100644
--- a/include/linux/serdev.h
+++ b/include/linux/serdev.h
@@ -334,4 +334,13 @@ static inline bool serdev_acpi_get_uart_resource(struct acpi_resource *ares,
 }
 #endif /* CONFIG_ACPI */
 
+#ifdef CONFIG_OF
+struct serdev_controller *of_find_serdev_controller_by_node(struct device_node *node);
+#else
+static inline struct serdev_controller *of_find_serdev_controller_by_node(struct device_node *node)
+{
+	return NULL;
+}
+#endif /* CONFIG_OF */
+
 #endif /*_LINUX_SERDEV_H */

-- 
2.51.0

