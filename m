From: Michael Reeves <michael.reeves077@gmail.com>
Date: Fri, 25 Sep 2026 23:43:48 +1000
Subject: [PATCH 13/13] wifi: brcmfmac: Add BCM4388 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-brcm4388-submit-v1-13-b5cbc2cde2fb@gmail.com>
References: <20260925-brcm4388-submit-v1-0-b5cbc2cde2fb@gmail.com>
In-Reply-To: <20260925-brcm4388-submit-v1-0-b5cbc2cde2fb@gmail.com>
To: Arend van Spriel <arend.vanspriel@broadcom.com>, 
 Pieter-Paul Giesberts <pieterpg@broadcom.com>, 
 "Franky Lin (Zhenhui)" <frankyl@broadcom.com>, 
 Mathy Vanhoef <vanhoefm@gmail.com>, Kalle Valo <kvalo@kernel.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-wireless@vger.kernel.org, brcm80211@lists.linux.dev, 
 brcm80211-dev-list.pdl@broadcom.com, asahi@lists.linux.dev, 
 Hector Martin <marcan@marcan.st>, Daniel Berlin <dberlin@dberlin.org>, 
 Janne Grunau <j@jannau.net>, linux-kernel@vger.kernel.org, 
 Hante Meuleman <meuleman@broadcom.com>, linux-hardening@vger.kernel.org, 
 Michael Reeves <michael.reeves077@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790343821; l=6944;
 i=michael.reeves077@gmail.com; s=fedora-20260918; h=from:subject:message-id;
 bh=0ssO1sL/zwTcjM/uwq1dbdxySVDbT2P3POHSvMWy5LY=;
 b=15qzXe8Zs0JsLnL9Pn/RjhYlBaxsVIeRapxQFIYp6sy0SHTGIY+nQBKVoQVMwnETOzvXEaVk3
 uEJR2ldFpjKCde00dCcsJqB0/m3lXkTsBr1C3dhfPvvZSfXbqxRn2fg
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=VJ0TvyQ9TvfzYZa908YSE9kpkjFLLD5luv0bERu+boc=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/fedora-20260918 with auth_id=1035
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

Add BCM4388 firmware mappings, RAM base and OTP handling, and increase
the RX posting and completion ring capacities to 2048 items.

On BCM4388, DMA_FROM_DEVICE mappings for posted receive buffers cause
DART read-permission faults followed by firmware DMA failure. Map these
buffers with DMA_BIDIRECTIONAL to allow device reads as well as writes.
Keep the existing mapping direction for other chips.

Signed-off-by: Hector Martin <marcan@marcan.st>
Co-developed-by: Michael Reeves <michael.reeves077@gmail.com>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 drivers/net/wireless/broadcom/brcm80211/brcmfmac/chip.c      |  1 +
 drivers/net/wireless/broadcom/brcm80211/brcmfmac/msgbuf.c    |  8 +++++---
 drivers/net/wireless/broadcom/brcm80211/brcmfmac/msgbuf.h    |  4 ++--
 drivers/net/wireless/broadcom/brcm80211/brcmfmac/pcie.c      | 12 +++++++++++-
 .../net/wireless/broadcom/brcm80211/include/brcm_hw_ids.h    |  2 ++
 5 files changed, 21 insertions(+), 6 deletions(-)

diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/chip.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/chip.c
index 253ab45c33..411188010f 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/chip.c
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/chip.c
@@ -751,6 +751,7 @@ static u32 brcmf_chip_tcm_rambase(struct brcmf_chip_priv *ci)
 	case BRCM_CC_4366_CHIP_ID:
 	case BRCM_CC_43664_CHIP_ID:
 	case BRCM_CC_43666_CHIP_ID:
+	case BRCM_CC_4388_CHIP_ID:
 		return 0x200000;
 	case BRCM_CC_4355_CHIP_ID:
 	case BRCM_CC_4359_CHIP_ID:
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/msgbuf.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/msgbuf.c
index 8e5c697e7f..5ad46d7ec6 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/msgbuf.c
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/msgbuf.c
@@ -12,6 +12,7 @@
 #include <linux/netdevice.h>
 #include <linux/etherdevice.h>
 
+#include <brcm_hw_ids.h>
 #include <brcmu_utils.h>
 #include <brcmu_wifi.h>
 
@@ -51,7 +52,7 @@
 #define MSGBUF_TYPE_D2H_MAILBOX_DATA		0x24
 
 #define NR_TX_PKTIDS				2048
-#define NR_RX_PKTIDS				1024
+#define NR_RX_PKTIDS				2048
 
 #define BRCMF_IOCTL_REQ_PKTID			0xFFFE
 
@@ -330,7 +331,6 @@ brcmf_msgbuf_init_pktids(u32 nr_array_entries,
 	return pktids;
 }
 
-
 static int
 brcmf_msgbuf_alloc_pktid(struct device *dev,
 			 struct brcmf_msgbuf_pktids *pktids,
@@ -1695,8 +1695,10 @@ int brcmf_proto_msgbuf_attach(struct brcmf_pub *drvr)
 						     DMA_TO_DEVICE);
 	if (!msgbuf->tx_pktids)
 		goto fail;
+	/* BCM4388 firmware also reads from posted RX buffers. */
 	msgbuf->rx_pktids = brcmf_msgbuf_init_pktids(NR_RX_PKTIDS,
-						     DMA_FROM_DEVICE);
+			drvr->bus_if->chip == BRCM_CC_4388_CHIP_ID ?
+			DMA_BIDIRECTIONAL : DMA_FROM_DEVICE);
 	if (!msgbuf->rx_pktids)
 		goto fail;
 
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/msgbuf.h b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/msgbuf.h
index 18b56d0789..1d0233c619 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/msgbuf.h
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/msgbuf.h
@@ -8,10 +8,10 @@
 #ifdef CONFIG_BRCMFMAC_PROTO_MSGBUF
 
 #define BRCMF_H2D_MSGRING_CONTROL_SUBMIT_MAX_ITEM	64
-#define BRCMF_H2D_MSGRING_RXPOST_SUBMIT_MAX_ITEM	1024
+#define BRCMF_H2D_MSGRING_RXPOST_SUBMIT_MAX_ITEM	2048
 #define BRCMF_D2H_MSGRING_CONTROL_COMPLETE_MAX_ITEM	64
 #define BRCMF_D2H_MSGRING_TX_COMPLETE_MAX_ITEM		1024
-#define BRCMF_D2H_MSGRING_RX_COMPLETE_MAX_ITEM		1024
+#define BRCMF_D2H_MSGRING_RX_COMPLETE_MAX_ITEM		2048
 #define BRCMF_H2D_TXFLOWRING_MAX_ITEM			512
 
 #define BRCMF_H2D_MSGRING_CONTROL_SUBMIT_ITEMSIZE	40
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pcie.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pcie.c
index 48402eb2ef..32c95b8f51 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pcie.c
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pcie.c
@@ -71,6 +71,8 @@ BRCMF_FW_CLM_DEF(4377B3, "brcmfmac4377b3-pcie");
 BRCMF_FW_CLM_DEF(4378B1, "brcmfmac4378b1-pcie");
 BRCMF_FW_CLM_DEF(4378B3, "brcmfmac4378b3-pcie");
 BRCMF_FW_CLM_DEF(4387C2, "brcmfmac4387c2-pcie");
+BRCMF_FW_CLM_DEF(4388B0, "brcmfmac4388b0-pcie");
+BRCMF_FW_CLM_DEF(4388C0, "brcmfmac4388c0-pcie");
 BRCMF_FW_CLM_DEF(54591, "brcmfmac54591-pcie");
 
 /* firmware config files */
@@ -113,6 +115,8 @@ static const struct brcmf_firmware_mapping brcmf_pcie_fwnames[] = {
 	BRCMF_FW_ENTRY(BRCM_CC_4378_CHIP_ID, 0x0000000F, 4378B1), /* revision ID 3 */
 	BRCMF_FW_ENTRY(BRCM_CC_4378_CHIP_ID, 0xFFFFFFE0, 4378B3), /* revision ID 5 */
 	BRCMF_FW_ENTRY(BRCM_CC_4387_CHIP_ID, 0xFFFFFFFF, 4387C2), /* revision ID 7 */
+	BRCMF_FW_ENTRY(BRCM_CC_4388_CHIP_ID, 0x0000000F, 4388B0),
+	BRCMF_FW_ENTRY(BRCM_CC_4388_CHIP_ID, 0xFFFFFFF0, 4388C0), /* revision ID 4 */
 };
 
 #define BRCMF_PCIE_FW_UP_TIMEOUT		5000 /* msec */
@@ -2397,6 +2401,11 @@ static int brcmf_pcie_read_otp(struct brcmf_pciedev_info *devinfo)
 		base = 0x113c;
 		words = 0x170;
 		break;
+	case BRCM_CC_4388_CHIP_ID:
+		coreid = BCMA_CORE_GCI;
+		base = 0x115c;
+		words = 0x150;
+		break;
 	default:
 		/* OTP not supported on this chip */
 		return 0;
@@ -2459,7 +2468,7 @@ static int brcmf_pcie_read_otp(struct brcmf_pciedev_info *devinfo)
 
 static bool brcmf_pcie_request_fw_signature(struct brcmf_pciedev_info *devinfo)
 {
-	return false;
+	return devinfo->ci->chip == BRCM_CC_4388_CHIP_ID;
 }
 
 static void brcmf_pcie_setup(struct device *dev, int ret,
@@ -3114,6 +3123,7 @@ static const struct pci_device_id brcmf_pcie_devid_table[] = {
 	BRCMF_PCIE_DEVICE(BRCM_PCIE_4377_DEVICE_ID, WCC_SEED),
 	BRCMF_PCIE_DEVICE(BRCM_PCIE_4378_DEVICE_ID, WCC_SEED),
 	BRCMF_PCIE_DEVICE(BRCM_PCIE_4387_DEVICE_ID, WCC_SEED),
+	BRCMF_PCIE_DEVICE(BRCM_PCIE_4388_DEVICE_ID, WCC_SEED),
 	BRCMF_PCIE_DEVICE(BRCM_PCIE_43752_DEVICE_ID, WCC_SEED),
 	BRCMF_PCIE_DEVICE(CY_PCIE_54591_DEVICE_ID, CYW),
 	{ /* end: all zeroes */ }
diff --git a/drivers/net/wireless/broadcom/brcm80211/include/brcm_hw_ids.h b/drivers/net/wireless/broadcom/brcm80211/include/brcm_hw_ids.h
index df3b67ba4d..f749337a06 100644
--- a/drivers/net/wireless/broadcom/brcm80211/include/brcm_hw_ids.h
+++ b/drivers/net/wireless/broadcom/brcm80211/include/brcm_hw_ids.h
@@ -57,6 +57,7 @@
 #define BRCM_CC_4377_CHIP_ID		0x4377
 #define BRCM_CC_4378_CHIP_ID		0x4378
 #define BRCM_CC_4387_CHIP_ID		0x4387
+#define BRCM_CC_4388_CHIP_ID		0x4388
 #define CY_CC_4373_CHIP_ID		0x4373
 #define CY_CC_43012_CHIP_ID		43012
 #define CY_CC_43439_CHIP_ID		43439
@@ -99,6 +100,7 @@
 #define BRCM_PCIE_4377_DEVICE_ID	0x4488
 #define BRCM_PCIE_4378_DEVICE_ID	0x4425
 #define BRCM_PCIE_4387_DEVICE_ID	0x4433
+#define BRCM_PCIE_4388_DEVICE_ID	0x4434
 #define CY_PCIE_54591_DEVICE_ID		0x4417
 
 /* brcmsmac IDs */

-- 
2.55.0

