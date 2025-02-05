From: Hermes Wu <Hermes.wu@ite.com.tw>
Subject: [PATCH v3 0/2] drm/bridge: it6505: add audio support with DRM HDMI
 codec framework
Date: Wed, 05 Feb 2025 14:41:02 +0800
Message-Id: <20250205-add-audio-codec-v3-0-26cfadb2d81f@ite.com.tw>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAP4Ho2cC/2XNyw6CMBCF4VchXVvSC1dXvodxUaaDzEJqWqwaw
 rtbiIkxLP+TzDczC+gJAztmM/MYKZAbU+hDxmAw4xU52dRMCVUKKQturOXmYclxcBaBN9Daoha
 VMhWwdHX32NNrE8+X1AOFyfn39iDKdf1aSu6sKLnkqPu+lp2GRrYnmjAHd8unJ1uxqH6AEnoPq
 ASU0ICtFWLZdX/AsiwfPFSDA/AAAAA=
X-Change-ID: 20250114-add-audio-codec-8c9d47062a6c
To: Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: treapking@chromium.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Pet.Weng@ite.com.tw, Kenneth.Hung@ite.com.tw, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1738737663; l=1167;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=gGvYZ6oXvm9dTs3/vqawO1m498fxu7l1N6ATj9ZnzCQ=;
 b=l6pLDMUlMGqGOfQBULdVFZ/N+p9sCF1awqniFveTab/zyIbIrqqrNtBT+vpHS1QWQ7GOHDQFL
 BBTwhV+P3WFCEfi2hx9A2GQABDxd1gn6JPyRfS1a8u1txWOE/WV/OnB
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For supporting audio form I2S to DP audio data sub stream.

Add hdmi_audio callbacks to drm_bridge_funcs for the HDMI codec 
framework.

The DRM_BRIDGE_OP_HDMI flag in bridge.ops must be set, 
and implement necessary callbacks for the drm_bridge_connector 
to enable the HDMI codec.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
Changes in v3:
- Separate DRM_BRIDGE_OP_HDMI supports and audio callbacks into two commits.
- Link to v2: https://lore.kernel.org/r/20250203-add-audio-codec-v2-1-5c8cd72ee5bb@ite.com.tw

Changes in v2:
- Use DRM HDMI codec framewrok for audio stream setup.
- Link to v1: https://lore.kernel.org/r/20250121-add-audio-codec-v1-1-e3ff71b3c819@ite.com.tw

---
Hermes Wu (2):
      drm/bridge: it6505: add support DRM_BRIDGE_OP_HDMI to drm_bridge
      drm/bridge: it6505: add audio support to drm_bridge_funcs

 drivers/gpu/drm/bridge/ite-it6505.c | 231 +++++++++++++++++++++++++-----------
 1 file changed, 161 insertions(+), 70 deletions(-)
---
base-commit: fe003bcb69f7bff9ff2b30b659b004dbafe52907
change-id: 20250114-add-audio-codec-8c9d47062a6c

Best regards,
-- 
Hermes Wu <Hermes.wu@ite.com.tw>

