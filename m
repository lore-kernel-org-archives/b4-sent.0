From: =?utf-8?q?Jonathan_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Fri, 28 Feb 2025 16:11:21 +0100
Subject: [PATCH v3 6/9] usb: storage: realtek_cr: Use const for constant
 arrays
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250228-misc-const-v3-6-09b417ded9c4@posteo.net>
References: <20250228-misc-const-v3-0-09b417ded9c4@posteo.net>
In-Reply-To: <20250228-misc-const-v3-0-09b417ded9c4@posteo.net>
To: Alan Stern <stern@rowland.harvard.edu>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, usb-storage@lists.one-eyed-alien.net, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Jonathan_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740755487; l=1603;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=Z4dFHNFlKFnAbpKqq4pi0I1NGjP1CC9FXDl74xxbcAw=;
 b=wADBdezbHfISTEs1/feZNXSrsSUOdAx6ibWlswwtMJBeMO7Ko8xzT4WRGA5sjyxOMngCV++1h
 1l44956ZjtWAzVLAIfckYMCtkbrtmspXifp6FZ9tyLx28DSIQE4s8ur
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These arrays are only read, never modified.

Declaring data as const makes it easier to see what's going on, and can
prevent unintended writes through placement in a read-only section.

Signed-off-by: Jonathan Neuschäfer <j.ne@posteo.net>
---

V3:
- elaborate why const is a good idea

V2:
- new patch
---
 drivers/usb/storage/realtek_cr.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/usb/storage/realtek_cr.c b/drivers/usb/storage/realtek_cr.c
index 2a82ed7b68eaa75993e786afeda0d5d3a3c3bfce..4e516b44513672ebe7889247a70043e0dd013bc8 100644
--- a/drivers/usb/storage/realtek_cr.c
+++ b/drivers/usb/storage/realtek_cr.c
@@ -191,7 +191,7 @@ MODULE_DEVICE_TABLE(usb, realtek_cr_ids);
 	.initFunction = init_function,	\
 }
 
-static struct us_unusual_dev realtek_cr_unusual_dev_list[] = {
+static const struct us_unusual_dev realtek_cr_unusual_dev_list[] = {
 #	include "unusual_realtek.h"
 	{}			/* Terminating entry */
 };
@@ -797,10 +797,10 @@ static void rts51x_invoke_transport(struct scsi_cmnd *srb, struct us_data *us)
 {
 	struct rts51x_chip *chip = (struct rts51x_chip *)(us->extra);
 	static int card_first_show = 1;
-	static u8 media_not_present[] = { 0x70, 0, 0x02, 0, 0, 0, 0,
+	static const u8 media_not_present[] = { 0x70, 0, 0x02, 0, 0, 0, 0,
 		10, 0, 0, 0, 0, 0x3A, 0, 0, 0, 0, 0
 	};
-	static u8 invalid_cmd_field[] = { 0x70, 0, 0x05, 0, 0, 0, 0,
+	static const u8 invalid_cmd_field[] = { 0x70, 0, 0x05, 0, 0, 0, 0,
 		10, 0, 0, 0, 0, 0x24, 0, 0, 0, 0, 0
 	};
 	int ret;

-- 
2.48.0.rc1.219.gb6b6757d772

