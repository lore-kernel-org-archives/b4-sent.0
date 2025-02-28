From: =?utf-8?q?Jonathan_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Fri, 28 Feb 2025 16:11:19 +0100
Subject: [PATCH v3 4/9] usb: storage: datafab: Use const for constant
 arrays
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250228-misc-const-v3-4-09b417ded9c4@posteo.net>
References: <20250228-misc-const-v3-0-09b417ded9c4@posteo.net>
In-Reply-To: <20250228-misc-const-v3-0-09b417ded9c4@posteo.net>
To: Alan Stern <stern@rowland.harvard.edu>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, usb-storage@lists.one-eyed-alien.net, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Jonathan_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740755487; l=2538;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=yfxYfaF8Q7PIxOVWEnYYboHL7YcgLcujoqn0SQzuem4=;
 b=JbKx0x32ZLzV6QqtxmDJURu77gmnOpKmN1kohJvtrdILXcI6OtZbOs9C5+mjbgi2BQLx08CP4
 Ovc0j/bPp/SCwW6sBmUDyP84ulfxo/kJP/4ih3aOhtHb9wpSKqz3BBY
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These arrays are only read, not modified.

Declaring data as const makes it easier to see what's going on, and can
prevent unintended writes through placement in a read-only section.

Signed-off-by: Jonathan Neuschäfer <j.ne@posteo.net>
---

V3:
- elaborate why const is a good idea

V2:
- new patch
---
 drivers/usb/storage/datafab.c | 14 +++++++-------
 1 file changed, 7 insertions(+), 7 deletions(-)

diff --git a/drivers/usb/storage/datafab.c b/drivers/usb/storage/datafab.c
index bbfa2398b17036f431c0692bbf794bdb01d68cdf..9ba369483c9b36c2f662749c32bf81b525ae897f 100644
--- a/drivers/usb/storage/datafab.c
+++ b/drivers/usb/storage/datafab.c
@@ -319,7 +319,7 @@ static int datafab_determine_lun(struct us_data *us,
 	//
 	// There might be a better way of doing this?
 
-	static unsigned char scommand[8] = { 0, 1, 0, 0, 0, 0xa0, 0xec, 1 };
+	static const unsigned char scommand[8] = { 0, 1, 0, 0, 0, 0xa0, 0xec, 1 };
 	unsigned char *command = us->iobuf;
 	unsigned char *buf;
 	int count = 0, rc;
@@ -384,7 +384,7 @@ static int datafab_id_device(struct us_data *us,
 	// to the ATA spec, 'Sector Count' isn't used but the Windows driver
 	// sets this bit so we do too...
 	//
-	static unsigned char scommand[8] = { 0, 1, 0, 0, 0, 0xa0, 0xec, 1 };
+	static const unsigned char scommand[8] = { 0, 1, 0, 0, 0, 0xa0, 0xec, 1 };
 	unsigned char *command = us->iobuf;
 	unsigned char *reply;
 	int rc;
@@ -437,16 +437,16 @@ static int datafab_handle_mode_sense(struct us_data *us,
 				     struct scsi_cmnd * srb, 
 				     int sense_6)
 {
-	static unsigned char rw_err_page[12] = {
+	static const unsigned char rw_err_page[12] = {
 		0x1, 0xA, 0x21, 1, 0, 0, 0, 0, 1, 0, 0, 0
 	};
-	static unsigned char cache_page[12] = {
+	static const unsigned char cache_page[12] = {
 		0x8, 0xA, 0x1, 0, 0, 0, 0, 0, 0, 0, 0, 0
 	};
-	static unsigned char rbac_page[12] = {
+	static const unsigned char rbac_page[12] = {
 		0x1B, 0xA, 0, 0x81, 0, 0, 0, 0, 0, 0, 0, 0
 	};
-	static unsigned char timer_page[8] = {
+	static const unsigned char timer_page[8] = {
 		0x1C, 0x6, 0, 0, 0, 0
 	};
 	unsigned char pc, page_code;
@@ -550,7 +550,7 @@ static int datafab_transport(struct scsi_cmnd *srb, struct us_data *us)
 	int rc;
 	unsigned long block, blocks;
 	unsigned char *ptr = us->iobuf;
-	static unsigned char inquiry_reply[8] = {
+	static const unsigned char inquiry_reply[8] = {
 		0x00, 0x80, 0x00, 0x01, 0x1F, 0x00, 0x00, 0x00
 	};
 

-- 
2.48.0.rc1.219.gb6b6757d772

