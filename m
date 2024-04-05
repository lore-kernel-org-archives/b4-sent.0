From: John Bauer <johnebgood@securitylive.com>
Date: Fri, 05 Apr 2024 02:06:26 -0500
Subject: [PATCH 1/2] media: uvcvideo: UVC minimum relative pan/tilt/zoom
 speed fix.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240405-uvc-fix-relative-ptz-speed-v1-1-c32cdb2a899d@securitylive.com>
References: <20240405-uvc-fix-relative-ptz-speed-v1-0-c32cdb2a899d@securitylive.com>
In-Reply-To: <20240405-uvc-fix-relative-ptz-speed-v1-0-c32cdb2a899d@securitylive.com>
To: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linh.tp.vu@gmail.com, ribalda@chromium.org, soyer@irl.hu, 
 John Bauer <johnebgood@securitylive.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1712300828; l=2495;
 i=johnebgood@securitylive.com; s=20240325; h=from:subject:message-id;
 bh=QZxJ8IkQ+0S1QgP+EtdvdygUUbw+bFRKj/oMsKdGp5w=;
 b=ltsEsCOxbxu0ln1jKn94gzFOMCRQv1XgcnCc6pRVSUAWgUf6DNec5T22UbznyJx0gzeAmMde/
 DvcEhFrQZohAEFPBCPrMov5E8JyalYW1JQtxMYUDblNjqEu+ljLuakL
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

-- 
2.34.1

