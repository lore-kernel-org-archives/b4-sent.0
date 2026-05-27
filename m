From: Xiubo Li <xiubo.lee@gmail.com>
Date: Wed, 27 May 2026 13:45:11 +0800
Subject: [PATCH v2] Revert "drm/msm: Restore second parameter name in
 purge() and evict()"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-mybr2-v2-1-0d1a14a7a06c@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/13MQQ7CIBCF4as0sxYDE9uKK+9huqB0aCeRYsAQm
 4a7i126/F9evh0SRaYEt2aHSJkTh7UGnhqwi1lnEjzVBpTYyRZ74bcxohjJXVrslCU5Qf2+Ijn
 +HM5jqL1weoe4HWxWv/VfyEooYbRGS73TdO3uszf8PNvgYSilfAEdMdbnmgAAAA==
X-Change-ID: 20260527-mybr2-bef45261ce0d
To: xiubli@kernel.org
Cc: Xiubo Li <xiubli@redhat.com>, Xiubo Li <xiubo.lee@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779860714; l=1455;
 i=xiubo.lee@gmail.com; s=20260527; h=from:subject:message-id;
 bh=kmDYJMU1VPsFDEtQtpK+BXRc+fIaQudJPb2iCdVxiR0=;
 b=XX1dmFXL2H4FoaIbPxFRID80BqZknlnoszq/iOv86TjUTdYHOEhNMka+O3Hslptp9pelfRFcb
 fgfccAtSw1rAjjYPgTDIyNMz880YzVYHbmxPu4aFBIbq2dfR4kG7ymE
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
Changes in v2:
- EDITME: describe what is new in this series revision.
- EDITME: use bulletpoints and terse descriptions.
- Link to v1: https://lore.kernel.org/r/20260527-mybr2-v1-1-a992ce7f9e86@gmail.com
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

