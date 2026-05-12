From: Chia-I Wu <olvaffe@gmail.com>
Date: Tue, 12 May 2026 10:36:28 -0700
Subject: [PATCH] drm/panthor: set __GFP_SKIP_KASAN
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260512-panthor-kasan-v1-1-d8d3e275d71b@gmail.com>
X-B4-Tracking: v=1; b=H4sIABtlA2oC/yXMzQ5FMBBA4VeRWWvS1l94FbEYDIakpIPcRLz7L
 Zbf4pwLhDyTQBVd4Olk4dUFmDiCbkI3kuI+GKy2uc6MVRu6fVq9WlDQKaPTorBJ2WJvIDSbp4F
 /769uPsvRztTtzwTu+w/4oywpcQAAAA==
X-Change-ID: 20260512-panthor-kasan-10477239bad1
To: Boris Brezillon <boris.brezillon@collabora.com>, 
 Steven Price <steven.price@arm.com>, Liviu Dudau <liviu.dudau@arm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Rob Clark <robin.clark@oss.qualcomm.com>, Chia-I Wu <olvaffe@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2047; i=olvaffe@gmail.com;
 h=from:subject:message-id; bh=ASiB3HunlPGvoW9uuO3lUbsW+ch1/3mXojcsoRe+zik=;
 b=owGbwMvMwCV2uuv6dHcvAWnG02pJDFnMqbL1Pebrfpx8uyloobn8sZj7fL0r47uNtzUZW+YnM
 avPmcXZUcrCIMbFICumyLJT6fPXwIzCy3eEG9fBzGFlAhnCwMUpABORXMnwP+LmBr44/VUCwtKf
 bFe/WZOrLOxsoVPTsKP6zuc9ZzJ+ZzH8LyqyeB+omLZcm8Xpbf60k86/o9xUF04LeK/tpSf8/Ec
 sNwA=
X-Developer-Key: i=olvaffe@gmail.com; a=openpgp;
 fpr=8C8F791802BBB330399230F27CB6CD58BE1B6831
X-Endpoint-Received: by B4 Relay for olvaffe@gmail.com/default with auth_id=776
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Pages that can be swapped out should be allocated with __GFP_SKIP_KASAN.
Rather than setting the flag directly, replace GFP_HIGHUSER by
(GFP_HIGHUSER_MOVABLE & ~__GFP_MOVABLE) instead, which should match the
preceding comment better.

On a CONFIG_KASAN_HW_TAGS=y system, without __GFP_SKIP_KASAN, the page
allocator assigns a valid tag to both the kernel mapping and MTE,
instead of assigning the match-all KASAN_TAG_KERNEL tag to the kernel
mapping. If userspace also maps the page with PROT_MTE and modifies the
MTE tag, accessing the page via the kernel mapping results in KASAN
invalid-access, such as

  BUG: KASAN: invalid-access in swap_writepage+0xb0/0x21c
  Read at addr f5ffff81aa71dff8 by task WM.task-4/6956
  Pointer tag: [f5], memory tag: [f9]

While userspace cannot map drm gem objects with PROT_MTE, the problem is
shmem_swapin_cluster. When it swaps in a cluster of pages using our gfp
flags, some of the pages might belong to other mappings that have
PROT_MTE.

Signed-off-by: Chia-I Wu <olvaffe@gmail.com>
---
The latest snapdragons appear to have MTE support. drm/msm might need
the same treatment.
---
 drivers/gpu/drm/panthor/panthor_gem.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/panthor/panthor_gem.c b/drivers/gpu/drm/panthor/panthor_gem.c
index 13295d7a593df..08c03aa0db2f7 100644
--- a/drivers/gpu/drm/panthor/panthor_gem.c
+++ b/drivers/gpu/drm/panthor/panthor_gem.c
@@ -1013,7 +1013,8 @@ panthor_gem_create(struct drm_device *dev, size_t size, uint32_t flags,
 	 * going to pin these pages.
 	 */
 	mapping_set_gfp_mask(bo->base.filp->f_mapping,
-			     GFP_HIGHUSER | __GFP_RETRY_MAYFAIL | __GFP_NOWARN);
+			     (GFP_HIGHUSER_MOVABLE & ~__GFP_MOVABLE) |
+				     __GFP_RETRY_MAYFAIL | __GFP_NOWARN);
 
 	ret = drm_gem_create_mmap_offset(&bo->base);
 	if (ret)

---
base-commit: 6101f78b684895d5860a96322e607e0f46f433ad
change-id: 20260512-panthor-kasan-10477239bad1

Best regards,
--  
Chia-I Wu <olvaffe@gmail.com>

