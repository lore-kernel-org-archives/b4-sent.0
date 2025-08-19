From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 19 Aug 2025 12:44:53 +0530
Subject: [PATCH 4/6] PCI: of: Add an API to get the BDF for the device node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250819-pci-pwrctrl-perst-v1-4-4b74978d2007@oss.qualcomm.com>
References: <20250819-pci-pwrctrl-perst-v1-0-4b74978d2007@oss.qualcomm.com>
In-Reply-To: <20250819-pci-pwrctrl-perst-v1-0-4b74978d2007@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2221;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=lJHwEOfLqtgwNWXWNyx+rOwSYNWAA15NNEAf91PmREE=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBopCRwaIMwBz8tCj4PzD3876H5Bz2hSyktqZcTT
 IfMJNmljQWJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaKQkcAAKCRBVnxHm/pHO
 9XL3B/9vn8nh6ovIeTV39DChlRj/smMt2t3vYSwSv23YtOBzrhXKOHIKcIUaLOzwPEn11ePfjgG
 r788CJqL9Jw+sSbutI6itc2N859DqFT+RPUqliN2Ow6KBwRugmPoujFXrhv2MTpY6aE1Dd8oVa3
 BBTDCGHjzjRwts2w9yJ4LdI2X/y+7LkgjwMNBckqo7VvBRoG5voujF+htZRIuxLtt6G96BhQ9Xp
 dbFlf/iUa3rqps5klEP9mSdzBMv/0fDjjCp3hG90cJefsSOw1bfkuXlwbL3rJ8bLe38cetXvPHW
 658yQDDTdMwKK99rGyWpZZBIghuVReZyVguWi85+uBBVRKt7
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Bus:Device:Function (BDF) numbers are used to uniquely identify a
device/function on a PCI bus. Hence, add an API to get the BDF from the
devicetree node of a device.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/of.c       | 21 +++++++++++++++++++++
 include/linux/of_pci.h |  6 ++++++
 2 files changed, 27 insertions(+)

diff --git a/drivers/pci/of.c b/drivers/pci/of.c
index 3579265f119845637e163d9051437c89662762f8..5e584d25434291430145e510b1d49a371dce9165 100644
--- a/drivers/pci/of.c
+++ b/drivers/pci/of.c
@@ -183,6 +183,27 @@ int of_pci_get_devfn(struct device_node *np)
 }
 EXPORT_SYMBOL_GPL(of_pci_get_devfn);
 
+/**
+ * of_pci_get_bdf() - Get Bus:Device:Function (BDF) numbers for a device node
+ * @np: device node
+ *
+ * Parses a standard 5-cell PCI resource and returns an 16-bit value that
+ * corresponds to the BDF of the node. On error, a negative error code is
+ * returned.
+ */
+int of_pci_get_bdf(struct device_node *np)
+{
+	u32 reg[5];
+	int error;
+
+	error = of_property_read_u32_array(np, "reg", reg, ARRAY_SIZE(reg));
+	if (error)
+		return error;
+
+	return (reg[0] >> 8) & 0xffff;
+}
+EXPORT_SYMBOL_GPL(of_pci_get_bdf);
+
 /**
  * of_pci_parse_bus_range() - parse the bus-range property of a PCI device
  * @node: device node
diff --git a/include/linux/of_pci.h b/include/linux/of_pci.h
index 29658c0ee71ff10122760214d04ee2bab01709fd..b36ac10653c82f4efdbb57cea56d2ec9d581212f 100644
--- a/include/linux/of_pci.h
+++ b/include/linux/of_pci.h
@@ -12,6 +12,7 @@ struct device_node;
 struct device_node *of_pci_find_child_device(struct device_node *parent,
 					     unsigned int devfn);
 int of_pci_get_devfn(struct device_node *np);
+int of_pci_get_bdf(struct device_node *np);
 void of_pci_check_probe_only(void);
 #else
 static inline struct device_node *of_pci_find_child_device(struct device_node *parent,
@@ -25,6 +26,11 @@ static inline int of_pci_get_devfn(struct device_node *np)
 	return -EINVAL;
 }
 
+static inline int of_pci_get_bdf(struct device_node *np)
+{
+	return -EINVAL;
+}
+
 static inline void of_pci_check_probe_only(void) { }
 #endif
 

-- 
2.45.2

