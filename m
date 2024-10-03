From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Thu, 03 Oct 2024 21:21:25 +0200
Subject: [PATCH RFC] bluetooth: qca: generate nvm fw name from boardid for
 WCN6855
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241003-bt-nvm-firmware-v1-1-79028931214f@oldschoolsolutions.biz>
X-B4-Tracking: v=1; b=H4sIALTu/mYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxNDAwNj3aQS3byyXN20zKLc8sSiVF0T81STFMMkc4NES0sloK6CotS0zAq
 widFKQW7OSrG1tQDFV46DZgAAAA==
To: Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Steev Klimaszewski <steev@kali.org>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727983298; l=4402;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=A//l2c8M2myBYVFdvINmnr1+5nW8/KoVbzWje8K7CX0=;
 b=MXyXjDalzxxrJ8VvkIZiXmIU1UMrwtP5JPWqyjJfKYzP+BWbmRLzAi+3pAxWwLWgDzi2m7FO6
 LsdFgqZHKl1Adg4qSSxmOb+0aUr10hMFV8YtC/V2uclWd7FYnxMla08
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Steev Klimaszewski <steev@kali.org>

This is based on the 2066 work, which the 6855 is basically the same
thing.

The already existing function qca_generate_hsp_nvm_name() appears to do
the right steps to generate the hpnv file name. For WCN6855, the suffix
seems to be the board id with prefix b, though.

Add specific masking for boardid to generate the full name.

boardid == 0 -> use 0 as parameter
boardid <  0x100 -> add 0x0b00 to it, otherwise add 0xb000

This generates correct hpnv* file names for the files on the Windows
partition that appear to work better with the hardware than the default
.bin.
Tested on Lenovo Thinkpad X13s, Microsoft WDK2023, and HP Omnibook X14.

The specific firmware is found on the Windows partition, and is supposed
to work a little bit better than the default .bin.

Co-authored-by: Steev Klimaszewski <steev@kali.org>
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Signed-off-by: Steev Klimaszewski <steev@kali.org>
---
This is based on the 2066 work, which the 6855 is basically the same
thing.

It generates the fw name to load from the board id, taking the file
name format for the WCN6855 into account. The hpnv* firmware files 
can be found on the Windows partition ofthe device. They usually 
work better with the specific hardware. If the file is not found it 
retries with the default name.

This has been tested on:

Lenovo Thinkpad X13s
Microsoft Windows Dev Kit 2023 (Blackrock)
HP Omnibook X14
---
 drivers/bluetooth/btqca.c | 28 +++++++++++++++++++++-------
 1 file changed, 21 insertions(+), 7 deletions(-)

diff --git a/drivers/bluetooth/btqca.c b/drivers/bluetooth/btqca.c
index dfbbac92242a8..ffc75680b322b 100644
--- a/drivers/bluetooth/btqca.c
+++ b/drivers/bluetooth/btqca.c
@@ -564,6 +564,21 @@ static int qca_download_firmware(struct hci_dev *hdev,
 					   config->fwname, ret);
 				return ret;
 			}
+			/* For WCN6855, if Windows firmware file isn't in place
+			 * then use the default .bin file.
+			 */
+		} else if (soc_type == QCA_WCN6855) {
+			bt_dev_dbg(hdev, "QCA Failed to request file: %s (%d)",
+				   config->fwname, ret);
+			snprintf(config->fwname, sizeof(config->fwname),
+				 "qca/hpnv%02x.bin", rom_ver);
+			bt_dev_info(hdev, "QCA Downloading %s", config->fwname);
+			ret = request_firmware(&fw, config->fwname, &hdev->dev);
+			if (ret) {
+				bt_dev_err(hdev, "QCA Failed to request file: %s (%d)",
+					   config->fwname, ret);
+				return ret;
+			}
 		} else {
 			bt_dev_err(hdev, "QCA Failed to request file: %s (%d)",
 				   config->fwname, ret);
@@ -773,6 +788,7 @@ int qca_uart_setup(struct hci_dev *hdev, uint8_t baudrate,
 			 "qca/apbtfw%02x.tlv", rom_ver);
 		break;
 	case QCA_QCA2066:
+	case QCA_WCN6855:
 		snprintf(config.fwname, sizeof(config.fwname),
 			 "qca/hpbtfw%02x.tlv", rom_ver);
 		break;
@@ -788,10 +804,6 @@ int qca_uart_setup(struct hci_dev *hdev, uint8_t baudrate,
 		snprintf(config.fwname, sizeof(config.fwname),
 			 "qca/msbtfw%02x.mbn", rom_ver);
 		break;
-	case QCA_WCN6855:
-		snprintf(config.fwname, sizeof(config.fwname),
-			 "qca/hpbtfw%02x.tlv", rom_ver);
-		break;
 	case QCA_WCN7850:
 		snprintf(config.fwname, sizeof(config.fwname),
 			 "qca/hmtbtfw%02x.tlv", rom_ver);
@@ -810,7 +822,7 @@ int qca_uart_setup(struct hci_dev *hdev, uint8_t baudrate,
 	/* Give the controller some time to get ready to receive the NVM */
 	msleep(10);
 
-	if (soc_type == QCA_QCA2066 || soc_type == QCA_WCN7850)
+	if (soc_type == QCA_QCA2066 || soc_type == QCA_WCN7850 || soc_type == QCA_WCN6855)
 		qca_read_fw_board_id(hdev, &boardid);
 
 	/* Download NVM configuration */
@@ -848,8 +860,10 @@ int qca_uart_setup(struct hci_dev *hdev, uint8_t baudrate,
 				 "qca/msnv%02x.bin", rom_ver);
 			break;
 		case QCA_WCN6855:
-			snprintf(config.fwname, sizeof(config.fwname),
-				 "qca/hpnv%02x.bin", rom_ver);
+			qca_generate_hsp_nvm_name(config.fwname,
+				sizeof(config.fwname), ver, rom_ver,
+				boardid == 0 ? boardid : (boardid < 0x0100 ?
+				(boardid & 0x00ff)|0x0b00 : (boardid & 0x0fff)|0xb000));
 			break;
 		case QCA_WCN7850:
 			qca_get_nvm_name_generic(&config, "hmt", rom_ver, boardid);

---
base-commit: 9852d85ec9d492ebef56dc5f229416c925758edc
change-id: 20241003-bt-nvm-firmware-47e4d1b70a99

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

