From: George Moussalem <george.moussalem@outlook.com>
Date: Fri, 03 Jul 2026 09:01:50 +0400
Subject: [PATCH v3 2/6] Bluetooth: btqca: Add IPQ5018 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260703-ipq5018-bluetooth-v3-2-62da72818ab3@outlook.com>
References: <20260703-ipq5018-bluetooth-v3-0-62da72818ab3@outlook.com>
In-Reply-To: <20260703-ipq5018-bluetooth-v3-0-62da72818ab3@outlook.com>
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-arm-msm@vger.kernel.org, linux-bluetooth@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783054918; l=3179;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=VsRRymuoav40YjOA1nuQIwCq+MFzT9PHwoR+fGa1uZA=;
 b=jFuxJdXBVTClZ2B4SAYdCC069D+/9Rj/f8J4KsqAqGAkZEWTiG4YsfXCTRgKVt2M6wuF4mN8F
 gTXfOy2Gx0EC6L/kkF7eHpc1va8bAy5Ze7BXnxRyJZBLoKW9v+vxHIO
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the IPQ5018 SoC type and support for loading its firmware.

The firmware tested has been taken from GPL sources of various router
boards. Firmware files needed are:
- qca/bt_fw_patch.mbn
- qca/mpnv10.bin

Acked-by: Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/bluetooth/btqca.c | 16 ++++++++++++++++
 drivers/bluetooth/btqca.h |  3 +++
 2 files changed, 19 insertions(+)

diff --git a/drivers/bluetooth/btqca.c b/drivers/bluetooth/btqca.c
index 04ebe290bc78..e136e91976cf 100644
--- a/drivers/bluetooth/btqca.c
+++ b/drivers/bluetooth/btqca.c
@@ -380,6 +380,9 @@ static int qca_tlv_check_data(struct hci_dev *hdev,
 		break;
 
 	case TLV_TYPE_NVM:
+		if (soc_type == QCA_IPQ5018)
+			break;
+
 		if (fw_size < sizeof(struct tlv_type_hdr))
 			return -EINVAL;
 
@@ -794,6 +797,9 @@ int qca_uart_setup(struct hci_dev *hdev, uint8_t baudrate,
 	else
 		rom_ver = ((soc_ver & 0x00000f00) >> 0x04) | (soc_ver & 0x0000000f);
 
+	if (soc_type == QCA_IPQ5018)
+		goto download_nvm;
+
 	if (soc_type == QCA_WCN6750)
 		qca_send_patch_config_cmd(hdev);
 
@@ -881,6 +887,7 @@ int qca_uart_setup(struct hci_dev *hdev, uint8_t baudrate,
 	if (soc_type == QCA_QCA2066 || soc_type == QCA_WCN7850)
 		qca_read_fw_board_id(hdev, &boardid);
 
+download_nvm:
 	/* Download NVM configuration */
 	config.type = TLV_TYPE_NVM;
 	if (firmware_name) {
@@ -939,6 +946,10 @@ int qca_uart_setup(struct hci_dev *hdev, uint8_t baudrate,
 			qca_get_nvm_name_by_board(config.fwname, sizeof(config.fwname),
 				 "hmtnv", soc_type, ver, rom_ver, boardid);
 			break;
+		case QCA_IPQ5018:
+			snprintf(config.fwname, sizeof(config.fwname),
+				 "qca/mpnv%02x.bin", rom_ver);
+			break;
 		default:
 			snprintf(config.fwname, sizeof(config.fwname),
 				 "qca/nvm_%08x.bin", soc_ver);
@@ -958,6 +969,9 @@ int qca_uart_setup(struct hci_dev *hdev, uint8_t baudrate,
 		return err;
 	}
 
+	if (soc_type == QCA_IPQ5018)
+		msleep(NVM_READY_DELAY_MS);
+
 	switch (soc_type) {
 	case QCA_QCA2066:
 	case QCA_QCA6390:
@@ -965,6 +979,7 @@ int qca_uart_setup(struct hci_dev *hdev, uint8_t baudrate,
 	case QCA_WCN6750:
 	case QCA_WCN6855:
 	case QCA_WCN7850:
+	case QCA_IPQ5018:
 		err = qca_disable_soc_logging(hdev);
 		if (err < 0)
 			return err;
@@ -1001,6 +1016,7 @@ int qca_uart_setup(struct hci_dev *hdev, uint8_t baudrate,
 	case QCA_WCN6750:
 	case QCA_WCN6855:
 	case QCA_WCN7850:
+	case QCA_IPQ5018:
 		/* get fw build info */
 		err = qca_read_fw_build_info(hdev);
 		if (err < 0)
diff --git a/drivers/bluetooth/btqca.h b/drivers/bluetooth/btqca.h
index 8f3c1b1c77b3..343cd62d1137 100644
--- a/drivers/bluetooth/btqca.h
+++ b/drivers/bluetooth/btqca.h
@@ -54,6 +54,8 @@
 #define QCA_HSP_GF_SOC_ID		0x1200
 #define QCA_HSP_GF_SOC_MASK		0x0000ff00
 
+#define NVM_READY_DELAY_MS		1500
+
 enum qca_baudrate {
 	QCA_BAUDRATE_115200	= 0,
 	QCA_BAUDRATE_57600,
@@ -158,6 +160,7 @@ enum qca_btsoc_type {
 	QCA_WCN6750,
 	QCA_WCN6855,
 	QCA_WCN7850,
+	QCA_IPQ5018,
 };
 
 #if IS_ENABLED(CONFIG_BT_QCA)

-- 
2.53.0

