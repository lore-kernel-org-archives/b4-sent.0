From: Michael Riesch <michael.riesch@wolfvision.net>
Date: Thu, 06 Apr 2023 16:31:12 +0200
Subject: [PATCH RFC 3/4] media: v4l2-ctrls: add lens calibration controls
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230406-feature-controls-lens-v1-3-543189a680de@wolfvision.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1680791498; l=4774;
 i=michael.riesch@wolfvision.net; s=20230406; h=from:subject:message-id;
 bh=xh3oWCYEuxKk813VjgkzcdJVj/4p3Q2RGXeu2ehNS1Q=;
 b=HN0AoCiyPKygCIQ1I7KzCH9sjczrGs3Z2VEzTS8xEI2rqm2rc0BcDmI7b5LEd/bfAoiQQFQG6
 v4Qi5xwyoSHAGW/dEEDTTh1ZbR/9zJIz/6NBPjEsswAtcvHkITiPqH3
X-Developer-Key: i=michael.riesch@wolfvision.net; a=ed25519;
 pk=G03kuYHL670EcdsWaNfVA7KnHWmkSpj98XziQm/hjbk=
X-Endpoint-Received: by B4 Relay for michael.riesch@wolfvision.net/20230406 with auth_id=38
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the controls V4L2_CID_LENS_CALIB_CONTROL and V4L2_CID_LENS_CALIB_STATUS
that facilitate the control of the lens group calibration procedure.

Signed-off-by: Michael Riesch <michael.riesch@wolfvision.net>
---
 .../userspace-api/media/v4l/ext-ctrls-camera.rst   | 35 ++++++++++++++++++++++
 drivers/media/v4l2-core/v4l2-ctrls-defs.c          |  6 ++++
 include/uapi/linux/v4l2-controls.h                 | 12 ++++++++
 3 files changed, 53 insertions(+)

diff --git a/Documentation/userspace-api/media/v4l/ext-ctrls-camera.rst b/Documentation/userspace-api/media/v4l/ext-ctrls-camera.rst
index 5e34515024bd..441467a971ac 100644
--- a/Documentation/userspace-api/media/v4l/ext-ctrls-camera.rst
+++ b/Documentation/userspace-api/media/v4l/ext-ctrls-camera.rst
@@ -297,6 +297,41 @@ enum v4l2_auto_focus_range -
     (V4L2_CID_ZOOM_ABSOLUTE and V4L2_CID_ZOOM_RELATIVE). The unit is
     driver-specific. The value should be a positive integer.
 
+``V4L2_CID_LENS_CALIB_CONTROL (bitmask)``
+    Control the calibration procedure (or individual parts thereof) of the lens
+    groups. For example, this could include the mechanical range detection
+    of zoom lens motors. This is a write-only control.
+
+.. tabularcolumns:: |p{6.8cm}|p{10.7cm}|
+
+.. flat-table::
+    :header-rows:  0
+    :stub-columns: 0
+
+    * - ``V4L2_LENS_CALIB_STOP``
+      - Stop the lens calibration procedure.
+    * - ``V4L2_LENS_CALIB_START``
+      - Start the complete lens calibration procedure.
+
+``V4L2_CID_LENS_CALIB_CONTROL (bitmask)``
+    The status of the calibration procedure (or individual parts thereof) of
+    the lens groups. This is a read-only control.
+
+.. tabularcolumns:: |p{6.8cm}|p{10.7cm}|
+
+.. flat-table::
+    :header-rows:  0
+    :stub-columns: 0
+
+    * - ``V4L2_LENS_CALIB_IDLE``
+      - Lens calibration procedure has not yet been started.
+    * - ``V4L2_LENS_CALIB_BUSY``
+      - Lens calibration procedure is in progress.
+    * - ``V4L2_LENS_CALIB_COMPLETE``
+      - Lens calibration procedure is complete.
+    * - ``V4L2_LENS_CALIB_FAILED``
+      - Lens calibration procedure has failed.
+
 ``V4L2_CID_IRIS_ABSOLUTE (integer)``
     This control sets the camera's aperture to the specified value. The
     unit is undefined. Larger values open the iris wider, smaller values
diff --git a/drivers/media/v4l2-core/v4l2-ctrls-defs.c b/drivers/media/v4l2-core/v4l2-ctrls-defs.c
index 2c21bcccc6ee..382abf6be9de 100644
--- a/drivers/media/v4l2-core/v4l2-ctrls-defs.c
+++ b/drivers/media/v4l2-core/v4l2-ctrls-defs.c
@@ -1048,6 +1048,8 @@ const char *v4l2_ctrl_get_name(u32 id)
 	case V4L2_CID_ZOOM_STATUS:		return "Zoom, Status";
 	case V4L2_CID_FOCUS_SPEED:		return "Focus, Speed";
 	case V4L2_CID_ZOOM_SPEED:		return "Zoom, Speed";
+	case V4L2_CID_LENS_CALIB_CONTROL:	return "Lens Calibration, Control";
+	case V4L2_CID_LENS_CALIB_STATUS:	return "Lens Calibration, Status";
 
 	/* FM Radio Modulator controls */
 	/* Keep the order of the 'case's the same as in v4l2-controls.h! */
@@ -1594,6 +1596,7 @@ void v4l2_ctrl_fill(u32 id, const char **name, enum v4l2_ctrl_type *type,
 	case V4L2_CID_FOCUS_RELATIVE:
 	case V4L2_CID_IRIS_RELATIVE:
 	case V4L2_CID_ZOOM_RELATIVE:
+	case V4L2_CID_LENS_CALIB_CONTROL:
 		*flags |= V4L2_CTRL_FLAG_WRITE_ONLY |
 			  V4L2_CTRL_FLAG_EXECUTE_ON_WRITE;
 		break;
@@ -1602,6 +1605,9 @@ void v4l2_ctrl_fill(u32 id, const char **name, enum v4l2_ctrl_type *type,
 		*type = V4L2_CTRL_TYPE_LENS_STATUS;
 		*flags |= V4L2_CTRL_FLAG_READ_ONLY | V4L2_CTRL_FLAG_VOLATILE;
 		break;
+	case V4L2_CID_LENS_CALIB_STATUS:
+		*flags |= V4L2_CTRL_FLAG_READ_ONLY | V4L2_CTRL_FLAG_VOLATILE;
+		break;
 	case V4L2_CID_FLASH_STROBE_STATUS:
 	case V4L2_CID_AUTO_FOCUS_STATUS:
 	case V4L2_CID_FLASH_READY:
diff --git a/include/uapi/linux/v4l2-controls.h b/include/uapi/linux/v4l2-controls.h
index fecce641d0d8..34601ad1213a 100644
--- a/include/uapi/linux/v4l2-controls.h
+++ b/include/uapi/linux/v4l2-controls.h
@@ -1008,6 +1008,18 @@ struct v4l2_ctrl_lens_status {
 #define V4L2_CID_FOCUS_SPEED			(V4L2_CID_CAMERA_CLASS_BASE + 39)
 #define V4L2_CID_ZOOM_SPEED			(V4L2_CID_CAMERA_CLASS_BASE + 40)
 
+#define V4L2_LENS_CALIB_STOP			(0 << 0)
+#define V4L2_LENS_CALIB_START			(1 << 0)
+
+#define V4L2_CID_LENS_CALIB_CONTROL		(V4L2_CID_CAMERA_CLASS_BASE + 41)
+
+#define V4L2_LENS_CALIB_IDLE			(0 << 0)
+#define V4L2_LENS_CALIB_BUSY			(1 << 0)
+#define V4L2_LENS_STATUS_COMPLETE		(1 << 1)
+#define V4L2_LENS_STATUS_FAILED			(1 << 2)
+
+#define V4L2_CID_LENS_CALIB_STATUS		(V4L2_CID_CAMERA_CLASS_BASE + 42)
+
 /* FM Modulator class control IDs */
 
 #define V4L2_CID_FM_TX_CLASS_BASE		(V4L2_CTRL_CLASS_FM_TX | 0x900)

-- 
2.30.2

