From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Thu, 15 Jan 2026 12:58:59 +0530
Subject: [PATCH v5 07/15] PCI/pwrctrl: slot: Factor out power on/off code
 to helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260115-pci-pwrctrl-rework-v5-7-9d26da3ce903@oss.qualcomm.com>
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
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2990;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=07P0XaSjsiTGjrvp6TvDoXT8i9vHCPaPhJUm8tU3mqw=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpaJdBfKkjKhqbNYu+PfvSiPL+Tf7KgumdswJHu
 afvm0WDU9+JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaWiXQQAKCRBVnxHm/pHO
 9VezB/0dkWi9FcYkQhbWq9qAYA64hxZsy6mDqFh7ROFgS04OVk5s4WYR3jGxqDjwtR9XO1brYym
 yK83n+EV7t62tZC/ojYWggCrz2uqRgGPwQVC3xPJiw970kVvZJbGAICJx32vqKbAcjJRK2rA130
 PPmHn1Aw5w/ky/hjBYKnNj19fDRZZVvwRiu9UJqCAbI6z3lrlzwYOx92/OeEBNpbV3y41LmrT53
 uyNi3BPmPqS85UcEHGApNcIVUiFtRm5B9Pvi1BLNWxf9B729O/HfNXcpEzcik+9aGdBKZe3cMrR
 39JhKzaeGciYGgcyQDfr8SfztQQFh3H/wcP9fKpZygtCIqYD
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In order to allow the pwrctrl core to control the power on/off logic of the
pwrctrl slot driver, move the power on/off code to
pci_pwrctrl_slot_power_{off/on} helper functions.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/pwrctrl/slot.c | 49 +++++++++++++++++++++++++++++++++-------------
 1 file changed, 35 insertions(+), 14 deletions(-)

diff --git a/drivers/pci/pwrctrl/slot.c b/drivers/pci/pwrctrl/slot.c
index 5ddae4ae3431..5d0ec880c0ec 100644
--- a/drivers/pci/pwrctrl/slot.c
+++ b/drivers/pci/pwrctrl/slot.c
@@ -17,13 +17,40 @@ struct pci_pwrctrl_slot {
 	struct pci_pwrctrl pwrctrl;
 	struct regulator_bulk_data *supplies;
 	int num_supplies;
+	struct clk *clk;
 };
 
-static void devm_pci_pwrctrl_slot_power_off(void *data)
+static int pci_pwrctrl_slot_power_on(struct pci_pwrctrl *pwrctrl)
 {
-	struct pci_pwrctrl_slot *slot = data;
+	struct pci_pwrctrl_slot *slot = container_of(pwrctrl,
+					    struct pci_pwrctrl_slot, pwrctrl);
+	int ret;
+
+	ret = regulator_bulk_enable(slot->num_supplies, slot->supplies);
+	if (ret < 0) {
+		dev_err(slot->pwrctrl.dev, "Failed to enable slot regulators\n");
+		return ret;
+	}
+
+	return clk_prepare_enable(slot->clk);
+}
+
+static int pci_pwrctrl_slot_power_off(struct pci_pwrctrl *pwrctrl)
+{
+	struct pci_pwrctrl_slot *slot = container_of(pwrctrl,
+					    struct pci_pwrctrl_slot, pwrctrl);
 
 	regulator_bulk_disable(slot->num_supplies, slot->supplies);
+	clk_disable_unprepare(slot->clk);
+
+	return 0;
+}
+
+static void devm_pci_pwrctrl_slot_release(void *data)
+{
+	struct pci_pwrctrl_slot *slot = data;
+
+	pci_pwrctrl_slot_power_off(&slot->pwrctrl);
 	regulator_bulk_free(slot->num_supplies, slot->supplies);
 }
 
@@ -31,7 +58,6 @@ static int pci_pwrctrl_slot_probe(struct platform_device *pdev)
 {
 	struct pci_pwrctrl_slot *slot;
 	struct device *dev = &pdev->dev;
-	struct clk *clk;
 	int ret;
 
 	slot = devm_kzalloc(dev, sizeof(*slot), GFP_KERNEL);
@@ -46,23 +72,18 @@ static int pci_pwrctrl_slot_probe(struct platform_device *pdev)
 	}
 
 	slot->num_supplies = ret;
-	ret = regulator_bulk_enable(slot->num_supplies, slot->supplies);
-	if (ret < 0) {
-		dev_err_probe(dev, ret, "Failed to enable slot regulators\n");
-		regulator_bulk_free(slot->num_supplies, slot->supplies);
-		return ret;
-	}
 
-	ret = devm_add_action_or_reset(dev, devm_pci_pwrctrl_slot_power_off,
+	ret = devm_add_action_or_reset(dev, devm_pci_pwrctrl_slot_release,
 				       slot);
 	if (ret)
 		return ret;
 
-	clk = devm_clk_get_optional_enabled(dev, NULL);
-	if (IS_ERR(clk)) {
-		return dev_err_probe(dev, PTR_ERR(clk),
+	slot->clk = devm_clk_get_optional(dev, NULL);
+	if (IS_ERR(slot->clk))
+		return dev_err_probe(dev, PTR_ERR(slot->clk),
 				     "Failed to enable slot clock\n");
-	}
+
+	pci_pwrctrl_slot_power_on(&slot->pwrctrl);
 
 	pci_pwrctrl_init(&slot->pwrctrl, dev);
 

-- 
2.48.1

