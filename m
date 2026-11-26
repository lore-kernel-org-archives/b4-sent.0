From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 26 Nov 2026 09:37:00 +0000
Subject: [PATCH v4 17/17] drm/panfrost: Name the BOs around an unhandled
 page fault
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-panfrost-long-jobs-v4-17-23579629ceca@gmail.com>
References: <20261126-panfrost-long-jobs-v4-0-23579629ceca@gmail.com>
In-Reply-To: <20261126-panfrost-long-jobs-v4-0-23579629ceca@gmail.com>
To: Boris Brezillon <boris.brezillon@collabora.com>, 
 Rob Herring <robh@kernel.org>, Steven Price <steven.price@arm.com>, 
 =?utf-8?q?Adri=C3=A1n_Larumbe?= <adrian.larumbe@collabora.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795685806; l=3787;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=5eVur+mtkqF3KeuduvBSAt8Mmx9XxQ3xEdEtH3eF7lE=;
 b=6DgG0L6amlfQCNH71sbOl9d0AKUzh0BVys1PGlJVDOixRBgplaFV6tjDYiJblGrGFllDlxT86
 JPnWRYDVZiPCdQrhAB5JUj2M/WNEWAEHvPrL0kCvK94D/7Bhme7j7Fm
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

An unhandled GPU page fault reports only the VA, which does not tell
an overrun of a BO from a stale or garbage pointer. Also print the BO
that contains the address, or else its nearest neighbours: VA range,
size, distance, heap/noexec and the userspace label. For an OpenCL
image read on a Mali-G31 it showed the texture unit reading past the
end of a 96-bit-per-texel texture. Heap growth faults are not
affected.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/panfrost/panfrost_mmu.c | 76 +++++++++++++++++++++++++++++++++
 1 file changed, 76 insertions(+)

diff --git a/drivers/gpu/drm/panfrost/panfrost_mmu.c b/drivers/gpu/drm/panfrost/panfrost_mmu.c
index 92a4d2963..0f81fee10 100644
--- a/drivers/gpu/drm/panfrost/panfrost_mmu.c
+++ b/drivers/gpu/drm/panfrost/panfrost_mmu.c
@@ -590,6 +590,81 @@ addr_to_mapping(struct panfrost_device *pfdev, int as, u64 addr)
 	return mapping;
 }
 
+static void panfrost_mmu_print_fault_bo(struct panfrost_device *pfdev,
+					struct panfrost_gem_mapping *m,
+					u64 addr, const char *where)
+{
+	struct panfrost_gem_object *bo = m->obj;
+	u64 start = m->mmnode.start << PAGE_SHIFT;
+	u64 end = (m->mmnode.start + m->mmnode.size) << PAGE_SHIFT;
+	u64 dist = addr < start ? start - addr : addr >= end ? addr - end : addr - start;
+
+	mutex_lock(&bo->label.lock);
+	dev_err(pfdev->base.dev,
+		"fault bo: %s: VA [0x%llx-0x%llx) size 0x%zx, fault at %s0x%llx%s%s, label \"%s\"\n",
+		where, start, end, bo->base.base.size,
+		addr < start ? "-" : addr >= end ? "end+" : "start+", dist,
+		bo->is_heap ? ", heap" : "", bo->noexec ? ", noexec" : "",
+		bo->label.str ? bo->label.str : "");
+	mutex_unlock(&bo->label.lock);
+}
+
+static void panfrost_mmu_report_fault_bos(struct panfrost_device *pfdev,
+					  int as, u64 addr)
+{
+	struct panfrost_gem_mapping *below = NULL, *above = NULL;
+	u64 offset = addr >> PAGE_SHIFT;
+	struct drm_mm_node *node;
+	struct panfrost_mmu *mmu;
+	bool inside = false;
+
+	spin_lock(&pfdev->as_lock);
+	list_for_each_entry(mmu, &pfdev->as_lru_list, list) {
+		if (as == mmu->as)
+			goto found_mmu;
+	}
+	spin_unlock(&pfdev->as_lock);
+	dev_err(pfdev->base.dev, "fault bo: no context holds AS%d\n", as);
+	return;
+
+found_mmu:
+	spin_lock(&mmu->mm_lock);
+	drm_mm_for_each_node(node, &mmu->mm) {
+		struct panfrost_gem_mapping *m = drm_mm_node_to_panfrost_mapping(node);
+
+		if (!kref_read(&m->refcount))
+			continue;
+		if (node->start > offset) {
+			above = m;
+			break;
+		}
+		below = m;
+	}
+	if (below) {
+		inside = offset < below->mmnode.start + below->mmnode.size;
+		if (inside)
+			above = NULL;
+		if (!kref_get_unless_zero(&below->refcount))
+			below = NULL;
+	}
+	if (above && !kref_get_unless_zero(&above->refcount))
+		above = NULL;
+	spin_unlock(&mmu->mm_lock);
+	spin_unlock(&pfdev->as_lock);
+
+	if (!below && !above)
+		dev_err(pfdev->base.dev, "fault bo: AS%d has no BO\n", as);
+	if (below) {
+		panfrost_mmu_print_fault_bo(pfdev, below, addr,
+					    inside ? "inside" : "below");
+		panfrost_gem_mapping_put(below);
+	}
+	if (above) {
+		panfrost_mmu_print_fault_bo(pfdev, above, addr, "above");
+		panfrost_gem_mapping_put(above);
+	}
+}
+
 #define NUM_FAULT_PAGES (SZ_2M / PAGE_SIZE)
 
 /* [start, end) is whole folios: it can reach past the 2 MB chunk. */
@@ -964,6 +1039,7 @@ static irqreturn_t panfrost_mmu_irq_handler_thread(int irq, void *data)
 				exception_type, panfrost_exception_name(exception_type),
 				access_type, access_type_name(pfdev, fault_status),
 				source_id);
+			panfrost_mmu_report_fault_bos(pfdev, as, addr);
 
 			spin_lock(&pfdev->as_lock);
 			/* Ignore MMU interrupts on this AS until it's been

-- 
2.55.0

