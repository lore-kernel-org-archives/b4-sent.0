From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 17 Jul 2024 22:33:10 +0530
Subject: [PATCH v2 05/13] PCI: endpoint: Assign PCI domain number for
 endpoint controllers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240717-pci-qcom-hotplug-v2-5-71d304b817f8@linaro.org>
References: <20240717-pci-qcom-hotplug-v2-0-71d304b817f8@linaro.org>
In-Reply-To: <20240717-pci-qcom-hotplug-v2-0-71d304b817f8@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3043;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=RgNx60ASNj1W+S8yTFl/XDFmb63UnDz74gKp1lFMkIw=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBml/lNJr0HPlA1u3KlDHSrQVmia8YznHXb4MGCI
 eq+KVVpCtqJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZpf5TQAKCRBVnxHm/pHO
 9c1MCACf1G9ULGICZoGu33tG6Da4yMhnoVZQjnNzAGUwjufpNwuc57Ze/yb8vcYtVdyV2KjvcjX
 o+sBZj0mbpbo5lOVD3A8/MLJppD2S1Bb3OEmPpHHkS5T8fIDxxgs+RBXEUriO6Ebl1hNkplz/c4
 7LT1QmMbpF5+94YFGvgalfAy3rsjOZFp5rVxHC023qBvNY6CAQkjbic6wEFJOgjMsBM9BQA3CdJ
 w74vH+FZ2zuG3n1wCXTgMQBa9xfgFTuCD3ycjuaS/YzakIwGTi8WNH8s6n62TKSD2Dj7OjTmZXP
 HEi3phA1+SkPddEz41ZiSCOp0YYI3o5DnWg4FjV1KdJcnBfT
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

If the architecture doesn't support CONFIG_PCI_DOMAINS_GENERIC (rare), then
currently a warning is thrown to indicate that the architecture specific
implementation is needed.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/endpoint/pci-epc-core.c | 10 ++++++++++
 include/linux/pci-epc.h             |  2 ++
 2 files changed, 12 insertions(+)

diff --git a/drivers/pci/endpoint/pci-epc-core.c b/drivers/pci/endpoint/pci-epc-core.c
index 84309dfe0c68..7fa81b91e762 100644
--- a/drivers/pci/endpoint/pci-epc-core.c
+++ b/drivers/pci/endpoint/pci-epc-core.c
@@ -838,6 +838,9 @@ void pci_epc_destroy(struct pci_epc *epc)
 {
 	pci_ep_cfs_remove_epc_group(epc->group);
 	device_unregister(&epc->dev);
+
+	if (IS_ENABLED(CONFIG_PCI_DOMAINS_GENERIC))
+		pci_bus_release_domain_nr(NULL, &epc->dev);
 }
 EXPORT_SYMBOL_GPL(pci_epc_destroy);
 
@@ -900,6 +903,13 @@ __pci_epc_create(struct device *dev, const struct pci_epc_ops *ops,
 	epc->dev.release = pci_epc_release;
 	epc->ops = ops;
 
+	/*
+	 * TODO: If the architecture doesn't support generic PCI domains, then
+	 * a custom implementation has to be used.
+	 */
+	if (!WARN_ON_ONCE(!IS_ENABLED(CONFIG_PCI_DOMAINS_GENERIC)))
+		epc->domain_nr = pci_bus_find_domain_nr(NULL, dev);
+
 	ret = dev_set_name(&epc->dev, "%s", dev_name(dev));
 	if (ret)
 		goto put_dev;
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

