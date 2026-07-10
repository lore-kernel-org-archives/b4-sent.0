From: Miles Krause <mileskrause5200@gmail.com>
Date: Fri, 10 Jul 2026 01:17:18 -0400
Subject: [PATCH] Bluetooth: btmtk: use bool for first_block
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-btmtk-first-block-bool-v1-1-e6ac61d918e4@gmail.com>
X-B4-Tracking: v=1; b=H4sIAF2AUGoC/yXMwQrCMAyA4VcZORtIi6zqq4iHpcs0bq7SVBHG3
 n1Vj9/h/xcwySoGp2aBLG81TXOF2zUQb918FdS+Gjz5loIj5PIoIw6arSBPKY7IKU3IPe0DHwM
 dvIMaP7MM+vmNz5e/7cV3ieV7g3XdALQwKO56AAAA
X-Change-ID: 20260710-btmtk-first-block-bool-bd047b970821
To: Marcel Holtmann <marcel@holtmann.org>, 
 Johan Hedberg <johan.hedberg@gmail.com>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>
Cc: linux-bluetooth@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Miles Krause <mileskrause5200@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783660640; l=2026;
 i=mileskrause5200@gmail.com; s=20260710; h=from:subject:message-id;
 bh=w0GMxlpAuvW9E5EoNTZ+r/cb96pIyUjH4Ud4DEGtoUM=;
 b=vYIwok7n0yB2vPf94Ve+SG+QU4JJSO3a1IJ7WltBPX0AqnfPkHP0R5xxqJ7W21A084yFGQG1v
 wCfGgNfnDrCAaLZ4XoWKi0oVnpEF//C8dsVM/JVzQoGMZxHUK1t+lW9
X-Developer-Key: i=mileskrause5200@gmail.com; a=ed25519;
 pk=QNhNjcQarqig3ColJBIEr3DYfWM1PHpP7z+6thxWXaU=
X-Endpoint-Received: by B4 Relay for mileskrause5200@gmail.com/20260710 with auth_id=861
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

first_block is reset for each firmware section and is never used outside
the section loop. Declare it as a bool inside the loop to limit its scope
and make its two-state purpose explicit.

No functional change.

Signed-off-by: Miles Krause <mileskrause5200@gmail.com>
---
Compile-tested on x86_64 with:

  make O=out allmodconfig
  make O=out W=1 drivers/bluetooth/btmtk.o

Sparse-tested with:

  make O=out-sparse allmodconfig
  make O=out-sparse C=1 CHECK=sparse drivers/bluetooth/btmtk.o
---
 drivers/bluetooth/btmtk.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/bluetooth/btmtk.c b/drivers/bluetooth/btmtk.c
index 809762d64fc6..b809eb82fc73 100644
--- a/drivers/bluetooth/btmtk.c
+++ b/drivers/bluetooth/btmtk.c
@@ -63,7 +63,7 @@ int btmtk_setup_firmware_79xx(struct hci_dev *hdev, const char *fwname,
 	const u8 *fw_ptr;
 	const u8 *fw_bin_ptr;
 	int err, dlen, i, status;
-	u8 flag, first_block, retry;
+	u8 flag, retry;
 	u32 section_num, dl_size, section_offset;
 	u8 cmd[64];
 
@@ -79,7 +79,7 @@ int btmtk_setup_firmware_79xx(struct hci_dev *hdev, const char *fwname,
 	section_num = le32_to_cpu(globaldesc->section_num);
 
 	for (i = 0; i < section_num; i++) {
-		first_block = 1;
+		bool first_block = true;
 		fw_ptr = fw_bin_ptr;
 		sectionmap = (struct btmtk_section_map *)(fw_ptr + MTK_FW_ROM_PATCH_HEADER_SIZE +
 			      MTK_FW_ROM_PATCH_GD_SIZE + MTK_FW_ROM_PATCH_SEC_MAP_SIZE * i);
@@ -132,9 +132,9 @@ int btmtk_setup_firmware_79xx(struct hci_dev *hdev, const char *fwname,
 
 			while (dl_size > 0) {
 				dlen = min_t(int, 250, dl_size);
-				if (first_block == 1) {
+				if (first_block) {
 					flag = 1;
-					first_block = 0;
+					first_block = false;
 				} else if (dl_size - dlen <= 0) {
 					flag = 3;
 				} else {

---
base-commit: 64b5c4c8e79c131fe8f135bab5e5dfaa245c5776
change-id: 20260710-btmtk-first-block-bool-bd047b970821

Best regards,
--  
Miles Krause <mileskrause5200@gmail.com>

