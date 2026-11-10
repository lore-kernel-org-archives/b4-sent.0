From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:19:28 +0000
Subject: [PATCH] drm/bridge: Fail an unsatisfiable bus format negotiation
 with -EINVAL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-drm-bridge-busfmt-einval-v1-1-c0494bd23264@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM0Q6CMAyF4VchvbbJOgwRX8V4wbaCJTJNC4SE8
 O5Ovfxycv4djFXY4FrtoLyKySsX0KmC+OjywCipGLzzDRE5TDphUEllCYv104wsee2e6GO8hDq
 RO7c1lPtbuZftl77d/7YljBznbw+O4wPXWCeLfAAAAA==
X-Change-ID: 20261110-drm-bridge-busfmt-einval-2cc8b3d10493
To: Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Luca Ceresoli <luca.ceresoli@bootlin.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295167; l=2931;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=6XMYzP0YUE+EgwGGwMYmFB73J3HaaBRqLqa6SWZe9Zw=;
 b=tKDI+fU38XeKY5fsQssGVW69baV1Qxo0SkqKz0o5wZreiIkudAVUWXiy68hPx040+wtvEH5ts
 yST01F+7SnsDWSenN9uq8r6RjEi7I/kKdLSn+PTM92BoBvmJ5bw3Wkg
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

drm_atomic_bridge_chain_select_bus_fmts() reports that no chain of bus
formats fits with -ENOTSUPP, and drm_atomic_bridge_chain_check() passes
that straight back through drm_atomic_helper_check_modeset() to the
atomic and legacy modeset ioctls. -ENOTSUPP (524) is a kernel-internal
code that userspace does not know; for a configuration the hardware
cannot do the atomic API returns -EINVAL. Since the connector "color
format" property makes the negotiation fail for any requested format a
bridge chain cannot output, userspace now hits this routinely: a DW DP
connector asked for YCbCr 4:2:0 on a sink without 4:2:0 support gets
here with no matching format and would fail the atomic commit with
errno 524, where an HDMI connector asked for the same returns EINVAL
from the HDMI state helper.

Return -EINVAL when the negotiation finds no chain, with a debug
message naming the encoder.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Found while making the DW DP bridge honour the "color format" connector
property on an Orange Pi 5 (RK3588S): once dw-dp only offers the bus
formats of the requested colour format, a request the sink or the mode
cannot take leaves the chain with no format, and the atomic check
returns the kernel-internal -ENOTSUPP.

Tested on that board with this patch and that dw-dp change, with a
DisplayPort monitor whose EDID has no YCbCr 4:2:0 support: all 74
commits asking for YCbCr 4:2:0 over the monitor's modes and depths are
refused with EINVAL, as the same request on the HDMI connector is; the
296 RGB, YCbCr 4:4:4/4:2:2 and automatic cases still get their format,
with the picture checked by a camera.

This patch was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit message, and I reviewed and tested it
as described above.
---
 drivers/gpu/drm/drm_bridge.c | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/drivers/gpu/drm/drm_bridge.c b/drivers/gpu/drm/drm_bridge.c
index 8ae2f9b1db44..6a97b579c604 100644
--- a/drivers/gpu/drm/drm_bridge.c
+++ b/drivers/gpu/drm/drm_bridge.c
@@ -1437,6 +1437,17 @@ int drm_atomic_bridge_chain_check(struct drm_bridge *bridge,
 
 	ret = drm_atomic_bridge_chain_select_bus_fmts(bridge, crtc_state,
 						      conn_state);
+	/*
+	 * -ENOTSUPP is the internal "no bus format chain" code of the
+	 * negotiation. It is not a valid userspace error code; an atomic
+	 * check that cannot be satisfied fails with -EINVAL.
+	 */
+	if (ret == -ENOTSUPP) {
+		drm_dbg_atomic(bridge->dev,
+			       "[ENCODER:%d:%s] no bus format chain found\n",
+			       bridge->encoder->base.id, bridge->encoder->name);
+		return -EINVAL;
+	}
 	if (ret)
 		return ret;
 

---
base-commit: 8deaade4a5a4ff635df91e246e42139ab2b33f6d
change-id: 20261110-drm-bridge-busfmt-einval-2cc8b3d10493

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

