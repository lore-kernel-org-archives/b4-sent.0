From: Richard Leitner <richard.leitner@linux.dev>
Date: Tue, 17 Jun 2025 09:31:36 +0200
Subject: [PATCH v5 02/10] media: v4l2-flash: add support for flash/strobe
 duration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250617-ov9282-flash-strobe-v5-2-9762da74d065@linux.dev>
References: <20250617-ov9282-flash-strobe-v5-0-9762da74d065@linux.dev>
In-Reply-To: <20250617-ov9282-flash-strobe-v5-0-9762da74d065@linux.dev>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: Hans Verkuil <hverkuil@xs4all.nl>, linux-media@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-leds@vger.kernel.org, 
 Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750145501; l=2303;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=FrCl/fSGFBnOk0+MAcM+KHDO4zcSf1DpGTy1y8P+ack=;
 b=3UFNRqcZuesqNlodPeYt8efWwjzdPgRjCVXwRt/jIpJBrLTp9ghLKj6Wf9kqDIIYXrsUjEqZy
 Rz92q8lYGiSC1l1yvAJh2SwGAKIGx/nzJJZeSn3Pi/6+Wxkko2LY2Xy
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the new V4L2_CID_FLASH_DURATION control to the v4l2
flash led class.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/v4l2-core/v4l2-flash-led-class.c | 25 +++++++++++++++++++++++++
 1 file changed, 25 insertions(+)

diff --git a/drivers/media/v4l2-core/v4l2-flash-led-class.c b/drivers/media/v4l2-core/v4l2-flash-led-class.c
index 355595a0fefac72c2f6941a30fa430d37dbdccfe..69b6c2026e0ad905aaebcdabe1e7002fc48f9e2c 100644
--- a/drivers/media/v4l2-core/v4l2-flash-led-class.c
+++ b/drivers/media/v4l2-core/v4l2-flash-led-class.c
@@ -29,6 +29,7 @@ enum ctrl_init_data_id {
 	INDICATOR_INTENSITY,
 	FLASH_TIMEOUT,
 	STROBE_SOURCE,
+	FLASH_DURATION,
 	/*
 	 * Only above values are applicable to
 	 * the 'ctrls' array in the struct v4l2_flash.
@@ -298,6 +299,12 @@ static int v4l2_flash_s_ctrl(struct v4l2_ctrl *c)
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
@@ -424,6 +431,14 @@ static void __fill_ctrl_init_data(struct v4l2_flash *v4l2_flash,
 		ctrl_cfg->flags = V4L2_CTRL_FLAG_VOLATILE |
 				  V4L2_CTRL_FLAG_EXECUTE_ON_WRITE;
 	}
+
+	/* Init FLASH_DURATION ctrl data */
+	if (has_flash_op(fled_cdev, duration_set)) {
+		ctrl_init_data[FLASH_DURATION].cid = V4L2_CID_FLASH_DURATION;
+		ctrl_cfg = &ctrl_init_data[FLASH_DURATION].config;
+		__lfs_to_v4l2_ctrl_config(&fled_cdev->duration, ctrl_cfg);
+		ctrl_cfg->id = V4L2_CID_FLASH_DURATION;
+	}
 }
 
 static int v4l2_flash_init_controls(struct v4l2_flash *v4l2_flash,
@@ -543,6 +558,16 @@ static int __sync_device_with_v4l2_controls(struct v4l2_flash *v4l2_flash)
 			return ret;
 	}
 
+	if (ctrls[FLASH_DURATION]) {
+		if (WARN_ON_ONCE(!fled_cdev))
+			return -EINVAL;
+
+		ret = led_set_flash_duration(fled_cdev,
+					ctrls[FLASH_DURATION]->val);
+		if (ret < 0)
+			return ret;
+	}
+
 	/*
 	 * For some hardware arrangements setting strobe source may affect
 	 * torch mode. Synchronize strobe source setting only if not in torch

-- 
2.47.2

