From: John Bauer <johnebgood@securitylive.com>
Date: Mon, 25 Mar 2024 19:38:22 -0500
Subject: [PATCH] uvcvideo: Remo OBSBOT quirk fix for incorrect relative min
 pan/tilt/zoom speeds
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240325-obsbot-quirk-fix-relative-ptz-speed-v1-1-0eb1387d98c7@securitylive.com>
X-B4-Tracking: v=1; b=H4sIAP0YAmYC/x2NwQrCMBAFf6Xs2YUYW7D+inhIzWtdlCbuxiKW/
 ruhx4FhZiWDCowuzUqKRUzSXOF4aOj+CPMElliZvPOtO/mO02BDKvz+iD55lC8rXqHIAs7lx5a
 ByH1Ai7Hr49kFqqWsqOZ+ud627Q+HVMGsdQAAAA==
To: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linh.tp.vu@gmail.com, ribalda@chromium.org, soyer@irl.hu, 
 John Bauer <john@oxt.co>, John Bauer <johnebgood@securitylive.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711413509; l=4420;
 i=johnebgood@securitylive.com; s=20240325; h=from:subject:message-id;
 bh=EC3DcD5yUB9YFZIy5yjNz83GEhb0RRD1YpnYxRcoesY=;
 b=7CLWWKuRqGJlsL0tB7PQ5mZVY2XRp5a0sqsaeYhEJB2qAQscB+U710fOIiceS7k1Niq4Za3Gj
 GMHr47YiVYOCaod5ydoGwYFXrzcNfyYcZMfMv5GIJ/U7BcOlaB0xkj1
X-Developer-Key: i=johnebgood@securitylive.com; a=ed25519;
 pk=RN31Fmrxbidp1TwtZGNmQwTDjUWMPnewQJfA/ug2P9E=
X-Endpoint-Received: by B4 Relay for johnebgood@securitylive.com/20240325 with auth_id=143
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The OBSBOT series of cameras misreports the minimum relative
pan_speed, tilt_speed and zoom_continuous v4l2 controls resulting
in the inability to control the camera with finesse with an analog
stick or other programmatic methods. This patch applies to all
Remo (OBSBOT) vendor cameras with the vendor ID of 0x3564. If the
vendor fixes the firmware this behavior should still remain valid.
With this broad vendor fix when new devices are released the kernel
module won't need to be modified. When the vendor fixes the firmware the
device list can be modified with finer grained device filters.

Signed-off-by: John Bauer <johnebgood@securitylive.com>
---
If the Remo/OBSBOT vendor filter is considered too broad I will track down 
all of the current product ID's and update the device list. It's currently 
unknown if the vendor is pursuing a fix this issue; this issue has been 
reported and known to them for over a year. Their only support channel 
is their Facebook group. 
---
 drivers/media/usb/uvc/uvc_ctrl.c   | 27 ++++++++++++++++++++++++++-
 drivers/media/usb/uvc/uvc_driver.c |  8 ++++++++
 drivers/media/usb/uvc/uvcvideo.h   |  1 +
 3 files changed, 35 insertions(+), 1 deletion(-)

diff --git a/drivers/media/usb/uvc/uvc_ctrl.c b/drivers/media/usb/uvc/uvc_ctrl.c
index e59a463c2761..1951e06527cf 100644
--- a/drivers/media/usb/uvc/uvc_ctrl.c
+++ b/drivers/media/usb/uvc/uvc_ctrl.c
@@ -1322,10 +1322,23 @@ static int __uvc_query_v4l2_ctrl(struct uvc_video_chain *chain,
 		break;
 	}
 
-	if (ctrl->info.flags & UVC_CTRL_FLAG_GET_MIN)
+	if (ctrl->info.flags & UVC_CTRL_FLAG_GET_MIN) {
 		v4l2_ctrl->minimum = mapping->get(mapping, UVC_GET_MIN,
 				     uvc_ctrl_data(ctrl, UVC_CTRL_DATA_MIN));
 
+		if (chain->dev->quirks & UVC_QUIRK_OBSBOT_MIN_SETTINGS) {
+			switch (v4l2_ctrl->id) {
+			case V4L2_CID_ZOOM_CONTINUOUS:
+			case V4L2_CID_PAN_SPEED:
+			case V4L2_CID_TILT_SPEED:
+				v4l2_ctrl->minimum = -1 * mapping->get(mapping, UVC_GET_MAX,
+						     uvc_ctrl_data(ctrl, UVC_CTRL_DATA_MAX));
+			default:
+				break;
+			}
+		}
+	}
+
 	if (ctrl->info.flags & UVC_CTRL_FLAG_GET_MAX)
 		v4l2_ctrl->maximum = mapping->get(mapping, UVC_GET_MAX,
 				     uvc_ctrl_data(ctrl, UVC_CTRL_DATA_MAX));
@@ -1914,6 +1927,18 @@ int uvc_ctrl_set(struct uvc_fh *handle,
 				   uvc_ctrl_data(ctrl, UVC_CTRL_DATA_MIN));
 		max = mapping->get(mapping, UVC_GET_MAX,
 				   uvc_ctrl_data(ctrl, UVC_CTRL_DATA_MAX));
+
+		if (chain->dev->quirks & UVC_QUIRK_OBSBOT_MIN_SETTINGS) {
+			switch (xctrl->id) {
+			case V4L2_CID_ZOOM_CONTINUOUS:
+			case V4L2_CID_PAN_SPEED:
+			case V4L2_CID_TILT_SPEED:
+				min = max * -1;
+			default:
+				break;
+			}
+		}
+
 		step = mapping->get(mapping, UVC_GET_RES,
 				    uvc_ctrl_data(ctrl, UVC_CTRL_DATA_RES));
 		if (step == 0)
diff --git a/drivers/media/usb/uvc/uvc_driver.c b/drivers/media/usb/uvc/uvc_driver.c
index bbd90123a4e7..d4edc1adb11b 100644
--- a/drivers/media/usb/uvc/uvc_driver.c
+++ b/drivers/media/usb/uvc/uvc_driver.c
@@ -3120,6 +3120,14 @@ static const struct usb_device_id uvc_ids[] = {
 	  .bInterfaceSubClass	= 1,
 	  .bInterfaceProtocol	= 0,
 	  .driver_info		= UVC_INFO_META(V4L2_META_FMT_D4XX) },
+	/* OBSBOT pan, tilt, zoom min settings quirk */
+	{ .match_flags		= USB_DEVICE_ID_MATCH_VENDOR
+				| USB_DEVICE_ID_MATCH_INT_INFO,
+	  .idVendor		= 0x3564,
+	  .bInterfaceClass	= USB_CLASS_VIDEO,
+	  .bInterfaceSubClass	= 1,
+	  .bInterfaceProtocol	= 0,
+	  .driver_info		= UVC_INFO_QUIRK(UVC_QUIRK_OBSBOT_MIN_SETTINGS) },
 	/* Generic USB Video Class */
 	{ USB_INTERFACE_INFO(USB_CLASS_VIDEO, 1, UVC_PC_PROTOCOL_UNDEFINED) },
 	{ USB_INTERFACE_INFO(USB_CLASS_VIDEO, 1, UVC_PC_PROTOCOL_15) },
diff --git a/drivers/media/usb/uvc/uvcvideo.h b/drivers/media/usb/uvc/uvcvideo.h
index 6fb0a78b1b00..0e2f083a5c0e 100644
--- a/drivers/media/usb/uvc/uvcvideo.h
+++ b/drivers/media/usb/uvc/uvcvideo.h
@@ -73,6 +73,7 @@
 #define UVC_QUIRK_FORCE_Y8		0x00000800
 #define UVC_QUIRK_FORCE_BPP		0x00001000
 #define UVC_QUIRK_WAKE_AUTOSUSPEND	0x00002000
+#define UVC_QUIRK_OBSBOT_MIN_SETTINGS 0x00004000
 
 /* Format flags */
 #define UVC_FMT_FLAG_COMPRESSED		0x00000001

---
base-commit: e8f897f4afef0031fe618a8e94127a0934896aba
change-id: 20240325-obsbot-quirk-fix-relative-ptz-speed-9ae4ef59d80a

Best regards,
-- 
John Bauer <johnebgood@securitylive.com>

