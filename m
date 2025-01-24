From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Fri, 24 Jan 2025 10:29:52 +0800
Subject: [PATCH 3/3] drm/bridge: it6505: skip auto training when previous
 try fail
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250124-fix-link-training-v1-3-09511050bb2c@ite.com.tw>
References: <20250124-fix-link-training-v1-0-09511050bb2c@ite.com.tw>
In-Reply-To: <20250124-fix-link-training-v1-0-09511050bb2c@ite.com.tw>
To: Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: Pet.Weng@ite.com.tw, Kenneth.Hung@ite.com.tw, treapking@chromium.org, 
 dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1737685792; l=2801;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=JH5TB+6KMos7mGcxiEmqDSjWU1p596CHLwJaILJm+RQ=;
 b=gXdNFv910hf0FF8myxOgVbYKQXZOItlk/m9x4G2/vhbNJ2J2mq7Jl5s3XPYZjzGW+gfQg8z+r
 +MLx3OxKsewDK2slp+NFS2yx6vPlduwM79JeJxZhh73fsT+ywN/qVy/
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When connect to device which can only training done by
step training, skip auto training when link training restart,
usually happen when display resolution is changed.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/gpu/drm/bridge/ite-it6505.c | 36 +++++++++++++++++++++---------------
 1 file changed, 21 insertions(+), 15 deletions(-)

diff --git a/drivers/gpu/drm/bridge/ite-it6505.c b/drivers/gpu/drm/bridge/ite-it6505.c
index 11231a642bbe185c4f36bf5f2a0b115fa056213b..730481a9446ff00a54ef70e86b4c28ff0a3f417e 100644
--- a/drivers/gpu/drm/bridge/ite-it6505.c
+++ b/drivers/gpu/drm/bridge/ite-it6505.c
@@ -468,6 +468,7 @@ struct it6505 {
 	struct work_struct hdcp_wait_ksv_list;
 	struct completion extcon_completion;
 	u8 auto_train_retry;
+	u8 step_train_only;
 	bool hdcp_desired;
 	bool is_repeater;
 	u8 hdcp_down_stream_count;
@@ -2459,11 +2460,13 @@ static void it6505_link_step_train_process(struct it6505 *it6505)
 				     ret ? "pass" : "failed", i + 1);
 		if (ret) {
 			it6505_link_train_ok(it6505);
+			it6505->step_train_only = true;
 			return;
 		}
 	}
 
 	DRM_DEV_DEBUG_DRIVER(dev, "training fail");
+	it6505->step_train_only = false;
 	it6505->link_state = LINK_IDLE;
 	it6505_video_reset(it6505);
 }
@@ -2479,21 +2482,23 @@ static void it6505_link_training_work(struct work_struct *work)
 
 	if (!it6505_get_sink_hpd_status(it6505))
 		return;
-
-	retry = it6505->auto_train_retry;
-	do {
-		it6505_link_training_setup(it6505);
-		it6505_reset_hdcp(it6505);
-		it6505_aux_reset(it6505);
-
-		ret = it6505_link_start_auto_train(it6505);
-		DRM_DEV_DEBUG_DRIVER(dev, "auto train %s, auto_train_retry: %d",
-			     ret ? "pass" : "failed", it6505->auto_train_retry);
-		if (ret) {
-			it6505_link_train_ok(it6505);
-			return;
-		}
-	} while (retry--);
+	/* skip auto training if previous auto train is fail*/
+	if (!it6505->step_train_only) {
+		retry = it6505->auto_train_retry;
+		do {
+			it6505_link_training_setup(it6505);
+			it6505_reset_hdcp(it6505);
+			it6505_aux_reset(it6505);
+
+			ret = it6505_link_start_auto_train(it6505);
+			DRM_DEV_DEBUG_DRIVER(dev, "auto train %s, auto_train_retry: %d",
+				ret ? "pass" : "failed", it6505->auto_train_retry);
+			if (ret) {
+				it6505_link_train_ok(it6505);
+				return;
+			}
+		} while (retry--);
+	}
 
 	/*After HW auto training fail, try link training step by step*/
 	it6505_link_step_train_process(it6505);
@@ -2605,6 +2610,7 @@ static void it6505_irq_hpd(struct it6505 *it6505)
 			it6505_parse_link_capabilities(it6505);
 		}
 		it6505->auto_train_retry = AUTO_TRAIN_RETRY;
+		it6505->step_train_only = false;
 
 		it6505_drm_dp_link_set_power(&it6505->aux, &it6505->link,
 					     DP_SET_POWER_D0);

-- 
2.34.1

