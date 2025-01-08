From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Wed, 08 Jan 2025 13:45:14 +0800
Subject: [PATCH] drm/bridge: it6505: fix HDCP V match check is not
 performed correctly
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250108-fix-hdcp-v-comp-v1-1-9404811825cd@ite.com.tw>
X-B4-Tracking: v=1; b=H4sIAOkQfmcC/x2MQQqAIBAAvyJ7bkGTMPpKdDBdcw+VKEQg/j3pO
 DAzFQplpgKLqJDp4cL31UENAly010HIvjOMcpykkgYDvxi9S/igu8+EerczaW+sDxp6lTJ15T+
 uW2sfDVAWQWEAAAA=
X-Change-ID: 20250107-fix-hdcp-v-comp-3ba8e3d7adf3
To: Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dmitry Baryshkov <dmitry.baryshkov@linaro.org>, 
 Hermes Wu <hermes.wu@ite.com.tw>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Pet.Weng@ite.com.tw, Kenneth.Hung@ite.com.tw, treapking@chromium.org, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736315115; l=1308;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=dyqbMaHoVsNvXn2a4OvVKxfPmk0+fIgLG5w+5YquGSw=;
 b=EGl+6seblMN/cphHfmfQmu8+zLNtcMleHGGC73U98PAlFWJbhZUhbWi9bnXbkwWE+NLl4YJxE
 nThd4mrPDQCBAQTS5xdVBUtJist3GUlzl19zpwb1gmXlkAPnpSP6fwt
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The loop of V compare is expected to iterate for 5 times
which compare V array form av[0][] to av[4][].
It should check loop counter reach the last statement before return true

Fixes: 0989c02c7a5c ("drm/bridge: it6505: fix HDCP CTS compare V matching")

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/gpu/drm/bridge/ite-it6505.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/bridge/ite-it6505.c b/drivers/gpu/drm/bridge/ite-it6505.c
index 88ef76a37fe6accacdd343839ff2569b31b18ceb..e87247aea1d2ffbdad192e241056d34fdfb32163 100644
--- a/drivers/gpu/drm/bridge/ite-it6505.c
+++ b/drivers/gpu/drm/bridge/ite-it6505.c
@@ -2254,9 +2254,12 @@ static bool it6505_hdcp_part2_ksvlist_check(struct it6505 *it6505)
 			if (bv[i][3] != av[i][0] || bv[i][2] != av[i][1] ||
 			    av[i][1] != av[i][2] || bv[i][0] != av[i][3])
 				break;
-
-			DRM_DEV_DEBUG_DRIVER(dev, "V' all match!! %d, %d", retry, i);
-			return true;
+			if (i == 4) {
+				DRM_DEV_DEBUG_DRIVER(dev,
+						     "V' all match!! %d",
+						     retry);
+				return true;
+			}
 		}
 	}
 

---
base-commit: 938fbb16aba8f7b88e0fdcf56f315a5bbad41aad
change-id: 20250107-fix-hdcp-v-comp-3ba8e3d7adf3

Best regards,
-- 
Hermes Wu <Hermes.wu@ite.com.tw>

