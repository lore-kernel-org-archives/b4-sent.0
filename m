From: =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>
Date: Thu, 26 Nov 2026 10:01:14 +0100
Subject: [PATCH v9 13/14] can: peak_usb: don't send uninitialized stack
 bytes to PCAN-USB devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261126-canfd_check_channel_idx-v9-13-abe0099b4585@peak-system.fr>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795683678; l=1921;
 i=s.grosjean@peak-system.fr; s=20261020; h=from:subject:message-id;
 bh=jlhgS5JaKaHZWAPKo+58DKqTvVR0iwbvuP1f/7kMmTo=;
 b=OeJqK4vY9A78+k+2csktpoeBzenmhxJSfwhaLTZq5EKS36pvx2z8XGg2h0cKile5wyCAVS/9e
 t/X7cgvX0nhArNDtJl3EvVWsj+8OAwzqkPfcaBUNCCZGA6Nbj2wNYq8
X-Developer-Key: i=s.grosjean@peak-system.fr; a=ed25519;
 pk=bP7QV2zvvAKAfConZlUOGKGEcXL64SNUpVUm++Ai+/c=
X-Endpoint-Received: by B4 Relay for s.grosjean@peak-system.fr/20261020 with auth_id=1250
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pcan_usb_send_cmd() copies the PCAN_USB_CMD_ARGS_LEN (14) bytes of the
args[] array of its caller into the command buffer, and sends the whole
command to the device.

pcan_usb_set_bittiming() only sets the first two bytes of its args[]
array, and pcan_usb_set_can_channel_id() only the first one. The other
12 or 13 bytes of these uninitialized stack arrays are thus sent to the
device each time the bitrate or the CAN channel ID is set.

Zero-initialize both arrays, as the other setters of the driver do.

Found by Sashiko AI review.

Fixes: 46be265d3388 ("can: usb: PEAK-System Technik PCAN-USB specific part")
Fixes: e7a7b3d22503 ("can: peak_usb: allow flashing of the CAN channel ID")
Cc: stable@vger.kernel.org
Signed-off-by: Stéphane Grosjean <s.grosjean@peak-system.fr>
---
 drivers/net/can/usb/peak_usb/pcan_usb.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/net/can/usb/peak_usb/pcan_usb.c b/drivers/net/can/usb/peak_usb/pcan_usb.c
index 83cf6fe7d258..2838e4ea2b4e 100644
--- a/drivers/net/can/usb/peak_usb/pcan_usb.c
+++ b/drivers/net/can/usb/peak_usb/pcan_usb.c
@@ -274,7 +274,7 @@ static int pcan_usb_set_led(struct peak_usb_device *dev, u8 onoff)
 static int pcan_usb_set_bittiming(struct peak_usb_device *dev,
 				  struct can_bittiming *bt)
 {
-	u8 args[PCAN_USB_CMD_ARGS_LEN];
+	u8 args[PCAN_USB_CMD_ARGS_LEN] = {};
 	u8 btr0, btr1;
 
 	btr0 = ((bt->brp - 1) & 0x3f) | (((bt->sjw - 1) & 0x3) << 6);
@@ -405,7 +405,7 @@ static int pcan_usb_get_can_channel_id(struct peak_usb_device *dev, u32 *can_ch_
 /* set a new CAN channel id in the flash memory of the device */
 static int pcan_usb_set_can_channel_id(struct peak_usb_device *dev, u32 can_ch_id)
 {
-	u8 args[PCAN_USB_CMD_ARGS_LEN];
+	u8 args[PCAN_USB_CMD_ARGS_LEN] = {};
 
 	/* this kind of device supports 8-bit values only */
 	if (can_ch_id > U8_MAX)

-- 
2.53.0

