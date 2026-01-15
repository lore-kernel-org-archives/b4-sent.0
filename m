From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Thu, 15 Jan 2026 12:58:54 +0530
Subject: [PATCH v5 02/15] PCI/pwrctrl: slot: Rename private struct and
 pointers for consistency
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260115-pci-pwrctrl-rework-v5-2-9d26da3ce903@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2784;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=44NVPWUXPuZjfLmJawVYZKHEmFFDsDqRXpz45pIkiiE=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpaJdBuIQNE5ifaCycNCiMPUkxX8+/GtEeFUCk1
 l5byjks6keJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaWiXQQAKCRBVnxHm/pHO
 9ZR/B/46p6o8wAxDjXi2SM97q9/E2HUBtSnn7zcX4kUMv/K8lHL4AcAN9IqScIvsv3FH0coTVpX
 YST09swQHNq9GRC+U48qNKlXB8AWPU4GBNjXMDM9CuqQGnthgu5CLdvq7bjQJYLvH5G+rGbZtyt
 Pyrr6+cYYVlORSUZQrdlTiEat4r5NeyHJXQi7GZ88mrcVQzXKtJGRqYgqX42iUQo5rUptIERpg6
 1pKuJ62+cx5ylqg+xQaxFf1O+mNFiItwYYw+h7ae/aiNPyj+hffz5qur2mDMBYwl6bvlc3+MH+P
 amHiXxjdYqdMWBC/XwWIqTRnABJpzgc18A58ftXPcHIFzpY/
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Bjorn Helgaas <bhelgaas@google.com>

Previously the pwrseq, tc9563, and slot pwrctrl drivers used different
naming conventions for their private data structs and pointers to them,
which makes patches hard to read:

  Previous names                         New names
  ------------------------------------   ----------------------------------
  struct pci_pwrctrl_pwrseq_data {       struct pci_pwrctrl_pwrseq {
    struct pci_pwrctrl ctx;                struct pci_pwrctrl pwrctrl;
  struct pci_pwrctrl_pwrseq_data *data   struct pci_pwrctrl_pwrseq *pwrseq

  struct tc9563_pwrctrl_ctx {            struct pci_pwrctrl_tc9563 {
  struct tc9563_pwrctrl_ctx *ctx         struct pci_pwrctrl_tc9563 *tc9563

  struct pci_pwrctrl_slot_data {         struct pci_pwrctrl_slot {
    struct pci_pwrctrl ctx;                struct pci_pwrctrl pwrctrl;
  struct pci_pwrctrl_slot_data *slot     struct pci_pwrctrl_slot *slot

Rename "struct pci_pwrctrl_slot_data" to "struct pci_pwrctrl_slot".

Rename the "struct pci_pwrctrl ctx" member to "struct pci_pwrctrl pwrctrl".

No functional change intended.

Signed-off-by: Bjorn Helgaas <bhelgaas@google.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/pwrctrl/slot.c | 12 ++++++------
 1 file changed, 6 insertions(+), 6 deletions(-)

diff --git a/drivers/pci/pwrctrl/slot.c b/drivers/pci/pwrctrl/slot.c
index 3320494b62d8..5ddae4ae3431 100644
--- a/drivers/pci/pwrctrl/slot.c
+++ b/drivers/pci/pwrctrl/slot.c
@@ -13,15 +13,15 @@
 #include <linux/regulator/consumer.h>
 #include <linux/slab.h>
 
-struct pci_pwrctrl_slot_data {
-	struct pci_pwrctrl ctx;
+struct pci_pwrctrl_slot {
+	struct pci_pwrctrl pwrctrl;
 	struct regulator_bulk_data *supplies;
 	int num_supplies;
 };
 
 static void devm_pci_pwrctrl_slot_power_off(void *data)
 {
-	struct pci_pwrctrl_slot_data *slot = data;
+	struct pci_pwrctrl_slot *slot = data;
 
 	regulator_bulk_disable(slot->num_supplies, slot->supplies);
 	regulator_bulk_free(slot->num_supplies, slot->supplies);
@@ -29,7 +29,7 @@ static void devm_pci_pwrctrl_slot_power_off(void *data)
 
 static int pci_pwrctrl_slot_probe(struct platform_device *pdev)
 {
-	struct pci_pwrctrl_slot_data *slot;
+	struct pci_pwrctrl_slot *slot;
 	struct device *dev = &pdev->dev;
 	struct clk *clk;
 	int ret;
@@ -64,9 +64,9 @@ static int pci_pwrctrl_slot_probe(struct platform_device *pdev)
 				     "Failed to enable slot clock\n");
 	}
 
-	pci_pwrctrl_init(&slot->ctx, dev);
+	pci_pwrctrl_init(&slot->pwrctrl, dev);
 
-	ret = devm_pci_pwrctrl_device_set_ready(dev, &slot->ctx);
+	ret = devm_pci_pwrctrl_device_set_ready(dev, &slot->pwrctrl);
 	if (ret)
 		return dev_err_probe(dev, ret, "Failed to register pwrctrl driver\n");
 

-- 
2.48.1

