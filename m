From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Wed, 30 Sep 2026 14:41:39 +0800
Subject: [PATCH v2 21/21] media: i2c: it6625: use enable_streams and
 disable_streams
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-upstream-it6625-follow-up-patch-v2-21-e353f887e7fa@ite.com.tw>
References: <20260930-upstream-it6625-follow-up-patch-v2-0-e353f887e7fa@ite.com.tw>
In-Reply-To: <20260930-upstream-it6625-follow-up-patch-v2-0-e353f887e7fa@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790750567; l=2777;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=G4Y3pCwRUr3hCF/1tQ6at9bCfCCdQ3wlFc2uUKsFLdg=;
 b=OYReQLa/Vq3GMHmFs262O1CLQW5yaUJre1HRcO3Q8yFFQMtojrQ0kGjCeOjNAE6JzORO5/foj
 ghQLRRipCSwCBrVVl+aUdJYULjmeZlXewu+DdeT5gZN2bme31FK/74p
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The .s_stream video op is deprecated; add .enable_streams()/
.disable_streams() pad ops instead and keep v4l2_subdev_s_stream_helper
for legacy .s_stream callers.

Both ops take it6625_lock explicitly around the MCU transactions. This
device has a single, non-multiplexed source pad, so the core's implicit
stream 0 is sufficient and V4L2_SUBDEV_FL_STREAMS is not set.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 27 ++++++++++++++++++---------
 1 file changed, 18 insertions(+), 9 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index 1127d050d82522e202f042832e3772fd88e63ca9..10619df51a2274a4deb155710d6aa46c950f10a9 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -935,12 +935,6 @@ static int it6625_enable_stream_locked(struct it6625 *it6625, bool enable)
 	return it6625_update_config(it6625);
 }
 
-static int it6625_enable_stream(struct it6625 *it6625, bool enable)
-{
-	guard(mutex)(&it6625->it6625_lock);
-	return it6625_enable_stream_locked(it6625, enable);
-}
-
 static int it6625_set_mipi_config_locked(struct it6625 *it6625, u32 cfg_val)
 {
 	u8 mipi_data_type;
@@ -1538,11 +1532,24 @@ static int it6625_dv_timings_cap(struct v4l2_subdev *sd,
 	return 0;
 }
 
-static int it6625_s_stream(struct v4l2_subdev *sd, int enable)
+static int it6625_enable_streams(struct v4l2_subdev *sd,
+				 struct v4l2_subdev_state *state,
+				 u32 pad, u64 streams_mask)
 {
 	struct it6625 *it6625 = sd_to_6625(sd);
 
-	return it6625_enable_stream(it6625, enable);
+	guard(mutex)(&it6625->it6625_lock);
+	return it6625_enable_stream_locked(it6625, true);
+}
+
+static int it6625_disable_streams(struct v4l2_subdev *sd,
+				  struct v4l2_subdev_state *state,
+				  u32 pad, u64 streams_mask)
+{
+	struct it6625 *it6625 = sd_to_6625(sd);
+
+	guard(mutex)(&it6625->it6625_lock);
+	return it6625_enable_stream_locked(it6625, false);
 }
 
 static int it6625_enum_mbus_code(struct v4l2_subdev *sd,
@@ -1833,7 +1840,7 @@ static const struct v4l2_subdev_core_ops it6625_core_ops = {
 
 static const struct v4l2_subdev_video_ops it6625_video_ops = {
 	.g_input_status = it6625_g_input_status,
-	.s_stream = it6625_s_stream,
+	.s_stream = v4l2_subdev_s_stream_helper,
 };
 
 static const struct v4l2_subdev_pad_ops it6625_pad_ops = {
@@ -1848,6 +1855,8 @@ static const struct v4l2_subdev_pad_ops it6625_pad_ops = {
 	.s_dv_timings = it6625_pad_s_dv_timings,
 	.g_dv_timings = it6625_pad_g_dv_timings,
 	.query_dv_timings = it6625_pad_query_dv_timings,
+	.enable_streams = it6625_enable_streams,
+	.disable_streams = it6625_disable_streams,
 };
 
 static const struct v4l2_subdev_ops it6625_ops = {

-- 
2.34.1

