From: Sam Ravnborg <sam@ravnborg.org>
Subject: [PATCH 0/2] drm bridge: drop drm_bridge_chain_mode_fixup.
Date: Fri, 31 May 2024 22:37:44 +0200
Message-Id: <20240531-bridge_chain_mode-v1-0-8b49e36c5dd3@ravnborg.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABg1WmYC/x2MUQqAIBAFrxL7nWBWoF0lIqp92X5koRBBdPekz
 2GYeSghChJ1xUMRlyQ5QoaqLGjZpuChhDOT0abRbV2pOQp7jFlKGPeDoRzYtsbCmYUpd2fEKvf
 /7If3/QDT/D+mYwAAAA==
To: dri-devel@lists.freedesktop.org, 
 Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>
Cc: Sam Ravnborg <sam@ravnborg.org>, Maxime Ripard <mripard@kernel.org>, 
 Laurent Pinchart <laurent.pinchart+renesas@ideasonboard.com>, 
 Chun-Kuang Hu <chunkuang.hu@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 Dafna Hirschfeld <dafna.hirschfeld@collabora.com>, 
 linux-mediatek@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Thomas Zimmermann <tzimmermann@suse.de>, David Airlie <airlied@linux.ie>, 
 Daniel Vetter <daniel@ffwll.ch>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717187864; l=888;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=3TZNScVbrXSoesw2SWXp2AE9mBMjCfX0SRtPx+bRQhs=;
 b=RJEgq3whBcLtGPUqO61RcGUeDm3zjIZl6CXwG2rw8fjT9OIY0boyiUXJaUSs/arIEDMtutVOk/RW
 0rYZJj4HBkh7CmMlGVs/q7tOwueKNcbyRkN/Pl8QH21RCSMlvz61
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Relay for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I had a few bridge related patches in an old branch.

They were last posted here almost one year ago:
https://lore.kernel.org/dri-devel/20220717174454.46616-1-sam@ravnborg.org/

The following two patches gets rid of drm_bridge_chain_mode_fixup.
The patches was already rb / ab - but due to the age a repost is
due before applying the patches.

	Sam

---
Sam Ravnborg (2):
      drm/mediatek: Drop chain_mode_fixup call in mode_valid()
      drm/bridge: Drop drm_bridge_chain_mode_fixup

 drivers/gpu/drm/drm_bridge.c        | 37 -------------------------------------
 drivers/gpu/drm/mediatek/mtk_hdmi.c | 11 -----------
 include/drm/drm_bridge.h            |  3 ---
 3 files changed, 51 deletions(-)
---
base-commit: c9402efe492bb46ccbf94fedc4783eb8f8747567
change-id: 20240531-bridge_chain_mode-9ed8528e92cd

Best regards,
-- 
Sam Ravnborg <sam@ravnborg.org>

