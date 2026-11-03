From: =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>
Date: Tue, 03 Nov 2026 13:30:28 +0100
Subject: [PATCH v8 12/14] can: peak_usb: pass the dev_num argument of
 PCAN-USB Pro GETDEVID
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261103-canfd_check_channel_idx-v8-12-4e8b2c0a8806@peak-system.fr>
References: <20261103-canfd_check_channel_idx-v8-0-4e8b2c0a8806@peak-system.fr>
In-Reply-To: <20261103-canfd_check_channel_idx-v8-0-4e8b2c0a8806@peak-system.fr>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, 
 Wolfgang Grandegger <wg@grandegger.com>, 
 =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>, 
 Dan Carpenter <error27@gmail.com>, Lukas Magel <lukas.magel@posteo.net>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Tristan Madani <tristmd@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793709024; l=2068;
 i=s.grosjean@peak-system.fr; s=20261020; h=from:subject:message-id;
 bh=tg+9JBfly0WW6BZBreiuqI5/gaJiy/qaGWKpT4l/6/0=;
 b=Hdej+jVl3N0KAZ3gTV0AnBPXC0qFqNz0TAMjStt05xcW4nMxhTbYNdQah87mWrx6Q1wxj47Fg
 y4SbWW80aY8BE1NuyzI/RJwMvce8QRWwYlUQHdLrO/Nl+sVGl0fJXMS
X-Developer-Key: i=s.grosjean@peak-system.fr; a=ed25519;
 pk=bP7QV2zvvAKAfConZlUOGKGEcXL64SNUpVUm++Ai+/c=
X-Endpoint-Received: by B4 Relay for s.grosjean@peak-system.fr/20261020 with auth_id=1250
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pcan_usb_pro_get_can_channel_id() builds its GETDEVID record with
pcan_msg_add_rec(), passing only the channel index. However,
pcan_msg_add_rec() handles GETDEVID together with SETBTR and SETDEVID,
and also reads a second argument with va_arg(), to fill the dev_num
field of the record. Reading this missing argument is undefined
behavior: in practice, whatever value is left in the corresponding
register or stack slot is written to the request in dev->cmd_buf.

This value is sent to the device with each GETDEVID request. Moreover,
peak_usb_disconnect() clears PCAN_USB_STATE_CONNECTED before it
unregisters the netdevs, and once it is cleared,
pcan_usb_pro_send_cmd() and pcan_usb_pro_wait_rsp() return success
without any USB transfer. pcan_usb_pro_get_can_channel_id() then
returns the dev_num field of the request as the CAN channel ID, so an
ETHTOOL_GEEPROM request handled in this window makes
peak_usb_get_eeprom() copy that value to userspace, and cache it in
dev->can_channel_id.

Pass 0 as dev_num, so that the request is fully defined, and a null ID
is returned in that case.

Found by Sashiko AI review.

Fixes: d8a199355f8f ("can: usb: PEAK-System Technik PCAN-USB Pro specific part")
Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: Stéphane Grosjean <s.grosjean@peak-system.fr>
---
 drivers/net/can/usb/peak_usb/pcan_usb_pro.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/can/usb/peak_usb/pcan_usb_pro.c b/drivers/net/can/usb/peak_usb/pcan_usb_pro.c
index 840658723648..0d014f4c08a7 100644
--- a/drivers/net/can/usb/peak_usb/pcan_usb_pro.c
+++ b/drivers/net/can/usb/peak_usb/pcan_usb_pro.c
@@ -435,7 +435,7 @@ static int pcan_usb_pro_get_can_channel_id(struct peak_usb_device *dev,
 	u8 *pc;
 
 	pc = pcan_msg_init_empty(&um, dev->cmd_buf, PCAN_USB_MAX_CMD_LEN);
-	pcan_msg_add_rec(&um, PCAN_USBPRO_GETDEVID, dev->ctrl_idx);
+	pcan_msg_add_rec(&um, PCAN_USBPRO_GETDEVID, dev->ctrl_idx, 0);
 
 	err =  pcan_usb_pro_send_cmd(dev, &um);
 	if (err)

-- 
2.53.0

