From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sun, 15 Nov 2026 08:49:15 +0000
Subject: [PATCH v3] drm/bridge: Fail an unsatisfiable bus format
 negotiation with -EINVAL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-drm-bridge-busfmt-einval-v3-1-ab38616d6135@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42Nyw6CMBBFf4V0bU2nrfhY+R/GBX0AYyiYFhoN4
 d9tccPKuDyZO+fMJFiPNpBLMRNvIwYc+gRiVxDdVn1jKZrEhDNeAgCjxjuqPJp0UVOo3Ugt9rH
 qKNf6pIQBJs+CpPentzW+VvXt/uUwqYfVY/blRYthHPx7bUfIuz8yEShQnSJSGS54Ka+Nq7Db6
 8GRnIl8K4IfIp5EtVJHeWaHEqTaipZl+QCHQoFpGwEAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794732555; l=2445;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=wDXeQt9euA8I+/3t45VeI1f/YvX4GBH9rBxqF2WJVaY=;
 b=DYQVDCJ5ppn7LVbkF62hmMtueR/ast2YyZseZIpyOAfxSFZ+ZZp/me3meaoXZI8p8lH7Sn9rg
 QUXTgKPXV3yDUEoOnrUNcQV4SCFb078jHL9BxsuAupqrTT7/s0tLsbi
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If no bus format chain fits, drm_atomic_bridge_chain_check() passes
-ENOTSUPP from the negotiation to userspace. Return -EINVAL instead and
update the KUnit test that expects -ENOTSUPP.

Fixes: f32df58acc68 ("drm/bridge: Add the necessary bits to support bus format negotiation")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Tested with the drm KUnit tests (UML).
Developed with Claude (Anthropic), which wrote the code and the commit
message. I reviewed it.
---
Changes in v3:
- Shorter commit message, without the DW DP example (Nicolas Frattaroli)
- Drop the code comment
- Link to v2: https://patch.msgid.link/20261111-drm-bridge-busfmt-einval-v2-1-fbb74905614b@gmail.com

Changes in v2:
- Make drm_test_bridge_rgb_yuv_no_path() expect -EINVAL (Sashiko)
- Add the Fixes tag (Sashiko)
- Cc Nicolas Frattaroli and Boris Brezillon
- Link to v1: https://patch.msgid.link/20261110-drm-bridge-busfmt-einval-v1-1-c0494bd23264@gmail.com
---
 drivers/gpu/drm/drm_bridge.c            | 6 ++++++
 drivers/gpu/drm/tests/drm_bridge_test.c | 2 +-
 2 files changed, 7 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/drm_bridge.c b/drivers/gpu/drm/drm_bridge.c
index 8ae2f9b1db44..33120cc7f982 100644
--- a/drivers/gpu/drm/drm_bridge.c
+++ b/drivers/gpu/drm/drm_bridge.c
@@ -1437,6 +1437,12 @@ int drm_atomic_bridge_chain_check(struct drm_bridge *bridge,
 
 	ret = drm_atomic_bridge_chain_select_bus_fmts(bridge, crtc_state,
 						      conn_state);
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

