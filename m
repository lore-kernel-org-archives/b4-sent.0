From: Mingcong Bai <jeffbai@aosc.io>
Date: Wed, 26 Feb 2025 10:00:22 +0800
Subject: [PATCH 5/5] drm/xe/query: use PAGE_SIZE as the minimum page
 alignment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250226-xe-non-4k-fix-v1-5-80f23b5ee40e@aosc.io>
References: <20250226-xe-non-4k-fix-v1-0-80f23b5ee40e@aosc.io>
In-Reply-To: <20250226-xe-non-4k-fix-v1-0-80f23b5ee40e@aosc.io>
To: Lucas De Marchi <lucas.demarchi@intel.com>, 
 =?utf-8?q?Thomas_Hellstr=C3=B6m?= <thomas.hellstrom@linux.intel.com>, 
 Rodrigo Vivi <rodrigo.vivi@intel.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 =?utf-8?q?Jos=C3=A9_Roberto_de_Souza?= <jose.souza@intel.com>, 
 Francois Dugast <francois.dugast@intel.com>, 
 Matthew Brost <matthew.brost@intel.com>, 
 Alan Previn <alan.previn.teres.alexis@intel.com>, 
 Zhanjun Dong <zhanjun.dong@intel.com>, 
 Matt Roper <matthew.d.roper@intel.com>, 
 Mateusz Naklicki <mateusz.naklicki@intel.com>
Cc: Mauro Carvalho Chehab <mauro.chehab@linux.intel.com>, 
 =?utf-8?q?Zbigniew_Kempczy=C5=84ski?= <zbigniew.kempczynski@intel.com>, 
 intel-xe@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Kexy Biscuit <kexybiscuit@aosc.io>, 
 Shang Yatsen <429839446@qq.com>, Mingcong Bai <jeffbai@aosc.io>, 
 stable@vger.kernel.org, Haien Liang <27873200@qq.com>, 
 Shirong Liu <lsr1024@qq.com>, Haofeng Wu <s2600cw2@126.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740535218; l=2489;
 i=jeffbai@aosc.io; s=20250225; h=from:subject:message-id;
 bh=kdJ4lbdvf4bhnqSjO+QvoRJ988PIBJrpUHd4FzEvGso=;
 b=3R8diCFFhMKJlehfdNxnm+lVc0U8/QuWXTuFJtjkUklxv2W0a6BEa1EAGiD3JqlnihLtFHEIy
 CZPDU4Ib5uQCxeQzvSEP7qgt23Z1BNi2/uGSACuew5MiAADRW/OmL6l
X-Developer-Key: i=jeffbai@aosc.io; a=ed25519;
 pk=PShXLX1m130BHsde1t/EjBugyyOjSVdzV0dYuYejXYU=
X-Endpoint-Received: by B4 Relay for jeffbai@aosc.io/20250225 with auth_id=349
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As this component hooks into userspace API, it should be assumed that it
will play well with non-4K/64K pages.

Use `PAGE_SIZE' as the final reference for page alignment instead.

Cc: stable@vger.kernel.org
Fixes: dd08ebf6c352 ("drm/xe: Introduce a new DRM driver for Intel GPUs")
Fixes: 801989b08aff ("drm/xe/uapi: Make constant comments visible in kernel doc")
Tested-by: Mingcong Bai <jeffbai@aosc.io>
Tested-by: Haien Liang <27873200@qq.com>
Tested-by: Shirong Liu <lsr1024@qq.com>
Tested-by: Haofeng Wu <s2600cw2@126.com>
Link: https://github.com/FanFansfan/loongson-linux/commit/22c55ab3931c32410a077b3ddb6dca3f28223360
Co-developed-by: Shang Yatsen <429839446@qq.com>
Signed-off-by: Shang Yatsen <429839446@qq.com>
Signed-off-by: Mingcong Bai <jeffbai@aosc.io>
---
 drivers/gpu/drm/xe/xe_query.c | 2 +-
 include/uapi/drm/xe_drm.h     | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/xe/xe_query.c b/drivers/gpu/drm/xe/xe_query.c
index c059639613f7b548c168f808b7b7b354f1cf3c94..8a017c526942d1f2b401e8b9a4244e6083d7b1e5 100644
--- a/drivers/gpu/drm/xe/xe_query.c
+++ b/drivers/gpu/drm/xe/xe_query.c
@@ -336,7 +336,7 @@ static int query_config(struct xe_device *xe, struct drm_xe_device_query *query)
 		config->info[DRM_XE_QUERY_CONFIG_FLAGS] =
 			DRM_XE_QUERY_CONFIG_FLAG_HAS_VRAM;
 	config->info[DRM_XE_QUERY_CONFIG_MIN_ALIGNMENT] =
-		xe->info.vram_flags & XE_VRAM_FLAGS_NEED64K ? SZ_64K : SZ_4K;
+		xe->info.vram_flags & XE_VRAM_FLAGS_NEED64K ? SZ_64K : PAGE_SIZE;
 	config->info[DRM_XE_QUERY_CONFIG_VA_BITS] = xe->info.va_bits;
 	config->info[DRM_XE_QUERY_CONFIG_MAX_EXEC_QUEUE_PRIORITY] =
 		xe_exec_queue_device_get_max_priority(xe);
diff --git a/include/uapi/drm/xe_drm.h b/include/uapi/drm/xe_drm.h
index f62689ca861a4673b885629460c11d6f3bc6523d..db7cf904926ebd6789a29d620161ac051e59f13f 100644
--- a/include/uapi/drm/xe_drm.h
+++ b/include/uapi/drm/xe_drm.h
@@ -394,7 +394,7 @@ struct drm_xe_query_mem_regions {
  *    - %DRM_XE_QUERY_CONFIG_FLAG_HAS_VRAM - Flag is set if the device
  *      has usable VRAM
  *  - %DRM_XE_QUERY_CONFIG_MIN_ALIGNMENT - Minimal memory alignment
- *    required by this device, typically SZ_4K or SZ_64K
+ *    required by this device, typically PAGE_SIZE.
  *  - %DRM_XE_QUERY_CONFIG_VA_BITS - Maximum bits of a virtual address
  *  - %DRM_XE_QUERY_CONFIG_MAX_EXEC_QUEUE_PRIORITY - Value of the highest
  *    available exec queue priority

-- 
2.48.1

