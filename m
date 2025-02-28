From: =?utf-8?q?Jonathan_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Fri, 28 Feb 2025 16:11:22 +0100
Subject: [PATCH v3 7/9] usb: storage: sddr09: Use const for constant arrays
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250228-misc-const-v3-7-09b417ded9c4@posteo.net>
References: <20250228-misc-const-v3-0-09b417ded9c4@posteo.net>
In-Reply-To: <20250228-misc-const-v3-0-09b417ded9c4@posteo.net>
To: Alan Stern <stern@rowland.harvard.edu>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, usb-storage@lists.one-eyed-alien.net, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Jonathan_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740755487; l=2527;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=l+RAY2RPsx/JPY4RJUMnd+IPm3/INCAlkSXItxmAg4Q=;
 b=6WBB8ETU477ruMo1xN/6W31d5OrSbxNiYQANwHrc/DsmaKLwdBrF+DRVOFoMu9N0t3v79sAzw
 fcvHCUvcTgzCwytQJQ6Jy3SAAwJsxM9BFHnDSv5ViAJOp4K8plvf6Z9
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The nand_flash_ids, inquiry_response, and mode_page_01 arrays are only
read, not modified.

Declaring data as const makes it easier to see what's going on, and can
prevent unintended writes through placement in a read-only section.

Signed-off-by: Jonathan Neuschäfer <j.ne@posteo.net>
---

V3:
- elaborate why const is a good idea

V2:
- new patch
---
 drivers/usb/storage/sddr09.c | 14 +++++++-------
 1 file changed, 7 insertions(+), 7 deletions(-)

diff --git a/drivers/usb/storage/sddr09.c b/drivers/usb/storage/sddr09.c
index d21ce3466e25842757b3e278d522c55b7c1f19de..e66b920e99e25c90b581ff1f3eae16ed0cfd903c 100644
--- a/drivers/usb/storage/sddr09.c
+++ b/drivers/usb/storage/sddr09.c
@@ -144,7 +144,7 @@ static inline char *nand_flash_manufacturer(int manuf_id) {
  * 256 MB NAND flash has a 5-byte ID with 2nd byte 0xaa, 0xba, 0xca or 0xda.
  */
 
-static struct nand_flash_dev nand_flash_ids[] = {
+static const struct nand_flash_dev nand_flash_ids[] = {
 	/* NAND flash */
 	{ 0x6e, 20, 8, 4, 8, 2},	/* 1 MB */
 	{ 0xe8, 20, 8, 4, 8, 2},	/* 1 MB */
@@ -169,7 +169,7 @@ static struct nand_flash_dev nand_flash_ids[] = {
 	{ 0,}
 };
 
-static struct nand_flash_dev *
+static const struct nand_flash_dev *
 nand_find_id(unsigned char id) {
 	int i;
 
@@ -1133,9 +1133,9 @@ sddr09_reset(struct us_data *us) {
 }
 #endif
 
-static struct nand_flash_dev *
+static const struct nand_flash_dev *
 sddr09_get_cardinfo(struct us_data *us, unsigned char flags) {
-	struct nand_flash_dev *cardinfo;
+	const struct nand_flash_dev *cardinfo;
 	unsigned char deviceID[4];
 	char blurbtxt[256];
 	int result;
@@ -1545,12 +1545,12 @@ static int sddr09_transport(struct scsi_cmnd *srb, struct us_data *us)
 
 	struct sddr09_card_info *info;
 
-	static unsigned char inquiry_response[8] = {
+	static const unsigned char inquiry_response[8] = {
 		0x00, 0x80, 0x00, 0x02, 0x1F, 0x00, 0x00, 0x00
 	};
 
 	/* note: no block descriptor support */
-	static unsigned char mode_page_01[19] = {
+	static const unsigned char mode_page_01[19] = {
 		0x00, 0x0F, 0x00, 0x0, 0x0, 0x0, 0x00,
 		0x01, 0x0A,
 		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
@@ -1584,7 +1584,7 @@ static int sddr09_transport(struct scsi_cmnd *srb, struct us_data *us)
 	}
 
 	if (srb->cmnd[0] == READ_CAPACITY) {
-		struct nand_flash_dev *cardinfo;
+		const struct nand_flash_dev *cardinfo;
 
 		sddr09_get_wp(us, info);	/* read WP bit */
 

-- 
2.48.0.rc1.219.gb6b6757d772

