From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Wed, 26 Mar 2025 13:34:14 +0800
Subject: [PATCH v2 2/5] drm/bridge: it6505: check INT_LINK_TRAIN_FAIL while
 link auto training
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250326-fix-link-training-v2-2-756c8306f500@ite.com.tw>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742967277; l=2881;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=q10oGVkoPBCuc3Dgp3JFILnyXIg3fT8rbmgboMHjtM8=;
 b=Z0D55US/qKGcCj5J/n1Wzl77WYp5AoC5Nh/RLZB5lzxxM10S9MrHbjMWUxK0IAVghH9dbBTwy
 KrEJbB/bwmzCMjtv4Kz+woyOPspNrfLV0rKg3905nKrZzEIQyeHrmx0
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When start link training, interrupt status INT_LINK_TRAIN_FAIL can
use to check link training fail and no need to wait until timeout.

it6505_irq_link_train_fail() remove from interrupt and no longer used.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/gpu/drm/bridge/ite-it6505.c | 25 ++++++++++++++-----------
 1 file changed, 14 insertions(+), 11 deletions(-)

diff --git a/drivers/gpu/drm/bridge/ite-it6505.c b/drivers/gpu/drm/bridge/ite-it6505.c
index b47042dc06bb1e1dfd92bc0dc6d69dc918a140ba..0607f99446b37c82b41a376c2f4e10c7565d1b61 100644
--- a/drivers/gpu/drm/bridge/ite-it6505.c
+++ b/drivers/gpu/drm/bridge/ite-it6505.c
@@ -821,8 +821,8 @@ static void it6505_int_mask_enable(struct it6505 *it6505)
 	it6505_write(it6505, INT_MASK_02, BIT(INT_AUX_CMD_FAIL) |
 		     BIT(INT_HDCP_KSV_CHECK) | BIT(INT_AUDIO_FIFO_ERROR));
 
-	it6505_write(it6505, INT_MASK_03, BIT(INT_LINK_TRAIN_FAIL) |
-		     BIT(INT_VID_FIFO_ERROR) | BIT(INT_IO_LATCH_FIFO_OVERFLOW));
+	it6505_write(it6505, INT_MASK_03, BIT(INT_VID_FIFO_ERROR) |
+		     BIT(INT_IO_LATCH_FIFO_OVERFLOW));
 }
 
 static void it6505_int_mask_disable(struct it6505 *it6505)
@@ -1802,6 +1802,7 @@ static bool it6505_link_start_auto_train(struct it6505 *it6505)
 {
 	int timeout = 500, link_training_state;
 	bool state = false;
+	int int03;
 
 	mutex_lock(&it6505->aux_lock);
 	it6505_set_bits(it6505, REG_TRAIN_CTRL0,
@@ -1814,6 +1815,17 @@ static bool it6505_link_start_auto_train(struct it6505 *it6505)
 	while (timeout > 0) {
 		usleep_range(1000, 2000);
 		link_training_state = it6505_read(it6505, REG_LINK_TRAIN_STS);
+		int03 = it6505_read(it6505, INT_STATUS_03);
+		if (int03 & BIT(INT_LINK_TRAIN_FAIL)) {
+			it6505_write(it6505, INT_STATUS_03,
+				     BIT(INT_LINK_TRAIN_FAIL));
+
+			DRM_DEV_DEBUG_DRIVER(dev,
+					     "INT_LINK_TRAIN_FAIL(%x)!",
+					      int03);
+
+			break;
+		}
 
 		if (link_training_state > 0 &&
 		    (link_training_state & LINK_STATE_NORP)) {
@@ -2693,14 +2705,6 @@ static void it6505_irq_audio_fifo_error(struct it6505 *it6505)
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
@@ -2765,7 +2769,6 @@ static irqreturn_t it6505_int_threaded_handler(int unused, void *data)
 		{ BIT_INT_AUX_CMD_FAIL, it6505_irq_aux_cmd_fail },
 		{ BIT_INT_HDCP_KSV_CHECK, it6505_irq_hdcp_ksv_check },
 		{ BIT_INT_AUDIO_FIFO_ERROR, it6505_irq_audio_fifo_error },
-		{ BIT_INT_LINK_TRAIN_FAIL, it6505_irq_link_train_fail },
 	};
 	int int_status[3], i;
 

-- 
2.34.1

