From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Fri, 18 Sep 2026 16:57:36 +0800
Subject: [PATCH 21/21] media: i2c: it6625: use enable_streams and
 disable_streams
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-upstream-it6625-follow-up-patch-v1-21-78d72d7886a5@ite.com.tw>
References: <20260918-upstream-it6625-follow-up-patch-v1-0-78d72d7886a5@ite.com.tw>
In-Reply-To: <20260918-upstream-it6625-follow-up-patch-v1-0-78d72d7886a5@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789721837; l=3281;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=PmFwvFAlIGe8S5KkdJ/0dJSm3Ai5OjykPBxjocuRLS8=;
 b=pzg0mXTeiUoizaAnBVMTecVitw6D/qbWMbgqWu7RkNbG+vrol9O4e0pUXFH4uag8CLYkMdXvT
 K27Qx+tvexPAVVABJ4Z5YxusCgmv5j4VfLMGKwesNZacVpQyMQYErWL
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The .s_stream video op is deprecated; add .enable_streams()/
.disable_streams() pad ops instead and keep v4l2_subdev_s_stream_helper
for legacy .s_stream callers, matching the same-device-class precedent
in lt6911uxe.c.

it6625_enable_streams()/it6625_disable_streams() call
it6625_enable_stream_locked() directly rather than the removed
lock-taking it6625_enable_stream() wrapper: v4l2_subdev_enable_streams()/
disable_streams() already lock the active state -- and hence
it6625_lock, shared as sd->state_lock since the previous change --
before calling into these ops.

Do not set V4L2_SUBDEV_FL_STREAMS: this device has a single,
non-multiplexed source pad, so the core's implicit stream 0 is
sufficient and v4l2_subdev_s_stream_helper() already handles that case
without it. Error handling is unchanged from the locked helper these
ops now call directly, so streaming failures are reported to the core
instead of being silently absorbed.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 25 ++++++++++++++++---------
 1 file changed, 16 insertions(+), 9 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index 550eb95c6f74a81fc11cc055b4590159ac50e969..680f27a4587eccfb863bb091c1dede290e57e909 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -936,12 +936,6 @@ static int it6625_enable_stream_locked(struct it6625 *it6625, bool enable)
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
@@ -1503,11 +1497,22 @@ static int it6625_dv_timings_cap(struct v4l2_subdev *sd,
 	return 0;
 }
 
-static int it6625_s_stream(struct v4l2_subdev *sd, int enable)
+static int it6625_enable_streams(struct v4l2_subdev *sd,
+				 struct v4l2_subdev_state *state,
+				 u32 pad, u64 streams_mask)
+{
+	struct it6625 *it6625 = sd_to_6625(sd);
+
+	return it6625_enable_stream_locked(it6625, true);
+}
+
+static int it6625_disable_streams(struct v4l2_subdev *sd,
+				  struct v4l2_subdev_state *state,
+				  u32 pad, u64 streams_mask)
 {
 	struct it6625 *it6625 = sd_to_6625(sd);
 
-	return it6625_enable_stream(it6625, enable);
+	return it6625_enable_stream_locked(it6625, false);
 }
 
 static int it6625_enum_mbus_code(struct v4l2_subdev *sd,
@@ -1795,7 +1800,7 @@ static const struct v4l2_subdev_core_ops it6625_core_ops = {
 
 static const struct v4l2_subdev_video_ops it6625_video_ops = {
 	.g_input_status = it6625_g_input_status,
-	.s_stream = it6625_s_stream,
+	.s_stream = v4l2_subdev_s_stream_helper,
 };
 
 static const struct v4l2_subdev_pad_ops it6625_pad_ops = {
@@ -1810,6 +1815,8 @@ static const struct v4l2_subdev_pad_ops it6625_pad_ops = {
 	.s_dv_timings = it6625_pad_s_dv_timings,
 	.g_dv_timings = it6625_pad_g_dv_timings,
 	.query_dv_timings = it6625_pad_query_dv_timings,
+	.enable_streams = it6625_enable_streams,
+	.disable_streams = it6625_disable_streams,
 };
 
 static const struct v4l2_subdev_ops it6625_ops = {

-- 
2.34.1

