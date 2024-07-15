From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Mon, 15 Jul 2024 23:03:48 +0530
Subject: [PATCH 06/14] PCI: endpoint: Assign PCI domain number for endpoint
 controllers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240715-pci-qcom-hotplug-v1-6-5f3765cc873a@linaro.org>
References: <20240715-pci-qcom-hotplug-v1-0-5f3765cc873a@linaro.org>
In-Reply-To: <20240715-pci-qcom-hotplug-v1-0-5f3765cc873a@linaro.org>
To: Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>
Cc: linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=openpgp-sha256; l=2371;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=BECkU4Os6kOoCK6Qfv68t/qW5FxIjT+Q5kndhCEtOC8=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmlV15F+kcwS5+/FEQPBlLHWbPgXesdW/M72MTi
 jRCb9LZ6RqJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZpVdeQAKCRBVnxHm/pHO
 9RpyCACSS3TlQfGlFVAKsoeJSe8dQG6CTaoBm5QHJxDiod8PIj9/kepgh3unKrlSjKH3NrHA8LW
 T3mT1GOAXHTeIculrZKZ2LCZSTWEWutKG/mDGXR3oNv2GC5E2EY5cF32Yrwd/RMWpHG0vuKkrpx
 yKjDMh3zTPOZDOzDIPe1F27RsgmoQVqgxdk9+DwrluZJjz9eXfKaWj76Axnupy6Nc1TPRFbhO53
 6zbJvq121HlgtYIRoChhSY0o7vopBiQk74jL4WKtUgZzh336aWq2cUi9+7mjkNaB9zRIV13FAGZ
 jWFYl5ADIqCZIGgQKl6raghKvnk0G5DqL7/UB1lI+BkxYv7W
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Right now, PCI endpoint subsystem doesn't assign PCI domain number for the
PCI endpoint controllers. But this domain number could be useful to the EPC
drivers to uniquely identify each controller based on the hardware instance
when there are multiple ones present in an SoC (even multiple RC/EP).

So let's make use of the existing pci_bus_find_domain_nr() API to allocate
domain numbers based on either Devicetree (linux,pci-domain) property or
dynamic domain number allocation scheme.

It should be noted that the domain number allocated by this API will be
based on both RC and EP controllers in a SoC. If the 'linux,pci-domain' DT
property is present, then the domain number represents the actual hardware
instance of the PCI endpoint controller. If not, then the domain number
will be allocated based on the PCI EP/RC controller probe order.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/endpoint/pci-epc-core.c | 1 +
 include/linux/pci-epc.h             | 2 ++
 2 files changed, 3 insertions(+)

diff --git a/drivers/pci/endpoint/pci-epc-core.c b/drivers/pci/endpoint/pci-epc-core.c
index 84309dfe0c68..7e8bf4ac003a 100644
--- a/drivers/pci/endpoint/pci-epc-core.c
+++ b/drivers/pci/endpoint/pci-epc-core.c
@@ -899,6 +899,7 @@ __pci_epc_create(struct device *dev, const struct pci_epc_ops *ops,
 	epc->dev.parent = dev;
 	epc->dev.release = pci_epc_release;
 	epc->ops = ops;
+	epc->domain_nr = pci_bus_find_domain_nr(NULL, dev);
 
 	ret = dev_set_name(&epc->dev, "%s", dev_name(dev));
 	if (ret)
diff --git a/include/linux/pci-epc.h b/include/linux/pci-epc.h
index 85bdf2adb760..8e3dcac55dcd 100644
--- a/include/linux/pci-epc.h
+++ b/include/linux/pci-epc.h
@@ -128,6 +128,7 @@ struct pci_epc_mem {
  * @group: configfs group representing the PCI EPC device
  * @lock: mutex to protect pci_epc ops
  * @function_num_map: bitmap to manage physical function number
+ * @domain_nr: PCI domain number of the endpoint controller
  * @init_complete: flag to indicate whether the EPC initialization is complete
  *                 or not
  */
@@ -145,6 +146,7 @@ struct pci_epc {
 	/* mutex to protect against concurrent access of EP controller */
 	struct mutex			lock;
 	unsigned long			function_num_map;
+	int				domain_nr;
 	bool				init_complete;
 };
 

-- 
2.25.1

