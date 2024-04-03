From: John Bauer <johnebgood@securitylive.com>
Date: Wed, 03 Apr 2024 14:58:08 -0500
Subject: [PATCH 2/3] media: uvcvideo: UVC minimum relative pan/tilt/zoom
 speed fix
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240403-uvc-fix-relative-ptz-speed-v1-2-624c9267f745@securitylive.com>
References: <20240403-uvc-fix-relative-ptz-speed-v1-0-624c9267f745@securitylive.com>
In-Reply-To: <20240403-uvc-fix-relative-ptz-speed-v1-0-624c9267f745@securitylive.com>
To: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linh.tp.vu@gmail.com, ribalda@chromium.org, soyer@irl.hu, 
 John Bauer <johnebgood@securitylive.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1712174305; l=2237;
 i=johnebgood@securitylive.com; s=20240325; h=from:subject:message-id;
 bh=XaPSPVobhTGsOxP+SRJcTVrPmARlAP4ikC9wTaKg0Fw=;
 b=pCd2bn9MLzzfJObg+LGhmAA/y7OKa/cYDJqI58Jva6YEELnlKpa+7FsgXS4EJ9XW0+7eazURY
 V+EaB3xg7KfBeYqsRyAUMfHDiF83T2CgL/6+t+7KnFhS78zvRIdy3nJ
X-Developer-Key: i=johnebgood@securitylive.com; a=ed25519;
 pk=RN31Fmrxbidp1TwtZGNmQwTDjUWMPnewQJfA/ug2P9E=
X-Endpoint-Received: by B4 Relay for johnebgood@securitylive.com/20240325 with auth_id=143
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Made recommended changes from Ricardo. I explored the case where
the minimum could be > 0 but less than the maximum. If this were
to occur the range of -maximum to maximum would still apply correctly
however there would be a range from -min to min that would possibly
not apply. It would be possible to capture the probed minimum and
check against that when setting the controls.

Signed-off-by: John Bauer <johnebgood@securitylive.com>
---
 drivers/media/usb/uvc/uvc_ctrl.c | 13 ++++++-------
 1 file changed, 6 insertions(+), 7 deletions(-)

diff --git a/drivers/media/usb/uvc/uvc_ctrl.c b/drivers/media/usb/uvc/uvc_ctrl.c
index b389ab3ee05d..04300a782c81 100644
--- a/drivers/media/usb/uvc/uvc_ctrl.c
+++ b/drivers/media/usb/uvc/uvc_ctrl.c
@@ -1322,6 +1322,10 @@ static int __uvc_query_v4l2_ctrl(struct uvc_video_chain *chain,
 		break;
 	}
 
+	if (ctrl->info.flags & UVC_CTRL_FLAG_GET_MAX)
+		v4l2_ctrl->maximum = mapping->get(mapping, UVC_GET_MAX,
+				     uvc_ctrl_data(ctrl, UVC_CTRL_DATA_MAX));
+
 	if (ctrl->info.flags & UVC_CTRL_FLAG_GET_MIN) {
 		switch (v4l2_ctrl->id) {
 		case V4L2_CID_ZOOM_CONTINUOUS:
@@ -1332,8 +1336,7 @@ static int __uvc_query_v4l2_ctrl(struct uvc_video_chain *chain,
 			 * value cannot be probed so it becomes the additive
 			 * inverse of maximum.
 			 */
-			v4l2_ctrl->minimum = -1 * mapping->get(mapping, UVC_GET_MAX,
-						uvc_ctrl_data(ctrl, UVC_CTRL_DATA_MAX));
+			v4l2_ctrl->minimum = -v4l2_ctrl->maximum;
 			break;
 		default:
 			v4l2_ctrl->minimum = mapping->get(mapping, UVC_GET_MIN,
@@ -1342,10 +1345,6 @@ static int __uvc_query_v4l2_ctrl(struct uvc_video_chain *chain,
 		}
 	}
 
-	if (ctrl->info.flags & UVC_CTRL_FLAG_GET_MAX)
-		v4l2_ctrl->maximum = mapping->get(mapping, UVC_GET_MAX,
-				     uvc_ctrl_data(ctrl, UVC_CTRL_DATA_MAX));
-
 	if (ctrl->info.flags & UVC_CTRL_FLAG_GET_RES)
 		v4l2_ctrl->step = mapping->get(mapping, UVC_GET_RES,
 				  uvc_ctrl_data(ctrl, UVC_CTRL_DATA_RES));
@@ -1940,7 +1939,7 @@ int uvc_ctrl_set(struct uvc_fh *handle,
 		case V4L2_CID_ZOOM_CONTINUOUS:
 		case V4L2_CID_PAN_SPEED:
 		case V4L2_CID_TILT_SPEED:
-			min = max * -1;
+			min = -max;
 		default:
 			break;
 		}

-- 
2.34.1

