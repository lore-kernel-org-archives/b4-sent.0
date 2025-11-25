From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 25 Nov 2025 16:42:28 +0530
Subject: [PATCH v3 3/4] PCI/pwrctrl: Create pwrctrl device if the graph
 port is found
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251125-pci-m2-v3-3-c528042aea47@oss.qualcomm.com>
References: <20251125-pci-m2-v3-0-c528042aea47@oss.qualcomm.com>
In-Reply-To: <20251125-pci-m2-v3-0-c528042aea47@oss.qualcomm.com>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-kernel@vger.kernel.org, linux-pci@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 linux-pm@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1400;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=85qx2Om/7njPst0xF59AZpGkw5zpMb/2p4I8tf0rGZI=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpJY8d8dHupd6VCH/oWWZ7QPaB9MbZJaUhUHcND
 zboN2Jf2ECJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaSWPHQAKCRBVnxHm/pHO
 9TkcB/9SuTMoRU5JJS6C646WFkzzsHd2Ulg4rKImNms7pLcqqyrc6/P7U0Bco+g0Cax4FvkIJzy
 iF/h8h/aXc+tjDqcq//6cF6mYbyfUxH22QfN0ePqMWbFkQ8TbV/mVKwLOqjexHCzX3AtMvuUuhi
 xKOUsCwhpKncFXKZ4lFt76UehmJiKM8bfEW0G6ILwrcuSmrIFs3osDINLRceMHuN2/54MEb1iYf
 y07jsNw+NtFtNEBcQ4MaXNK1Dg3p2xrjlG9jT3Dsfw8Fo1hFo5q9pedfto3QmEcuQyFsq8VBkUm
 AEqmE7RCcFuAw/UEp4ZiWk5C7HcNKIV0lzQdlrQc61jzdTEv
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The devicetree node of the PCIe Root Port/Slot could have the graph port
to link the PCIe M.2 connector node. Since the M.2 connectors are modelled
as Power Sequencing devices, they need to be controlled by the pwrctrl
driver as like the Root Port/Slot supplies.

Hence, create the pwrctrl device if the graph port is found in the node.

Reviewed-by: Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/probe.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/pci/probe.c b/drivers/pci/probe.c
index c83e75a0ec12..9c8669e2fe72 100644
--- a/drivers/pci/probe.c
+++ b/drivers/pci/probe.c
@@ -9,6 +9,7 @@
 #include <linux/init.h>
 #include <linux/pci.h>
 #include <linux/msi.h>
+#include <linux/of_graph.h>
 #include <linux/of_pci.h>
 #include <linux/of_platform.h>
 #include <linux/platform_device.h>
@@ -2555,7 +2556,7 @@ static struct platform_device *pci_pwrctrl_create_device(struct pci_bus *bus, in
 	 * not. This is decided based on at least one of the power supplies
 	 * being defined in the devicetree node of the device.
 	 */
-	if (!of_pci_supply_present(np)) {
+	if (!of_pci_supply_present(np) && !of_graph_is_present(np)) {
 		pr_debug("PCI/pwrctrl: Skipping OF node: %s\n", np->name);
 		goto err_put_of_node;
 	}

-- 
2.48.1

