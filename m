From: Richard Leitner <richard.leitner@linux.dev>
Date: Tue, 29 Apr 2025 14:59:07 +0200
Subject: [PATCH v3 2/9] leds: flash: add support for flash/stobe duration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250429-ov9282-flash-strobe-v3-2-2105ce179952@linux.dev>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745931554; l=2827;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=HDEsgaluUKEPdxixqt/Aekf5T3lFNnaVwddtdEWptfw=;
 b=6M/61HmZntl6x9awtwRbQFDQpMX+zbdz7fFVJ+CjaQLXInH1bRos1VW9t5D31eRmSUYhwouXc
 Gn9Y9mGn5X2A1cPjJxiEGSaLbzsnf9Ob5ImmdvMY2IkG8hN1YC+O7L+
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the new V4L2_CID_FLASH_DURATION control to the leds
driver.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/leds/led-class-flash.c  | 15 +++++++++++++++
 include/linux/led-class-flash.h | 16 ++++++++++++++++
 2 files changed, 31 insertions(+)

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

