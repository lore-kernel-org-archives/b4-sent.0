From: =?utf-8?q?Jonathan_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Wed, 26 Feb 2025 15:17:30 +0100
Subject: [PATCH v2 8/9] usb: storage: sddr55: Use const for constant arrays
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250226-misc-const-v2-8-ab655a4a29cc@posteo.net>
References: <20250226-misc-const-v2-0-ab655a4a29cc@posteo.net>
In-Reply-To: <20250226-misc-const-v2-0-ab655a4a29cc@posteo.net>
To: Alan Stern <stern@rowland.harvard.edu>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, usb-storage@lists.one-eyed-alien.net, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Jonathan_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740579450; l=1112;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=C7r28z1CFDV+sjQ7yiPOSMNteEWeKSpRUku1z3cAVDw=;
 b=YuvuOBJy+MirOAneLt7BuRHA3K01RUAXy/oJzPdR4gMU/FUr1G0Dut5fQeBkMLP3Mqei9WLw5
 /KKgx2FY460BuIB3Lj4iv23TkpxIWhNYdfxfbm3NITH3RwC8Wx4X46r
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These arrays are only read, not modified.

Signed-off-by: Jonathan Neuschäfer <j.ne@posteo.net>
---

V2:
- new patch
---
 drivers/usb/storage/sddr55.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/usb/storage/sddr55.c b/drivers/usb/storage/sddr55.c
index d5cdff30f6f31f98d3d58ffcdd2426d7cd385cbb..b323f0a3626031905b946ce64ddf04539a6e3232 100644
--- a/drivers/usb/storage/sddr55.c
+++ b/drivers/usb/storage/sddr55.c
@@ -775,11 +775,11 @@ static void sddr55_card_info_destructor(void *extra) {
 static int sddr55_transport(struct scsi_cmnd *srb, struct us_data *us)
 {
 	int result;
-	static unsigned char inquiry_response[8] = {
+	static const unsigned char inquiry_response[8] = {
 		0x00, 0x80, 0x00, 0x02, 0x1F, 0x00, 0x00, 0x00
 	};
  	// write-protected for now, no block descriptor support
-	static unsigned char mode_page_01[20] = {
+	static const unsigned char mode_page_01[20] = {
 		0x0, 0x12, 0x00, 0x80, 0x0, 0x0, 0x0, 0x0,
 		0x01, 0x0A,
 		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

-- 
2.48.0.rc1.219.gb6b6757d772

