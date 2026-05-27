From: Xiubo Li <xiubli@kernel.org>
Date: Wed, 27 May 2026 14:38:14 +0800
Subject: [PATCH] Revert "drm/msm: Restore second parameter name in purge()
 and evict()"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-mybr4-v1-1-9b8220e756c2@kernel.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDUyNz3dzKpCIT3SSz1FTL5LTkRFMTcyWg2oKi1LTMCrA50bG1tQAdkA0
 eVwAAAA==
X-Change-ID: 20260527-mybr4-b6ee9cfca547
To: xiubli@kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779863900; l=1189;
 i=xiubli@kernel.org; s=20260527; h=from:subject:message-id;
 bh=u4myyMyzJe4llbhuzA6U6mvI3hbhQWQxZsLFbUVuNNg=;
 b=/P/xuY1o51OrPwhsXlnPFYiiKGIRFnOkgcSOpxqnMvWvyXE8Cv6TORGzQyl86comu/dI4g7bR
 dwnFZZHrbd6COVXOUtBAL/+2YK8ADh+Za7mEKRFhWZ8EHJlyeH2JvMS
X-Developer-Key: i=xiubli@kernel.org; a=ed25519;
 pk=x2BSkeQcykT+nbQKshFk72C0c70TVkHCI1Mz9+ywY+M=
X-Endpoint-Received: by B4 Relay for xiubli@kernel.org/20260527 with auth_id=795
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This reverts commit 53676e4d44d6b38c8a0d9bff331f170ae2e41bbe.

Signed-off-by: Xiubo Li <xiubli@kernel.org>
---
Test
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

