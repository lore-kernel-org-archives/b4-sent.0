From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Wed, 16 Oct 2024 15:54:20 +0800
Subject: [PATCH v6 08/10] drm/bridge: it6505: fix HDCP CTS compare V
 matching
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241016-upstream-v6-v6-8-4d93a0c46de1@ite.com.tw>
References: <20241016-upstream-v6-v6-0-4d93a0c46de1@ite.com.tw>
In-Reply-To: <20241016-upstream-v6-v6-0-4d93a0c46de1@ite.com.tw>
To: Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Pin-yen Lin <treapking@chromium.org>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Kenneth Hung <Kenneth.hung@ite.com.tw>, Pet Weng <Pet.Weng@ite.com.tw>, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729065263; l=2090;
 i=Hermes.wu@ite.com.tw; s=20241016; h=from:subject:message-id;
 bh=vVGOPh2gUmJR+gDRTv9xrafnNiddtntN9yPHXoZ0A7Y=;
 b=OhDMy/DGwZCFCTXSW4O5wIhEi0wj63lfX8wE8fgG/wVL5mzlXwX5mi906+fCnd3oxkJtwrf+S
 hffdaKRx9ELDya2dnsW8IkAP4XiJAKhCP0NG/iL2O3ns/4Cl+c0ani0
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=kV18uQEXox+1WccdQceCbMlJKN+BBNUk3N8VsoULcQ0=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241016 with auth_id=250
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When HDCP negotiation with a repeater device.
Checking SHA V' matching must retry 3 times before restarting HDCP.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/gpu/drm/bridge/ite-it6505.c | 32 +++++++++++++++++++-------------
 1 file changed, 19 insertions(+), 13 deletions(-)

diff --git a/drivers/gpu/drm/bridge/ite-it6505.c b/drivers/gpu/drm/bridge/ite-it6505.c
index 40fb47f4954331d63681066fb3af19f0f57bb929..439cca455ecf91b5f83b0add416db7f099f9a34d 100644
--- a/drivers/gpu/drm/bridge/ite-it6505.c
+++ b/drivers/gpu/drm/bridge/ite-it6505.c
@@ -2057,7 +2057,7 @@ static bool it6505_hdcp_part2_ksvlist_check(struct it6505 *it6505)
 {
 	struct device *dev = it6505->dev;
 	u8 av[5][4], bv[5][4];
-	int i, err;
+	int i, err, retry;
 
 	i = it6505_setup_sha1_input(it6505, it6505->sha1_input);
 	if (i <= 0) {
@@ -2066,22 +2066,28 @@ static bool it6505_hdcp_part2_ksvlist_check(struct it6505 *it6505)
 	}
 
 	it6505_sha1_digest(it6505, it6505->sha1_input, i, (u8 *)av);
+	/*1B-05 V' must retry 3 times */
+	for (retry = 0; retry < 3; retry++) {
+		err = it6505_get_dpcd(it6505, DP_AUX_HDCP_V_PRIME(0), (u8 *)bv,
+				      sizeof(bv));
 
-	err = it6505_get_dpcd(it6505, DP_AUX_HDCP_V_PRIME(0), (u8 *)bv,
-			      sizeof(bv));
+		if (err < 0) {
+			dev_err(dev, "Read V' value Fail %d", retry);
+			continue;
+		}
 
-	if (err < 0) {
-		dev_err(dev, "Read V' value Fail");
-		return false;
-	}
+		for (i = 0; i < 5; i++) {
+			if (bv[i][3] != av[i][0] || bv[i][2] != av[i][1] ||
+			    av[i][1] != av[i][2] || bv[i][0] != av[i][3])
+				break;
 
-	for (i = 0; i < 5; i++)
-		if (bv[i][3] != av[i][0] || bv[i][2] != av[i][1] ||
-		    bv[i][1] != av[i][2] || bv[i][0] != av[i][3])
-			return false;
+			DRM_DEV_DEBUG_DRIVER(dev, "V' all match!! %d, %d", retry, i);
+			return true;
+		}
+	}
 
-	DRM_DEV_DEBUG_DRIVER(dev, "V' all match!!");
-	return true;
+	DRM_DEV_DEBUG_DRIVER(dev, "V' NOT match!! %d", retry);
+	return false;
 }
 
 static void it6505_hdcp_wait_ksv_list(struct work_struct *work)

-- 
2.34.1

