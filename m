From: ymodlin <yogev.modlin@realsenseai.com>
Date: Wed, 22 Oct 2025 14:15:18 +0300
Subject: [PATCH] change: drop 'Intel' from RealSense camera comments
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251022-fix-uvc-v1-1-e4cd03606735@realsenseai.com>
X-B4-Tracking: v=1; b=H4sIAMW8+GgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDAyMj3bTMCt3SsmRdI0tj85QkY8PkREtjJaDqgqJUoBTYpOjY2loAC6v
 3y1kAAAA=
To: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Hans de Goede <hansg@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yogev Modlin <yogev.modlin@realsenseai.com>, 
 ymodlin <yogev.modlin@realsenseai.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761131725; l=4253;
 i=yogev.modlin@realsenseai.com; s=20251022; h=from:subject:message-id;
 bh=vetAyfvSfxHLKMYbudFyIvkX+DxlHNbHORbyaU7GB68=;
 b=V4VF3vBAhDjxk2g8/UoqJxHvcjLmAvIG5RVjBE63QjfyQNu8PT48l/NlCpz5bSeMh0bw2REvf
 zK8A6tZA4hNDCNZphFS0jtoDnlFruXffHlBut5tudGEO2tVU0CcIled
X-Developer-Key: i=yogev.modlin@realsenseai.com; a=ed25519;
 pk=V3EENbzJJO6YkqjrHtGmN67ulKS2b5TU7Ze0hVi1G1o=
X-Endpoint-Received: by B4 Relay for yogev.modlin@realsenseai.com/20251022 with auth_id=549
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

RealSense branding is now independent of Intel. Update all driver
comments referencing "Intel RealSense" to just "RealSense" to reflect
current ownership. No code logic changes.

Signed-off-by: Yogev Modlin <yogev.modlin@realsenseai.com>
---
Since Realsense has been spin-off Intel, the comment should be change.

Signed-off-by: ymodlin <yogev.modlin@realsenseai.com>
---
 drivers/media/usb/uvc/uvc_driver.c | 18 +++++++++---------
 1 file changed, 9 insertions(+), 9 deletions(-)

diff --git a/drivers/media/usb/uvc/uvc_driver.c b/drivers/media/usb/uvc/uvc_driver.c
index fb6afb8e84f0..b1457678833e 100644
--- a/drivers/media/usb/uvc/uvc_driver.c
+++ b/drivers/media/usb/uvc/uvc_driver.c
@@ -3142,7 +3142,7 @@ static const struct usb_device_id uvc_ids[] = {
 	  .bInterfaceSubClass	= 1,
 	  .bInterfaceProtocol	= 0,
 	  .driver_info		= UVC_INFO_QUIRK(UVC_QUIRK_DISABLE_AUTOSUSPEND) },
-	/* Intel D410/ASR depth camera */
+	/* Realsense D410/ASR depth camera */
 	{ .match_flags		= USB_DEVICE_ID_MATCH_DEVICE
 				| USB_DEVICE_ID_MATCH_INT_INFO,
 	  .idVendor		= 0x8086,
@@ -3151,7 +3151,7 @@ static const struct usb_device_id uvc_ids[] = {
 	  .bInterfaceSubClass	= 1,
 	  .bInterfaceProtocol	= 0,
 	  .driver_info		= UVC_INFO_META(V4L2_META_FMT_D4XX) },
-	/* Intel D415/ASRC depth camera */
+	/* Realsense D415/ASRC depth camera */
 	{ .match_flags		= USB_DEVICE_ID_MATCH_DEVICE
 				| USB_DEVICE_ID_MATCH_INT_INFO,
 	  .idVendor		= 0x8086,
@@ -3160,7 +3160,7 @@ static const struct usb_device_id uvc_ids[] = {
 	  .bInterfaceSubClass	= 1,
 	  .bInterfaceProtocol	= 0,
 	  .driver_info		= UVC_INFO_META(V4L2_META_FMT_D4XX) },
-	/* Intel D430/AWG depth camera */
+	/* Realsense D430/AWG depth camera */
 	{ .match_flags		= USB_DEVICE_ID_MATCH_DEVICE
 				| USB_DEVICE_ID_MATCH_INT_INFO,
 	  .idVendor		= 0x8086,
@@ -3169,7 +3169,7 @@ static const struct usb_device_id uvc_ids[] = {
 	  .bInterfaceSubClass	= 1,
 	  .bInterfaceProtocol	= 0,
 	  .driver_info		= UVC_INFO_META(V4L2_META_FMT_D4XX) },
-	/* Intel RealSense D4M */
+	/* Realsense RealSense D4M */
 	{ .match_flags		= USB_DEVICE_ID_MATCH_DEVICE
 				| USB_DEVICE_ID_MATCH_INT_INFO,
 	  .idVendor		= 0x8086,
@@ -3178,7 +3178,7 @@ static const struct usb_device_id uvc_ids[] = {
 	  .bInterfaceSubClass	= 1,
 	  .bInterfaceProtocol	= 0,
 	  .driver_info		= UVC_INFO_META(V4L2_META_FMT_D4XX) },
-	/* Intel D435/AWGC depth camera */
+	/* Realsense D435/AWGC depth camera */
 	{ .match_flags		= USB_DEVICE_ID_MATCH_DEVICE
 				| USB_DEVICE_ID_MATCH_INT_INFO,
 	  .idVendor		= 0x8086,
@@ -3187,7 +3187,7 @@ static const struct usb_device_id uvc_ids[] = {
 	  .bInterfaceSubClass	= 1,
 	  .bInterfaceProtocol	= 0,
 	  .driver_info		= UVC_INFO_META(V4L2_META_FMT_D4XX) },
-	/* Intel D435i depth camera */
+	/* Realsense D435i depth camera */
 	{ .match_flags		= USB_DEVICE_ID_MATCH_DEVICE
 				| USB_DEVICE_ID_MATCH_INT_INFO,
 	  .idVendor		= 0x8086,
@@ -3196,7 +3196,7 @@ static const struct usb_device_id uvc_ids[] = {
 	  .bInterfaceSubClass	= 1,
 	  .bInterfaceProtocol	= 0,
 	  .driver_info		= UVC_INFO_META(V4L2_META_FMT_D4XX) },
-	/* Intel D405 Depth Camera */
+	/* Realsense D405 Depth Camera */
 	{ .match_flags		= USB_DEVICE_ID_MATCH_DEVICE
 				| USB_DEVICE_ID_MATCH_INT_INFO,
 	  .idVendor		= 0x8086,
@@ -3205,7 +3205,7 @@ static const struct usb_device_id uvc_ids[] = {
 	  .bInterfaceSubClass	= 1,
 	  .bInterfaceProtocol	= 0,
 	  .driver_info		= UVC_INFO_META(V4L2_META_FMT_D4XX) },
-	/* Intel D455 Depth Camera */
+	/* Realsense D455 Depth Camera */
 	{ .match_flags		= USB_DEVICE_ID_MATCH_DEVICE
 				| USB_DEVICE_ID_MATCH_INT_INFO,
 	  .idVendor		= 0x8086,
@@ -3214,7 +3214,7 @@ static const struct usb_device_id uvc_ids[] = {
 	  .bInterfaceSubClass	= 1,
 	  .bInterfaceProtocol	= 0,
 	  .driver_info		= UVC_INFO_META(V4L2_META_FMT_D4XX) },
-	/* Intel D421 Depth Module */
+	/* Realsense D421 Depth Module */
 	{ .match_flags		= USB_DEVICE_ID_MATCH_DEVICE
 				| USB_DEVICE_ID_MATCH_INT_INFO,
 	  .idVendor		= 0x8086,

---
base-commit: 552c50713f273b494ac6c77052032a49bc9255e2
change-id: 20251022-fix-uvc-2937db31ca93

Best regards,
-- 
ymodlin <yogev.modlin@realsenseai.com>

