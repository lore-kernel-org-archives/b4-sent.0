From: Junrui Luo <moonafterrain@outlook.com>
Date: Tue, 11 Aug 2026 00:13:11 +0800
Subject: [PATCH 2/5] drm/amdgpu: reject PRT mappings as user queue buffer
 VAs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-amdgpu-fixes-v1-2-4954a417b8ff@outlook.com>
References: <20260811-amdgpu-fixes-v1-0-4954a417b8ff@outlook.com>
In-Reply-To: <20260811-amdgpu-fixes-v1-0-4954a417b8ff@outlook.com>
To: Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Sumit Semwal <sumit.semwal@linaro.org>, Junwei Zhang <Jerry.Zhang@amd.com>, 
 =?utf-8?q?Nicolai_H=C3=A4hnle?= <nicolai.haehnle@amd.com>, 
 Prike Liang <Prike.Liang@amd.com>, Arvind Yadav <arvind.yadav@amd.com>, 
 Shashank Sharma <shashank.sharma@amd.com>, Leo Liu <leo.liu@amd.com>, 
 Felix Kuehling <Felix.Kuehling@amd.com>
Cc: amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, linux-media@vger.kernel.org, 
 linaro-mm-sig@lists.linaro.org, Junrui Luo <moonafterrain@outlook.com>, 
 Yuhao Jiang <danisjiang@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2330;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=lfRKX90eM1yWKlq0c1LdgUl6q5HeCXaJonPRnO3TU20=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrMqfS8MzkkW8LcUEFkwJaFi1V09slfqyG/p2N5wes
 iw49vLaimkdpSwMYlwMsmKKLMcLLn2z8N2iu8VnSzLMHFYmkCEMXJwCMBFRB4b/SdMkBBe5RRtO
 Kl8g8cNstk7TrfXJ4Q4LbT0f2EaHsxRdYGS4rlpeoZampVt1JDRg451N3yeHZ+1T8PzAf9bk7c5
 PjdbcAPu3SQM=
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

amdgpu_userq_input_va_validate() resolves a user-supplied queue_va,
rptr_va or wptr_va to a VM mapping and latches userq_va_mapped on
the owning bo_va. It only checks that a mapping exists and that
the requested span is contained in it, never that the mapping has
a backing BO. PRT mappings do not: amdgpu_gem_va_ioctl() routes
every AMDGPU_VM_PAGE_PRT map through fpriv->prt_va, created via
amdgpu_vm_bo_add(adev, vm, NULL), so base.bo stays NULL while
amdgpu_vm_bo_insert_map() still sets mapping->bo_va.

A VA inside such a mapping therefore passes validation and marks
fpriv->prt_va as userq mapped. The flag is never cleared. On the
next unmap of any PRT mapping in that VM, amdgpu_vm_bo_unmap() sees
userq_va_mapped and calls amdgpu_userq_gem_va_unmap_validate(), which
reads bo_va->base.bo->tbo.base.resv before its ip_mask guard, leading
to a NULL pointer dereference.

Fix by rejecting a mapping without a backing BO in the validation
helper, so the invariant amdgpu_userq_gem_va_unmap_validate() relies
on holds by construction. A sparse mapping has no memory behind it and
cannot serve as a ring, rptr or wptr buffer.

Fixes: 2e7ceac0ea41 ("drm/amdgpu: validate userq va for GEM unmap")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 drivers/gpu/drm/amd/amdgpu/amdgpu_userq.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/gpu/drm/amd/amdgpu/amdgpu_userq.c b/drivers/gpu/drm/amd/amdgpu/amdgpu_userq.c
index 6d3ed55e9ab4..bec107216811 100644
--- a/drivers/gpu/drm/amd/amdgpu/amdgpu_userq.c
+++ b/drivers/gpu/drm/amd/amdgpu/amdgpu_userq.c
@@ -259,6 +259,14 @@ int amdgpu_userq_input_va_validate(struct amdgpu_device *adev,
 	if (!va_map)
 		return -EINVAL;
 
+	/*
+	 * A PRT mapping has no backing BO and so can't carry the eviction
+	 * fence which amdgpu_userq_gem_va_unmap_validate() waits on. Reject it
+	 * here, otherwise that helper dereferences a NULL bo on GEM unmap.
+	 */
+	if (!va_map->bo_va->base.bo)
+		return -EINVAL;
+
 	/* Lookup guarantees start_page is mapped; ensure full span is covered. */
 	if ((end_addr >> AMDGPU_GPU_PAGE_SHIFT) <= va_map->last) {
 		va_map->bo_va->userq_va_mapped = true;

-- 
2.51.2

