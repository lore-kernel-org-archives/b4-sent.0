From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 16 Jun 2026 21:45:19 +0530
Subject: [PATCH] PCI: qcom: Skip PERST# GPIOs provided by downstream PCIe
 devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260616-pci-qcom-perst-fix-v1-1-27600d6ae357@oss.qualcomm.com>
X-B4-Tracking: v=1; b=H4sIAJZ2MWoC/yXMQQrCMBCF4auUWTuQFJugVxEXcTrqCLYxE6UQc
 vemdvk9eH8B5SSscO4KJP6Jyjw12EMH9AzTg1HGZuhN74yzDiMJfmh+Y+SkGe+yoDFH60MYfDg
 5aMeYuM3/6OW6W7+3F1PeSlDrCuwFEj12AAAA
X-Change-ID: 20260616-pci-qcom-perst-fix-00417aa57a96
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-arm-msm@vger.kernel.org, linux-pci@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3083;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=SAG1WtlnXkQauMnV0DcExAZh86wK4HSUyapFJVHHEa4=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqMXad1EQZDA1Q+azZIoD14TsRxfPwzlzqAWMsJ
 QDCPpo1y7SJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCajF2nQAKCRBVnxHm/pHO
 9QKTB/41ovfWXcOGtCXxtK/RPBXxzZmvHF6TmIDcmgrzyztBsljFajLXdEIeX3zu1g0UDKKO1Ny
 OzV0XFUkUxz6NQi00U5EdUkFJRS4oFThbdxWjyz8vM+z95pKaoDru1lwQ2ZGJCutfTq+e834Aj3
 h1MeUBAeL/g/p5xknPldWjUI4SM3UXJgNe6NZEm5+UR0AJw7uGeMyKmqVwhfF0Efg0MSruYjkCU
 gUo6sudOQ5POYaTJ5kW9pM80FDjgcsdfl/vNk0ajYSsYxsBuuiVK3BQpEdN+TO+8nm6rL3j7q2I
 0DBQOGgUBglrv+zoC9CiJsT5VG3xJgl8qoyOHEdD3eUs8YlE
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, the pcie-qcom driver recursively parses the PERST# GPIO from all
child nodes defined in DT and acquires them. But this creates issues with
PERST# GPIO provided by one of the child devices like the PCIe switch port.
In this case, the RC driver cannot acquire the PERST# GPIO since it will be
provided by the child PCIe device which was not yet enumerated during RC
driver probe.

Fix this by checking if the GPIO provider is a child of the RC's DT node
(i.e., sits behind this PCIe controller). If so, skip it, as PERST#
should be controlled by the respective PCIe client driver implementation.
GPIOs provided by external GPIO controllers (e.g., TLMM in Qcom SoCs)
continue to be handled normally.

Fixes: 2fd60a2edb83 ("PCI: qcom: Parse PERST# from all PCIe bridge nodes")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-qcom.c | 36 ++++++++++++++++++++++++++++++++++
 1 file changed, 36 insertions(+)

diff --git a/drivers/pci/controller/dwc/pcie-qcom.c b/drivers/pci/controller/dwc/pcie-qcom.c
index af6bf5cce65b..f90ff68cdaf2 100644
--- a/drivers/pci/controller/dwc/pcie-qcom.c
+++ b/drivers/pci/controller/dwc/pcie-qcom.c
@@ -1693,6 +1693,22 @@ static const struct pci_ecam_ops pci_qcom_ecam_ops = {
 	}
 };
 
+static bool qcom_pcie_is_child_node(struct device *dev,
+				    struct device_node *node)
+{
+	struct device_node *parent;
+
+	for (parent = of_get_parent(node); parent;
+	     parent = of_get_next_parent(parent)) {
+		if (parent == dev->of_node) {
+			of_node_put(parent);
+			return true;
+		}
+	}
+
+	return false;
+}
+
 /* Parse PERST# from all nodes in depth first manner starting from @np */
 static int qcom_pcie_parse_perst(struct qcom_pcie *pcie,
 				 struct qcom_pcie_port *port,
@@ -1700,12 +1716,32 @@ static int qcom_pcie_parse_perst(struct qcom_pcie *pcie,
 {
 	struct device *dev = pcie->pci->dev;
 	struct qcom_pcie_perst *perst;
+	struct device_node *gpio_np;
 	struct gpio_desc *reset;
 	int ret;
 
 	if (!of_find_property(np, "reset-gpios", NULL))
 		goto parse_child_node;
 
+	/*
+	 * Skip GPIOs provided by a PCIe device which is a child of the Root
+	 * Complex (e.g., a PCIe switch with GPIO controller capability). Such
+	 * controllers won't be available at RC probe time and their PERST#
+	 * should be controlled by the respective PCI client driver
+	 * implementation.
+	 */
+	gpio_np = of_parse_phandle(np, "reset-gpios", 0);
+	if (!gpio_np) {
+		dev_err(dev, "Failed to parse GPIO provider\n");
+		return -EINVAL;
+	}
+
+	if (qcom_pcie_is_child_node(dev, gpio_np)) {
+		of_node_put(gpio_np);
+		goto parse_child_node;
+	}
+	of_node_put(gpio_np);
+
 	reset = devm_fwnode_gpiod_get(dev, of_fwnode_handle(np), "reset",
 				      GPIOD_OUT_HIGH, "PERST#");
 	if (IS_ERR(reset)) {

---
base-commit: 5200f5f493f79f14bbdc349e402a40dfb32f23c8
change-id: 20260616-pci-qcom-perst-fix-00417aa57a96

Best regards,
--  
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

