From: Richard Leitner <richard.leitner@linux.dev>
Date: Tue, 29 Apr 2025 14:59:08 +0200
Subject: [PATCH v3 3/9] media: v4l2-flash: add support for flash/strobe
 duration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250429-ov9282-flash-strobe-v3-3-2105ce179952@linux.dev>
References: <20250429-ov9282-flash-strobe-v3-0-2105ce179952@linux.dev>
In-Reply-To: <20250429-ov9282-flash-strobe-v3-0-2105ce179952@linux.dev>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: Hans Verkuil <hverkuil@xs4all.nl>, linux-media@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-leds@vger.kernel.org, 
 Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745931554; l=1581;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=bHa9DyU5pY4KwqBVVlo7OhSDU5Z0nzs/MOBy8JAQCk8=;
 b=hVLXrCC7H/khQgUUmgEY6fKTLCw2sfgTBSOK7fv5eNAhyCFTkDCcubJY6AF75MdxFRtdzZy2o
 yzE9BVZM+BTDwY3RokFPA6JAstT7f+XTi0dkNf5jgv//PoSkhrv764I
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the new V4L2_CID_FLASH_DURATION control to the v4l2
flash led class.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/v4l2-core/v4l2-flash-led-class.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/media/v4l2-core/v4l2-flash-led-class.c b/drivers/media/v4l2-core/v4l2-flash-led-class.c
index 355595a0fefac72c2f6941a30fa430d37dbdccfe..963b549480f6eb3b9eb0d80696a764de7ffcc1a2 100644
--- a/drivers/media/v4l2-core/v4l2-flash-led-class.c
+++ b/drivers/media/v4l2-core/v4l2-flash-led-class.c
@@ -298,6 +298,12 @@ static int v4l2_flash_s_ctrl(struct v4l2_ctrl *c)
 		 * microamperes for flash intensity units.
 		 */
 		return led_set_flash_brightness(fled_cdev, c->val);
+	case V4L2_CID_FLASH_DURATION:
+		/*
+		 * No conversion is needed as LED Flash class also uses
+		 * microseconds for flash duration units.
+		 */
+		return led_set_flash_duration(fled_cdev, c->val);
 	}
 
 	return -EINVAL;
@@ -424,6 +430,13 @@ static void __fill_ctrl_init_data(struct v4l2_flash *v4l2_flash,
 		ctrl_cfg->flags = V4L2_CTRL_FLAG_VOLATILE |
 				  V4L2_CTRL_FLAG_EXECUTE_ON_WRITE;
 	}
+
+	/* Init FLASH_DURATION ctrl data */
+	if (has_flash_op(fled_cdev, timeout_set)) {
+		ctrl_init_data[FLASH_DURATION].cid = V4L2_CID_FLASH_DURATION;
+		ctrl_cfg = &ctrl_init_data[FLASH_DURATION].config;
+		__lfs_to_v4l2_ctrl_config(&fled_cdev->duration, ctrl_cfg);
+		ctrl_cfg->id = V4L2_CID_FLASH_DURATION;
 }
 
 static int v4l2_flash_init_controls(struct v4l2_flash *v4l2_flash,

-- 
2.47.2

