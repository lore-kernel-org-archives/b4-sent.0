From: Richard Leitner <richard.leitner@linux.dev>
Date: Tue, 04 Nov 2025 15:30:52 +0100
Subject: [PATCH v8 1/8] media: v4l: ctrls: add a control for flash/strobe
 duration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251104-ov9282-flash-strobe-v8-1-b91dfef1c65a@linux.dev>
References: <20251104-ov9282-flash-strobe-v8-0-b91dfef1c65a@linux.dev>
In-Reply-To: <20251104-ov9282-flash-strobe-v8-0-b91dfef1c65a@linux.dev>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-leds@vger.kernel.org, Richard Leitner <richard.leitner@linux.dev>, 
 Hans Verkuil <hverkuil@kernel.org>
X-Mailer: b4 0.15-dev-509f5
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762266668; l=1820;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=UANwLOgcj9WwONW3K+0Sy55FYPHJ20LKps0TM9A7gAM=;
 b=RdU6KiIoLWrm9x31+vdY74YcAAIGkKWQ7InHoJrFG+E/ThxZYIojLc+6qdz16VJ4X2SjxcIaI
 IVO4oDL872GB9SnkzD1h4mFYzecp4mbHW6ae2MGZvWq7i9cYvfHepA1
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a V4L2_CID_FLASH_DURATION control to set the duration of a
flash/strobe pulse. This controls the length of the flash/strobe pulse
output by device (typically a camera sensor) and connected to the flash
controller. This is different to the V4L2_CID_FLASH_TIMEOUT control,
which is implemented by the flash controller and defines a limit after
which the flash is "forcefully" turned off again.

Reviewed-by: Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/v4l2-core/v4l2-ctrls-defs.c | 1 +
 include/uapi/linux/v4l2-controls.h        | 1 +
 2 files changed, 2 insertions(+)

diff --git a/drivers/media/v4l2-core/v4l2-ctrls-defs.c b/drivers/media/v4l2-core/v4l2-ctrls-defs.c
index ad41f65374e23..4848423205ff7 100644
--- a/drivers/media/v4l2-core/v4l2-ctrls-defs.c
+++ b/drivers/media/v4l2-core/v4l2-ctrls-defs.c
@@ -1135,6 +1135,7 @@ const char *v4l2_ctrl_get_name(u32 id)
 	case V4L2_CID_FLASH_FAULT:		return "Faults";
 	case V4L2_CID_FLASH_CHARGE:		return "Charge";
 	case V4L2_CID_FLASH_READY:		return "Ready to Strobe";
+	case V4L2_CID_FLASH_DURATION:		return "Strobe Duration";
 
 	/* JPEG encoder controls */
 	/* Keep the order of the 'case's the same as in v4l2-controls.h! */
diff --git a/include/uapi/linux/v4l2-controls.h b/include/uapi/linux/v4l2-controls.h
index 2d30107e047ee..9830833b48a52 100644
--- a/include/uapi/linux/v4l2-controls.h
+++ b/include/uapi/linux/v4l2-controls.h
@@ -1186,6 +1186,7 @@ enum v4l2_flash_strobe_source {
 
 #define V4L2_CID_FLASH_CHARGE			(V4L2_CID_FLASH_CLASS_BASE + 11)
 #define V4L2_CID_FLASH_READY			(V4L2_CID_FLASH_CLASS_BASE + 12)
+#define V4L2_CID_FLASH_DURATION			(V4L2_CID_FLASH_CLASS_BASE + 13)
 
 
 /* JPEG-class control IDs */

-- 
2.47.3

