From: Sven Peter <sven@svenpeter.dev>
Date: Sun, 02 Jun 2024 09:57:05 +0000
Subject: [PATCH] Bluetooth: hci_bcm4377: Add BCM4388 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240602-btbcm4388-v1-1-210e4b4eeb3b@svenpeter.dev>
X-B4-Tracking: v=1; b=H4sIAPBBXGYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDMwMj3aSSpORcE2MLC10TY8PE1BRLgxRzM2MloPqCotS0zAqwWdGxtbU
 AgC4e91sAAAA=
To: Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Hector Martin <marcan@marcan.st>, Alyssa Rosenzweig <alyssa@rosenzweig.io>
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Sven Peter <sven@svenpeter.dev>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=8598; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=hBpmMDY7wBVHwKgfEbk3URNsOlwPdvTDeeJohMrHkUs=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ1qMk8StjD0f3e3/KgR/4r8n3HC2cf10/0ceuvfSJjW1T
 mLh33i2o5SFQYyDQVZMkWX7fnvTJw/fCC7ddOk9zBxWJpAhDFycAjCRx6KMDEtPXXEWdSxiO1b+
 Py0rrfeDazpvL3P7vQmnQq4K1h69UMLIMPPJ714/9TPVfLVZe42i/9yaLiXO/2WTad31t37psQY
 rOQA=
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

This new variant needs a different core2_window1 and always uses
beamforming.
The BAR2 also has an offset (RAM start, presumably), so add that.

Signed-off-by: Hector Martin <marcan@marcan.st>
Reviewed-by: Sven Peter <sven@svenpeter.dev>
[sven: rebased, updated some comments, mentioned 4388 in Kconfig]
Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
Hi,

This is just a single commit mostly written by Hector that adds support
for BCM4388 chips. I've just rebased this to the current bluetooth-next
since it also needs 9dc8ac15ca5 and adjusted some comments.

Best,

Sven
---
 drivers/bluetooth/Kconfig       |  6 ++--
 drivers/bluetooth/hci_bcm4377.c | 61 +++++++++++++++++++++++++++++++----------
 2 files changed, 50 insertions(+), 17 deletions(-)

diff --git a/drivers/bluetooth/Kconfig b/drivers/bluetooth/Kconfig
index 0b5f218ac505..87484f5de8e3 100644
--- a/drivers/bluetooth/Kconfig
+++ b/drivers/bluetooth/Kconfig
@@ -287,12 +287,12 @@ config BT_HCIBCM203X
 
 
 config BT_HCIBCM4377
-	tristate "HCI BCM4377/4378/4387 PCIe driver"
+	tristate "HCI BCM4377/4378/4387/4388 PCIe driver"
 	depends on PCI
 	select FW_LOADER
 	help
-	  Support for Broadcom BCM4377/4378/4387 Bluetooth chipsets attached via
-	  PCIe. These are usually found in Apple machines.
+	  Support for Broadcom BCM4377/4378/4387/4388 Bluetooth chipsets
+	  attached via PCIe. These are usually found in Apple machines.
 
 	  Say Y here to compile support for HCI BCM4377 family devices into the
 	  kernel or say M to compile it as module (hci_bcm4377).
diff --git a/drivers/bluetooth/hci_bcm4377.c b/drivers/bluetooth/hci_bcm4377.c
index e6644cb0163c..77a5454a8721 100644
--- a/drivers/bluetooth/hci_bcm4377.c
+++ b/drivers/bluetooth/hci_bcm4377.c
@@ -1,6 +1,6 @@
 // SPDX-License-Identifier: GPL-2.0-only OR MIT
 /*
- * Bluetooth HCI driver for Broadcom 4377/4378/4387 devices attached via PCIe
+ * Bluetooth HCI driver for Broadcom 4377/4378/4387/4388 devices attached via PCIe
  *
  * Copyright (C) The Asahi Linux Contributors
  */
@@ -26,11 +26,13 @@ enum bcm4377_chip {
 	BCM4377 = 0,
 	BCM4378,
 	BCM4387,
+	BCM4388,
 };
 
 #define BCM4377_DEVICE_ID 0x5fa0
 #define BCM4378_DEVICE_ID 0x5f69
 #define BCM4387_DEVICE_ID 0x5f71
+#define BCM4388_DEVICE_ID 0x5f72
 
 #define BCM4377_TIMEOUT msecs_to_jiffies(1000)
 #define BCM4377_BOOT_TIMEOUT msecs_to_jiffies(5000)
@@ -488,6 +490,7 @@ struct bcm4377_data;
  *                     second window in BAR0
  * has_bar0_core2_window2: Set to true if this chip requires the second core's
  *                         second window to be configured
+ * bar2_offset: Offset to the start of the variables in BAR2
  * clear_pciecfg_subsystem_ctrl_bit19: Set to true if bit 19 in the
  *                                     vendor-specific subsystem control
  *                                     register has to be cleared
@@ -511,6 +514,7 @@ struct bcm4377_hw {
 	u32 bar0_window1;
 	u32 bar0_window2;
 	u32 bar0_core2_window2;
+	u32 bar2_offset;
 
 	unsigned long has_bar0_core2_window2 : 1;
 	unsigned long clear_pciecfg_subsystem_ctrl_bit19 : 1;
@@ -836,8 +840,8 @@ static irqreturn_t bcm4377_irq(int irq, void *data)
 	struct bcm4377_data *bcm4377 = data;
 	u32 bootstage, rti_status;
 
-	bootstage = ioread32(bcm4377->bar2 + BCM4377_BAR2_BOOTSTAGE);
-	rti_status = ioread32(bcm4377->bar2 + BCM4377_BAR2_RTI_STATUS);
+	bootstage = ioread32(bcm4377->bar2 + bcm4377->hw->bar2_offset + BCM4377_BAR2_BOOTSTAGE);
+	rti_status = ioread32(bcm4377->bar2 + bcm4377->hw->bar2_offset + BCM4377_BAR2_RTI_STATUS);
 
 	if (bootstage != bcm4377->bootstage ||
 	    rti_status != bcm4377->rti_status) {
@@ -1197,6 +1201,14 @@ static int bcm4387_send_calibration(struct bcm4377_data *bcm4377)
 						  bcm4377->taurus_cal_size);
 }
 
+static int bcm4388_send_calibration(struct bcm4377_data *bcm4377)
+{
+	/* BCM4388 always uses beamforming */
+	return __bcm4378_send_calibration(
+		bcm4377, bcm4377->taurus_beamforming_cal_blob,
+		bcm4377->taurus_beamforming_cal_size);
+}
+
 static const struct firmware *bcm4377_request_blob(struct bcm4377_data *bcm4377,
 						   const char *suffix)
 {
@@ -1820,8 +1832,8 @@ static int bcm4377_boot(struct bcm4377_data *bcm4377)
 	int ret = 0;
 	u32 bootstage, rti_status;
 
-	bootstage = ioread32(bcm4377->bar2 + BCM4377_BAR2_BOOTSTAGE);
-	rti_status = ioread32(bcm4377->bar2 + BCM4377_BAR2_RTI_STATUS);
+	bootstage = ioread32(bcm4377->bar2 + bcm4377->hw->bar2_offset + BCM4377_BAR2_BOOTSTAGE);
+	rti_status = ioread32(bcm4377->bar2 + bcm4377->hw->bar2_offset + BCM4377_BAR2_RTI_STATUS);
 
 	if (bootstage != 0) {
 		dev_err(&bcm4377->pdev->dev, "bootstage is %d and not 0\n",
@@ -1855,9 +1867,12 @@ static int bcm4377_boot(struct bcm4377_data *bcm4377)
 	iowrite32(BCM4377_DMA_MASK,
 		  bcm4377->bar0 + BCM4377_BAR0_HOST_WINDOW_SIZE);
 
-	iowrite32(lower_32_bits(fw_dma), bcm4377->bar2 + BCM4377_BAR2_FW_LO);
-	iowrite32(upper_32_bits(fw_dma), bcm4377->bar2 + BCM4377_BAR2_FW_HI);
-	iowrite32(fw->size, bcm4377->bar2 + BCM4377_BAR2_FW_SIZE);
+	iowrite32(lower_32_bits(fw_dma),
+		  bcm4377->bar2 + bcm4377->hw->bar2_offset + BCM4377_BAR2_FW_LO);
+	iowrite32(upper_32_bits(fw_dma),
+		  bcm4377->bar2 + bcm4377->hw->bar2_offset + BCM4377_BAR2_FW_HI);
+	iowrite32(fw->size,
+		  bcm4377->bar2 + bcm4377->hw->bar2_offset + BCM4377_BAR2_FW_SIZE);
 	iowrite32(0, bcm4377->bar0 + BCM4377_BAR0_FW_DOORBELL);
 
 	dev_dbg(&bcm4377->pdev->dev, "waiting for firmware to boot\n");
@@ -1914,16 +1929,16 @@ static int bcm4377_setup_rti(struct bcm4377_data *bcm4377)
 	dev_dbg(&bcm4377->pdev->dev, "RTI is in state 1\n");
 
 	/* allow access to the entire IOVA space again */
-	iowrite32(0, bcm4377->bar2 + BCM4377_BAR2_RTI_WINDOW_LO);
-	iowrite32(0, bcm4377->bar2 + BCM4377_BAR2_RTI_WINDOW_HI);
+	iowrite32(0, bcm4377->bar2 + bcm4377->hw->bar2_offset + BCM4377_BAR2_RTI_WINDOW_LO);
+	iowrite32(0, bcm4377->bar2 + bcm4377->hw->bar2_offset + BCM4377_BAR2_RTI_WINDOW_HI);
 	iowrite32(BCM4377_DMA_MASK,
-		  bcm4377->bar2 + BCM4377_BAR2_RTI_WINDOW_SIZE);
+		  bcm4377->bar2 + bcm4377->hw->bar2_offset + BCM4377_BAR2_RTI_WINDOW_SIZE);
 
 	/* setup "Converged IPC" context */
 	iowrite32(lower_32_bits(bcm4377->ctx_dma),
-		  bcm4377->bar2 + BCM4377_BAR2_CONTEXT_ADDR_LO);
+		  bcm4377->bar2 + bcm4377->hw->bar2_offset + BCM4377_BAR2_CONTEXT_ADDR_LO);
 	iowrite32(upper_32_bits(bcm4377->ctx_dma),
-		  bcm4377->bar2 + BCM4377_BAR2_CONTEXT_ADDR_HI);
+		  bcm4377->bar2 + bcm4377->hw->bar2_offset + BCM4377_BAR2_CONTEXT_ADDR_HI);
 	iowrite32(2, bcm4377->bar0 + BCM4377_BAR0_RTI_CONTROL);
 
 	ret = wait_for_completion_interruptible_timeout(&bcm4377->event,
@@ -2489,6 +2504,21 @@ static const struct bcm4377_hw bcm4377_hw_variants[] = {
 		.send_calibration = bcm4387_send_calibration,
 		.send_ptb = bcm4378_send_ptb,
 	},
+
+	[BCM4388] = {
+		.id = 0x4388,
+		.otp_offset = 0x415c,
+		.bar2_offset = 0x200000,
+		.bar0_window1 = 0x18002000,
+		.bar0_window2 = 0x18109000,
+		.bar0_core2_window2 = 0x18106000,
+		.has_bar0_core2_window2 = true,
+		.broken_mws_transport_config = true,
+		.broken_le_coded = true,
+		.broken_le_ext_adv_report_phy = true,
+		.send_calibration = bcm4388_send_calibration,
+		.send_ptb = bcm4378_send_ptb,
+	},
 };
 
 #define BCM4377_DEVID_ENTRY(id)                                             \
@@ -2502,6 +2532,7 @@ static const struct pci_device_id bcm4377_devid_table[] = {
 	BCM4377_DEVID_ENTRY(4377),
 	BCM4377_DEVID_ENTRY(4378),
 	BCM4377_DEVID_ENTRY(4387),
+	BCM4377_DEVID_ENTRY(4388),
 	{},
 };
 MODULE_DEVICE_TABLE(pci, bcm4377_devid_table);
@@ -2516,7 +2547,7 @@ static struct pci_driver bcm4377_pci_driver = {
 module_pci_driver(bcm4377_pci_driver);
 
 MODULE_AUTHOR("Sven Peter <sven@svenpeter.dev>");
-MODULE_DESCRIPTION("Bluetooth support for Broadcom 4377/4378/4387 devices");
+MODULE_DESCRIPTION("Bluetooth support for Broadcom 4377/4378/4387/4388 devices");
 MODULE_LICENSE("Dual MIT/GPL");
 MODULE_FIRMWARE("brcm/brcmbt4377*.bin");
 MODULE_FIRMWARE("brcm/brcmbt4377*.ptb");
@@ -2524,3 +2555,5 @@ MODULE_FIRMWARE("brcm/brcmbt4378*.bin");
 MODULE_FIRMWARE("brcm/brcmbt4378*.ptb");
 MODULE_FIRMWARE("brcm/brcmbt4387*.bin");
 MODULE_FIRMWARE("brcm/brcmbt4387*.ptb");
+MODULE_FIRMWARE("brcm/brcmbt4388*.bin");
+MODULE_FIRMWARE("brcm/brcmbt4388*.ptb");

---
base-commit: 3c376f35eb13a144d5039d911b35110c2beef815
change-id: 20240602-btbcm4388-431aed90d763

Best regards,
-- 
Sven Peter <sven@svenpeter.dev>

