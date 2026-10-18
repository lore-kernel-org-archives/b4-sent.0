From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 18 Oct 2026 17:03:47 -0500
Subject: [PATCH v2 2/2] drm/tegra: Support YVU420
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261018-tegra-drm-yvu420-v2-2-512889103ab4@gmail.com>
References: <20261018-tegra-drm-yvu420-v2-0-512889103ab4@gmail.com>
In-Reply-To: <20261018-tegra-drm-yvu420-v2-0-512889103ab4@gmail.com>
To: Thierry Reding <thierry.reding@kernel.org>, 
 Mikko Perttunen <mperttunen@nvidia.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, Jonathan Hunter <jonathanh@nvidia.com>
Cc: dri-devel@lists.freedesktop.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792361027; l=2166;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=zCXQRgMgGrE/4Z64BHhTFEWRbQko1sGdhPQ7CQ9cxNY=;
 b=9/d6cCKyKcBy1HzraYGCfzSBU+a/AboZeVFNdP9190xrnLIVlklda/Eaif4IjIie/Ny8L8erO
 RKLHg4mM3HqBR6Cxa420WDz6/i6si7J1Mkzh271+J3SHVegzL+NX6FS
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This format is used by AOSP for video playback among other things.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/gpu/drm/tegra/dc.c    | 3 +++
 drivers/gpu/drm/tegra/hub.c   | 1 +
 drivers/gpu/drm/tegra/plane.c | 8 ++++++++
 3 files changed, 12 insertions(+)

diff --git a/drivers/gpu/drm/tegra/dc.c b/drivers/gpu/drm/tegra/dc.c
index 39c2e920d76a6..61e155ecbfcb7 100644
--- a/drivers/gpu/drm/tegra/dc.c
+++ b/drivers/gpu/drm/tegra/dc.c
@@ -1282,6 +1282,7 @@ static const u32 tegra20_overlay_formats[] = {
 	DRM_FORMAT_YUYV,
 	DRM_FORMAT_YUV420,
 	DRM_FORMAT_YUV422,
+	DRM_FORMAT_YVU420,
 };
 
 static const u32 tegra114_overlay_formats[] = {
@@ -1309,6 +1310,7 @@ static const u32 tegra114_overlay_formats[] = {
 	DRM_FORMAT_YUYV,
 	DRM_FORMAT_YUV420,
 	DRM_FORMAT_YUV422,
+	DRM_FORMAT_YVU420,
 	/* semi-planar formats */
 	DRM_FORMAT_NV12,
 	DRM_FORMAT_NV21,
@@ -1349,6 +1351,7 @@ static const u32 tegra124_overlay_formats[] = {
 	DRM_FORMAT_YUV420, /* YU12 */
 	DRM_FORMAT_YUV422, /* YU16 */
 	DRM_FORMAT_YUV444, /* YU24 */
+	DRM_FORMAT_YVU420, /* YV12 */
 	/* semi-planar formats */
 	DRM_FORMAT_NV12,
 	DRM_FORMAT_NV21,
diff --git a/drivers/gpu/drm/tegra/hub.c b/drivers/gpu/drm/tegra/hub.c
index 6427155ac4fdf..f176badfd922b 100644
--- a/drivers/gpu/drm/tegra/hub.c
+++ b/drivers/gpu/drm/tegra/hub.c
@@ -51,6 +51,7 @@ static const u32 tegra_shared_plane_formats[] = {
 	DRM_FORMAT_YUYV,
 	DRM_FORMAT_YUV420,
 	DRM_FORMAT_YUV422,
+	DRM_FORMAT_YVU420,
 };
 
 static const u64 tegra_shared_plane_modifiers[] = {
diff --git a/drivers/gpu/drm/tegra/plane.c b/drivers/gpu/drm/tegra/plane.c
index 757bc552809fe..0771a6cce8984 100644
--- a/drivers/gpu/drm/tegra/plane.c
+++ b/drivers/gpu/drm/tegra/plane.c
@@ -433,6 +433,14 @@ int tegra_plane_format(u32 fourcc, u32 *format, u32 *swap, bool *swap_uv)
 		*format = WIN_COLOR_DEPTH_YCbCr420P;
 		break;
 
+	case DRM_FORMAT_YVU420:
+		if (!swap_uv)
+			return -EINVAL;
+
+		*format = WIN_COLOR_DEPTH_YCbCr420P;
+		*swap_uv = true;
+		break;
+
 	case DRM_FORMAT_YUV422:
 		*format = WIN_COLOR_DEPTH_YCbCr422P;
 		break;

-- 
2.54.0

