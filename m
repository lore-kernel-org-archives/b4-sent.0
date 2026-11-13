From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 09:02:55 +0000
Subject: [PATCH v3 03/14] drm/panfrost: Don't take a reference on a mapping
 that is being freed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-panfrost-long-jobs-v3-3-80ae78d38f6e@gmail.com>
References: <20261113-panfrost-long-jobs-v3-0-80ae78d38f6e@gmail.com>
In-Reply-To: <20261113-panfrost-long-jobs-v3-0-80ae78d38f6e@gmail.com>
To: Boris Brezillon <boris.brezillon@collabora.com>, 
 Rob Herring <robh@kernel.org>, Steven Price <steven.price@arm.com>, 
 =?utf-8?q?Adri=C3=A1n_Larumbe?= <adrian.larumbe@collabora.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794560572; l=1825;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=b5WA5vi0EwiXvHHxwNKezB3PYG2ZPzZFSsrErt1HQZU=;
 b=Sv88zJ5LVAd7XESsIuxNbFNKPf99SGx8nbIdEiVXtPB7UUnjLpZDVe8CWY7w0F3p60cbiXZFJ
 UtZqtUDnLydAl0wui9acx8wCuCnzP+kRZ20YNQgmksEB42o6LCJLUH3
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

addr_to_mapping() takes a reference on the mapping it finds in the
address space's drm_mm with kref_get(). But the last reference is
dropped before panfrost_gem_teardown_mapping() removes the node from the
drm_mm under mm_lock, so the lookup can find a mapping whose refcount is
zero. kref_get() revives it, the release still frees it and drops the
BO, and the fault handler maps pages into a BO that is being freed.

This takes a GPU fault on a heap BO while its last handle and last job
reference go away, so a job that uses a heap BO it does not list;
userspace on the render node can submit that.

Use kref_get_unless_zero(); the fault is then reported as unhandled.

Found by code review, after Sashiko reported the same pattern in new
code of this series. Not reproduced.

Fixes: bdefca2d8dc0 ("drm/panfrost: Add the panfrost_gem_mapping concept")
Cc: stable@vger.kernel.org
Link: https://lore.kernel.org/all/sashiko-outbox-206570@kernel.org/
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/panfrost/panfrost_mmu.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/panfrost/panfrost_mmu.c b/drivers/gpu/drm/panfrost/panfrost_mmu.c
index faa62643c..d0c6b6635 100644
--- a/drivers/gpu/drm/panfrost/panfrost_mmu.c
+++ b/drivers/gpu/drm/panfrost/panfrost_mmu.c
@@ -576,7 +576,11 @@ addr_to_mapping(struct panfrost_device *pfdev, int as, u64 addr)
 		    offset < (node->start + node->size)) {
 			mapping = drm_mm_node_to_panfrost_mapping(node);
 
-			kref_get(&mapping->refcount);
+			/* The node stays in the mm after the last reference is
+			 * dropped: don't revive a mapping that is being freed.
+			 */
+			if (!kref_get_unless_zero(&mapping->refcount))
+				mapping = NULL;
 			break;
 		}
 	}

-- 
2.55.0

