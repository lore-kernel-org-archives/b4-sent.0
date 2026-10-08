From: Aaron Kling <webgeek1234@gmail.com>
Date: Thu, 08 Oct 2026 15:57:21 -0500
Subject: [PATCH 1/2] drm/tegra: Support swapping chroma planes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-tegra-drm-yvu420-v1-1-dc1c443c00f3@gmail.com>
References: <20261008-tegra-drm-yvu420-v1-0-dc1c443c00f3@gmail.com>
In-Reply-To: <20261008-tegra-drm-yvu420-v1-0-dc1c443c00f3@gmail.com>
To: Thierry Reding <thierry.reding@kernel.org>, 
 Mikko Perttunen <mperttunen@nvidia.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, Jonathan Hunter <jonathanh@nvidia.com>
Cc: dri-devel@lists.freedesktop.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791493050; l=5791;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=BopnCTkaY23nVxWNbXTxwUZtTwBr62+4Cr0uweuArTo=;
 b=uqI0thF7Auwk1snaUbWeJJJnToOLdXeANrgetciUw3GTiLwg8MW6HrV6PDVdQAm2j46pIBeFb
 KcsmO2IPz6IAsYhh0Oz3KSkI8g6fchIKkHdVoqLJYGpg5n0TlzfuALl
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Tegra display controller supports some yuv types, but not their
chroma swapped variants. For example, yuv420 is supported but yvu420 is
not. This can be efficiently worked around by just passing the hardware
said chroma planes backwards. Add a flag to the plane state struct and
handling to both tegradc and nvdisplay paths.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/gpu/drm/tegra/dc.c    | 17 ++++++++++++-----
 drivers/gpu/drm/tegra/hub.c   | 14 +++++++++-----
 drivers/gpu/drm/tegra/plane.c |  4 +++-
 drivers/gpu/drm/tegra/plane.h |  3 ++-
 4 files changed, 26 insertions(+), 12 deletions(-)

diff --git a/drivers/gpu/drm/tegra/dc.c b/drivers/gpu/drm/tegra/dc.c
index b0bfa946e6979..76d3841a17b8b 100644
--- a/drivers/gpu/drm/tegra/dc.c
+++ b/drivers/gpu/drm/tegra/dc.c
@@ -444,7 +444,8 @@ tegra_plane_use_vertical_filtering(struct tegra_plane *plane,
 }
 
 static void tegra_dc_setup_window(struct tegra_plane *plane,
-				  const struct tegra_dc_window *window)
+				  const struct tegra_dc_window *window,
+				  struct tegra_plane_state *tegra_plane_state)
 {
 	unsigned h_offset, v_offset, h_size, v_size, h_dda, v_dda, bpp;
 	struct tegra_dc *dc = plane->dc;
@@ -510,10 +511,13 @@ static void tegra_dc_setup_window(struct tegra_plane *plane,
 	tegra_plane_writel(plane, window->base[0], DC_WINBUF_START_ADDR);
 
 	if (yuv && planes > 1) {
-		tegra_plane_writel(plane, window->base[1], DC_WINBUF_START_ADDR_U);
+		uint8_t u = tegra_plane_state->swap_uv ? 2 : 1;
+		uint8_t v = tegra_plane_state->swap_uv ? 1 : 2;
+
+		tegra_plane_writel(plane, window->base[u], DC_WINBUF_START_ADDR_U);
 
 		if (planes > 2)
-			tegra_plane_writel(plane, window->base[2], DC_WINBUF_START_ADDR_V);
+			tegra_plane_writel(plane, window->base[v], DC_WINBUF_START_ADDR_V);
 
 		value = window->stride[1] << 16 | window->stride[0];
 		tegra_plane_writel(plane, value, DC_WIN_LINE_STRIDE);
@@ -740,7 +744,8 @@ static int tegra_plane_atomic_check(struct drm_plane *plane,
 
 	err = tegra_plane_format(new_plane_state->fb->format->format,
 				 &plane_state->format,
-				 &plane_state->swap);
+				 &plane_state->swap,
+				 &plane_state->swap_uv);
 	if (err < 0)
 		return err;
 
@@ -871,8 +876,10 @@ static void tegra_plane_atomic_update(struct drm_plane *plane,
 		if (i < 2)
 			window.stride[i] = fb->pitches[i];
 	}
+	if (tegra_plane_state->swap_uv)
+		window.stride[1] = fb->pitches[2];
 
-	tegra_dc_setup_window(p, &window);
+	tegra_dc_setup_window(p, &window, tegra_plane_state);
 }
 
 static const struct drm_plane_helper_funcs tegra_plane_helper_funcs = {
diff --git a/drivers/gpu/drm/tegra/hub.c b/drivers/gpu/drm/tegra/hub.c
index 448f49f3a7d7e..6427155ac4fdf 100644
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
 
@@ -664,24 +665,27 @@ static void tegra_shared_plane_atomic_update(struct drm_plane *plane,
 	tegra_plane_writel(p, value, DC_WIN_PLANAR_STORAGE);
 
 	if (yuv && planes > 1) {
-		base = tegra_plane_state->iova[1] + fb->offsets[1];
+		uint8_t u = tegra_plane_state->swap_uv ? 2 : 1;
+		uint8_t v = tegra_plane_state->swap_uv ? 1 : 2;
+
+		base = tegra_plane_state->iova[u] + fb->offsets[u];
 		base |= addr_flag;
 
 		tegra_plane_writel(p, upper_32_bits(base), DC_WINBUF_START_ADDR_HI_U);
 		tegra_plane_writel(p, lower_32_bits(base), DC_WINBUF_START_ADDR_U);
 
 		if (planes > 2) {
-			base = tegra_plane_state->iova[2] + fb->offsets[2];
+			base = tegra_plane_state->iova[v] + fb->offsets[v];
 			base |= addr_flag;
 
 			tegra_plane_writel(p, upper_32_bits(base), DC_WINBUF_START_ADDR_HI_V);
 			tegra_plane_writel(p, lower_32_bits(base), DC_WINBUF_START_ADDR_V);
 		}
 
-		value = PITCH_U(fb->pitches[1]);
+		value = PITCH_U(fb->pitches[u]);
 
 		if (planes > 2)
-			value |= PITCH_V(fb->pitches[2]);
+			value |= PITCH_V(fb->pitches[v]);
 
 		tegra_plane_writel(p, value, DC_WIN_PLANAR_STORAGE_UV);
 	} else {
diff --git a/drivers/gpu/drm/tegra/plane.c b/drivers/gpu/drm/tegra/plane.c
index 2148b0c59815c..f4feec62ac023 100644
--- a/drivers/gpu/drm/tegra/plane.c
+++ b/drivers/gpu/drm/tegra/plane.c
@@ -319,11 +319,13 @@ int tegra_plane_state_add(struct tegra_plane *plane,
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

