From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Tue, 01 Apr 2025 15:54:57 +0800
Subject: [PATCH v3 3/5] drm/bridge: it6505: modify DP link auto training
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250401-fix-link-training-v3-3-7f60f2ab7b8c@ite.com.tw>
References: <20250401-fix-link-training-v3-0-7f60f2ab7b8c@ite.com.tw>
In-Reply-To: <20250401-fix-link-training-v3-0-7f60f2ab7b8c@ite.com.tw>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1743494115; l=2426;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=w0mjd1b/vD9l754Z7HEk7/mi9+TqCrQ9as279Ea9bf8=;
 b=+cLnmpKZvWnSs9nFSmMV3fSWd/NXpkMJSeeIgIE2+UcyeS8EhXzDTIWjwJTPJGmOt2XHyMZDw
 v4qlN1oPJnmCT5mrLTlbPUFcXYrkbweSP3VPKSWzUCfHJuxnaidBVMj
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
 drivers/gpu/drm/bridge/ite-it6505.c | 14 +++++++++++++-
 1 file changed, 13 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/bridge/ite-it6505.c b/drivers/gpu/drm/bridge/ite-it6505.c
index 7f6227c278a51358c70a3de93454aafeef64f2bb..f9b99c70789eea6beb3c6513155c9a4ca103d219 100644
--- a/drivers/gpu/drm/bridge/ite-it6505.c
+++ b/drivers/gpu/drm/bridge/ite-it6505.c
@@ -1806,6 +1806,13 @@ static bool it6505_link_start_auto_train(struct it6505 *it6505)
 	struct device *dev = it6505->dev;
 
 	mutex_lock(&it6505->aux_lock);
+
+	/* Disable FIFO error interrupt trigger  */
+	/* to prevent training fail loop issue   */
+	it6505_set_bits(it6505, INT_MASK_03, BIT(INT_VID_FIFO_ERROR), 0);
+
+	it6505_write(it6505, INT_STATUS_03,
+		     BIT(INT_LINK_TRAIN_FAIL) | BIT(INT_VID_FIFO_ERROR));
 	it6505_set_bits(it6505, REG_TRAIN_CTRL0,
 			FORCE_CR_DONE | FORCE_EQ_DONE, 0x00);
 	/* reset link state machine and re start training*/
@@ -1818,8 +1825,10 @@ static bool it6505_link_start_auto_train(struct it6505 *it6505)
 		link_training_state = it6505_read(it6505, REG_LINK_TRAIN_STS);
 		int03 = it6505_read(it6505, INT_STATUS_03);
 		if (int03 & BIT(INT_LINK_TRAIN_FAIL)) {
+			/* Ignore INT_VID_FIFO_ERROR when auto training fail*/
 			it6505_write(it6505, INT_STATUS_03,
-				     BIT(INT_LINK_TRAIN_FAIL));
+				     BIT(INT_LINK_TRAIN_FAIL) |
+				     BIT(INT_VID_FIFO_ERROR));
 
 			DRM_DEV_DEBUG_DRIVER(dev,
 					     "INT_LINK_TRAIN_FAIL(%x)!",
@@ -1837,6 +1846,9 @@ static bool it6505_link_start_auto_train(struct it6505 *it6505)
 		timeout--;
 	}
 unlock:
+	/* recover interrupt trigger*/
+	it6505_set_bits(it6505, INT_MASK_03,
+			BIT(INT_VID_FIFO_ERROR), BIT(INT_VID_FIFO_ERROR));
 	mutex_unlock(&it6505->aux_lock);
 
 	return state;

-- 
2.34.1

