From: "David R. Hedges" <linuxdev844@thelittleman.net>
Date: Tue, 03 Nov 2026 13:28:04 -0600
Subject: [PATCH 4/5] drm/nouveau/kms/nv50-: don't drive outputs at 0 bpc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-nouveau-dp-fixes-v1-4-892f4bd357cd@thelittleman.net>
References: <20261103-nouveau-dp-fixes-v1-0-892f4bd357cd@thelittleman.net>
In-Reply-To: <20261103-nouveau-dp-fixes-v1-0-892f4bd357cd@thelittleman.net>
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dave Airlie <airlied@redhat.com>, Ben Skeggs <bskeggs@redhat.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, 
 "David R. Hedges" <linuxdev844@thelittleman.net>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793734092; l=2679;
 i=linuxdev844@thelittleman.net; s=20261103; h=from:subject:message-id;
 bh=Y8v/DP3NOf5boFL10j0leqHt5FR44DRl4gjR9gPSoac=;
 b=+gfw9HJYdTUWBbNvL/5bE6j3pQ5M2dXlma30T3x0/6svDsBcr376nzMJYo9HEWDj21DWbIhVB
 W5lYu0HUogyD3E8e+nQnlm5I3q1zaW67LFVgvN5alhEUva/Mr8gOH9q
X-Developer-Key: i=linuxdev844@thelittleman.net; a=ed25519;
 pk=Cynzuei/w0GLdh3LuNJdvH7aaszLrHSxY5UyujS7l+g=
X-Endpoint-Received: by B4 Relay for linuxdev844@thelittleman.net/20261103 with auth_id=1397
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When nouveau_connector_detect() can't read an EDID it clears the
connector's EDID, which resets display_info.bpc to 0.  A default is
only filled back in by nouveau_connector_detect_depth(), from
->get_modes(), so if the HPD worker's probe loses the EDID and
userspace commits a modeset before it next fetches the mode list,
nv50_outp_atomic_check() sets or.bpc to 0.

For DP, nouveau_dp_train() then computes a minimum link rate of 0, and
nv50_sor_dp_watermark_sst() computes 0 symbols per line and fires

  WARNING: drivers/gpu/drm/nouveau/dispnv50/disp.c:1678 at nv50_sor_dp_watermark_sst.isra.0+0x2ab/0x2c0 [nouveau]

This was seen on a GA102 right after "DDC responded, but no EDID for
DP-3" from the HPD worker, while replugging a DP monitor.

Fall back to 8 bpc when the connector doesn't provide a value, which is
nouveau_connector_detect_depth()'s own default for outputs that are
neither eDP nor LVDS, and do the same in nv50_msto_atomic_check(),
which takes or.bpc from the MST connector the same way.  Calling
nouveau_connector_detect_depth() from ->detect() instead isn't an
option, as for LVDS it depends on the native mode that ->get_modes()
sets up.

Fixes: ac2d9275f371 ("drm/nouveau/kms/nv50-: Store the bpc we're using in nv50_head_atom")
Cc: stable@vger.kernel.org
Link: https://gitlab.freedesktop.org/drm/nouveau/-/work_items/515
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: David R. Hedges <linuxdev844@thelittleman.net>
---
 drivers/gpu/drm/nouveau/dispnv50/disp.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/nouveau/dispnv50/disp.c b/drivers/gpu/drm/nouveau/dispnv50/disp.c
index 2c66e480b511..a265fd971c99 100644
--- a/drivers/gpu/drm/nouveau/dispnv50/disp.c
+++ b/drivers/gpu/drm/nouveau/dispnv50/disp.c
@@ -418,8 +418,11 @@ nv50_outp_atomic_check(struct drm_encoder *encoder,
 	if (ret)
 		return ret;
 
+	/* display_info.bpc is reset to 0 when a probe loses the EDID, and
+	 * isn't given a default again until ->get_modes() runs.
+	 */
 	if (crtc_state->mode_changed || crtc_state->connectors_changed)
-		asyh->or.bpc = connector->display_info.bpc;
+		asyh->or.bpc = connector->display_info.bpc ?: 8;
 
 	/* We might have to reduce the bpc */
 	nv50_outp_atomic_fix_depth(encoder, crtc_state);
@@ -989,7 +992,7 @@ nv50_msto_atomic_check(struct drm_encoder *encoder,
 	if (!state->duplicated) {
 		const int clock = crtc_state->adjusted_mode.clock;
 
-		asyh->or.bpc = connector->display_info.bpc;
+		asyh->or.bpc = connector->display_info.bpc ?: 8;
 		asyh->dp.pbn = drm_dp_calc_pbn_mode(clock, asyh->or.bpc * 3 << 4);
 	}
 

-- 
2.55.0

