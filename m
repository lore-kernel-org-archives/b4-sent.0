From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Fri, 24 Jan 2025 10:29:50 +0800
Subject: [PATCH 1/3] drm/bridge: it6505: modify DP link auto training
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250124-fix-link-training-v1-1-09511050bb2c@ite.com.tw>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1737685792; l=4987;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=54tlhkHj+pxYl9kznBsAM5796RL+l7b8tF/1hdi0qzs=;
 b=FehmlgQ5oHH00ZpCfQpwKs0q4XVm5Hm7rf4IkmcCBcfKqraYkk8CP4VmXOVaaSV/jJ58R/dZ7
 yiZWQvKVzlKAM3wdr7NNZsWCZfL1ErcVuzwmiguSMzLhz70mLAejM0C
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

Since INT_LINK_TRAIN_FAIL is checked when auto training, it is remove
from  it6505_int_threaded_handler()

In order to reset HW link auto training state,
bits FORCE_RETRAIN and MANUAL_TRAIN at REG_TRAIN_CTRL1 must be set
at the same time.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/gpu/drm/bridge/ite-it6505.c | 61 +++++++++++++++++++++++++------------
 1 file changed, 42 insertions(+), 19 deletions(-)

diff --git a/drivers/gpu/drm/bridge/ite-it6505.c b/drivers/gpu/drm/bridge/ite-it6505.c
index 88ef76a37fe6accacdd343839ff2569b31b18ceb..dc1179c8338e27866f6adda4ef8fb2950336221b 100644
--- a/drivers/gpu/drm/bridge/ite-it6505.c
+++ b/drivers/gpu/drm/bridge/ite-it6505.c
@@ -821,7 +821,7 @@ static void it6505_int_mask_enable(struct it6505 *it6505)
 	it6505_write(it6505, INT_MASK_02, BIT(INT_AUX_CMD_FAIL) |
 		     BIT(INT_HDCP_KSV_CHECK) | BIT(INT_AUDIO_FIFO_ERROR));
 
-	it6505_write(it6505, INT_MASK_03, BIT(INT_LINK_TRAIN_FAIL) |
+	it6505_write(it6505, INT_MASK_03,
 		     BIT(INT_VID_FIFO_ERROR) | BIT(INT_IO_LATCH_FIFO_OVERFLOW));
 }
 
@@ -1800,30 +1800,62 @@ static void it6505_link_training_setup(struct it6505 *it6505)
 
 static bool it6505_link_start_auto_train(struct it6505 *it6505)
 {
-	int timeout = 500, link_training_state;
+	int link_training_state;
 	bool state = false;
+	struct device *dev = it6505->dev;
+	int int03;
+	unsigned long timeout;
+
+	guard(mutex)(&it6505->aux_lock);
+	/* Disable FIFO error interrupt trigger  */
+	/* to prevent training fail loop issue   */
+	it6505_set_bits(it6505, INT_MASK_03, BIT(INT_VID_FIFO_ERROR), 0);
+
+	it6505_write(it6505, INT_STATUS_03,
+		     BIT(INT_LINK_TRAIN_FAIL) | BIT(INT_VID_FIFO_ERROR));
+	int03 = it6505_read(it6505, INT_STATUS_03);
 
-	mutex_lock(&it6505->aux_lock);
 	it6505_set_bits(it6505, REG_TRAIN_CTRL0,
 			FORCE_CR_DONE | FORCE_EQ_DONE, 0x00);
-	it6505_write(it6505, REG_TRAIN_CTRL1, FORCE_RETRAIN);
+
+	/* reset link state machine and re start training*/
+	it6505_write(it6505, REG_TRAIN_CTRL1,
+		     FORCE_RETRAIN | MANUAL_TRAIN);
 	it6505_write(it6505, REG_TRAIN_CTRL1, AUTO_TRAIN);
 
-	while (timeout > 0) {
+	timeout = jiffies + msecs_to_jiffies(100) + 1;
+	for (;;) {
 		usleep_range(1000, 2000);
 		link_training_state = it6505_read(it6505, REG_LINK_TRAIN_STS);
+		int03 = it6505_read(it6505, INT_STATUS_03);
+		if (int03 & BIT(INT_LINK_TRAIN_FAIL)) {
+			/* Ignore INT_VID_FIFO_ERROR when auto training fail*/
+			it6505_write(it6505, INT_STATUS_03,
+				     BIT(INT_LINK_TRAIN_FAIL) |
+				     BIT(INT_VID_FIFO_ERROR));
+
+			if (int03 & BIT(INT_VID_FIFO_ERROR)) {
+				DRM_DEV_DEBUG_DRIVER(dev,
+				"video fifo error when training fail (%x)!",
+				int03);
+			}
+
+			break;
+		}
 
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
 
@@ -2377,7 +2409,7 @@ static void it6505_stop_link_train(struct it6505 *it6505)
 {
 	it6505->link_state = LINK_IDLE;
 	cancel_work_sync(&it6505->link_works);
-	it6505_write(it6505, REG_TRAIN_CTRL1, FORCE_RETRAIN);
+	it6505_write(it6505, REG_TRAIN_CTRL1, FORCE_RETRAIN | MANUAL_TRAIN);
 }
 
 static void it6505_link_train_ok(struct it6505 *it6505)
@@ -2691,14 +2723,6 @@ static void it6505_irq_audio_fifo_error(struct it6505 *it6505)
 		it6505_enable_audio(it6505);
 }
 
-static void it6505_irq_link_train_fail(struct it6505 *it6505)
-{
-	struct device *dev = it6505->dev;
-
-	DRM_DEV_DEBUG_DRIVER(dev, "link training fail interrupt");
-	schedule_work(&it6505->link_works);
-}
-
 static bool it6505_test_bit(unsigned int bit, const unsigned int *addr)
 {
 	return 1 & (addr[bit / BITS_PER_BYTE] >> (bit % BITS_PER_BYTE));
@@ -2763,7 +2787,6 @@ static irqreturn_t it6505_int_threaded_handler(int unused, void *data)
 		{ BIT_INT_AUX_CMD_FAIL, it6505_irq_aux_cmd_fail },
 		{ BIT_INT_HDCP_KSV_CHECK, it6505_irq_hdcp_ksv_check },
 		{ BIT_INT_AUDIO_FIFO_ERROR, it6505_irq_audio_fifo_error },
-		{ BIT_INT_LINK_TRAIN_FAIL, it6505_irq_link_train_fail },
 	};
 	int int_status[3], i;
 

-- 
2.34.1

