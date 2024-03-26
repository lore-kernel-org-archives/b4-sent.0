From: John Bauer <johnebgood@securitylive.com>
Date: Tue, 26 Mar 2024 04:02:35 -0500
Subject: [PATCH] media: uvcvideo: UVC minimum relative pan/tilt/zoom speed
 fix.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240326-uvc-relative-ptz-speed-fix-v1-1-453fd5ccfd37@securitylive.com>
X-B4-Tracking: v=1; b=H4sIACqPAmYC/x3MQQqDMBBG4auEWTuQpFqkVyku0vjbDhQNSQyie
 HeDy+8t3kEJUZDopQ6KKJJkmStMo8j/3PwFy1hNVttWP2zHa/Ec8XdZCjjknVMARp5kY6uNcXD
 P/tNNVAchouZ7/h7O8wIzonqgbAAAAA==
To: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Gergo Koteles <soyer@irl.hu>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, linh.tp.vu@gmail.com, 
 ribalda@chromium.org, John Bauer <johnebgood@securitylive.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711443757; l=3347;
 i=johnebgood@securitylive.com; s=20240325; h=from:subject:message-id;
 bh=J5cUwDm8JSMrStvNfFZtZHjj3H7C9GUHhWu66GtOqLc=;
 b=BhUk8Rlx7w70KHg9iaN556luombmQ9OTlYd4HYzcPcA2k9Qy41j2jFBBrVlg4FHJGX2/tC8Hc
 7E1dxaiwbGrBMlF1+/NgafN1YdVz6ZHfyQNDf9MwBRpy7Q62W7qt8Os
X-Developer-Key: i=johnebgood@securitylive.com; a=ed25519;
 pk=RN31Fmrxbidp1TwtZGNmQwTDjUWMPnewQJfA/ug2P9E=
X-Endpoint-Received: by B4 Relay for johnebgood@securitylive.com/20240325 with auth_id=143
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The minimum UVC control value for the relative pan/tilt/zoom speeds
cannot be probed as the implementation condenses the pan and tilt
direction and speed into two 16 bit values. The minimum cannot be
set at probe time because it is probed first and the maximum is not
yet known. With this fix if a relative speed control is queried
or set the minimum is set and checked based on the additive inverse of
the maximum at that time.

Signed-off-by: John Bauer <johnebgood@securitylive.com>
---
Gergo noticed that a quirk fix would not be needed and the just 
the minimum value needed to be set. Thanks Ricardo, Linh and Gergo 
for helping me along here. The reason the problem presented is that 
the minimum probe is done before the maximum however the way the 
driver has condensed direction and speed controls 
(with great simplification benefit to the user) the minimum
value must be derived from the maximum and negated. This
fix gets/checks/sets the correct relative minimum value when 
needed instead of of at probe time. This minimum value does not 
reflect the UVC 1.5 spec but the simplified condensed 
implementation of the driver; it's beautiful.
---
 drivers/media/usb/uvc/uvc_ctrl.c | 37 ++++++++++++++++++++++++++++++++++---
 1 file changed, 34 insertions(+), 3 deletions(-)

diff --git a/drivers/media/usb/uvc/uvc_ctrl.c b/drivers/media/usb/uvc/uvc_ctrl.c
index e59a463c2761..b389ab3ee05d 100644
--- a/drivers/media/usb/uvc/uvc_ctrl.c
+++ b/drivers/media/usb/uvc/uvc_ctrl.c
@@ -1322,9 +1322,25 @@ static int __uvc_query_v4l2_ctrl(struct uvc_video_chain *chain,
 		break;
 	}
 
-	if (ctrl->info.flags & UVC_CTRL_FLAG_GET_MIN)
-		v4l2_ctrl->minimum = mapping->get(mapping, UVC_GET_MIN,
-				     uvc_ctrl_data(ctrl, UVC_CTRL_DATA_MIN));
+	if (ctrl->info.flags & UVC_CTRL_FLAG_GET_MIN) {
+		switch (v4l2_ctrl->id) {
+		case V4L2_CID_ZOOM_CONTINUOUS:
+		case V4L2_CID_PAN_SPEED:
+		case V4L2_CID_TILT_SPEED:
+			/*
+			 * For the relative speed implementation the minimum
+			 * value cannot be probed so it becomes the additive
+			 * inverse of maximum.
+			 */
+			v4l2_ctrl->minimum = -1 * mapping->get(mapping, UVC_GET_MAX,
+						uvc_ctrl_data(ctrl, UVC_CTRL_DATA_MAX));
+			break;
+		default:
+			v4l2_ctrl->minimum = mapping->get(mapping, UVC_GET_MIN,
+						uvc_ctrl_data(ctrl, UVC_CTRL_DATA_MIN));
+			break;
+		}
+	}
 
 	if (ctrl->info.flags & UVC_CTRL_FLAG_GET_MAX)
 		v4l2_ctrl->maximum = mapping->get(mapping, UVC_GET_MAX,
@@ -1914,6 +1930,21 @@ int uvc_ctrl_set(struct uvc_fh *handle,
 				   uvc_ctrl_data(ctrl, UVC_CTRL_DATA_MIN));
 		max = mapping->get(mapping, UVC_GET_MAX,
 				   uvc_ctrl_data(ctrl, UVC_CTRL_DATA_MAX));
+
+		/*
+		 * For the relative speed implementation the minimum
+		 * value cannot be probed so it becomes the additive
+		 * inverse of maximum.
+		 */
+		switch (xctrl->id) {
+		case V4L2_CID_ZOOM_CONTINUOUS:
+		case V4L2_CID_PAN_SPEED:
+		case V4L2_CID_TILT_SPEED:
+			min = max * -1;
+		default:
+			break;
+		}
+
 		step = mapping->get(mapping, UVC_GET_RES,
 				    uvc_ctrl_data(ctrl, UVC_CTRL_DATA_RES));
 		if (step == 0)

---
base-commit: e8f897f4afef0031fe618a8e94127a0934896aba
change-id: 20240325-uvc-relative-ptz-speed-fix-2011aea68b5f

Best regards,
-- 
John Bauer <johnebgood@securitylive.com>

