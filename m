From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Tue, 21 Jan 2025 15:01:51 +0800
Subject: [PATCH v4] drm/bridge: it6505: fix HDCP V match check is not
 performed correctly
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250121-fix-hdcp-v-comp-v4-1-185f45c728dc@ite.com.tw>
X-B4-Tracking: v=1; b=H4sIAF5Gj2cC/4XNQQ7CIBAF0KsY1tLAACm48h7GBYWpZWHbQIOap
 neXNjHRdOHyz/x5M5OEMWAip8NMIuaQwtCXII8H4jrb35AGXzIBBopxVtM2PGnn3UgzdcN9pKK
 xGoWvrW8FKVdjxFLZxMu15C6kaYiv7UHm6/Rj6Z2VOeXUSCY15xqU8+cwYVVW1fQgK5bhGzB7A
 ApQe4fMKqNAtDtA/AFEATgojb4BaWzzAyzL8gY27iWFMQEAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1737442945; l=2084;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=dUqXlNgYAl2Ay3XuEGf25rTzX7c3cUgN/Ydq0aXRSw0=;
 b=nhbLadf23YE4qooMAxAUwjrpv7qAIZFRU5IYDckSVOaGDmJ7mdEbwcLIJhd4fRDiDwexc8PKJ
 IOu5RI71KYrAZUdYsCaaoksnZrYbLNnHp4cYAL1uz4AbJlG07knRRND
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix a typo where V compare incorrectly compares av[] with av[] itself,
which can result in HDCP failure.

The loop of V compare is expected to iterate for 5 times
which compare V array form av[0][] to av[4][].
It should check loop counter reach the last statement "i == 5"
before return true

Fixes: 0989c02c7a5c ("drm/bridge: it6505: fix HDCP CTS compare V matching")
Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
Changes in v4:
- Fix a typo where V compare incorrectly compares av[] with av[] itself
- Link to v3: https://lore.kernel.org/r/20250109-fix-hdcp-v-comp-v3-1-1258edb249ab@ite.com.tw

Changes in v3:
- The V value compare loop from i = 0 to i = 4 and shall exit with i == 5 
  if all V element matches
- Link to v2: https://lore.kernel.org/r/20250109-fix-hdcp-v-comp-v2-1-7dce0a59523f@ite.com.tw

Changes in v2:
- pull the check of statment "i" out of V value check loop 
- Link to v1: https://lore.kernel.org/r/20250108-fix-hdcp-v-comp-v1-1-9404811825cd@ite.com.tw
---
 drivers/gpu/drm/bridge/ite-it6505.c | 7 ++++---
 1 file changed, 4 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/bridge/ite-it6505.c b/drivers/gpu/drm/bridge/ite-it6505.c
index 88ef76a37fe6accacdd343839ff2569b31b18ceb..76dabca04d0d191b3bdee23c6a3e55f4b6d3bad4 100644
--- a/drivers/gpu/drm/bridge/ite-it6505.c
+++ b/drivers/gpu/drm/bridge/ite-it6505.c
@@ -2250,12 +2250,13 @@ static bool it6505_hdcp_part2_ksvlist_check(struct it6505 *it6505)
 			continue;
 		}
 
-		for (i = 0; i < 5; i++) {
+		for (i = 0; i < 5; i++)
 			if (bv[i][3] != av[i][0] || bv[i][2] != av[i][1] ||
-			    av[i][1] != av[i][2] || bv[i][0] != av[i][3])
+			    bv[i][1] != av[i][2] || bv[i][0] != av[i][3])
 				break;
 
-			DRM_DEV_DEBUG_DRIVER(dev, "V' all match!! %d, %d", retry, i);
+		if (i == 5) {
+			DRM_DEV_DEBUG_DRIVER(dev, "V' all match!! %d", retry);
 			return true;
 		}
 	}

---
base-commit: 938fbb16aba8f7b88e0fdcf56f315a5bbad41aad
change-id: 20250107-fix-hdcp-v-comp-3ba8e3d7adf3

Best regards,
-- 
Hermes Wu <Hermes.wu@ite.com.tw>

