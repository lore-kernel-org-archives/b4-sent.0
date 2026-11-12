From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:48:36 +0000
Subject: [PATCH v2 03/11] drm/panfrost: Don't take a reference on a mapping
 that is being freed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-panfrost-long-jobs-v2-3-a06830da3d99@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794473314; l=2240;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=rqdqg/OAAoy83+50ChQ3aQoU7NkR4pnj4DQAb5ccFxY=;
 b=Oyzab45fRaSg0gCSQpPedyAhPZ8VSqJ25maLTpFnmx5Sm1cIpV2KK+zz9i9BzB0yVnH1IDLF8
 yc4H6gxvNvOAAyev8HEdZIcS8xMq+JnKj0NcBoeE8duLrwihorKerVC
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

addr_to_mapping() looks up the mapping that contains a faulting GPU
address in the address space's drm_mm and takes a reference on it with
kref_get(). But panfrost_gem_mapping_put() drops the last reference
before panfrost_gem_mapping_release() -> panfrost_gem_teardown_mapping()
unmaps the BO and removes its node from the drm_mm under mm_lock, so the
lookup can find a mapping whose refcount is already zero. kref_get()
then revives it (refcount_t warns about the addition on zero), the
release goes on and frees the mapping and drops the BO, and the fault
handler maps pages into a BO that is being freed.

This takes a GPU fault on a heap BO's address while the last handle and
the last job reference to that BO go away. Jobs hold a reference on the
mappings of the BOs they list, so it takes a job that uses a heap BO it
does not list; userspace on the render node can submit that.

Use kref_get_unless_zero() and treat a mapping that is being freed as
absent: the fault is then reported as unhandled.

Found by code review: the same pattern in new code of this series was
reported by Sashiko. Not reproduced.

Fixes: bdefca2d8dc0 ("drm/panfrost: Add the panfrost_gem_mapping concept")
Cc: stable@vger.kernel.org
Link: https://lore.kernel.org/all/sashiko-outbox-206570@kernel.org/
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/panfrost/panfrost_mmu.c | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/panfrost/panfrost_mmu.c b/drivers/gpu/drm/panfrost/panfrost_mmu.c
index faa62643c..eaf94d47d 100644
--- a/drivers/gpu/drm/panfrost/panfrost_mmu.c
+++ b/drivers/gpu/drm/panfrost/panfrost_mmu.c
@@ -576,7 +576,13 @@ addr_to_mapping(struct panfrost_device *pfdev, int as, u64 addr)
 		    offset < (node->start + node->size)) {
 			mapping = drm_mm_node_to_panfrost_mapping(node);
 
-			kref_get(&mapping->refcount);
+			/* The last reference to a mapping is dropped before
+			 * panfrost_gem_teardown_mapping() takes its node out
+			 * of the address space: don't revive one that is
+			 * being freed.
+			 */
+			if (!kref_get_unless_zero(&mapping->refcount))
+				mapping = NULL;
 			break;
 		}
 	}

-- 
2.55.0

