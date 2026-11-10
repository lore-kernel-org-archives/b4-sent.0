From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Tue, 10 Nov 2026 03:56:28 +0000
Subject: [PATCH 1/2] can: esd_usb: limit the number of nets reported by the
 device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-esd-usb-validate-v1-1-7ee499b4926d@gmail.com>
References: <20261110-esd-usb-validate-v1-0-7ee499b4926d@gmail.com>
In-Reply-To: <20261110-esd-usb-validate-v1-0-7ee499b4926d@gmail.com>
To: mkl@pengutronix.de, mailhol@kernel.org, frank.jungclaus@esd.eu, 
 socketcan@esd.eu, joasantonio108@gmail.com
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794282987; l=1647;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=xaRFfiQi+LE78/iydRbgfL5xgKrJdnS3XrPXYUllshg=;
 b=pFELmjGayKDc9q2M+73NCZukOJtkYOTlUlrwLtLE6l3tJCBXCpfk6w40WpxU6W8QIB66Gr3GK
 v9KnqMm8GcuBA823tfFxrAVElIsoHCmA7Uor2D5b917ySTqYupZT9UB
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

esd_usb_probe() takes the number of CAN nets from the version reply
sent by the device and uses it unchecked as the loop bound for
esd_usb_probe_one_net(), which stores the new private data pointer in
dev->nets[index].  The nets array only has ESD_USB_MAX_NETS (2)
entries, while the device controlled u8 can be up to 255.

A device that reports more than two nets makes the driver write
pointers past the end of the array, first over the following members
of struct esd_usb and then beyond the end of the allocation.  The
loops in esd_usb_read_bulk_callback(), unlink_all_urbs() and
esd_usb_disconnect() read dev->nets[] with the same bound.

A malicious USB device can use this to corrupt kernel heap memory
just by being plugged in.

Clamp the count to the size of the array.

Found by LLM-assisted source review.

Fixes: 96d8e90382dc ("can: Add driver for esd CAN-USB/2 device")
Cc: stable@vger.kernel.org
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
 drivers/net/can/usb/esd_usb.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/can/usb/esd_usb.c b/drivers/net/can/usb/esd_usb.c
index f41d4a0d140f..f26a8780686f 100644
--- a/drivers/net/can/usb/esd_usb.c
+++ b/drivers/net/can/usb/esd_usb.c
@@ -1343,7 +1343,7 @@ static int esd_usb_probe(struct usb_interface *intf,
 		goto free_msg;
 	}
 
-	dev->net_count = (int)msg->version_reply.nets;
+	dev->net_count = min_t(int, msg->version_reply.nets, ESD_USB_MAX_NETS);
 	dev->version = le32_to_cpu(msg->version_reply.version);
 
 	if (device_create_file(&intf->dev, &dev_attr_firmware))

-- 
2.43.0

