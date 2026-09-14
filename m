From: Richard Leitner <richard.leitner@linux.dev>
Date: Mon, 14 Sep 2026 21:21:07 +0200
Subject: [PATCH 10/10] media: i2c: ov9282: clamp flash_duration default to
 its maximum
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-ov9282-fixes-v1-10-f520af59df1b@linux.dev>
References: <20260914-ov9282-fixes-v1-0-f520af59df1b@linux.dev>
In-Reply-To: <20260914-ov9282-fixes-v1-0-f520af59df1b@linux.dev>
To: Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Martina Krasteva <martinax.krasteva@intel.com>, 
 "Paul J. Murphy" <paul.j.murphy@intel.com>, 
 Daniele Alessandrelli <daniele.alessandrelli@gmail.com>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: Mauro Carvalho Chehab <mchehab+huawei@kernel.org>, 
 Gyula Kelemen <gyula.kelemen@advasolutions.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.16-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789413683; l=1566;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=QmfEvOE4SfAXS/MeusYKjadXdFtLLVJQBW79Ocyb2sE=;
 b=k0eF9Jh8G8G7xgYuL6nj8uXj+T+DlDKz8Z/VilI9haV6d1DhZrUbfoOrhsfDK4b3YpJWcHh6N
 ur71VONOvRHCn2x7V5wUAO0m9fxwWcxK5b/FHeB+i9vSW0CySkG68Sy
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently the OV9282_STROBE_FRAME_SPAN_DEFAULT is always passed as default
to the flash_duration v4l2 control, where the maximum is dynamically
changed. This may lead to situations where the default is above the
maximum.

Fix this by setting the maximum value as default when
OV9282_STROBE_FRAME_SPAN_DEFAULT is above the maximum value.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/i2c/ov9282.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/ov9282.c b/drivers/media/i2c/ov9282.c
index be38ecfad8c82..1c5bed85781ce 100644
--- a/drivers/media/i2c/ov9282.c
+++ b/drivers/media/i2c/ov9282.c
@@ -11,6 +11,7 @@
 #include <linux/i2c.h>
 #include <linux/math.h>
 #include <linux/math64.h>
+#include <linux/minmax.h>
 #include <linux/module.h>
 #include <linux/pm_runtime.h>
 #include <linux/regmap.h>
@@ -556,12 +557,15 @@ static int ov9282_update_ctrl_range_flash_duration(struct ov9282 *ov9282)
 	u32 exposure_us = ov9282_exposure_to_us(ov9282, ov9282->exp_ctrl->val);
 	u32 fd_max = ov9282_us_to_flash_duration(ov9282, exposure_us);
 	u32 fd_max_us = ov9282_flash_duration_to_us(ov9282, fd_max);
+	u32 fd_default;
 
 	if (fd_max_us < exposure_us)
 		fd_max_us = ov9282_flash_duration_to_us(ov9282, fd_max + 1);
 
+	fd_default = min_t(u32, OV9282_STROBE_FRAME_SPAN_DEFAULT, fd_max_us);
+
 	return __v4l2_ctrl_modify_range(ov9282->flash_duration, 0, fd_max_us,
-					1, OV9282_STROBE_FRAME_SPAN_DEFAULT);
+					1, fd_default);
 }
 
 /**

-- 
2.53.0

