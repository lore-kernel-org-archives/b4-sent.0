From: Michael Riesch <michael.riesch@wolfvision.net>
Date: Thu, 06 Apr 2023 16:31:11 +0200
Subject: [PATCH RFC 2/4] media: v4l2-ctrls: add lens group speed controls
 for zoom and focus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230406-feature-controls-lens-v1-2-543189a680de@wolfvision.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1680791498; l=3216;
 i=michael.riesch@wolfvision.net; s=20230406; h=from:subject:message-id;
 bh=b4YZSmV5OSkcANw6i4qtO28ABjbGRhtxIpQPQN9ckB4=;
 b=xFNDz6axwjBG+xovNgY7mhVeYp78O/FABWR7nJ0us5zRPKrzF8b16IMVDdHUF5xbRzkC44/IV
 PXcB7I0DjV+DTflx2oZTqzwinj34zhn4dpu8VV81rOlpmLYlymiYWFk
X-Developer-Key: i=michael.riesch@wolfvision.net; a=ed25519;
 pk=G03kuYHL670EcdsWaNfVA7KnHWmkSpj98XziQm/hjbk=
X-Endpoint-Received: by B4 Relay for michael.riesch@wolfvision.net/20230406 with auth_id=38
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the controls V4L2_CID_FOCUS_SPEED and V4L2_CID_ZOOM_SPEED that set
the speed of the zoom lens group and focus lens group, respectively.

Signed-off-by: Michael Riesch <michael.riesch@wolfvision.net>
---
 Documentation/userspace-api/media/v4l/ext-ctrls-camera.rst | 10 ++++++++++
 drivers/media/v4l2-core/v4l2-ctrls-defs.c                  |  2 ++
 include/uapi/linux/v4l2-controls.h                         |  2 ++
 3 files changed, 14 insertions(+)

diff --git a/Documentation/userspace-api/media/v4l/ext-ctrls-camera.rst b/Documentation/userspace-api/media/v4l/ext-ctrls-camera.rst
index 3a270bc63f1a..5e34515024bd 100644
--- a/Documentation/userspace-api/media/v4l/ext-ctrls-camera.rst
+++ b/Documentation/userspace-api/media/v4l/ext-ctrls-camera.rst
@@ -173,6 +173,11 @@ enum v4l2_exposure_metering -
 	will not transition from this state until another action is performed
 	by an application.
 
+``V4L2_CID_FOCUS_SPEED (integer)``
+    Set the speed with which the focus lens group of the camera is moved
+    (V4L2_CID_FOCUS_ABSOLUTE and V4L2_CID_FOCUS_RELATIVE). The unit is
+    driver-specific. The value should be a positive integer.
+
 ``V4L2_CID_FOCUS_AUTO (boolean)``
     Enables continuous automatic focus adjustments. The effect of manual
     focus adjustments while this feature is enabled is undefined,
@@ -287,6 +292,11 @@ enum v4l2_auto_focus_range -
 	not transition from this state until another action is performed by an
 	application.
 
+``V4L2_CID_ZOOM_SPEED (integer)``
+    Set the speed with which the zoom lens group of the camera is moved
+    (V4L2_CID_ZOOM_ABSOLUTE and V4L2_CID_ZOOM_RELATIVE). The unit is
+    driver-specific. The value should be a positive integer.
+
 ``V4L2_CID_IRIS_ABSOLUTE (integer)``
     This control sets the camera's aperture to the specified value. The
     unit is undefined. Larger values open the iris wider, smaller values
diff --git a/drivers/media/v4l2-core/v4l2-ctrls-defs.c b/drivers/media/v4l2-core/v4l2-ctrls-defs.c
index 9b26a3aa9e9c..2c21bcccc6ee 100644
--- a/drivers/media/v4l2-core/v4l2-ctrls-defs.c
+++ b/drivers/media/v4l2-core/v4l2-ctrls-defs.c
@@ -1046,6 +1046,8 @@ const char *v4l2_ctrl_get_name(u32 id)
 	case V4L2_CID_HDR_SENSOR_MODE:		return "HDR Sensor Mode";
 	case V4L2_CID_FOCUS_STATUS:		return "Focus, Status";
 	case V4L2_CID_ZOOM_STATUS:		return "Zoom, Status";
+	case V4L2_CID_FOCUS_SPEED:		return "Focus, Speed";
+	case V4L2_CID_ZOOM_SPEED:		return "Zoom, Speed";
 
 	/* FM Radio Modulator controls */
 	/* Keep the order of the 'case's the same as in v4l2-controls.h! */
diff --git a/include/uapi/linux/v4l2-controls.h b/include/uapi/linux/v4l2-controls.h
index 8b037467ba9a..fecce641d0d8 100644
--- a/include/uapi/linux/v4l2-controls.h
+++ b/include/uapi/linux/v4l2-controls.h
@@ -1005,6 +1005,8 @@ struct v4l2_ctrl_lens_status {
 
 #define V4L2_CID_FOCUS_STATUS			(V4L2_CID_CAMERA_CLASS_BASE + 37)
 #define V4L2_CID_ZOOM_STATUS			(V4L2_CID_CAMERA_CLASS_BASE + 38)
+#define V4L2_CID_FOCUS_SPEED			(V4L2_CID_CAMERA_CLASS_BASE + 39)
+#define V4L2_CID_ZOOM_SPEED			(V4L2_CID_CAMERA_CLASS_BASE + 40)
 
 /* FM Modulator class control IDs */
 

-- 
2.30.2

