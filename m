From: George Moussalem <george.moussalem@outlook.com>
Date: Mon, 06 Jul 2026 21:26:18 +0400
Subject: [PATCH v4 2/6] Bluetooth: btqca: Add IPQ5018 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260706-ipq5018-bluetooth-v4-2-350262a30959@outlook.com>
References: <20260706-ipq5018-bluetooth-v4-0-350262a30959@outlook.com>
In-Reply-To: <20260706-ipq5018-bluetooth-v4-0-350262a30959@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783358843; l=2838;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=27ilBM9DiR7XYOp5RrhwrliFAC3j44UFDtaGy/ks68c=;
 b=2Kwiw64kDFOlj1MmMSMkZQ+TOfHwx0Uk+RXo+hz4uXX/p3L5Jmi2oZncwq8v1vVtYFDqbhNPr
 6SDTk2niL2JBhKbhcMxTkXF7T2aRE7bF5mNknwV3NP2MuXZXzmGDyNl
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
index 04ebe290bc78..08375664408b 100644
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
@@ -894,6 +901,10 @@ int qca_uart_setup(struct hci_dev *hdev, uint8_t baudrate,
 		}
 	} else {
 		switch (soc_type) {
+		case QCA_IPQ5018:
+			snprintf(config.fwname, sizeof(config.fwname),
+				 "qca/mpnv%02x.bin", rom_ver);
+			break;
 		case QCA_QCA2066:
 			qca_get_nvm_name_by_board(config.fwname,
 						  sizeof(config.fwname),
@@ -958,7 +969,11 @@ int qca_uart_setup(struct hci_dev *hdev, uint8_t baudrate,
 		return err;
 	}
 
+	if (soc_type == QCA_IPQ5018)
+		msleep(NVM_READY_DELAY_MS);
+
 	switch (soc_type) {
+	case QCA_IPQ5018:
 	case QCA_QCA2066:
 	case QCA_QCA6390:
 	case QCA_WCN3991:
@@ -997,6 +1012,7 @@ int qca_uart_setup(struct hci_dev *hdev, uint8_t baudrate,
 	}
 
 	switch (soc_type) {
+	case QCA_IPQ5018:
 	case QCA_WCN3991:
 	case QCA_WCN6750:
 	case QCA_WCN6855:
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

