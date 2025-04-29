From: Richard Leitner <richard.leitner@linux.dev>
Date: Tue, 29 Apr 2025 14:59:09 +0200
Subject: [PATCH v3 4/9] media: v4l2-flash: fix flash_timeout comment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250429-ov9282-flash-strobe-v3-4-2105ce179952@linux.dev>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745931554; l=878;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=8XoXfLI3glbsttjIv49MTkNU8w73Ts/XjbKrGmMzkd0=;
 b=Vq8RYyKXTeDizbDIP7IUbAZFqHkLZBZKwFKb49hINPfxPyE8rYPfI2bTUFxoo8MoEliN3pWnG
 Fft5ZyMMDSPCKz+khm2gLoRnlV+FYf4fxgAgaVv5IJgEzrmHfWYSa9S
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The comment for the flash_timeout setter mentioned it is the "flash
duration". Fix this by changing it to "flash timeout".

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 include/linux/led-class-flash.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/include/linux/led-class-flash.h b/include/linux/led-class-flash.h
index 21ec856c36bc67decda46aa8ff1c040ffdcf1181..775a96217518936633541c7a5d394502dbf04f83 100644
--- a/include/linux/led-class-flash.h
+++ b/include/linux/led-class-flash.h
@@ -197,7 +197,7 @@ int led_update_flash_brightness(struct led_classdev_flash *fled_cdev);
  * @fled_cdev: the flash LED to set
  * @timeout: the flash timeout to set it to
  *
- * Set the flash strobe duration.
+ * Set the flash strobe timeout.
  *
  * Returns: 0 on success or negative error value on failure
  */

-- 
2.47.2

