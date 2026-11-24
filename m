From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Tue, 24 Nov 2026 11:04:40 +0800
Subject: [PATCH v2 3/9] media: i2c: tc358743: also report the standard
 audio controls
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-upstream-it6625-alsa-i2s-v2-3-a154685f6989@ite.com.tw>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795489507; l=2928;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=ytAWsRiTLVmmRHZAGjnaMocH6hwobSFfACvLY218tdQ=;
 b=BnHBczbCbD+LslyqMcoasYmBx2keRAWAlGqCe6IkPyA5Hc7lHHNsvbu5vepYBiXKS1Qxnz8pB
 RktmPmNFtXACZLYLpscicbJDFrfQMARx+bAXMYDDB+R+25Qee4YWGo3
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver reports the HDMI audio sampling rate and whether audio is
present through its custom controls TC358743_CID_AUDIO_SAMPLING_RATE and
TC358743_CID_AUDIO_PRESENT. There are now standard controls for both:
V4L2_CID_DV_RX_AUDIO_SAMPLING_RATE and V4L2_CID_DV_RX_AUDIO_PRESENT.

Add the standard controls and set them together with the custom ones,
from the same values. The custom controls are kept, since userspace may
already use them.
---
 drivers/media/i2c/tc358743.c | 31 ++++++++++++++++++++++++++-----
 1 file changed, 26 insertions(+), 5 deletions(-)

diff --git a/drivers/media/i2c/tc358743.c b/drivers/media/i2c/tc358743.c
index d9cd0563d50b62e90387397210e80a8b10f0988f..873fc22d030a3cc87c79e35eb57579eba902432f 100644
--- a/drivers/media/i2c/tc358743.c
+++ b/drivers/media/i2c/tc358743.c
@@ -95,6 +95,8 @@ struct tc358743_state {
 	struct v4l2_ctrl *detect_tx_5v_ctrl;
 	struct v4l2_ctrl *audio_sampling_rate_ctrl;
 	struct v4l2_ctrl *audio_present_ctrl;
+	struct v4l2_ctrl *audio_sampling_rate_std_ctrl;
+	struct v4l2_ctrl *audio_present_std_ctrl;
 
 	struct delayed_work delayed_work_enable_hotplug;
 
@@ -589,17 +591,27 @@ static int tc358743_s_ctrl_detect_tx_5v(struct v4l2_subdev *sd)
 static int tc358743_s_ctrl_audio_sampling_rate(struct v4l2_subdev *sd)
 {
 	struct tc358743_state *state = to_state(sd);
+	int rate = get_audio_sampling_rate(sd);
+	int ret;
 
-	return v4l2_ctrl_s_ctrl(state->audio_sampling_rate_ctrl,
-			get_audio_sampling_rate(sd));
+	ret = v4l2_ctrl_s_ctrl(state->audio_sampling_rate_ctrl, rate);
+	if (ret)
+		return ret;
+
+	return v4l2_ctrl_s_ctrl(state->audio_sampling_rate_std_ctrl, rate);
 }
 
 static int tc358743_s_ctrl_audio_present(struct v4l2_subdev *sd)
 {
 	struct tc358743_state *state = to_state(sd);
+	bool present = audio_present(sd);
+	int ret;
 
-	return v4l2_ctrl_s_ctrl(state->audio_present_ctrl,
-			audio_present(sd));
+	ret = v4l2_ctrl_s_ctrl(state->audio_present_ctrl, present);
+	if (ret)
+		return ret;
+
+	return v4l2_ctrl_s_ctrl(state->audio_present_std_ctrl, present);
 }
 
 static int tc358743_update_controls(struct v4l2_subdev *sd)
@@ -2217,11 +2229,20 @@ static int tc358743_probe(struct i2c_client *client)
 	}
 
 	/* control handlers */
-	v4l2_ctrl_handler_init(&state->hdl, 3);
+	v4l2_ctrl_handler_init(&state->hdl, 5);
 
 	state->detect_tx_5v_ctrl = v4l2_ctrl_new_std(&state->hdl, NULL,
 			V4L2_CID_DV_RX_POWER_PRESENT, 0, 1, 0, 0);
 
+	state->audio_sampling_rate_std_ctrl =
+		v4l2_ctrl_new_std(&state->hdl, NULL,
+				  V4L2_CID_DV_RX_AUDIO_SAMPLING_RATE,
+				  0, 768000, 1, 0);
+
+	state->audio_present_std_ctrl =
+		v4l2_ctrl_new_std(&state->hdl, NULL,
+				  V4L2_CID_DV_RX_AUDIO_PRESENT, 0, 1, 1, 0);
+
 	/* custom controls */
 	state->audio_sampling_rate_ctrl = v4l2_ctrl_new_custom(&state->hdl,
 			&tc358743_ctrl_audio_sampling_rate, NULL);

-- 
2.34.1

