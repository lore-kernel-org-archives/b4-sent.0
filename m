From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:48:37 +0000
Subject: [PATCH v2 04/11] drm/panfrost: Don't WARN when a GEM mapping
 cannot get its pages
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-panfrost-long-jobs-v2-4-a06830da3d99@gmail.com>
References: <20261112-panfrost-long-jobs-v2-0-a06830da3d99@gmail.com>
In-Reply-To: <20261112-panfrost-long-jobs-v2-0-a06830da3d99@gmail.com>
To: Boris Brezillon <boris.brezillon@collabora.com>, 
 Rob Herring <robh@kernel.org>, Steven Price <steven.price@arm.com>, 
 =?utf-8?q?Adri=C3=A1n_Larumbe?= <adrian.larumbe@collabora.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794473314; l=1604;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=zrP1tS5NT5+cDSeYI5XUvjSLeC58wAvwjUaRiUsqgLA=;
 b=4ybjvrDmdRHMugxl1r5Rh61Ogh91dSN/LMcS2BCoGQvy00af0ST/5486xFwsmzrsElqilb7o7
 J1VoVulXAQzBnByjAFgeUqeVYzMpR35JvEr58iCCyaKT6VM41u8qe/5
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

panfrost_mmu_map() gets the pages of a BO with
drm_gem_shmem_get_pages_sgt(), which fails with -ENOMEM when shmem
cannot allocate them, for instance when the caller's memory cgroup is at
its limit, or with -EINTR when the caller is being killed. Those are
ordinary failures that reach userspace as an error (Mesa reports
"DRM_IOCTL_PANFROST_CREATE_BO failed (err=12)"), not driver bugs, but
the WARN_ON() turns each of them into a kernel warning with a backtrace:

  WARNING: drivers/gpu/drm/panfrost/panfrost_mmu.c:478 at panfrost_mmu_map+0xcc

dEQP-GLES31.functional.draw_indirect.compute_interop.large.* run in a
600 MB memory cgroup on a 1 GB Mali-G31 board prints it five times.

Return the error without the warning. No pages are held at this point,
so there is nothing to undo.

Fixes: f3ba91228e8e ("drm/panfrost: Add initial panfrost driver")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/panfrost/panfrost_mmu.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/panfrost/panfrost_mmu.c b/drivers/gpu/drm/panfrost/panfrost_mmu.c
index eaf94d47d..971552c42 100644
--- a/drivers/gpu/drm/panfrost/panfrost_mmu.c
+++ b/drivers/gpu/drm/panfrost/panfrost_mmu.c
@@ -480,7 +480,7 @@ int panfrost_mmu_map(struct panfrost_gem_mapping *mapping)
 		prot |= IOMMU_NOEXEC;
 
 	sgt = drm_gem_shmem_get_pages_sgt(shmem);
-	if (WARN_ON(IS_ERR(sgt)))
+	if (IS_ERR(sgt))
 		return PTR_ERR(sgt);
 
 	ret = mmu_map_sg(pfdev, mapping->mmu, mapping->mmnode.start << PAGE_SHIFT,

-- 
2.55.0

