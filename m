From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 20 Oct 2026 03:10:07 -0500
Subject: [PATCH v3 1/2] drm/tegra: Support swapping chroma planes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-tegra-drm-yvu420-v3-1-7f19a834ba98@gmail.com>
References: <20261020-tegra-drm-yvu420-v3-0-7f19a834ba98@gmail.com>
In-Reply-To: <20261020-tegra-drm-yvu420-v3-0-7f19a834ba98@gmail.com>
To: Thierry Reding <thierry.reding@kernel.org>, 
 Mikko Perttunen <mperttunen@nvidia.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, Jonathan Hunter <jonathanh@nvidia.com>
Cc: dri-devel@lists.freedesktop.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792483811; l=4205;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=aseBG4+nsmwlogE8nfji0wIaNX+2LJ0Usy3RCoj2p3w=;
 b=+kv2t7CxKtklxPPslCL2P6ENlUlcpoNJU1sOtYT9/pKSItwbcFMIr4PQZZKw89mJyLBEtvNQY
 b9sZzXIBXywBqRuurN9xoOTttST3H9Z1wHYnMoRaf3WIw5b+dtGWB5r
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Tegra display controller supports some yuv types, but not their
chroma swapped variants. For example, yuv420 is supported but yvu420 is
not. For tegradc, this can be efficiently worked around by just passing
the hardware said chroma planes backwards. For nvdisplay, there is a
window group flag to do the swap in hardware. Add a flag to the plane
state struct and handling to both tegradc and nvdisplay paths.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/gpu/drm/tegra/dc.c    | 6 +++++-
 drivers/gpu/drm/tegra/hub.c   | 7 +++++--
 drivers/gpu/drm/tegra/plane.c | 5 ++++-
 drivers/gpu/drm/tegra/plane.h | 3 ++-
 4 files changed, 16 insertions(+), 5 deletions(-)

diff --git a/drivers/gpu/drm/tegra/dc.c b/drivers/gpu/drm/tegra/dc.c
index b0bfa946e6979..39c2e920d76a6 100644
--- a/drivers/gpu/drm/tegra/dc.c
+++ b/drivers/gpu/drm/tegra/dc.c
@@ -740,7 +740,8 @@ static int tegra_plane_atomic_check(struct drm_plane *plane,
 
 	err = tegra_plane_format(new_plane_state->fb->format->format,
 				 &plane_state->format,
-				 &plane_state->swap);
+				 &plane_state->swap,
+				 &plane_state->swap_uv);
 	if (err < 0)
 		return err;
 
@@ -872,6 +873,9 @@ static void tegra_plane_atomic_update(struct drm_plane *plane,
 			window.stride[i] = fb->pitches[i];
 	}
 
+	if (tegra_plane_state->swap_uv)
+		swap(window.base[1], window.base[2]);
+
 	tegra_dc_setup_window(p, &window);
 }
 
diff --git a/drivers/gpu/drm/tegra/hub.c b/drivers/gpu/drm/tegra/hub.c
index 448f49f3a7d7e..5a86f8260f136 100644
--- a/drivers/gpu/drm/tegra/hub.c
+++ b/drivers/gpu/drm/tegra/hub.c
@@ -440,7 +440,8 @@ static int tegra_shared_plane_atomic_check(struct drm_plane *plane,
 
 	err = tegra_plane_format(new_plane_state->fb->format->format,
 				 &plane_state->format,
-				 &plane_state->swap);
+				 &plane_state->swap,
+				 &plane_state->swap_uv);
 	if (err < 0)
 		return err;
 
@@ -642,7 +643,9 @@ static void tegra_shared_plane_atomic_update(struct drm_plane *plane,
 	base |= addr_flag;
 
 	tegra_plane_writel(p, tegra_plane_state->format, DC_WIN_COLOR_DEPTH);
-	tegra_plane_writel(p, 0, DC_WIN_PRECOMP_WGRP_PARAMS);
+
+	value = tegra_plane_state->swap_uv ? SWAP_UV : 0;
+	tegra_plane_writel(p, value, DC_WIN_PRECOMP_WGRP_PARAMS);
 
 	value = V_POSITION(new_state->crtc_y) |
 		H_POSITION(new_state->crtc_x);
diff --git a/drivers/gpu/drm/tegra/plane.c b/drivers/gpu/drm/tegra/plane.c
index 2148b0c59815c..757bc552809fe 100644
--- a/drivers/gpu/drm/tegra/plane.c
+++ b/drivers/gpu/drm/tegra/plane.c
@@ -59,6 +59,7 @@ tegra_plane_atomic_duplicate_state(struct drm_plane *plane)
 	copy->tiling = state->tiling;
 	copy->format = state->format;
 	copy->swap = state->swap;
+	copy->swap_uv = state->swap_uv;
 	copy->reflect_x = state->reflect_x;
 	copy->reflect_y = state->reflect_y;
 	copy->opaque = state->opaque;
@@ -319,11 +320,13 @@ int tegra_plane_state_add(struct tegra_plane *plane,
 	return 0;
 }
 
-int tegra_plane_format(u32 fourcc, u32 *format, u32 *swap)
+int tegra_plane_format(u32 fourcc, u32 *format, u32 *swap, bool *swap_uv)
 {
 	/* assume no swapping of fetched data */
 	if (swap)
 		*swap = BYTE_SWAP_NOSWAP;
+	if (swap_uv)
+		*swap_uv = false;
 
 	switch (fourcc) {
 	case DRM_FORMAT_ARGB4444:
diff --git a/drivers/gpu/drm/tegra/plane.h b/drivers/gpu/drm/tegra/plane.h
index e33a581e6490e..dba5f1b254e98 100644
--- a/drivers/gpu/drm/tegra/plane.h
+++ b/drivers/gpu/drm/tegra/plane.h
@@ -49,6 +49,7 @@ struct tegra_plane_state {
 	struct tegra_bo_tiling tiling;
 	u32 format;
 	u32 swap;
+	bool swap_uv;
 
 	bool reflect_x;
 	bool reflect_y;
@@ -88,7 +89,7 @@ void tegra_plane_cleanup_fb(struct drm_plane *plane,
 int tegra_plane_state_add(struct tegra_plane *plane,
 			  struct drm_plane_state *state);
 
-int tegra_plane_format(u32 fourcc, u32 *format, u32 *swap);
+int tegra_plane_format(u32 fourcc, u32 *format, u32 *swap, bool *swap_uv);
 bool tegra_plane_format_is_indexed(unsigned int format);
 bool tegra_plane_format_is_yuv(unsigned int format, unsigned int *planes, unsigned int *bpc);
 int tegra_plane_setup_legacy_state(struct tegra_plane *tegra,

-- 
2.54.0

