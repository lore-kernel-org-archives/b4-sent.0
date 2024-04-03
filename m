From: John Bauer <johnebgood@securitylive.com>
Date: Wed, 03 Apr 2024 14:58:09 -0500
Subject: [PATCH 3/3] media: uvcvideo: Moved control checks to helper
 function
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240403-uvc-fix-relative-ptz-speed-v1-3-624c9267f745@securitylive.com>
References: <20240403-uvc-fix-relative-ptz-speed-v1-0-624c9267f745@securitylive.com>
In-Reply-To: <20240403-uvc-fix-relative-ptz-speed-v1-0-624c9267f745@securitylive.com>
To: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linh.tp.vu@gmail.com, ribalda@chromium.org, soyer@irl.hu, 
 John Bauer <johnebgood@securitylive.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1712174305; l=2692;
 i=johnebgood@securitylive.com; s=20240325; h=from:subject:message-id;
 bh=2nl53Ftu6Hpf35R3FNa8JPbVSTHm2rJO1iLfSKB2ysg=;
 b=BhLEBiU0ZU86ee4ynGsqy1lFJdDPqxN8ydK1MeNxTyyuxPXHnWaLEAdFaP4ffI6z2Y/HjSzDy
 AyLB7FWoRxJDQTr3AuakRSnCoM6/nkz7NOiXW7IvPBYLDKLc86/p+QM
X-Developer-Key: i=johnebgood@securitylive.com; a=ed25519;
 pk=RN31Fmrxbidp1TwtZGNmQwTDjUWMPnewQJfA/ug2P9E=
X-Endpoint-Received: by B4 Relay for johnebgood@securitylive.com/20240325 with auth_id=143
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Made additional recommended changes from Ricardo. Relative
controls are now checked with helper function is_relative_ptz_ctrl().

Signed-off-by: John Bauer <johnebgood@securitylive.com>
---
 drivers/media/usb/uvc/uvc_ctrl.c | 40 +++++++++++++++++++---------------------
 1 file changed, 19 insertions(+), 21 deletions(-)

diff --git a/drivers/media/usb/uvc/uvc_ctrl.c b/drivers/media/usb/uvc/uvc_ctrl.c
index 04300a782c81..34a9a29b0754 100644
--- a/drivers/media/usb/uvc/uvc_ctrl.c
+++ b/drivers/media/usb/uvc/uvc_ctrl.c
@@ -441,7 +441,6 @@ static s32 uvc_ctrl_get_rel_speed(struct uvc_control_mapping *mapping,
 		return (rel == 0) ? 0 : (rel > 0 ? data[first+1]
 						 : -data[first+1]);
 	case UVC_GET_MIN:
-		return -data[first+1];
 	case UVC_GET_MAX:
 	case UVC_GET_RES:
 	case UVC_GET_DEF:
@@ -1233,6 +1232,17 @@ static u32 uvc_get_ctrl_bitmap(struct uvc_control *ctrl,
 	return ~0;
 }
 
+static bool is_relative_ptz_ctrl(__u32 ctrl_id)
+{
+	switch (ctrl_id) {
+	case V4L2_CID_ZOOM_CONTINUOUS:
+	case V4L2_CID_PAN_SPEED:
+	case V4L2_CID_TILT_SPEED:
+		return true;
+	}
+	return false;
+}
+
 static int __uvc_query_v4l2_ctrl(struct uvc_video_chain *chain,
 	struct uvc_control *ctrl,
 	struct uvc_control_mapping *mapping,
@@ -1327,22 +1337,16 @@ static int __uvc_query_v4l2_ctrl(struct uvc_video_chain *chain,
 				     uvc_ctrl_data(ctrl, UVC_CTRL_DATA_MAX));
 
 	if (ctrl->info.flags & UVC_CTRL_FLAG_GET_MIN) {
-		switch (v4l2_ctrl->id) {
-		case V4L2_CID_ZOOM_CONTINUOUS:
-		case V4L2_CID_PAN_SPEED:
-		case V4L2_CID_TILT_SPEED:
-			/*
-			 * For the relative speed implementation the minimum
-			 * value cannot be probed so it becomes the additive
-			 * inverse of maximum.
-			 */
+		/*
+		 * For the relative speed implementation the minimum
+		 * value cannot be probed so it becomes the additive
+		 * inverse of maximum.
+		 */
+		if (is_relative_ptz_ctrl(v4l2_ctrl->id))
 			v4l2_ctrl->minimum = -v4l2_ctrl->maximum;
-			break;
-		default:
+		else
 			v4l2_ctrl->minimum = mapping->get(mapping, UVC_GET_MIN,
 						uvc_ctrl_data(ctrl, UVC_CTRL_DATA_MIN));
-			break;
-		}
 	}
 
 	if (ctrl->info.flags & UVC_CTRL_FLAG_GET_RES)
@@ -1935,14 +1939,8 @@ int uvc_ctrl_set(struct uvc_fh *handle,
 		 * value cannot be probed so it becomes the additive
 		 * inverse of maximum.
 		 */
-		switch (xctrl->id) {
-		case V4L2_CID_ZOOM_CONTINUOUS:
-		case V4L2_CID_PAN_SPEED:
-		case V4L2_CID_TILT_SPEED:
+		if (is_relative_ptz_ctrl(xctrl->id))
 			min = -max;
-		default:
-			break;
-		}
 
 		step = mapping->get(mapping, UVC_GET_RES,
 				    uvc_ctrl_data(ctrl, UVC_CTRL_DATA_RES));

-- 
2.34.1

