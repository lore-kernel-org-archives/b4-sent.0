From: Yogev Modlin <yogev.modlin@realsenseai.com>
Date: Fri, 24 Oct 2025 08:49:48 +0300
Subject: [PATCH v3 3/3] media: uvc: Add D436 and D555 cameras metadata
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251024-fix-uvc-v3-3-b7f83c012ca7@realsenseai.com>
References: <20251024-fix-uvc-v3-0-b7f83c012ca7@realsenseai.com>
In-Reply-To: <20251024-fix-uvc-v3-0-b7f83c012ca7@realsenseai.com>
To: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Hans de Goede <hansg@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 ymodlin <yogev.modlin@realsenseai.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761284988; l=1832;
 i=yogev.modlin@realsenseai.com; s=20251022; h=from:subject:message-id;
 bh=iyrLXXvX6649ccACpjDB81ZR69kmGOLUpxdAJ8yQQ8w=;
 b=CpS2m7QQ8wrOXNVjTwBxqDseIklATOaiom16pdXFTEhbtfQCSLaUAcqmSVK4USMa2GmUtPq6f
 Q29L/XfaV0SCYrw6YzeliA/jSjwfNVqVUE3DpK/ncLSL7bBL4+fMQXR
X-Developer-Key: i=yogev.modlin@realsenseai.com; a=ed25519;
 pk=V3EENbzJJO6YkqjrHtGmN67ulKS2b5TU7Ze0hVi1G1o=
X-Endpoint-Received: by B4 Relay for yogev.modlin@realsenseai.com/20251022 with auth_id=549
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for Intel RealSense D436 and D555 depth cameras metadata.
These cameras use the D4XX metadata format for transmitting depth and
sensor information.

The D555 camera uses UVC protocol version 1.5, while the D436 uses
an undefined protocol version. Both cameras require the D4XX metadata
format flag to properly handle their metadata streams.

Signed-off-by: Yogev Modlin <yogev.modlin@realsenseai.com>
---
 drivers/media/usb/uvc/uvc_driver.c | 18 ++++++++++++++++++
 1 file changed, 18 insertions(+)

diff --git a/drivers/media/usb/uvc/uvc_driver.c b/drivers/media/usb/uvc/uvc_driver.c
index dbdacc64ea6b..6f0053a78123 100644
--- a/drivers/media/usb/uvc/uvc_driver.c
+++ b/drivers/media/usb/uvc/uvc_driver.c
@@ -3223,6 +3223,24 @@ static const struct usb_device_id uvc_ids[] = {
 	  .bInterfaceSubClass	= 1,
 	  .bInterfaceProtocol	= 0,
 	  .driver_info		= UVC_INFO_META(V4L2_META_FMT_D4XX) },
+	/* Intel Realsense D555 Depth Camera */
+	{ .match_flags		= USB_DEVICE_ID_MATCH_DEVICE
+				| USB_DEVICE_ID_MATCH_INT_INFO,
+	  .idVendor		= 0x8086,
+	  .idProduct		= 0x0b56,
+	  .bInterfaceClass	= USB_CLASS_VIDEO,
+	  .bInterfaceSubClass	= 1,
+	  .bInterfaceProtocol	= UVC_PC_PROTOCOL_15,
+	  .driver_info		= UVC_INFO_META(V4L2_META_FMT_D4XX) },
+	/* Intel Realsense D436 Camera */
+	{ .match_flags		= USB_DEVICE_ID_MATCH_DEVICE
+				| USB_DEVICE_ID_MATCH_INT_INFO,
+	  .idVendor		= 0x8086,
+	  .idProduct		= 0x1156,
+	  .bInterfaceClass	= USB_CLASS_VIDEO,
+	  .bInterfaceSubClass	= 1,
+	  .bInterfaceProtocol	= UVC_PC_PROTOCOL_UNDEFINED,
+	  .driver_info		= UVC_INFO_META(V4L2_META_FMT_D4XX) },
 	/* Generic USB Video Class */
 	{ USB_INTERFACE_INFO(USB_CLASS_VIDEO, 1, UVC_PC_PROTOCOL_UNDEFINED) },
 	{ USB_INTERFACE_INFO(USB_CLASS_VIDEO, 1, UVC_PC_PROTOCOL_15) },

-- 
2.43.0

