From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Tue, 10 Nov 2026 03:56:29 +0000
Subject: [PATCH 2/2] can: esd_usb: validate the message length in the rx
 path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-esd-usb-validate-v1-2-7ee499b4926d@gmail.com>
References: <20261110-esd-usb-validate-v1-0-7ee499b4926d@gmail.com>
In-Reply-To: <20261110-esd-usb-validate-v1-0-7ee499b4926d@gmail.com>
To: mkl@pengutronix.de, mailhol@kernel.org, frank.jungclaus@esd.eu, 
 socketcan@esd.eu, joasantonio108@gmail.com
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794282987; l=2262;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=pV/Sdz7aRtptMVVSSDZWKUxUjOppcKrFNiTGGsGPRAM=;
 b=SSGJExKFCETEo3C8HhdXj534u3ZYyx3Iue+QM6jolsbMwZq2EMNVZdAtZoOQLd7C23P1sL087
 C/fyZE3eEbAAyvWaswu2b+TINscMtUJ0jKrU0EyQM6a3pF6Uk5Axo4s
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

esd_usb_read_bulk_callback() walks the messages in a received buffer
using the length byte from each message header:

	pos += msg->hdr.len * sizeof(u32); /* convert to # of bytes */

	if (pos > urb->actual_length) {

The length is supplied by the device and is not checked against zero.
A message with hdr.len == 0 leaves pos unchanged, so the loop never
terminates and keeps handling the same message in the URB completion
handler, which locks up the CPU.

The check that the declared length lies within the received data is
also done only after the message has been handled.

Compute the message length first and reject a message that is empty or
whose declared length does not fit into the remaining data before it is
handled.  The handlers still rely on the fixed layout of the message
they are given; checking the declared length against the layout of each
command is left for a separate change.

Found by LLM-assisted source review.

Fixes: 96d8e90382dc ("can: Add driver for esd CAN-USB/2 device")
Cc: stable@vger.kernel.org
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
 drivers/net/can/usb/esd_usb.c | 14 ++++++++------
 1 file changed, 8 insertions(+), 6 deletions(-)

diff --git a/drivers/net/can/usb/esd_usb.c b/drivers/net/can/usb/esd_usb.c
index f26a8780686f..67dba118ce9e 100644
--- a/drivers/net/can/usb/esd_usb.c
+++ b/drivers/net/can/usb/esd_usb.c
@@ -507,8 +507,15 @@ static void esd_usb_read_bulk_callback(struct urb *urb)
 
 	while (pos < urb->actual_length) {
 		union esd_usb_msg *msg;
+		unsigned int msg_len;
 
 		msg = (union esd_usb_msg *)(urb->transfer_buffer + pos);
+		msg_len = msg->hdr.len * sizeof(u32); /* convert to # of bytes */
+
+		if (!msg_len || msg_len > urb->actual_length - pos) {
+			dev_err(dev->udev->dev.parent, "format error\n");
+			break;
+		}
 
 		switch (msg->hdr.cmd) {
 		case ESD_USB_CMD_CAN_RX:
@@ -531,12 +538,7 @@ static void esd_usb_read_bulk_callback(struct urb *urb)
 			break;
 		}
 
-		pos += msg->hdr.len * sizeof(u32); /* convert to # of bytes */
-
-		if (pos > urb->actual_length) {
-			dev_err(dev->udev->dev.parent, "format error\n");
-			break;
-		}
+		pos += msg_len;
 	}
 
 resubmit_urb:

-- 
2.43.0

