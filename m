From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Mon, 04 Nov 2024 14:43:37 +0800
Subject: [PATCH v7 07/10] drm/bridge: it6505: fix HDCP CTS KSV list read
 with UNIGRAF DPR-100.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241104-v7-upstream-v7-7-8b71fd0f1d2d@ite.com.tw>
References: <20241104-v7-upstream-v7-0-8b71fd0f1d2d@ite.com.tw>
In-Reply-To: <20241104-v7-upstream-v7-0-8b71fd0f1d2d@ite.com.tw>
To: Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Hermes Wu <hermes.wu@ite.com.tw>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Pin-yen Lin <treapking@chromium.org>, 
 Kenneth Hung <Kenneth.Hung@ite.com.tw>, Pet Weng <Pet.Weng@ite.com.tw>, 
 Hermes Wu <Hermes.wu@ite.com.tw>, 
 Dmitry Baryshkov <dmitry.baryshkov@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730702658; l=3017;
 i=Hermes.wu@ite.com.tw; s=20241101; h=from:subject:message-id;
 bh=LkPmWJ3+m9M5J4gwKc6RK5juQw3WKrt44Jh3DJ8DUnY=;
 b=/4DGNl6gmpJctBFosSW3teRnwAylMwNxDWmHIo/I0uS3ya8Giz7igPIWIDr0M9XMQ/JM+r68N
 07XvT2jGbNdBq/0jkfwFWZvcPKkedRW+m5rJQT9Is7PkYfA26gsxVOv
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=FOYYbsP2Nlw6mjB3rLFYSLmAiENzj4AWQly5XTcDuMM=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241101 with auth_id=268
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When running the HDCP CTS test with UNIGRAF DPR-100.
KSV list must be read from DP_AUX_HDCP_KSV_FIFO in an AUX request,
and can not separate with multiple read requests.

The AUX operation command "CMD_AUX_GET_KSV_LIST" reads the KSV list
with AUX FIFO and is able to read DP_AUX_HDCP_KSV_FIFO in an AUX request.

Add it6505_get_ksvlist() which uses CMD_AUX_GET_KSV_LIST operation
to read the KSV list.

Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@linaro.org>
Signed-off-by: Hermes Wu <hermes.wu@ite.com.tw>
---
 drivers/gpu/drm/bridge/ite-it6505.c | 48 +++++++++++++++++++++++++++----------
 1 file changed, 36 insertions(+), 12 deletions(-)

diff --git a/drivers/gpu/drm/bridge/ite-it6505.c b/drivers/gpu/drm/bridge/ite-it6505.c
index 614fbb6295237708aa5b692de87ab5548c499da5..4ed4899227602a4574a13ffa22442dcc4a5c2092 100644
--- a/drivers/gpu/drm/bridge/ite-it6505.c
+++ b/drivers/gpu/drm/bridge/ite-it6505.c
@@ -1189,6 +1189,37 @@ static int it6505_get_edid_block(void *data, u8 *buf, unsigned int block,
 	return 0;
 }
 
+static int it6505_get_ksvlist(struct it6505 *it6505, u8 *buf, size_t len)
+{
+	struct device *dev = it6505->dev;
+	enum aux_cmd_reply reply;
+	int request_size, ret;
+	int i = 0;
+
+	do {
+		request_size = min_t(int, (int)len - i, 15);
+
+		ret = it6505_aux_do_transfer(it6505, CMD_AUX_GET_KSV_LIST,
+					     DP_AUX_HDCP_KSV_FIFO,
+					     buf + i, request_size, &reply);
+
+		DRM_DEV_DEBUG_DRIVER(dev, "request_size = %d, ret =%d", request_size, ret);
+		if (ret < 0)
+			return ret;
+
+		i += request_size;
+	} while (i < len);
+
+	DRM_DEV_DEBUG_DRIVER(dev, "ksv read cnt = %d down_stream_cnt=%d ", i, i / 5);
+
+	for (i = 0 ; i < len; i += 5) {
+		DRM_DEV_DEBUG_DRIVER(dev, "ksv[%d] = %02X%02X%02X%02X%02X",
+				     i / 5, buf[i], buf[i + 1], buf[i + 2], buf[i + 3], buf[i + 4]);
+	}
+
+	return len;
+}
+
 static void it6505_variable_config(struct it6505 *it6505)
 {
 	it6505->link_rate_bw_code = HBR;
@@ -1970,7 +2001,7 @@ static int it6505_setup_sha1_input(struct it6505 *it6505, u8 *sha1_input)
 {
 	struct device *dev = it6505->dev;
 	u8 binfo[2];
-	int down_stream_count, i, err, msg_count = 0;
+	int down_stream_count, err, msg_count = 0;
 
 	err = it6505_get_dpcd(it6505, DP_AUX_HDCP_BINFO, binfo,
 			      ARRAY_SIZE(binfo));
@@ -1995,18 +2026,11 @@ static int it6505_setup_sha1_input(struct it6505 *it6505, u8 *sha1_input)
 			down_stream_count);
 		return 0;
 	}
+	err =  it6505_get_ksvlist(it6505, sha1_input, down_stream_count * 5);
+	if (err < 0)
+		return err;
 
-	for (i = 0; i < down_stream_count; i++) {
-		err = it6505_get_dpcd(it6505, DP_AUX_HDCP_KSV_FIFO +
-				      (i % 3) * DRM_HDCP_KSV_LEN,
-				      sha1_input + msg_count,
-				      DRM_HDCP_KSV_LEN);
-
-		if (err < 0)
-			return err;
-
-		msg_count += 5;
-	}
+	msg_count += down_stream_count * 5;
 
 	it6505->hdcp_down_stream_count = down_stream_count;
 	sha1_input[msg_count++] = binfo[0];

-- 
2.34.1

