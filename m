From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Wed, 11 Nov 2026 07:19:41 +0000
Subject: [PATCH v2] drm/bridge: Fail an unsatisfiable bus format
 negotiation with -EINVAL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-drm-bridge-busfmt-einval-v2-1-fbb74905614b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42NTQ6CMBBGr0Jm7RimEKKuvIdhQdsBxlAwLTQaw
 t0teAGXL9/PWyGwFw5wy1bwHCXINCZQpwxM34wdo9jEoHJVEVGO1jvUXmxK9BJaNyPLGJsBlTE
 XXVjKy2sBaf7y3Mr7uH7UPw6LfrKZ97+90UuYJ/853JH23h+aSEhokqTUVhWqKu+da2Q4m8lBv
 W3bF9Z/s8LSAAAA
X-Change-ID: 20261110-drm-bridge-busfmt-einval-2cc8b3d10493
To: Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Luca Ceresoli <luca.ceresoli@bootlin.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Nicolas Frattaroli <nicolas.frattaroli@collabora.com>, 
 Boris Brezillon <boris.brezillon@collabora.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794381580; l=4655;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Ziyi2IZLgbKXw37gKHjsH70kDZh1z3mkpnBpz48qVjs=;
 b=CTIsg0OH7JUFZHae3BOEI0lTa03NHzsUj5+AJYyeUAkZXBYalcoBcTWtAguxGRZ2EpGL2Qucv
 5Xtku29gr03C7dzC4uZ1Sz8P/z6KDmNLgM9vJDlwzeeE3DIKfNGMmX/
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
message naming the encoder, and make the drm_bridge KUnit test of a
chain with no bus format path, drm_test_bridge_rgb_yuv_no_path(),
expect -EINVAL from the atomic commit.

Fixes: f32df58acc68 ("drm/bridge: Add the necessary bits to support bus format negotiation")
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
Changes in v2:
- Make drm_test_bridge_rgb_yuv_no_path() expect -EINVAL instead of
  -ENOTSUPP; v1 broke it, and I had not run the DRM KUnit tests. All
  drivers/gpu/drm/tests suites pass with v2 (UML). Reported by Sashiko.
  The colour format series added that check to record the value the
  negotiation already returned; I found no review comment about the
  error code on the test's postings (v6 to v17), and the atomic uAPI
  reports a state the hardware cannot do with -EINVAL, as the HDMI state
  helper does for the same colour format request.
- Add the Fixes tag, for the commit that made the atomic check return
  -ENOTSUPP. Suggested by Sashiko.
- Cc Nicolas Frattaroli (author of the test) and Boris Brezillon
  (author of the commit in Fixes).
- Link to v1: https://patch.msgid.link/20261110-drm-bridge-busfmt-einval-v1-1-c0494bd23264@gmail.com
---
 drivers/gpu/drm/drm_bridge.c            | 11 +++++++++++
 drivers/gpu/drm/tests/drm_bridge_test.c |  2 +-
 2 files changed, 12 insertions(+), 1 deletion(-)

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
 
diff --git a/drivers/gpu/drm/tests/drm_bridge_test.c b/drivers/gpu/drm/tests/drm_bridge_test.c
index 15583ade8494..792dbd035501 100644
--- a/drivers/gpu/drm/tests/drm_bridge_test.c
+++ b/drivers/gpu/drm/tests/drm_bridge_test.c
@@ -1351,7 +1351,7 @@ static void drm_test_bridge_rgb_yuv_no_path(struct kunit *test)
 		drm_modeset_backoff(&ctx);
 		goto retry_commit;
 	}
-	KUNIT_EXPECT_EQ(test, ret, -ENOTSUPP);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
 
 	drm_modeset_drop_locks(&ctx);
 	drm_modeset_acquire_fini(&ctx);

---
base-commit: 8deaade4a5a4ff635df91e246e42139ab2b33f6d
change-id: 20261110-drm-bridge-busfmt-einval-2cc8b3d10493

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

