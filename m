From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Tue, 25 Feb 2025 13:25:03 +0100
Subject: [PATCH] usb: storage: jumpshot: Use const for constant arrays
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250225-misc-const-v1-1-121ff3b86437@posteo.net>
X-B4-Tracking: v=1; b=H4sIAJ+2vWcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDEwND3dzM4mTd5Py84hLdVPMkk+Q0I4MU0zRLJaCGgqLUtMwKsGHRsbW
 1AOPiNc9cAAAA
X-Change-ID: 20240401-misc-const-e7b4cf20d5f9
To: Alan Stern <stern@rowland.harvard.edu>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, usb-storage@lists.one-eyed-alien.net, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>, 
 =?utf-8?q?Jonathan_Neusch=C3=A4fer?= <j.neuschaefer@gmx.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740486309; l=1810;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=8rz6vHhtFj67IR1PYVzJt/W+sDgjep7yfy8XQRNUyVM=;
 b=xcrvT+n6wVQZdgOquo/5oCozE3BNKpweD3XshACH5KiYMKRKGFNmqrlpzJa9go/5yaUOv/1m6
 J215lkf+nznAm3bUW8JpZvqPnlnHgmQGXmbgm/03EEUBACJssgxzOWh
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These arrays are not modified. Make them const.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
Signed-off-by: Jonathan Neuschäfer <j.neuschaefer@gmx.net>
---

This change was compile-tested with ARCH=powerpc
---
 drivers/usb/storage/jumpshot.c | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/drivers/usb/storage/jumpshot.c b/drivers/usb/storage/jumpshot.c
index 39ca84d6859122903de4e64b13e697e8b7d4ab31..089c6f8ac85fbb683cca8b03a2ff06c0ca776167 100644
--- a/drivers/usb/storage/jumpshot.c
+++ b/drivers/usb/storage/jumpshot.c
@@ -367,16 +367,16 @@ static int jumpshot_handle_mode_sense(struct us_data *us,
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
@@ -477,7 +477,7 @@ static int jumpshot_transport(struct scsi_cmnd *srb, struct us_data *us)
 	int rc;
 	unsigned long block, blocks;
 	unsigned char *ptr = us->iobuf;
-	static unsigned char inquiry_response[8] = {
+	static const unsigned char inquiry_response[8] = {
 		0x00, 0x80, 0x00, 0x01, 0x1F, 0x00, 0x00, 0x00
 	};
 

---
base-commit: 2014c95afecee3e76ca4a56956a936e23283f05b
change-id: 20240401-misc-const-e7b4cf20d5f9

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

