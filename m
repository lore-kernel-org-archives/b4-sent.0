From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 07 Jan 2026 19:41:25 +0530
Subject: [PATCH v5 3/5] PCI/pwrctrl: Add support for handling PCIe M.2
 connectors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260107-pci-m2-v5-3-8173d8a72641@oss.qualcomm.com>
References: <20260107-pci-m2-v5-0-8173d8a72641@oss.qualcomm.com>
In-Reply-To: <20260107-pci-m2-v5-0-8173d8a72641@oss.qualcomm.com>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bartosz Golaszewski <brgl@bgdev.pl>, 
 Damien Le Moal <dlemoal@kernel.org>, Niklas Cassel <cassel@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-pci@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 linux-pm@vger.kernel.org, linux-ide@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3872;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=AO6DA+THdUbk+4mox05j2FvqW5j/957nknRRq0lgeZo=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpXmmLbuanTaixUENX17ESNDeHEkjjUvEDpSHQq
 OIa/nKMk+OJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaV5piwAKCRBVnxHm/pHO
 9Yi1B/0SOYOlEeLDDD9jX9NWp3N+YIh9dJRecwZiEMGM9fNtU2UZGhUw0UksS+n+ZGt38guam1W
 p0f/qe5dKiVO/AvyJ12bHt/eePY77qkMqMptJt+Q1TGy4ym3x7jl8QwDXcyZLfHtpNUZ3J/wfxC
 8YPRzY67gCxUmH7ffcGsiXKtDsmuMM4ltoKJZKB+1jTPfpt1Ll3eaFE0Th6ARW68OwyubaTmVjJ
 AJsKahYs/3BOZtT+fQkk3aTfmRGi3NB9WwZARsJo1B/a/UkiU3AroFrG9enqF2mA81g+sR1YdMY
 Yzng0kQP+4EMzqKCiauWJ2qcCsf3fYVwBXvUDhGBcdFGhI/6
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for handling the PCIe M.2 connectors as Power Sequencing
devices. These connectors are exposed as the Power Sequencing devices
as they often support multiple interfaces like PCIe/SATA, USB/UART to the
host machine and each interfaces could be driven by different client
drivers at the same time.

This driver handles the PCIe interface of these connectors. It first checks
for the presence of the graph port in the Root Port node with the help of
of_graph_is_present() API, if present, it acquires/poweres ON the
corresponding pwrseq device.

Once the pwrseq device is powered ON, the driver will skip parsing the Root
Port/Slot resources and registers with the pwrctrl framework.

Reviewed-by: Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/pwrctrl/Kconfig |  1 +
 drivers/pci/pwrctrl/slot.c  | 35 ++++++++++++++++++++++++++++++-----
 2 files changed, 31 insertions(+), 5 deletions(-)

diff --git a/drivers/pci/pwrctrl/Kconfig b/drivers/pci/pwrctrl/Kconfig
index e0f999f299bb..cd3aa15bad00 100644
--- a/drivers/pci/pwrctrl/Kconfig
+++ b/drivers/pci/pwrctrl/Kconfig
@@ -13,6 +13,7 @@ config PCI_PWRCTRL_PWRSEQ
 
 config PCI_PWRCTRL_SLOT
 	tristate "PCI Power Control driver for PCI slots"
+	select POWER_SEQUENCING
 	select PCI_PWRCTRL
 	help
 	  Say Y here to enable the PCI Power Control driver to control the power
diff --git a/drivers/pci/pwrctrl/slot.c b/drivers/pci/pwrctrl/slot.c
index 3320494b62d8..d46c2365208a 100644
--- a/drivers/pci/pwrctrl/slot.c
+++ b/drivers/pci/pwrctrl/slot.c
@@ -8,8 +8,10 @@
 #include <linux/device.h>
 #include <linux/mod_devicetable.h>
 #include <linux/module.h>
+#include <linux/of_graph.h>
 #include <linux/pci-pwrctrl.h>
 #include <linux/platform_device.h>
+#include <linux/pwrseq/consumer.h>
 #include <linux/regulator/consumer.h>
 #include <linux/slab.h>
 
@@ -17,12 +19,18 @@ struct pci_pwrctrl_slot_data {
 	struct pci_pwrctrl ctx;
 	struct regulator_bulk_data *supplies;
 	int num_supplies;
+	struct pwrseq_desc *pwrseq;
 };
 
 static void devm_pci_pwrctrl_slot_power_off(void *data)
 {
 	struct pci_pwrctrl_slot_data *slot = data;
 
+	if (slot->pwrseq) {
+		pwrseq_power_off(slot->pwrseq);
+		return;
+	}
+
 	regulator_bulk_disable(slot->num_supplies, slot->supplies);
 	regulator_bulk_free(slot->num_supplies, slot->supplies);
 }
@@ -38,6 +46,20 @@ static int pci_pwrctrl_slot_probe(struct platform_device *pdev)
 	if (!slot)
 		return -ENOMEM;
 
+	if (of_graph_is_present(dev_of_node(dev))) {
+		slot->pwrseq = devm_pwrseq_get(dev, "pcie");
+		if (IS_ERR(slot->pwrseq))
+			return dev_err_probe(dev, PTR_ERR(slot->pwrseq),
+				     "Failed to get the power sequencer\n");
+
+		ret = pwrseq_power_on(slot->pwrseq);
+		if (ret)
+			return dev_err_probe(dev, ret,
+				     "Failed to power-on the device\n");
+
+		goto skip_resources;
+	}
+
 	ret = of_regulator_bulk_get_all(dev, dev_of_node(dev),
 					&slot->supplies);
 	if (ret < 0) {
@@ -53,17 +75,20 @@ static int pci_pwrctrl_slot_probe(struct platform_device *pdev)
 		return ret;
 	}
 
-	ret = devm_add_action_or_reset(dev, devm_pci_pwrctrl_slot_power_off,
-				       slot);
-	if (ret)
-		return ret;
-
 	clk = devm_clk_get_optional_enabled(dev, NULL);
 	if (IS_ERR(clk)) {
+		regulator_bulk_disable(slot->num_supplies, slot->supplies);
+		regulator_bulk_free(slot->num_supplies, slot->supplies);
 		return dev_err_probe(dev, PTR_ERR(clk),
 				     "Failed to enable slot clock\n");
 	}
 
+skip_resources:
+	ret = devm_add_action_or_reset(dev, devm_pci_pwrctrl_slot_power_off,
+				       slot);
+	if (ret)
+		return ret;
+
 	pci_pwrctrl_init(&slot->ctx, dev);
 
 	ret = devm_pci_pwrctrl_device_set_ready(dev, &slot->ctx);

-- 
2.48.1

