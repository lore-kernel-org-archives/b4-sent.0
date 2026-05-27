From: Xiubo Li <xiubli@kernel.org>
Date: Wed, 27 May 2026 14:40:49 +0800
Subject: [PATCH v2] Revert "drm/msm: Restore second parameter name in
 purge() and evict()"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-mybr4-v2-1-28c4c2effb9f@kernel.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/13MQQ7CIBCF4as0sxYDkwLWlfcwXRSctkQtZjDEp
 uHuYpcu/5eXb4NEHCjBudmAKYcU4lIDDw34eVgmEuFWG1CikRqteK6OW+EMUedHP+jWQv2+mMb
 w2Z1rX3sO6R153dmsfuu/kJVQonMnRElWG4+XO/FCj2PkCfpSyhcDo4onmwAAAA==
X-Change-ID: 20260527-mybr4-b6ee9cfca547
To: xiubli@kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779864050; l=1404;
 i=xiubli@kernel.org; s=20260527; h=from:subject:message-id;
 bh=nOvXcXVU60D22fqlX5jn3QPHLDSP3KArKvMLVm4f5MU=;
 b=VYhfu0DbrbVacmIRap5B2R65Zo5kR+WNjOia24sJFpKBOajEjCgsr12NK5M6XBwSVJ4y3Up6p
 ImlwNH4UJrlBlO6Yw2zr3zHkMN+KMx6ewN7qSnjxtBMh03nhKW85l1K
X-Developer-Key: i=xiubli@kernel.org; a=ed25519;
 pk=x2BSkeQcykT+nbQKshFk72C0c70TVkHCI1Mz9+ywY+M=
X-Endpoint-Received: by B4 Relay for xiubli@kernel.org/20260527 with auth_id=795
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This reverts commit 53676e4d44d6b38c8a0d9bff331f170ae2e41bbe.

Signed-off-by: Xiubo Li <xiubli@kernel.org>
---
Test
---
Changes in v2:
- EDITME: describe what is new in this series revision.
- EDITME: use bulletpoints and terse descriptions.
- Link to v1: https://lore.kernel.org/r/20260527-mybr4-v1-1-9b8220e756c2@kernel.org
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
change-id: 20260527-mybr4-b6ee9cfca547

Best regards,
-- 
Xiubo Li <xiubli@kernel.org>

