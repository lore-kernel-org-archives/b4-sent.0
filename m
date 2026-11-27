From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Fri, 27 Nov 2026 21:30:14 +0100
Subject: [PATCH 2/4] media: i2c: ov7251: use pm_runtime_put_autosuspend()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-ov7251-strobe-ncont-v1-2-cefa8c6c020b@gmail.com>
References: <20261127-ov7251-strobe-ncont-v1-0-cefa8c6c020b@gmail.com>
In-Reply-To: <20261127-ov7251-strobe-ncont-v1-0-cefa8c6c020b@gmail.com>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Jacopo Mondi <jacopo@jmondi.org>, Todor Tomov <todor.too@gmail.com>
Cc: Mauro Carvalho Chehab <mchehab+samsung@kernel.org>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795811412; l=1739;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=gErO0p9aK1yRxQdJb89ZcwQcXYtyiVlMBOlVrQz7Oiw=;
 b=88n+Sz8iFxi/ox+amXJ2lbBOdkooWOAkdyRY+efoaTeoZznwZZRTZszLOIqubfdoFSJnrqzOd
 OL0JlSWKKi2A4ZtaABy0AzBgOlCQNVndftg0/YJ/tYH4nT5gkVq+IQl
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ov7251_probe() configures runtime PM autosuspend with a 1000 ms delay,
but ov7251_s_ctrl() and ov7251_s_stream() call pm_runtime_put() without
updating last_busy or using autosuspend, immediately powering down the
sensor on stream stop or control writes.

Use pm_runtime_mark_last_busy() and pm_runtime_put_autosuspend() in
ov7251_s_ctrl() and ov7251_s_stream() so the configured autosuspend
window is honored across back-to-back captures.

Fixes: d30bb512da3d ("media: Add a driver for the ov7251 camera sensor")
Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 drivers/media/i2c/ov7251.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/drivers/media/i2c/ov7251.c b/drivers/media/i2c/ov7251.c
index 77ac60fad62209eda0444015196e52564a0e947d..5a50a5100c1e995714201fb509fb207fa03c5f39 100644
--- a/drivers/media/i2c/ov7251.c
+++ b/drivers/media/i2c/ov7251.c
@@ -1074,7 +1074,8 @@ static int ov7251_s_ctrl(struct v4l2_ctrl *ctrl)
 		break;
 	}
 
-	pm_runtime_put(ov7251->dev);
+	pm_runtime_mark_last_busy(ov7251->dev);
+	pm_runtime_put_autosuspend(ov7251->dev);
 
 	return ret;
 }
@@ -1378,14 +1379,16 @@ static int ov7251_s_stream(struct v4l2_subdev *subdev, int enable)
 	} else {
 		ret = ov7251_write_reg(ov7251, OV7251_SC_MODE_SELECT,
 				       OV7251_SC_MODE_SELECT_SW_STANDBY);
-		pm_runtime_put(ov7251->dev);
+		pm_runtime_mark_last_busy(ov7251->dev);
+		pm_runtime_put_autosuspend(ov7251->dev);
 	}
 
 	mutex_unlock(&ov7251->lock);
 	return ret;
 
 err_power_down:
-	pm_runtime_put(ov7251->dev);
+	pm_runtime_mark_last_busy(ov7251->dev);
+	pm_runtime_put_autosuspend(ov7251->dev);
 	mutex_unlock(&ov7251->lock);
 	return ret;
 }

-- 
2.47.3

