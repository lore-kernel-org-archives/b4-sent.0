From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Tue, 24 Nov 2026 11:04:45 +0800
Subject: [PATCH v2 8/9] media: i2c: it6625: use the standard audio rate and
 present controls
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-upstream-it6625-alsa-i2s-v2-8-a154685f6989@ite.com.tw>
References: <20261124-upstream-it6625-alsa-i2s-v2-0-a154685f6989@ite.com.tw>
In-Reply-To: <20261124-upstream-it6625-alsa-i2s-v2-0-a154685f6989@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Mark Brown <broonie@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, linux-sound@vger.kernel.org, 
 linux-api@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795489507; l=2258;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=SkAsbIaGVKIQpu4PLBLiScjWzS60ulmPXbGK1gIyRUA=;
 b=EPbz+eQZU6tQGZRrbCgRMkp8ivgUZYY5P8FGOY6g9e0F+V3KkoRsD9/ltJ90X8Yl7jMFe83oB
 G10+fy1PBn/AWdsVWLQe9nNvvZuKi28ly/qh8iR877j7afI3F82AfVG
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver reports the HDMI audio sampling rate and whether audio is
present through the driver-specific controls
V4L2_CID_IT6625_AUDIO_SAMPLING_RATE and V4L2_CID_IT6625_AUDIO_PRESENT.
There are now standard controls for both.

Report V4L2_CID_DV_RX_AUDIO_SAMPLING_RATE and
V4L2_CID_DV_RX_AUDIO_PRESENT instead, with the same range and the same
values. The driver-specific control IDs are no longer used.
---
 drivers/media/i2c/it6625.c | 30 ++++--------------------------
 1 file changed, 4 insertions(+), 26 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index 72ca1d4ecdc932609f1a38129bfa1e188a024ddf..e4487e8111b94b2fa9f599e37ecd2b8a11425862 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -2127,28 +2127,6 @@ static const struct v4l2_subdev_internal_ops it6625_internal_ops = {
 	.init_state = it6625_init_state,
 };
 
-static const struct v4l2_ctrl_config it6625_ctrl_audio_sampling_rate = {
-	.id = V4L2_CID_IT6625_AUDIO_SAMPLING_RATE,
-	.name = "Audio Sampling Rate",
-	.type = V4L2_CTRL_TYPE_INTEGER,
-	.min = 0,
-	.max = 1536000,
-	.step = 1,
-	.def = 0,
-	.flags = V4L2_CTRL_FLAG_READ_ONLY,
-};
-
-static const struct v4l2_ctrl_config it6625_ctrl_audio_present = {
-	.id = V4L2_CID_IT6625_AUDIO_PRESENT,
-	.name = "Audio Present",
-	.type = V4L2_CTRL_TYPE_BOOLEAN,
-	.min = 0,
-	.max = 1,
-	.step = 1,
-	.def = 0,
-	.flags = V4L2_CTRL_FLAG_READ_ONLY,
-};
-
 static int it6625_v4l2_init_controls(struct v4l2_subdev *sd)
 {
 	struct it6625 *it6625 = sd_to_6625(sd);
@@ -2163,11 +2141,11 @@ static int it6625_v4l2_init_controls(struct v4l2_subdev *sd)
 				  0, 1, 0, 0);
 
 	it6625->ctrl_audio_sampling_rate =
-		v4l2_ctrl_new_custom(hdl,
-				     &it6625_ctrl_audio_sampling_rate,
-				     NULL);
+		v4l2_ctrl_new_std(hdl, NULL, V4L2_CID_DV_RX_AUDIO_SAMPLING_RATE,
+				  0, 1536000, 1, 0);
 	it6625->ctrl_audio_present =
-		v4l2_ctrl_new_custom(hdl, &it6625_ctrl_audio_present, NULL);
+		v4l2_ctrl_new_std(hdl, NULL, V4L2_CID_DV_RX_AUDIO_PRESENT,
+				  0, 1, 1, 0);
 	it6625->ctrl_audio_type =
 		v4l2_ctrl_new_std_menu(hdl, NULL, V4L2_CID_DV_RX_AUDIO_TYPE,
 				       V4L2_DV_RX_AUDIO_TYPE_ONE_BIT, 0,

-- 
2.34.1

