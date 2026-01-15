From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Thu, 15 Jan 2026 12:59:01 +0530
Subject: [PATCH v5 09/15] PCI/pwrctrl: Add 'struct
 pci_pwrctrl::power_{on/off}' callbacks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260115-pci-pwrctrl-rework-v5-9-9d26da3ce903@oss.qualcomm.com>
References: <20260115-pci-pwrctrl-rework-v5-0-9d26da3ce903@oss.qualcomm.com>
In-Reply-To: <20260115-pci-pwrctrl-rework-v5-0-9d26da3ce903@oss.qualcomm.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Bartosz Golaszewski <brgl@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, Jingoo Han <jingoohan1@gmail.com>
Cc: linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Chen-Yu Tsai <wens@kernel.org>, 
 Brian Norris <briannorris@chromium.org>, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 Niklas Cassel <cassel@kernel.org>, Alex Elder <elder@riscstar.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Chen-Yu Tsai <wenst@chromium.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=5551;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=cgHzIAEsgNpOwxTB3hHxgFQ6227n1CTcovLsMGKsXc0=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpaJdCbwbZM/FEGqymRB6MoAXpaH0pdHnNTUxeQ
 Uif4gdfT3KJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaWiXQgAKCRBVnxHm/pHO
 9bnJB/wLlc37LesynXGPEY5Ry+XMkojfF3H/PaxNUzuvl94aOx28ZpDzr129LG5bN5iAcAmHnlY
 y4f/PEgIih9L+ueK4E236iIOB7Y9Bew5LtOWTidP4YQ8YNXD4PsvDDygmDtnTfQdQPm2hRRApoM
 mHu9F/ZgVdhsdUIZNl2fGe92783XW9EFogjBbWSd7bXaAHoCm5ZrIib4drXQoE/nm/lizaIVN0N
 cNHSquxsyxJFhzv9gkTk7AYI+nWAS2cAH88Klc1fl+I6gyble1QrLajqM/mD9N90r6ReoNix3RY
 lwTnEb3jF3HNYxGN6G4S5rg9cRaJUMfrXirN7bQFJ7IJJGQ0
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To allow the pwrctrl core to control the power on/off sequences of the
pwrctrl drivers, add the 'struct pci_pwrctrl::power_{on/off}' callbacks and
populate them in the respective pwrctrl drivers.

The pwrctrl drivers still power on the resources on their own now. So there
is no functional change.

Co-developed-by: Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>
Signed-off-by: Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Signed-off-by: Bjorn Helgaas <bhelgaas@google.com>
Tested-by: Chen-Yu Tsai <wenst@chromium.org>
Reviewed-by: Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>
---
 drivers/pci/pwrctrl/pci-pwrctrl-pwrseq.c |  3 +++
 drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c | 22 ++++++++++++++++------
 drivers/pci/pwrctrl/slot.c               |  3 +++
 include/linux/pci-pwrctrl.h              |  4 ++++
 4 files changed, 26 insertions(+), 6 deletions(-)

diff --git a/drivers/pci/pwrctrl/pci-pwrctrl-pwrseq.c b/drivers/pci/pwrctrl/pci-pwrctrl-pwrseq.c
index d2c261b09030..2ee02edd55a3 100644
--- a/drivers/pci/pwrctrl/pci-pwrctrl-pwrseq.c
+++ b/drivers/pci/pwrctrl/pci-pwrctrl-pwrseq.c
@@ -111,6 +111,9 @@ static int pci_pwrctrl_pwrseq_probe(struct platform_device *pdev)
 	if (ret)
 		return ret;
 
+	pwrseq->pwrctrl.power_on = pci_pwrctrl_pwrseq_power_on;
+	pwrseq->pwrctrl.power_off = pci_pwrctrl_pwrseq_power_off;
+
 	pci_pwrctrl_init(&pwrseq->pwrctrl, dev);
 
 	ret = devm_pci_pwrctrl_device_set_ready(dev, &pwrseq->pwrctrl);
diff --git a/drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c b/drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c
index 8ae27abdf362..a71d7ef2d4b8 100644
--- a/drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c
+++ b/drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c
@@ -450,15 +450,22 @@ static int tc9563_pwrctrl_parse_device_dt(struct pci_pwrctrl_tc9563 *tc9563,
 	return 0;
 }
 
-static void tc9563_pwrctrl_power_off(struct pci_pwrctrl_tc9563 *tc9563)
+static int tc9563_pwrctrl_power_off(struct pci_pwrctrl *pwrctrl)
 {
+	struct pci_pwrctrl_tc9563 *tc9563 = container_of(pwrctrl,
+					struct pci_pwrctrl_tc9563, pwrctrl);
+
 	gpiod_set_value(tc9563->reset_gpio, 1);
 
 	regulator_bulk_disable(ARRAY_SIZE(tc9563->supplies), tc9563->supplies);
+
+	return 0;
 }
 
-static int tc9563_pwrctrl_bring_up(struct pci_pwrctrl_tc9563 *tc9563)
+static int tc9563_pwrctrl_power_on(struct pci_pwrctrl *pwrctrl)
 {
+	struct pci_pwrctrl_tc9563 *tc9563 = container_of(pwrctrl,
+					struct pci_pwrctrl_tc9563, pwrctrl);
 	struct device *dev = tc9563->pwrctrl.dev;
 	struct tc9563_pwrctrl_cfg *cfg;
 	int ret, i;
@@ -520,7 +527,7 @@ static int tc9563_pwrctrl_bring_up(struct pci_pwrctrl_tc9563 *tc9563)
 		return 0;
 
 power_off:
-	tc9563_pwrctrl_power_off(tc9563);
+	tc9563_pwrctrl_power_off(&tc9563->pwrctrl);
 	return ret;
 }
 
@@ -613,7 +620,7 @@ static int tc9563_pwrctrl_probe(struct platform_device *pdev)
 			goto remove_i2c;
 	}
 
-	ret = tc9563_pwrctrl_bring_up(tc9563);
+	ret = tc9563_pwrctrl_power_on(&tc9563->pwrctrl);
 	if (ret)
 		goto remove_i2c;
 
@@ -623,6 +630,9 @@ static int tc9563_pwrctrl_probe(struct platform_device *pdev)
 			goto power_off;
 	}
 
+	tc9563->pwrctrl.power_on = tc9563_pwrctrl_power_on;
+	tc9563->pwrctrl.power_off = tc9563_pwrctrl_power_off;
+
 	ret = devm_pci_pwrctrl_device_set_ready(dev, &tc9563->pwrctrl);
 	if (ret)
 		goto power_off;
@@ -632,7 +642,7 @@ static int tc9563_pwrctrl_probe(struct platform_device *pdev)
 	return 0;
 
 power_off:
-	tc9563_pwrctrl_power_off(tc9563);
+	tc9563_pwrctrl_power_off(&tc9563->pwrctrl);
 remove_i2c:
 	i2c_unregister_device(tc9563->client);
 	put_device(&tc9563->adapter->dev);
@@ -643,7 +653,7 @@ static void tc9563_pwrctrl_remove(struct platform_device *pdev)
 {
 	struct pci_pwrctrl_tc9563 *tc9563 = platform_get_drvdata(pdev);
 
-	tc9563_pwrctrl_power_off(tc9563);
+	tc9563_pwrctrl_power_off(&tc9563->pwrctrl);
 	i2c_unregister_device(tc9563->client);
 	put_device(&tc9563->adapter->dev);
 }
diff --git a/drivers/pci/pwrctrl/slot.c b/drivers/pci/pwrctrl/slot.c
index 5d0ec880c0ec..55828aec2486 100644
--- a/drivers/pci/pwrctrl/slot.c
+++ b/drivers/pci/pwrctrl/slot.c
@@ -85,6 +85,9 @@ static int pci_pwrctrl_slot_probe(struct platform_device *pdev)
 
 	pci_pwrctrl_slot_power_on(&slot->pwrctrl);
 
+	slot->pwrctrl.power_on = pci_pwrctrl_slot_power_on;
+	slot->pwrctrl.power_off = pci_pwrctrl_slot_power_off;
+
 	pci_pwrctrl_init(&slot->pwrctrl, dev);
 
 	ret = devm_pci_pwrctrl_device_set_ready(dev, &slot->pwrctrl);
diff --git a/include/linux/pci-pwrctrl.h b/include/linux/pci-pwrctrl.h
index 4aefc7901cd1..435b822c841e 100644
--- a/include/linux/pci-pwrctrl.h
+++ b/include/linux/pci-pwrctrl.h
@@ -31,6 +31,8 @@ struct device_link;
 /**
  * struct pci_pwrctrl - PCI device power control context.
  * @dev: Address of the power controlling device.
+ * @power_on: Callback to power on the power controlling device.
+ * @power_off: Callback to power off the power controlling device.
  *
  * An object of this type must be allocated by the PCI power control device and
  * passed to the pwrctrl subsystem to trigger a bus rescan and setup a device
@@ -38,6 +40,8 @@ struct device_link;
  */
 struct pci_pwrctrl {
 	struct device *dev;
+	int (*power_on)(struct pci_pwrctrl *pwrctrl);
+	int (*power_off)(struct pci_pwrctrl *pwrctrl);
 
 	/* private: internal use only */
 	struct notifier_block nb;

-- 
2.48.1

