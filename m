From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Tue, 31 Dec 2024 15:13:47 +0530
Subject: [PATCH v2 6/6] PCI/pwrctrl: Add pwrctrl driver for PCI Slots
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241231-pci-pwrctrl-slot-v2-6-6a15088ba541@linaro.org>
References: <20241231-pci-pwrctrl-slot-v2-0-6a15088ba541@linaro.org>
In-Reply-To: <20241231-pci-pwrctrl-slot-v2-0-6a15088ba541@linaro.org>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Qiang Yu <quic_qianyu@quicinc.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=5046;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=5dX65BdkoJK96uXxbW3egypDqFuEy1NtN49QNZGGNsE=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnc7zr7I0vWAahaKk1DBFdKMQZ91pYlEUDFnSrL
 RAnljRPpcCJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ3O86wAKCRBVnxHm/pHO
 9cZWB/91OJ2SOc0tiIbMRhbFZqRG+z01zOJH0m32xtqf6742piljnQrylYQ0cLvKDgZm445jn1V
 9lM71Iz+aCLBEZeF2hbBdtEEIh6CmRUBDB+YcpwOsb7P0HVnbmt8ECjXQsu7cEQabuuRyyVzFtf
 aORILbefzyiIoeOsyKrPYsslnxx4gQp8c9r3+97crDAgA5yK3odKXzPuNkJk63tGJAWgRSJ1+zx
 LOlHQktW5LyVKJOTT4BAMyuT7SnHlpFa7KJo1+po33EXCoJSl0lceV6j7SEWq5PVlPB1eJvMoab
 wZ9qu9kz1JIVcWWwSz4OKGmpmlrqOftdCZVwfks/eeqg3mN8
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This driver is used to control the power state of the devices attached to
the PCI slots. Currently, it controls the voltage rails of the PCI slots
defined in the devicetree node of the root port.

The voltage rails for PCI slots are documented in the dt-schema:
https://github.com/devicetree-org/dt-schema/blob/v2024.11/dtschema/schemas/pci/pci-bus-common.yaml#L153

Since this driver has to work with different kind of slots (x{1/4/8/16}
PCIe, Mini PCIe, PCI etc...), the driver is using the
of_regulator_bulk_get_all() API to obtain the voltage regulators defined
in the DT node, instead of hardcoding them. The DT node of the root port
should define the relevant supply properties corresponding to the voltage
rails of the PCI slot.

Tested-by: Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/pwrctrl/Kconfig  | 11 ++++++
 drivers/pci/pwrctrl/Makefile |  3 ++
 drivers/pci/pwrctrl/slot.c   | 93 ++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 107 insertions(+)

diff --git a/drivers/pci/pwrctrl/Kconfig b/drivers/pci/pwrctrl/Kconfig
index 54589bb2403b..990cab67d413 100644
--- a/drivers/pci/pwrctrl/Kconfig
+++ b/drivers/pci/pwrctrl/Kconfig
@@ -10,3 +10,14 @@ config PCI_PWRCTL_PWRSEQ
 	tristate
 	select POWER_SEQUENCING
 	select PCI_PWRCTL
+
+config PCI_PWRCTL_SLOT
+	tristate "PCI Power Control driver for PCI slots"
+	select PCI_PWRCTL
+	help
+	  Say Y here to enable the PCI Power Control driver to control the power
+	  state of PCI slots.
+
+	  This is a generic driver that controls the power state of different
+	  PCI slots. The voltage regulators powering the rails of the PCI slots
+	  are expected to be defined in the devicetree node of the PCI bridge.
diff --git a/drivers/pci/pwrctrl/Makefile b/drivers/pci/pwrctrl/Makefile
index 75c7ce531c7e..ddfb12c5aadf 100644
--- a/drivers/pci/pwrctrl/Makefile
+++ b/drivers/pci/pwrctrl/Makefile
@@ -4,3 +4,6 @@ obj-$(CONFIG_PCI_PWRCTL)		+= pci-pwrctrl-core.o
 pci-pwrctrl-core-y			:= core.o
 
 obj-$(CONFIG_PCI_PWRCTL_PWRSEQ)		+= pci-pwrctrl-pwrseq.o
+
+obj-$(CONFIG_PCI_PWRCTL_SLOT)		+= pci-pwrctl-slot.o
+pci-pwrctl-slot-y			:= slot.o
diff --git a/drivers/pci/pwrctrl/slot.c b/drivers/pci/pwrctrl/slot.c
new file mode 100644
index 000000000000..18becc144913
--- /dev/null
+++ b/drivers/pci/pwrctrl/slot.c
@@ -0,0 +1,93 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (C) 2024 Linaro Ltd.
+ * Author: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
+ */
+
+#include <linux/device.h>
+#include <linux/mod_devicetable.h>
+#include <linux/module.h>
+#include <linux/pci-pwrctrl.h>
+#include <linux/platform_device.h>
+#include <linux/regulator/consumer.h>
+#include <linux/slab.h>
+
+struct pci_pwrctrl_slot_data {
+	struct pci_pwrctrl ctx;
+	struct regulator_bulk_data *supplies;
+	int num_supplies;
+};
+
+static void devm_pci_pwrctrl_slot_power_off(void *data)
+{
+	struct pci_pwrctrl_slot_data *slot = data;
+
+	regulator_bulk_disable(slot->num_supplies, slot->supplies);
+	regulator_bulk_free(slot->num_supplies, slot->supplies);
+}
+
+static int pci_pwrctrl_slot_probe(struct platform_device *pdev)
+{
+	struct pci_pwrctrl_slot_data *slot;
+	struct device *dev = &pdev->dev;
+	int ret;
+
+	slot = devm_kzalloc(dev, sizeof(*slot), GFP_KERNEL);
+	if (!slot)
+		return -ENOMEM;
+
+	ret = of_regulator_bulk_get_all(dev, dev_of_node(dev),
+					&slot->supplies);
+	if (ret < 0) {
+		dev_err_probe(dev, ret, "Failed to get slot regulators\n");
+		return ret;
+	}
+
+	slot->num_supplies = ret;
+	ret = regulator_bulk_enable(slot->num_supplies, slot->supplies);
+	if (ret < 0) {
+		dev_err_probe(dev, ret, "Failed to enable slot regulators\n");
+		goto err_regulator_free;
+	}
+
+	ret = devm_add_action_or_reset(dev, devm_pci_pwrctrl_slot_power_off,
+				       slot);
+	if (ret)
+		goto err_regulator_disable;
+
+	pci_pwrctrl_init(&slot->ctx, dev);
+
+	ret = devm_pci_pwrctrl_device_set_ready(dev, &slot->ctx);
+	if (ret)
+		return dev_err_probe(dev, ret, "Failed to register pwrctrl driver\n");
+
+	return 0;
+
+err_regulator_disable:
+	regulator_bulk_disable(slot->num_supplies, slot->supplies);
+err_regulator_free:
+	regulator_bulk_free(slot->num_supplies, slot->supplies);
+
+	return ret;
+}
+
+static const struct of_device_id pci_pwrctrl_slot_of_match[] = {
+	{
+		.compatible = "pciclass,0604",
+	},
+	{ }
+};
+MODULE_DEVICE_TABLE(of, pci_pwrctrl_slot_of_match);
+
+static struct platform_driver pci_pwrctrl_slot_driver = {
+	.driver = {
+		.name = "pci-pwrctrl-slot",
+		.of_match_table = pci_pwrctrl_slot_of_match,
+	},
+	.probe = pci_pwrctrl_slot_probe,
+};
+module_platform_driver(pci_pwrctrl_slot_driver);
+
+MODULE_AUTHOR("Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>");
+MODULE_DESCRIPTION("Generic PCI Power Control driver for PCI Slots");
+MODULE_LICENSE("GPL");

-- 
2.25.1

