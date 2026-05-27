From: Xiubo Li <xiubo.lee@gmail.com>
Date: Wed, 27 May 2026 13:43:08 +0800
Subject: [PATCH] Revert "drm/msm: Restore second parameter name in purge()
 and evict()"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-mybr2-v1-1-a992ce7f9e86@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDUyNz3dzKpCIj3aTUNBNTIzPD5FSDFCWg2oKi1LTMCrA50bG1tQC7N5L
 5VwAAAA==
X-Change-ID: 20260527-mybr2-bef45261ce0d
To: xiubli@kernel.org
Cc: Xiubo Li <xiubli@redhat.com>, Xiubo Li <xiubo.lee@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779860591; l=1241;
 i=xiubo.lee@gmail.com; s=20260527; h=from:subject:message-id;
 bh=7tYayk6Z8aFbWLMjw7I5OJLeFO5/MJDO6e+sBWPMlic=;
 b=XOVqOgEiTxwgGLqo+PSeJYN54R4ac1G1KTOsQlDIz3GdaKqTbPj7EO/WCz9PEMVPAe4FNDKyS
 o3QmHkylnItB2J23EARFaiGlBhDj/z2/k3MV446z3HO8DFj3fKvhFB0
X-Developer-Key: i=xiubo.lee@gmail.com; a=ed25519;
 pk=x2BSkeQcykT+nbQKshFk72C0c70TVkHCI1Mz9+ywY+M=
X-Endpoint-Received: by B4 Relay for xiubo.lee@gmail.com/20260527 with auth_id=794
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Xiubo Li <xiubli@redhat.com>

This reverts commit 53676e4d44d6b38c8a0d9bff331f170ae2e41bbe.

Signed-off-by: Xiubo Li <xiubli@kernel.org>
---
Test.

Signed-off-by: Xiubo Li <xiubo.lee@gmail.com>
---
 drivers/gpu/drm/msm/msm_gem_shrinker.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/msm/msm_gem_shrinker.c b/drivers/gpu/drm/msm/msm_gem_shrinker.c
index 9d2788f79ace..c8dda2b68cff 100644
--- a/drivers/gpu/drm/msm/msm_gem_shrinker.c
+++ b/drivers/gpu/drm/msm/msm_gem_shrinker.c
@@ -102,7 +102,7 @@ with_vm_locks(void (*fn)(struct drm_gem_object *obj),
 }
 
 static bool
-purge(struct drm_gem_object *obj, struct ww_acquire_ctx *unused)
+purge(struct drm_gem_object *obj, struct ww_acquire_ctx *)
 {
 	if (!is_purgeable(to_msm_bo(obj)))
 		return false;
@@ -114,7 +114,7 @@ purge(struct drm_gem_object *obj, struct ww_acquire_ctx *unused)
 }
 
 static bool
-evict(struct drm_gem_object *obj, struct ww_acquire_ctx *unused)
+evict(struct drm_gem_object *obj, struct ww_acquire_ctx *)
 {
 	if (is_unevictable(to_msm_bo(obj)))
 		return false;

---
base-commit: e7ae89a0c97ce2b68b0983cd01eda67cf373517d
change-id: 20260527-mybr2-bef45261ce0d

Best regards,
-- 
Xiubo Li <xiubo.lee@gmail.com>

