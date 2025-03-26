From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Wed, 26 Mar 2025 13:34:15 +0800
Subject: [PATCH v2 3/5] drm/bridge: it6505: modify DP link auto training
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250326-fix-link-training-v2-3-756c8306f500@ite.com.tw>
References: <20250326-fix-link-training-v2-0-756c8306f500@ite.com.tw>
In-Reply-To: <20250326-fix-link-training-v2-0-756c8306f500@ite.com.tw>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742967277; l=3243;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=7J6H/GfrtlSBRUa1Zq4Q3BBQ6RF81ypZS5T9zoXdwKE=;
 b=UfbQwxcyZy4hSilSen89RuLoTEI0B1PbBkTVqkpw4L5U70/C+uiM8M8DVI+r7KAjrs9IY1oKo
 1lJ1gYcfrl9AWt+ukZN1cY0D8AiDDl7M97AWC67tt5AYteI2BGBhBIT
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IT6505 supports HW link training which will write DPCD and check
training status automatically.

In the case that driver set link rate at 2.7G and HW fail to training,
it will change link configuration and try 1.65G. And this will cause
INT_VID_FIFO_ERROR triggered when link clock is changed.

When video error occurs, video logic is reset and link training restart,
this will cause endless auto link training.

Modify link auto training with disable INT_VID_FIFO_ERROR to avoid loop
and check INT_LINK_TRAIN_FAIL event to abort wait training done.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/gpu/drm/bridge/ite-it6505.c | 38 +++++++++++++++++++++++++++----------
 1 file changed, 28 insertions(+), 10 deletions(-)

diff --git a/drivers/gpu/drm/bridge/ite-it6505.c b/drivers/gpu/drm/bridge/ite-it6505.c
index 0607f99446b37c82b41a376c2f4e10c7565d1b61..e0e13e737763fb801fd1cd803734a0d6ae1dd812 100644
--- a/drivers/gpu/drm/bridge/ite-it6505.c
+++ b/drivers/gpu/drm/bridge/ite-it6505.c
@@ -1800,11 +1800,20 @@ static void it6505_link_training_setup(struct it6505 *it6505)
 
 static bool it6505_link_start_auto_train(struct it6505 *it6505)
 {
-	int timeout = 500, link_training_state;
+	int link_training_state;
 	bool state = false;
 	int int03;
+	struct device *dev = it6505->dev;
+	unsigned long timeout;
+
+	guard(mutex)(&it6505->aux_lock);
+	/* Disable FIFO error interrupt trigger  */
+	/* to prevent training fail loop issue   */
+	it6505_set_bits(it6505, INT_MASK_03, BIT(INT_VID_FIFO_ERROR), 0);
+
+	it6505_write(it6505, INT_STATUS_03,
+		     BIT(INT_LINK_TRAIN_FAIL) | BIT(INT_VID_FIFO_ERROR));
 
-	mutex_lock(&it6505->aux_lock);
 	it6505_set_bits(it6505, REG_TRAIN_CTRL0,
 			FORCE_CR_DONE | FORCE_EQ_DONE, 0x00);
 	/* reset link state machine and re start training*/
@@ -1812,32 +1821,41 @@ static bool it6505_link_start_auto_train(struct it6505 *it6505)
 		     FORCE_RETRAIN | MANUAL_TRAIN);
 	it6505_write(it6505, REG_TRAIN_CTRL1, AUTO_TRAIN);
 
-	while (timeout > 0) {
+	timeout = jiffies + msecs_to_jiffies(100) + 1;
+	for (;;) {
 		usleep_range(1000, 2000);
 		link_training_state = it6505_read(it6505, REG_LINK_TRAIN_STS);
 		int03 = it6505_read(it6505, INT_STATUS_03);
 		if (int03 & BIT(INT_LINK_TRAIN_FAIL)) {
-			it6505_write(it6505, INT_STATUS_03,
-				     BIT(INT_LINK_TRAIN_FAIL));
-
 			DRM_DEV_DEBUG_DRIVER(dev,
 					     "INT_LINK_TRAIN_FAIL(%x)!",
 					      int03);
 
+			/* Ignore INT_VID_FIFO_ERROR when auto training fail*/
+			it6505_write(it6505, INT_STATUS_03,
+				     BIT(INT_LINK_TRAIN_FAIL) |
+				     BIT(INT_VID_FIFO_ERROR));
+
+			if (int03 & BIT(INT_VID_FIFO_ERROR))
+				DRM_DEV_DEBUG_DRIVER(dev,
+						     "video fifo error when training fail");
+
 			break;
 		}
 
 		if (link_training_state > 0 &&
 		    (link_training_state & LINK_STATE_NORP)) {
 			state = true;
-			goto unlock;
+			break;
 		}
 
-		timeout--;
+		if (time_after(jiffies, timeout))
+			break;
 	}
-unlock:
-	mutex_unlock(&it6505->aux_lock);
 
+	/* recover interrupt trigger*/
+	it6505_set_bits(it6505, INT_MASK_03,
+			BIT(INT_VID_FIFO_ERROR), BIT(INT_VID_FIFO_ERROR));
 	return state;
 }
 

-- 
2.34.1

