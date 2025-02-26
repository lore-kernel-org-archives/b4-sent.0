From: =?utf-8?q?Jonathan_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Wed, 26 Feb 2025 15:17:24 +0100
Subject: [PATCH v2 2/9] usb: storage: transport: Use const for constant
 array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250226-misc-const-v2-2-ab655a4a29cc@posteo.net>
References: <20250226-misc-const-v2-0-ab655a4a29cc@posteo.net>
In-Reply-To: <20250226-misc-const-v2-0-ab655a4a29cc@posteo.net>
To: Alan Stern <stern@rowland.harvard.edu>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, usb-storage@lists.one-eyed-alien.net, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Jonathan_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740579450; l=893;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=nCzpJM3/zudVjCfMlG+Oo6xwILkwbL682EKLwocy/kg=;
 b=lyHT+26EK6qmfohCAo8e05Ihj7lHLa719aBwcSP2MiZPYO0GbADJ6SUOjHAwbrtTUhbp7Hzbd
 XiK5kPyOekHAamnhE5wM2hnDdWgAwBL7fJHb58K46jDRw+2dJ32C44L
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This array is only read, not modified

Signed-off-by: Jonathan Neuschäfer <j.ne@posteo.net>
---

V2:
- new patch
---
 drivers/usb/storage/transport.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/usb/storage/transport.c b/drivers/usb/storage/transport.c
index e6bc8ecaecbb202714be69c6db6b0a4824de4855..1aa1bd26c81f2f9fbd508fdfed4465e6482bdef0 100644
--- a/drivers/usb/storage/transport.c
+++ b/drivers/usb/storage/transport.c
@@ -528,7 +528,7 @@ static void last_sector_hacks(struct us_data *us, struct scsi_cmnd *srb)
 	u32 sector;
 
 	/* To Report "Medium Error: Record Not Found */
-	static unsigned char record_not_found[18] = {
+	static const unsigned char record_not_found[18] = {
 		[0]	= 0x70,			/* current error */
 		[2]	= MEDIUM_ERROR,		/* = 0x03 */
 		[7]	= 0x0a,			/* additional length */

-- 
2.48.0.rc1.219.gb6b6757d772

