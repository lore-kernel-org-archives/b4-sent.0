From: Michael Riesch <michael.riesch@wolfvision.net>
Date: Thu, 06 Apr 2023 16:31:13 +0200
Subject: [PATCH RFC 4/4] media: v4l2-ctrls: add controls for individual
 zoom lenses
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230406-feature-controls-lens-v1-4-543189a680de@wolfvision.net>
References: <20230406-feature-controls-lens-v1-0-543189a680de@wolfvision.net>
In-Reply-To: <20230406-feature-controls-lens-v1-0-543189a680de@wolfvision.net>
To: Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: libcamera-devel@lists.libcamera.org, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Matthias Fend <Matthias.Fend@wolfvision.net>, linux-media@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Michael Riesch <michael.riesch@wolfvision.net>
X-Mailer: b4 0.12.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1680791498; l=4975;
 i=michael.riesch@wolfvision.net; s=20230406; h=from:subject:message-id;
 bh=bWxc8Ua5gbQYUJyRGSLgrVBk7cmDY97sq4ZtW5eVx8o=;
 b=FRhHgOOPeeWYPHlfi10xNaxB9EQWRcKsY/3IdhIFJJQnh6VhfwiI2bRP4HI/PTIV4h0MrUMc1
 +qwu9p8YNc9BKVePQhZXrNxF1IQWgFlFqjRPSmyvOQ8UmuHnnQTeJmn
X-Developer-Key: i=michael.riesch@wolfvision.net; a=ed25519;
 pk=G03kuYHL670EcdsWaNfVA7KnHWmkSpj98XziQm/hjbk=
X-Endpoint-Received: by B4 Relay for michael.riesch@wolfvision.net/20230406 with auth_id=38
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A zoom lens group may consist of several lenses, and in a calibration
context it may be necessary to position the lenses individually. Add a pair
of V4L2_CID_LENS_CALIB_ZOOMx_ABSOLUTE and V4L2_CID_LENS_CALIB_ZOOMx_STATUS
controls for each individual lens, where x = {1...5}.

Signed-off-by: Michael Riesch <michael.riesch@wolfvision.net>
---
 .../userspace-api/media/v4l/ext-ctrls-camera.rst          | 12 ++++++++++++
 drivers/media/v4l2-core/v4l2-ctrls-defs.c                 | 15 +++++++++++++++
 include/uapi/linux/v4l2-controls.h                        | 12 ++++++++++++
 3 files changed, 39 insertions(+)

diff --git a/Documentation/userspace-api/media/v4l/ext-ctrls-camera.rst b/Documentation/userspace-api/media/v4l/ext-ctrls-camera.rst
index 441467a971ac..920c7be2823d 100644
--- a/Documentation/userspace-api/media/v4l/ext-ctrls-camera.rst
+++ b/Documentation/userspace-api/media/v4l/ext-ctrls-camera.rst
@@ -332,6 +332,18 @@ enum v4l2_auto_focus_range -
     * - ``V4L2_LENS_CALIB_FAILED``
       - Lens calibration procedure has failed.
 
+``V4L2_CID_LENS_CALIB_ZOOM{1...5}_ABSOLUTE`` (integer)
+    Set the absolute position of the individual lens of the zoom lens group.
+    Most likely, this is done in a calibration context. The unit is
+    driver-specific.
+
+``V4L2_CID_LENS_CALIB_ZOOM{1...5}_STATUS`` (struct)
+    The current status of the individual lens of the zoom lens group. Most
+    likely, this is done in a calibration context. This is a read-only control.
+    The returned data structure contains the current position and movement
+    indication flags. The unit of the current position is driver-specific. For
+    the description of the flags refer to V4L2_CID_ZOOM_ABSOLUTE.
+
 ``V4L2_CID_IRIS_ABSOLUTE (integer)``
     This control sets the camera's aperture to the specified value. The
     unit is undefined. Larger values open the iris wider, smaller values
diff --git a/drivers/media/v4l2-core/v4l2-ctrls-defs.c b/drivers/media/v4l2-core/v4l2-ctrls-defs.c
index 382abf6be9de..7d1154d05102 100644
--- a/drivers/media/v4l2-core/v4l2-ctrls-defs.c
+++ b/drivers/media/v4l2-core/v4l2-ctrls-defs.c
@@ -1050,6 +1050,16 @@ const char *v4l2_ctrl_get_name(u32 id)
 	case V4L2_CID_ZOOM_SPEED:		return "Zoom, Speed";
 	case V4L2_CID_LENS_CALIB_CONTROL:	return "Lens Calibration, Control";
 	case V4L2_CID_LENS_CALIB_STATUS:	return "Lens Calibration, Status";
+	case V4L2_CID_LENS_CALIB_ZOOM1_ABSOLUTE:	return "Zoom1, Absolute";
+	case V4L2_CID_LENS_CALIB_ZOOM2_ABSOLUTE:	return "Zoom2, Absolute";
+	case V4L2_CID_LENS_CALIB_ZOOM3_ABSOLUTE:	return "Zoom3, Absolute";
+	case V4L2_CID_LENS_CALIB_ZOOM4_ABSOLUTE:	return "Zoom4, Absolute";
+	case V4L2_CID_LENS_CALIB_ZOOM5_ABSOLUTE:	return "Zoom5, Absolute";
+	case V4L2_CID_LENS_CALIB_ZOOM1_STATUS:	return "Zoom1, Status";
+	case V4L2_CID_LENS_CALIB_ZOOM2_STATUS:	return "Zoom2, Status";
+	case V4L2_CID_LENS_CALIB_ZOOM3_STATUS:	return "Zoom3, Status";
+	case V4L2_CID_LENS_CALIB_ZOOM4_STATUS:	return "Zoom4, Status";
+	case V4L2_CID_LENS_CALIB_ZOOM5_STATUS:	return "Zoom5, Status";
 
 	/* FM Radio Modulator controls */
 	/* Keep the order of the 'case's the same as in v4l2-controls.h! */
@@ -1602,6 +1612,11 @@ void v4l2_ctrl_fill(u32 id, const char **name, enum v4l2_ctrl_type *type,
 		break;
 	case V4L2_CID_FOCUS_STATUS:
 	case V4L2_CID_ZOOM_STATUS:
+	case V4L2_CID_LENS_CALIB_ZOOM1_STATUS:
+	case V4L2_CID_LENS_CALIB_ZOOM2_STATUS:
+	case V4L2_CID_LENS_CALIB_ZOOM3_STATUS:
+	case V4L2_CID_LENS_CALIB_ZOOM4_STATUS:
+	case V4L2_CID_LENS_CALIB_ZOOM5_STATUS:
 		*type = V4L2_CTRL_TYPE_LENS_STATUS;
 		*flags |= V4L2_CTRL_FLAG_READ_ONLY | V4L2_CTRL_FLAG_VOLATILE;
 		break;
diff --git a/include/uapi/linux/v4l2-controls.h b/include/uapi/linux/v4l2-controls.h
index 34601ad1213a..232e6d1d7655 100644
--- a/include/uapi/linux/v4l2-controls.h
+++ b/include/uapi/linux/v4l2-controls.h
@@ -1020,6 +1020,18 @@ struct v4l2_ctrl_lens_status {
 
 #define V4L2_CID_LENS_CALIB_STATUS		(V4L2_CID_CAMERA_CLASS_BASE + 42)
 
+#define V4L2_CID_LENS_CALIB_ZOOM1_ABSOLUTE	(V4L2_CID_CAMERA_CLASS_BASE + 43)
+#define V4L2_CID_LENS_CALIB_ZOOM2_ABSOLUTE	(V4L2_CID_CAMERA_CLASS_BASE + 44)
+#define V4L2_CID_LENS_CALIB_ZOOM3_ABSOLUTE	(V4L2_CID_CAMERA_CLASS_BASE + 45)
+#define V4L2_CID_LENS_CALIB_ZOOM4_ABSOLUTE	(V4L2_CID_CAMERA_CLASS_BASE + 46)
+#define V4L2_CID_LENS_CALIB_ZOOM5_ABSOLUTE	(V4L2_CID_CAMERA_CLASS_BASE + 47)
+
+#define V4L2_CID_LENS_CALIB_ZOOM1_STATUS	(V4L2_CID_CAMERA_CLASS_BASE + 48)
+#define V4L2_CID_LENS_CALIB_ZOOM2_STATUS	(V4L2_CID_CAMERA_CLASS_BASE + 49)
+#define V4L2_CID_LENS_CALIB_ZOOM3_STATUS	(V4L2_CID_CAMERA_CLASS_BASE + 50)
+#define V4L2_CID_LENS_CALIB_ZOOM4_STATUS	(V4L2_CID_CAMERA_CLASS_BASE + 51)
+#define V4L2_CID_LENS_CALIB_ZOOM5_STATUS	(V4L2_CID_CAMERA_CLASS_BASE + 52)
+
 /* FM Modulator class control IDs */
 
 #define V4L2_CID_FM_TX_CLASS_BASE		(V4L2_CTRL_CLASS_FM_TX | 0x900)

-- 
2.30.2

