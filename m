From: Junrui Luo <moonafterrain@outlook.com>
Date: Sat, 08 Aug 2026 18:07:26 +0800
Subject: [PATCH v2] drm/amdgpu: add the BO-va mapping offset when kmapping
 an IB
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260808-amdgpu-fixes-v2-1-36d66398601f@outlook.com>
X-B4-Tracking: v=1; b=H4sIAN3/dmoC/x3LQQqAIBBA0avIrBNGF2VdJVqIjjaLTJQikO6et
 Hx8foNKhanCIhoUurnymTr0IMDtNkWS7LtBox7RoJH28DFfMvBDVc7OKgwWJ1IIfcmF/tCPdXv
 fD5LIg2xeAAAA
X-Change-ID: 20260808-amdgpu-fixes-9ca10fa07e10
To: Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Jammy Zhou <Jammy.Zhou@amd.com>, Madhav Chauhan <madhav.chauhan@amd.com>, 
 Felix Kuehling <Felix.Kuehling@amd.com>
Cc: amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Yuhao Jiang <danisjiang@gmail.com>, 
 Junrui Luo <moonafterrain@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2208;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=3FBj59YR9q4hNFYlTzD+oO1vogRrIbKjZwQeOYVwbY4=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrLL/j5LPXtkjmyZdbdzboX/ab4H+s35D75Blv2+7f
 ZR7uX/PlhcdpSwMYlwMsmKKLMcLLn2z8N2iu8VnSzLMHFYmkCEMXJwCMBGtGIY/fJUxaotOOr/P
 uPCvbapvhFXwb+Zllak+D1aKfQl58qVlLcN/31milS8V3qhJeh2Yz7DC8dG3f40PLiwU79W5mPx
 /8sQIJgB7+VFO
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

amdgpu_cs_patch_ibs() derives the CPU-side view of a UVD/VCE/VCN
indirect buffer from the BO returned by amdgpu_cs_find_mapping():

    r = amdgpu_bo_kmap(aobj, (void **)&kptr);
    kptr += va_start - (m->start * AMDGPU_GPU_PAGE_SIZE);

amdgpu_bo_kmap() returns the start of the BO, so only the displacement
of va_start inside the mapping is added.  The page tables, however, are
programmed from mapping->offset (see amdgpu_vm_bo_update()), which
records the offset_in_bo the client passed to AMDGPU_GEM_VA.  The GPU
therefore resolves va_start to BO byte

    m->offset + (va_start - m->start * AMDGPU_GPU_PAGE_SIZE)

while the kernel inspects the byte m->offset lower.  Whenever an IB is
submitted through a mapping created with a non-zero offset_in_bo, the
two views disagree.

Add the missing term so the kmapped pointer describes the same bytes the
page tables do.

Every other CPU-side consumer of amdgpu_cs_find_mapping() omits
mapping->offset in the same way.

Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
Reviewed-by: Christian König <christian.koenig@amd.com>
---
Changes in v2:
- Drop the Fixes tag.
- Pick up Christian's Reviewed-by.
- Resend standalone.
- Link to v1: https://lore.kernel.org/r/20260806-amdgpu-fixes-v1-3-ce247012d4da@outlook.com
---
 drivers/gpu/drm/amd/amdgpu/amdgpu_cs.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/amd/amdgpu/amdgpu_cs.c b/drivers/gpu/drm/amd/amdgpu/amdgpu_cs.c
index 5445f75741b5..17fe6d56e020 100644
--- a/drivers/gpu/drm/amd/amdgpu/amdgpu_cs.c
+++ b/drivers/gpu/drm/amd/amdgpu/amdgpu_cs.c
@@ -1043,7 +1043,7 @@ static int amdgpu_cs_patch_ibs(struct amdgpu_cs_parser *p,
 		if (r)
 			return r;
 
-		kptr += va_start - (m->start * AMDGPU_GPU_PAGE_SIZE);
+		kptr += m->offset + va_start - (m->start * AMDGPU_GPU_PAGE_SIZE);
 
 		if (ring->funcs->parse_cs) {
 			memcpy(ib->ptr, kptr, ib->length_dw * 4);

---
base-commit: 075b74841bd0065a3bda3440873c747938e69b68
change-id: 20260808-amdgpu-fixes-9ca10fa07e10

Best regards,
-- 
Junrui Luo <moonafterrain@outlook.com>

