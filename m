From: Richard Leitner <richard.leitner@linux.dev>
Date: Wed, 07 May 2025 09:51:38 +0200
Subject: [PATCH v4 09/10] media: i2c: ov9282: add strobe_source v4l2
 control
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250507-ov9282-flash-strobe-v4-9-72b299c1b7c9@linux.dev>
References: <20250507-ov9282-flash-strobe-v4-0-72b299c1b7c9@linux.dev>
In-Reply-To: <20250507-ov9282-flash-strobe-v4-0-72b299c1b7c9@linux.dev>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: Hans Verkuil <hverkuil@xs4all.nl>, linux-media@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-leds@vger.kernel.org, 
 Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746604340; l=1686;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=8vJtoHTUTJrvONHO5vnxfREHXCoupGjqP9LZtMbdTp8=;
 b=E2JTQ4G5ISf8J+ZKkw1SGv3NDaPKG+xpsxVH4/leWk99GZAKugTPnIkldfWZKDFoLfftzorYx
 /jPLVRjZTXrAG12ZOmNS/C2KL9YDeIDnIu8eITOyobyCMUpJsackX5D
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add read-only V4L2_CID_FLASH_STROBE_SOURCE control. Its value is fixed
to V4L2_FLASH_STROBE_SOURCE_EXTERNAL as the camera sensor triggers the
strobe based on its register settings.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/i2c/ov9282.c | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/ov9282.c b/drivers/media/i2c/ov9282.c
index 0bbdf08d7cda8f72e05fdc292aa69a4c821e4e03..09d522d5977ec6fb82028ddb6015f05c9328191d 100644
--- a/drivers/media/i2c/ov9282.c
+++ b/drivers/media/i2c/ov9282.c
@@ -1368,11 +1368,12 @@ static int ov9282_init_controls(struct ov9282 *ov9282)
 	struct v4l2_ctrl_handler *ctrl_hdlr = &ov9282->ctrl_handler;
 	const struct ov9282_mode *mode = ov9282->cur_mode;
 	struct v4l2_fwnode_device_properties props;
+	struct v4l2_ctrl *ctrl;
 	u32 hblank_min;
 	u32 lpfr;
 	int ret;
 
-	ret = v4l2_ctrl_handler_init(ctrl_hdlr, 12);
+	ret = v4l2_ctrl_handler_init(ctrl_hdlr, 13);
 	if (ret)
 		return ret;
 
@@ -1447,6 +1448,14 @@ static int ov9282_init_controls(struct ov9282 *ov9282)
 	v4l2_ctrl_new_std(ctrl_hdlr, &ov9282_ctrl_ops, V4L2_CID_FLASH_DURATION,
 			  0, 13900, 1, 8);
 
+	ctrl = v4l2_ctrl_new_std_menu(ctrl_hdlr, &ov9282_ctrl_ops,
+				      V4L2_CID_FLASH_STROBE_SOURCE,
+				      V4L2_FLASH_STROBE_SOURCE_EXTERNAL,
+				      ~(1 << V4L2_FLASH_STROBE_SOURCE_EXTERNAL),
+				      V4L2_FLASH_STROBE_SOURCE_EXTERNAL);
+	if (ctrl)
+		ctrl->flags |= V4L2_CTRL_FLAG_READ_ONLY;
+
 	ret = v4l2_fwnode_device_parse(ov9282->dev, &props);
 	if (!ret) {
 		/* Failure sets ctrl_hdlr->error, which we check afterwards anyway */

-- 
2.47.2

