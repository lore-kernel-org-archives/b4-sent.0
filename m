From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Thu, 09 Jan 2025 12:36:23 +0800
Subject: [PATCH v2] drm/bridge: it6505: fix HDCP V match check is not
 performed correctly
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250109-fix-hdcp-v-comp-v2-1-7dce0a59523f@ite.com.tw>
X-B4-Tracking: v=1; b=H4sIAEZSf2cC/2WNQQ6CMBBFr0Jm7ZC2QKiuuIdhge1gZyGQtqka0
 rtbSVy5fH/+f7NDIM8U4FLt4Clx4HUpoE4VGDctd0K2hUEJ1Qkpepz5hc6aDROa9bFhc5s0Nba
 f7NxAWW2eSuUwXsfCjkNc/ft4kOQ3/bn0nytJlHhuRaul1KozduBIdTnV8QljzvkDS2x+qK8AA
 AA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736397401; l=1566;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=EkBgkfoeDLP1LIGeFj8kxcbiBg0jOTcKAZtPNxZo1Us=;
 b=2HjXDrMwWjjLJAL2u6vN+KktIl36gJRFDbsZLDXC5MrIazjNtqvRI7OAbrmI3+uib0fX/h8fW
 XIFreCRFdgLD9/jGcQMmSyNQbzL9FLGzC3j+WuUq4GoDzoCMn5ACErj
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The loop of V compare is expected to iterate for 5 times
which compare V array form av[0][] to av[4][].
It should check loop counter reach the last statement before return true

Fixes: 0989c02c7a5c ("drm/bridge: it6505: fix HDCP CTS compare V matching")
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@linaro.org>
Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
Changes in v2:
- pull the check of statment "i" out of V value check loop 
- Link to v1: https://lore.kernel.org/r/20250108-fix-hdcp-v-comp-v1-1-9404811825cd@ite.com.tw
---
 drivers/gpu/drm/bridge/ite-it6505.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/bridge/ite-it6505.c b/drivers/gpu/drm/bridge/ite-it6505.c
index 88ef76a37fe6accacdd343839ff2569b31b18ceb..a7c33270a2b75d7c8ab85f6165b367a7c1a364a3 100644
--- a/drivers/gpu/drm/bridge/ite-it6505.c
+++ b/drivers/gpu/drm/bridge/ite-it6505.c
@@ -2250,12 +2250,13 @@ static bool it6505_hdcp_part2_ksvlist_check(struct it6505 *it6505)
 			continue;
 		}
 
-		for (i = 0; i < 5; i++) {
+		for (i = 0; i < 5; i++)
 			if (bv[i][3] != av[i][0] || bv[i][2] != av[i][1] ||
 			    av[i][1] != av[i][2] || bv[i][0] != av[i][3])
 				break;
 
-			DRM_DEV_DEBUG_DRIVER(dev, "V' all match!! %d, %d", retry, i);
+		if (i == 4) {
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

