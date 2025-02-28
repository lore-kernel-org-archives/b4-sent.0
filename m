From: =?utf-8?q?Jonathan_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Fri, 28 Feb 2025 16:11:18 +0100
Subject: [PATCH v3 3/9] usb: storage: alauda: Use const for card ID array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250228-misc-const-v3-3-09b417ded9c4@posteo.net>
References: <20250228-misc-const-v3-0-09b417ded9c4@posteo.net>
In-Reply-To: <20250228-misc-const-v3-0-09b417ded9c4@posteo.net>
To: Alan Stern <stern@rowland.harvard.edu>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, usb-storage@lists.one-eyed-alien.net, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Jonathan_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740755487; l=1923;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=AZumiHFV94k9HcBLZR6/HqBt2YaBXyvzIkuQ2zvtWu4=;
 b=7qv1Cd/INWh/lZF4QpH0wu5HRq6qdQDZ65XW11dcqRHlPkoDgZDiwVk4a4xitAUAuiBPD5d81
 W4RebuHnTelCFEKEumtfyEZXcIfLfczTk/A2gxSoMLMYfDFUA+m+G+E
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The alauda_card_ids array is only read, and not modified.

Declaring data as const makes it easier to see what's going on, and can
prevent unintended writes through placement in a read-only section.

Signed-off-by: Jonathan Neuschäfer <j.ne@posteo.net>
---

V3:
- elaborate why const is a good idea

V2:
- new patch
---
 drivers/usb/storage/alauda.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/usb/storage/alauda.c b/drivers/usb/storage/alauda.c
index 6263c4e61678e890e0192c5c9dad9b97dbaf0e66..e01f3a42bde4200da245c17abd5299c062868204 100644
--- a/drivers/usb/storage/alauda.c
+++ b/drivers/usb/storage/alauda.c
@@ -174,7 +174,7 @@ struct alauda_card_info {
 	unsigned char zoneshift;	/* 1<<zs blocks per zone */
 };
 
-static struct alauda_card_info alauda_card_ids[] = {
+static const struct alauda_card_info alauda_card_ids[] = {
 	/* NAND flash */
 	{ 0x6e, 20, 8, 4, 8},	/* 1 MB */
 	{ 0xe8, 20, 8, 4, 8},	/* 1 MB */
@@ -200,7 +200,7 @@ static struct alauda_card_info alauda_card_ids[] = {
 	{ 0,}
 };
 
-static struct alauda_card_info *alauda_card_find_id(unsigned char id)
+static const struct alauda_card_info *alauda_card_find_id(unsigned char id)
 {
 	int i;
 
@@ -383,7 +383,7 @@ static int alauda_init_media(struct us_data *us)
 {
 	unsigned char *data = us->iobuf;
 	int ready = 0;
-	struct alauda_card_info *media_info;
+	const struct alauda_card_info *media_info;
 	unsigned int num_zones;
 
 	while (ready == 0) {
@@ -1132,7 +1132,7 @@ static int alauda_transport(struct scsi_cmnd *srb, struct us_data *us)
 	int rc;
 	struct alauda_info *info = (struct alauda_info *) us->extra;
 	unsigned char *ptr = us->iobuf;
-	static unsigned char inquiry_response[36] = {
+	static const unsigned char inquiry_response[36] = {
 		0x00, 0x80, 0x00, 0x01, 0x1F, 0x00, 0x00, 0x00
 	};
 

-- 
2.48.0.rc1.219.gb6b6757d772

