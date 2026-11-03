From: "David R. Hedges" <linuxdev844@thelittleman.net>
Date: Tue, 03 Nov 2026 14:02:47 -0600
Subject: [PATCH 1/5] drm/nouveau/kms/nv50-: reject DP modesets the link
 can't carry
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-nouveau-dp-relink-v1-1-7ee88c7f1e8a@thelittleman.net>
References: <20261103-nouveau-dp-relink-v1-0-7ee88c7f1e8a@thelittleman.net>
In-Reply-To: <20261103-nouveau-dp-relink-v1-0-7ee88c7f1e8a@thelittleman.net>
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Jani Nikula <jani.nikula@intel.com>, Ben Skeggs <bskeggs@nvidia.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Danilo Krummrich <me@dakr.org>, 
 "David R. Hedges" <linuxdev844@thelittleman.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793736171; l=3402;
 i=linuxdev844@thelittleman.net; s=20261103; h=from:subject:message-id;
 bh=NdWN23uKT/9mBJCO7M1jmiktyYPpdGsPPw0VjH8l0q4=;
 b=IDMPhXCycTOWwZ/CRnLH/Xfh5uYfJtanaF2UzJY8wy5H+5T0PisIBcpFVhOQcX/XX7dqv8lD7
 BGybTpcR0nDB4K6k93VWh8f58LWKetnMziHXxpiJcFefJYu4bXsneZ+
X-Developer-Key: i=linuxdev844@thelittleman.net; a=ed25519;
 pk=Cynzuei/w0GLdh3LuNJdvH7aaszLrHSxY5UyujS7l+g=
X-Endpoint-Received: by B4 Relay for linuxdev844@thelittleman.net/20261103 with auth_id=1397
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

nv50_outp_atomic_fix_depth() lowers the bpc of a DP mode until it fits
the link's capabilities, but carries on at 6 bpc if it still doesn't.
nouveau_dp_train() then finds no lane count and link rate fast enough,
trains nothing, and the output is enabled anyway.

Modes are checked against the link when they're probed, so this takes
a sink whose capabilities have dropped since, or that couldn't be
probed at all.  An IGM L28TN4K on a GA102 (GSP-RM 570.144) manages
both: for a moment after being switched on with its power button it
advertises DPCD 1.1 and HBR rather than DPCD 1.2 and HBR2, and the
3840x2160@60 mode it had been running needs 1336500 kB/s even at
6 bpc, against 1080000 kB/s for 4 x HBR; and while it's switched off
it keeps HPD asserted but doesn't answer AUX, which leaves its link
capabilities at zero.  Enabling the output in either state ended in
"core notifier timeout", after which GSP stopped answering RPCs.

Fail the modeset in that case, so that userspace can pick a mode that
fits.  A commit that only turns the CRTC back on mustn't fail (see
struct drm_crtc_state), so that case is left to the commit path, which
the next patch deals with.

Link: https://gitlab.freedesktop.org/drm/nouveau/-/work_items/515
Signed-off-by: David R. Hedges <linuxdev844@thelittleman.net>
---
 drivers/gpu/drm/nouveau/dispnv50/disp.c | 23 +++++++++++++++++++----
 1 file changed, 19 insertions(+), 4 deletions(-)

diff --git a/drivers/gpu/drm/nouveau/dispnv50/disp.c b/drivers/gpu/drm/nouveau/dispnv50/disp.c
index 7daecaecccac..8af01de822d5 100644
--- a/drivers/gpu/drm/nouveau/dispnv50/disp.c
+++ b/drivers/gpu/drm/nouveau/dispnv50/disp.c
@@ -373,7 +373,8 @@ nv50_outp_atomic_check_view(struct drm_encoder *encoder,
 	return 0;
 }
 
-static void
+/* Returns false if the link can't carry the mode even at the lowest bpc. */
+static bool
 nv50_outp_atomic_fix_depth(struct drm_encoder *encoder, struct drm_crtc_state *crtc_state)
 {
 	struct nv50_head_atom *asyh = nv50_head_atom(crtc_state);
@@ -389,17 +390,26 @@ nv50_outp_atomic_fix_depth(struct drm_encoder *encoder, struct drm_crtc_state *c
 		asyh->or.bpc = min_t(u8, asyh->or.bpc, 10);
 
 		/* reduce the bpc until it works out */
-		while (asyh->or.bpc > 6) {
+		for (;;) {
 			mode_rate = DIV_ROUND_UP(mode->clock * asyh->or.bpc * 3, 8);
 			if (mode_rate <= max_rate)
 				break;
 
+			if (asyh->or.bpc <= 6) {
+				drm_dbg_kms(encoder->dev,
+					    "[ENCODER:%d:%s] mode needs %u kB/s, link carries %u kB/s\n",
+					    encoder->base.id, encoder->name, mode_rate, max_rate);
+				return false;
+			}
+
 			asyh->or.bpc -= 2;
 		}
 		break;
 	default:
 		break;
 	}
+
+	return true;
 }
 
 static int
@@ -423,8 +433,13 @@ nv50_outp_atomic_check(struct drm_encoder *encoder,
 	if (crtc_state->mode_changed || crtc_state->connectors_changed)
 		asyh->or.bpc = connector->display_info.bpc ?: 8;
 
-	/* We might have to reduce the bpc */
-	nv50_outp_atomic_fix_depth(encoder, crtc_state);
+	/* We might have to reduce the bpc.  If the link can't carry the mode
+	 * at all, fail a modeset, but not a plain DPMS on, which userspace
+	 * expects to always succeed.
+	 */
+	if (!nv50_outp_atomic_fix_depth(encoder, crtc_state) &&
+	    (crtc_state->mode_changed || crtc_state->connectors_changed))
+		return -EINVAL;
 
 	return 0;
 }

-- 
2.55.0

