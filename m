From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Sat, 28 Nov 2026 21:41:08 +0100
Subject: [PATCH v2 2/3] media: i2c: ov7251: use
 pm_runtime_put_autosuspend()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-ov7251-strobe-ncont-v2-2-9428bbb6347e@gmail.com>
References: <20261128-ov7251-strobe-ncont-v2-0-9428bbb6347e@gmail.com>
In-Reply-To: <20261128-ov7251-strobe-ncont-v2-0-9428bbb6347e@gmail.com>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Jacopo Mondi <jacopo@jmondi.org>, Todor Tomov <todor.too@gmail.com>
Cc: Antoine Pichot <antoine.pichot@gmail.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795898468; l=1466;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=4+jnej36VRHVSIe3byc32TNoOJR7alJczgCt59RWw48=;
 b=Em4Un5+jvFYN3nCUyhL6bJmDSUdmP5lW0xlzTGMjs6vX9w7bvXpyxWrH9D2ypOyfpQn2+Yq8V
 XPpi8qL4lIuDvws1M46lpp5dX6YAJjWx2dVS2bJkj+9s4mIXB5pSkzQ
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ov7251_probe() configures runtime PM autosuspend with a 1000 ms delay,
but ov7251_s_ctrl() and ov7251_s_stream() call pm_runtime_put(),
immediately powering down the sensor on stream stop or control writes
instead of keeping it in software standby across the autosuspend window.

Use pm_runtime_put_autosuspend() in ov7251_s_ctrl() and
ov7251_s_stream().

Fixes: 207f4162f1c9 ("media: i2c: Add pm_runtime support to ov7251")
Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 drivers/media/i2c/ov7251.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/media/i2c/ov7251.c b/drivers/media/i2c/ov7251.c
index 393260929f29..8c6e610586cd 100644
--- a/drivers/media/i2c/ov7251.c
+++ b/drivers/media/i2c/ov7251.c
@@ -905,7 +905,7 @@ static int ov7251_s_ctrl(struct v4l2_ctrl *ctrl)
 		break;
 	}
 
-	pm_runtime_put(ov7251->dev);
+	pm_runtime_put_autosuspend(ov7251->dev);
 
 	return ret;
 }
@@ -1153,14 +1153,14 @@ static int ov7251_s_stream(struct v4l2_subdev *subdev, int enable)
 	} else {
 		ret = ov7251_write_reg(ov7251, OV7251_SC_MODE_SELECT,
 				       OV7251_SC_MODE_SELECT_SW_STANDBY);
-		pm_runtime_put(ov7251->dev);
+		pm_runtime_put_autosuspend(ov7251->dev);
 	}
 
 	v4l2_subdev_unlock_state(state);
 	return ret;
 
 err_power_down:
-	pm_runtime_put(ov7251->dev);
+	pm_runtime_put_autosuspend(ov7251->dev);
 	v4l2_subdev_unlock_state(state);
 	return ret;
 }

-- 
2.56.0

