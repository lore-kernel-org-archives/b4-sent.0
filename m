From: Richard Leitner <richard.leitner@linux.dev>
Date: Fri, 14 Mar 2025 09:49:56 +0100
Subject: [PATCH v2 2/8] media: v4l2-flash: add support for flash/stobe
 duration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250314-ov9282-flash-strobe-v2-2-14d7a281342d@linux.dev>
References: <20250314-ov9282-flash-strobe-v2-0-14d7a281342d@linux.dev>
In-Reply-To: <20250314-ov9282-flash-strobe-v2-0-14d7a281342d@linux.dev>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-leds@vger.kernel.org, Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741942203; l=4241;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=LVdkx1HHnCgF9PxdCqbpp0HAodzXvbi8+XOQgquqxWI=;
 b=T1N5UmGtWggEUhkBBhtxOf4UrOFcr+ii4LAMLTErvZNeQNiORQpROhK5RQ3cEdsBBUMhe747v
 KEdPSOnnljvCi26vO01sRUdQVDkVNPTuf7ehSGa+OGdlM0bq25ye3+K
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the new V4L2_CID_FLASH_DURATION control to the v4l2
led flash class.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/leds/led-class-flash.c                 | 15 +++++++++++++++
 drivers/media/v4l2-core/v4l2-flash-led-class.c | 13 +++++++++++++
 include/linux/led-class-flash.h                | 16 ++++++++++++++++
 3 files changed, 44 insertions(+)

diff --git a/drivers/leds/led-class-flash.c b/drivers/leds/led-class-flash.c
index f4e26ce84862c05092a9598e63ed301967852f13..165035a8826ca7d44a5cd265a5130a76c6e94347 100644
--- a/drivers/leds/led-class-flash.c
+++ b/drivers/leds/led-class-flash.c
@@ -440,6 +440,21 @@ int led_update_flash_brightness(struct led_classdev_flash *fled_cdev)
 }
 EXPORT_SYMBOL_GPL(led_update_flash_brightness);
 
+int led_set_flash_duration(struct led_classdev_flash *fled_cdev, u32 duration)
+{
+	struct led_classdev *led_cdev = &fled_cdev->led_cdev;
+	struct led_flash_setting *s = &fled_cdev->duration;
+
+	s->val = duration;
+	led_clamp_align(s);
+
+	if (!(led_cdev->flags & LED_SUSPENDED))
+		return call_flash_op(fled_cdev, duration_set, s->val);
+
+	return 0;
+}
+EXPORT_SYMBOL_GPL(led_set_flash_duration);
+
 MODULE_AUTHOR("Jacek Anaszewski <j.anaszewski@samsung.com>");
 MODULE_DESCRIPTION("LED Flash class interface");
 MODULE_LICENSE("GPL v2");
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
diff --git a/include/linux/led-class-flash.h b/include/linux/led-class-flash.h
index 36df927ec4b7dcaf9074c6ef32ac8ce83a87a79d..21ec856c36bc67decda46aa8ff1c040ffdcf1181 100644
--- a/include/linux/led-class-flash.h
+++ b/include/linux/led-class-flash.h
@@ -45,6 +45,8 @@ struct led_flash_ops {
 	int (*timeout_set)(struct led_classdev_flash *fled_cdev, u32 timeout);
 	/* get the flash LED fault */
 	int (*fault_get)(struct led_classdev_flash *fled_cdev, u32 *fault);
+	/* set flash duration */
+	int (*duration_set)(struct led_classdev_flash *fled_cdev, u32 duration);
 };
 
 /*
@@ -75,6 +77,9 @@ struct led_classdev_flash {
 	/* flash timeout value in microseconds along with its constraints */
 	struct led_flash_setting timeout;
 
+	/* flash timeout value in microseconds along with its constraints */
+	struct led_flash_setting duration;
+
 	/* LED Flash class sysfs groups */
 	const struct attribute_group *sysfs_groups[LED_FLASH_SYSFS_GROUPS_SIZE];
 };
@@ -209,4 +214,15 @@ int led_set_flash_timeout(struct led_classdev_flash *fled_cdev, u32 timeout);
  */
 int led_get_flash_fault(struct led_classdev_flash *fled_cdev, u32 *fault);
 
+/**
+ * led_set_flash_duration - set flash LED duration
+ * @fled_cdev: the flash LED to set
+ * @timeout: the flash duration to set it to
+ *
+ * Set the flash strobe duration.
+ *
+ * Returns: 0 on success or negative error value on failure
+ */
+int led_set_flash_duration(struct led_classdev_flash *fled_cdev, u32 duration);
+
 #endif	/* __LINUX_FLASH_LEDS_H_INCLUDED */

-- 
2.47.2

