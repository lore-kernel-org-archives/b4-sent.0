From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 25 Oct 2026 17:34:30 -0500
Subject: [PATCH v4 2/2] drm/tegra: Support YVU formats
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261025-tegra-drm-yvu420-v4-2-30b3bb0d0752@gmail.com>
References: <20261025-tegra-drm-yvu420-v4-0-30b3bb0d0752@gmail.com>
In-Reply-To: <20261025-tegra-drm-yvu420-v4-0-30b3bb0d0752@gmail.com>
To: Thierry Reding <thierry.reding@kernel.org>, 
 Mikko Perttunen <mperttunen@nvidia.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, Jonathan Hunter <jonathanh@nvidia.com>
Cc: dri-devel@lists.freedesktop.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792967672; l=2852;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=8hGc03SYXizHw33ULcwZEIrKQWKQjAVy5h5uRAdlKuo=;
 b=1D6RRONTaL2oH0hlIrVl+UBp4c9XG3985eezteFQ4tHkYjh2vAO8O+zne7rWV0vOR/nGd+92O
 OZmtRuge0pXDhOs68QBNrmG3SUErtE6s9OoSfiaNvR7UCSmW34tooOg
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

YVU420 is used by AOSP for video playback among other things. YVU422 and
YVU444 can be trivially supported in the same manner, so add them where
supported as well.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/gpu/drm/tegra/dc.c    |  7 +++++++
 drivers/gpu/drm/tegra/hub.c   |  1 +
 drivers/gpu/drm/tegra/plane.c | 24 ++++++++++++++++++++++++
 3 files changed, 32 insertions(+)

diff --git a/drivers/gpu/drm/tegra/dc.c b/drivers/gpu/drm/tegra/dc.c
index 39c2e920d76a6..be913f2609077 100644
--- a/drivers/gpu/drm/tegra/dc.c
+++ b/drivers/gpu/drm/tegra/dc.c
@@ -1282,6 +1282,8 @@ static const u32 tegra20_overlay_formats[] = {
 	DRM_FORMAT_YUYV,
 	DRM_FORMAT_YUV420,
 	DRM_FORMAT_YUV422,
+	DRM_FORMAT_YVU420,
+	DRM_FORMAT_YVU422,
 };
 
 static const u32 tegra114_overlay_formats[] = {
@@ -1309,6 +1311,8 @@ static const u32 tegra114_overlay_formats[] = {
 	DRM_FORMAT_YUYV,
 	DRM_FORMAT_YUV420,
 	DRM_FORMAT_YUV422,
+	DRM_FORMAT_YVU420,
+	DRM_FORMAT_YVU422,
 	/* semi-planar formats */
 	DRM_FORMAT_NV12,
 	DRM_FORMAT_NV21,
@@ -1349,6 +1353,9 @@ static const u32 tegra124_overlay_formats[] = {
 	DRM_FORMAT_YUV420, /* YU12 */
 	DRM_FORMAT_YUV422, /* YU16 */
 	DRM_FORMAT_YUV444, /* YU24 */
+	DRM_FORMAT_YVU420, /* YV12 */
+	DRM_FORMAT_YVU422, /* YV16 */
+	DRM_FORMAT_YVU444, /* YV24 */
 	/* semi-planar formats */
 	DRM_FORMAT_NV12,
 	DRM_FORMAT_NV21,
diff --git a/drivers/gpu/drm/tegra/hub.c b/drivers/gpu/drm/tegra/hub.c
index 5a86f8260f136..46756c749e674 100644
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
index 757bc552809fe..79ef5fc1b3678 100644
--- a/drivers/gpu/drm/tegra/plane.c
+++ b/drivers/gpu/drm/tegra/plane.c
@@ -433,14 +433,38 @@ int tegra_plane_format(u32 fourcc, u32 *format, u32 *swap, bool *swap_uv)
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
 
+	case DRM_FORMAT_YVU422:
+		if (!swap_uv)
+			return -EINVAL;
+
+		*format = WIN_COLOR_DEPTH_YCbCr422P;
+		*swap_uv = true;
+		break;
+
 	case DRM_FORMAT_YUV444:
 		*format = WIN_COLOR_DEPTH_YCbCr444P;
 		break;
 
+	case DRM_FORMAT_YVU444:
+		if (!swap_uv)
+			return -EINVAL;
+
+		*format = WIN_COLOR_DEPTH_YCbCr444P;
+		*swap_uv = true;
+		break;
+
 	case DRM_FORMAT_NV12:
 		*format = WIN_COLOR_DEPTH_YCbCr420SP;
 		break;

-- 
2.56.0

