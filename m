From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Fri, 18 Sep 2026 16:57:17 +0800
Subject: [PATCH 02/21] media: i2c: it6625: propagate control-update errors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-upstream-it6625-follow-up-patch-v1-2-78d72d7886a5@ite.com.tw>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789721837; l=2441;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=Wu6oxlWNkGLpHo/RmSh9dUsCuP2b2+83EwxRGB5e1D4=;
 b=RlU/Qf+rDPlwqR1YBCM1C5YMsX3cf/mJrEpXgdDpTeIMU2UM3G/W4E4NR87Q1woSw7im6Hg6z
 VTXApez6ku/Di26mH0J4SmYduvp2tCTVtO14bNPANxR9kiduYYbqZnL
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

it6625_v4l2_sd_ctrl_update() discarded the return value of all three
v4l2_ctrl_s_ctrl() calls it makes. Make it return int, run the updates
sequentially, and return the first error; both call sites now check
and log it.

None of the three controls has a driver .ops, so the only failure path
in v4l2_ctrl_s_ctrl() is range validation, and every value this driver
passes is always in range -- this is an error-handling correctness fix
responsive to review, not a fix for an observed runtime failure.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 25 +++++++++++++++++++------
 1 file changed, 19 insertions(+), 6 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index da17e5d5ce9e2dd1060abba1598b0e3f78857e9c..5d267676606e340ad0ee5ad2b78e5acb50a32980 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -889,11 +889,19 @@ static int it6625_s_ctrl_audio_present(struct v4l2_subdev *sd)
 				audio_present(it6625));
 }
 
-static void it6625_v4l2_sd_ctrl_update(struct v4l2_subdev *sd)
+static int it6625_v4l2_sd_ctrl_update(struct v4l2_subdev *sd)
 {
-	it6625_s_ctrl_detect_hdmi_5v(sd);
-	it6625_s_ctrl_audio_sampling_rate(sd);
-	it6625_s_ctrl_audio_present(sd);
+	int ret;
+
+	ret = it6625_s_ctrl_detect_hdmi_5v(sd);
+	if (ret)
+		return ret;
+
+	ret = it6625_s_ctrl_audio_sampling_rate(sd);
+	if (ret)
+		return ret;
+
+	return it6625_s_ctrl_audio_present(sd);
 }
 
 static void it6625_enable_stream_locked(struct it6625 *it6625, bool enable)
@@ -1136,9 +1144,12 @@ static void it6625_clear_timings(struct it6625 *it6625)
 static void it6625_irq_hdmi_5v_change(struct it6625 *it6625)
 {
 	struct v4l2_subdev *sd = &it6625->sd;
+	int ret;
 
 	it6625_clear_timings(it6625);
-	it6625_v4l2_sd_ctrl_update(sd);
+	ret = it6625_v4l2_sd_ctrl_update(sd);
+	if (ret)
+		dev_err(it6625->dev, "%s: failed to update controls: %d", __func__, ret);
 }
 
 static void it6625_irq_hdcp_change(struct it6625 *it6625)
@@ -2297,7 +2308,9 @@ static int it6625_probe(struct i2c_client *client)
 	it6625_debugfs_init(it6625, client);
 
 	it6625_initial_setup(it6625);
-	it6625_v4l2_sd_ctrl_update(sd);
+	err = it6625_v4l2_sd_ctrl_update(sd);
+	if (err)
+		dev_err(it6625->dev, "%s: failed to update controls: %d", __func__, err);
 
 	err = v4l2_async_register_subdev(sd);
 	if (err < 0) {

-- 
2.34.1

