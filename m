From: Gaurav Suman <gauravsuman007@gmail.com>
Date: Mon, 09 Nov 2026 22:34:24 +0000
Subject: [PATCH] drm/msm: align kernel-managed GPU VAs to 64 KiB
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-msm-va-align-v1-1-2e9b576d2e4e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAG9K8moC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQwNL3dziXN2yRN3EnMz0PF0Dc6MkUwtTA2OLxEQloJaCotS0zAqwcdG
 xtbUAN7gbFV4AAAA=
X-Change-ID: 20261109-msm-va-align-072b585038aa
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Gaurav Suman <gauravsuman007@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794263665; l=3102;
 i=gauravsuman007@gmail.com; s=default; h=from:subject:message-id;
 bh=jgOwJ2FL7GTVl1ehT01v9Wyso8hTCmJQBXKc1hdLWFE=;
 b=ZwtuXkntUilUgklhqwAwOwthlQCa5WxHHtyOfF7o8H8qaTEv5zMIZWw18/XTo6OaFTJUfuPPZ
 oGRybGxy7EwB/fHyzPAkDe9tt5lR9XXh9ylBqqk1S9hnSZfGzNYe+1G
X-Developer-Key: i=gauravsuman007@gmail.com; a=ed25519;
 pk=lnUC0mQfc0KyA0LE73pQ4+QWYVRaCD8Sd3XWxLZO+JY=
X-Endpoint-Received: by B4 Relay for gauravsuman007@gmail.com/default with auth_id=1467
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On an Adreno 640 (SM8150, LG G8x) GNOME Shell triggers SMMU
translation faults with source=CCU, about ten per login, when
freedreno uses GMEM (binning) rendering. FD_MESA_DEBUG=nogmem or
=inorder hides them.

A stall-on-fault capture decoded with crashdec shows the faulting
address at an exact 64 KiB boundary (FAR 0x110690000) while the pass
drew to MRT0 at 0x110695000 and depth at 0x11069f000, all in that
64 KiB block. The block start belonged to the unmapped tail of
another buffer that was not part of the running submit. A ring
buffer of pagetable operations confirmed this for every fault: the
CCU reads the 64 KiB-aligned start of the block holding a bound
render target, and msm packs kernel-managed VAs at 4 KiB, so that
address often belongs to a different, unmapped buffer. Batch
reordering makes this common, which is why inorder hides it.

Align kernel-managed VAs to 64 KiB, falling back to page alignment
when the range is too tight (a6xx_gmu_init() fails with -ENOSPC
otherwise).

Tested on the LG G8x with Mesa unchanged and GMEM enabled: in an A/B
run in one boot, 4 KiB alignment gave 10 and 10 faults per login, 64
KiB alignment 0, 0, 0 and 0. No faults in three further logins, a
GMEM stress test or the full device test suite; glmark2 is unchanged
within noise. Userspace-managed VMs (VM_BIND) are not changed; Mesa
may want the same alignment there.

This was investigated, written and tested with the help of an AI
coding assistant (Claude Opus 5.5, Anthropic); I reviewed the change
and the test results.

Signed-off-by: Gaurav Suman <gauravsuman007@gmail.com>
---
Tested on LG G8x ThinQ (SM8150).
---
 drivers/gpu/drm/msm/msm_gem_vma.c | 13 ++++++++++++-
 1 file changed, 12 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/msm/msm_gem_vma.c b/drivers/gpu/drm/msm/msm_gem_vma.c
index f687a629629d348b54ebb379d3a2fa956b8e472e..2af43291289945d54326287affeffa7e72645880 100644
--- a/drivers/gpu/drm/msm/msm_gem_vma.c
+++ b/drivers/gpu/drm/msm/msm_gem_vma.c
@@ -388,9 +388,20 @@ msm_gem_vma_new(struct drm_gpuvm *gpuvm, struct drm_gem_object *obj,
 	if (vm->managed) {
 		BUG_ON(offset != 0);
 		BUG_ON(!obj);  /* NULL mappings not valid for kernel managed VM */
+		/*
+		 * On a6xx (seen on A640) the CCU can read the 64 KiB-aligned
+		 * start of the block that holds a bound render target. Align
+		 * kernel-managed VAs to 64 KiB so that block start lies inside
+		 * the buffer itself; callers with a tight fixed window, such as
+		 * the GMU, fall back to page alignment.
+		 */
 		ret = drm_mm_insert_node_in_range(&vm->mm, &vma->node,
-						obj->size, PAGE_SIZE, 0,
+						obj->size, SZ_64K, 0,
 						range_start, range_end, 0);
+		if (ret == -ENOSPC)
+			ret = drm_mm_insert_node_in_range(&vm->mm, &vma->node,
+							  obj->size, PAGE_SIZE, 0,
+							  range_start, range_end, 0);
 
 		if (ret)
 			goto err_free_vma;

---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261109-msm-va-align-072b585038aa

Best regards,
-- 
Gaurav Suman <gauravsuman007@gmail.com>

