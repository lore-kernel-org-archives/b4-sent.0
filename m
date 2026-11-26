From: =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>
Date: Thu, 26 Nov 2026 10:01:12 +0100
Subject: [PATCH v9 11/14] can: peak_usb: don't return an uninitialized
 PCAN-USB CAN channel ID
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261126-canfd_check_channel_idx-v9-11-abe0099b4585@peak-system.fr>
References: <20261126-canfd_check_channel_idx-v9-0-abe0099b4585@peak-system.fr>
In-Reply-To: <20261126-canfd_check_channel_idx-v9-0-abe0099b4585@peak-system.fr>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, 
 Wolfgang Grandegger <wg@grandegger.com>, 
 =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>, 
 Dan Carpenter <error27@gmail.com>, Lukas Magel <lukas.magel@posteo.net>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Tristan Madani <tristmd@gmail.com>, 
 Joas Antonio dos Santos <joasantonio108@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795683678; l=1561;
 i=s.grosjean@peak-system.fr; s=20261020; h=from:subject:message-id;
 bh=7B0vo9diFeiQEBLv9AiKbJVJlPqFLZBQsRQcMQ4PkzQ=;
 b=qoAEH4Ry4cBHX1KCTE3uZ5mEToYppW4Ve5O3b5J6VAY0jXFquNBcQPfeG5a5q4LDUeKqIn7Us
 NBMM1XtNhweChYfVO1Tm/rDUZgPmXFbfZk4d1WGPYoBG3GzV4GtMAMB
X-Developer-Key: i=s.grosjean@peak-system.fr; a=ed25519;
 pk=bP7QV2zvvAKAfConZlUOGKGEcXL64SNUpVUm++Ai+/c=
X-Endpoint-Received: by B4 Relay for s.grosjean@peak-system.fr/20261020 with auth_id=1250
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pcan_usb_get_can_channel_id() takes the CAN channel ID of a PCAN-USB
from the args[] array, which pcan_usb_wait_rsp() fills with the response
of the device. However, args[] is not initialized, and
pcan_usb_wait_rsp() returns success without touching it once the device
is no longer connected.

peak_usb_disconnect() clears PCAN_USB_STATE_CONNECTED before it
unregisters the netdevs. An ETHTOOL_GEEPROM request handled in this
window makes peak_usb_get_eeprom() copy an uninitialized stack byte to
userspace, and cache it in dev->can_channel_id.

Initialize args[], so that a null ID is returned in that case.

Found by Sashiko AI review.

Fixes: 36d007c6fc79 ("can: peak_usb: add ethtool interface to user-configurable CAN channel identifier")
Cc: stable@vger.kernel.org
Signed-off-by: Stéphane Grosjean <s.grosjean@peak-system.fr>
---
 drivers/net/can/usb/peak_usb/pcan_usb.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/can/usb/peak_usb/pcan_usb.c b/drivers/net/can/usb/peak_usb/pcan_usb.c
index ff1921779065..83cf6fe7d258 100644
--- a/drivers/net/can/usb/peak_usb/pcan_usb.c
+++ b/drivers/net/can/usb/peak_usb/pcan_usb.c
@@ -386,7 +386,7 @@ static int pcan_usb_get_serial(struct peak_usb_device *dev, u32 *serial_number)
  */
 static int pcan_usb_get_can_channel_id(struct peak_usb_device *dev, u32 *can_ch_id)
 {
-	u8 args[PCAN_USB_CMD_ARGS_LEN];
+	u8 args[PCAN_USB_CMD_ARGS_LEN] = {};
 	int err;
 
 	err = pcan_usb_wait_rsp(dev, PCAN_USB_CMD_DEVID, PCAN_USB_GET, args);

-- 
2.53.0

