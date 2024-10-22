From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Tue, 22 Oct 2024 15:57:29 +0530
Subject: [PATCH 1/5] PCI/pwrctl: Use of_platform_device_create() to create
 pwrctl devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241022-pci-pwrctl-rework-v1-1-94a7e90f58c5@linaro.org>
References: <20241022-pci-pwrctl-rework-v1-0-94a7e90f58c5@linaro.org>
In-Reply-To: <20241022-pci-pwrctl-rework-v1-0-94a7e90f58c5@linaro.org>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Baryshkov <dmitry.baryshkov@linaro.org>, 
 Johan Hovold <johan+linaro@kernel.org>, Abel Vesa <abel.vesa@linaro.org>, 
 Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Srinivas Kandagatla <srinivas.kandagatla@linaro.org>, 
 Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1771;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=MGzatbYJniVLg7BZgRAG2FQoP+AtAWyuUZzih9eO9g4=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnF34utpei03sy9L2UxAgWs45Ed1FfiX7hVSSOx
 Q7B8FKTJnCJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZxd+LgAKCRBVnxHm/pHO
 9WgbB/9jmbynDRZTrQAupCu4BsISZu3OHHosTFflg8Ss3KvfJ86aP1cHNuegSpYBtwXYNIfSHu+
 8+LYfuz9Hot9J+WUzvFtpAi8g8o+tKnOlGhayndJneAInm04GhZRP5elSCtzVObI/c5iKPgk8SC
 /PVJUq+PKZRBxRE62p5IbnY3L1NW+doZ6QXSEtBrEDM5pfhOughejsMbCyNVRdrOBzDyyFigGCS
 mY0ZzLYne//VJ75TLQsdKrZUDvxHwlsg2PEfpaaqUX7q7DgCpqIbPhvKiZzphGS7+8cbm3Ev+vR
 y7OVOizOhxGfe7LKXAZjxaYRSIYwyhgjTDaDkW6mV2IF211A
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

of_platform_populate() API creates platform devices by descending through
the children of the parent node. But it provides no control over the child
nodes, which makes it difficult to add checks for the child nodes in the
future. So use of_platform_device_create() API together with
for_each_child_of_node_scoped() so that it is possible to add checks for
each node before creating the platform device.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/bus.c | 12 +++++++-----
 1 file changed, 7 insertions(+), 5 deletions(-)

diff --git a/drivers/pci/bus.c b/drivers/pci/bus.c
index 55c853686051..959044b059b5 100644
--- a/drivers/pci/bus.c
+++ b/drivers/pci/bus.c
@@ -13,6 +13,7 @@
 #include <linux/ioport.h>
 #include <linux/of.h>
 #include <linux/of_platform.h>
+#include <linux/platform_device.h>
 #include <linux/proc_fs.h>
 #include <linux/slab.h>
 
@@ -329,6 +330,7 @@ void __weak pcibios_bus_add_device(struct pci_dev *pdev) { }
 void pci_bus_add_device(struct pci_dev *dev)
 {
 	struct device_node *dn = dev->dev.of_node;
+	struct platform_device *pdev;
 	int retval;
 
 	/*
@@ -351,11 +353,11 @@ void pci_bus_add_device(struct pci_dev *dev)
 	pci_dev_assign_added(dev, true);
 
 	if (dev_of_node(&dev->dev) && pci_is_bridge(dev)) {
-		retval = of_platform_populate(dev_of_node(&dev->dev), NULL, NULL,
-					      &dev->dev);
-		if (retval)
-			pci_err(dev, "failed to populate child OF nodes (%d)\n",
-				retval);
+		for_each_child_of_node_scoped(dn, child) {
+			pdev = of_platform_device_create(child, NULL, &dev->dev);
+			if (!pdev)
+				pci_err(dev, "failed to create OF node: %s\n", child->name);
+		}
 	}
 }
 EXPORT_SYMBOL_GPL(pci_bus_add_device);

-- 
2.25.1

