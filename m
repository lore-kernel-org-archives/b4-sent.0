From: Junrui Luo <moonafterrain@outlook.com>
Date: Thu, 06 Aug 2026 12:45:26 +0800
Subject: [PATCH 3/3] drm/amdgpu: add the BO-va mapping offset when kmapping
 an IB
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260806-amdgpu-fixes-v1-3-ce247012d4da@outlook.com>
References: <20260806-amdgpu-fixes-v1-0-ce247012d4da@outlook.com>
In-Reply-To: <20260806-amdgpu-fixes-v1-0-ce247012d4da@outlook.com>
To: Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Jammy Zhou <Jammy.Zhou@amd.com>, Madhav Chauhan <madhav.chauhan@amd.com>, 
 Felix Kuehling <Felix.Kuehling@amd.com>
Cc: amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Junrui Luo <moonafterrain@outlook.com>, 
 Yuhao Jiang <danisjiang@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1861;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=MbTPCxPC+NDqqRce7zTi4D+evqyxLQPMZapIx+qmD0Q=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrBLB/DfZi47l17h7SAeu4BEMcj9s2DaB3/PUHs7Qr
 W735Venv+goZWEQ42KQFVNkOV5w6ZuF7xbdLT5bkmHmsDKBDGHg4hSAiSzNYfjJGLTW9nlC6BXO
 woRQd5XGF9N/L/TaekN2tl3t8czgJm1nRoYNy5/s/vlEadqbDVUJms8cuoTL51u9k/f/yJS309L
 u0B8uAHdPSUc=
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

Fixes: 4802ce117786 ("drm/amdgpu: fix UVD/VCE VM emulation")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 drivers/gpu/drm/amd/amdgpu/amdgpu_cs.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/amd/amdgpu/amdgpu_cs.c b/drivers/gpu/drm/amd/amdgpu/amdgpu_cs.c
index 9c514cb01096..a72cee871af3 100644
--- a/drivers/gpu/drm/amd/amdgpu/amdgpu_cs.c
+++ b/drivers/gpu/drm/amd/amdgpu/amdgpu_cs.c
@@ -1047,7 +1047,7 @@ static int amdgpu_cs_patch_ibs(struct amdgpu_cs_parser *p,
 		if (r)
 			return r;
 
-		kptr += va_start - (m->start * AMDGPU_GPU_PAGE_SIZE);
+		kptr += m->offset + va_start - (m->start * AMDGPU_GPU_PAGE_SIZE);
 
 		if (ring->funcs->parse_cs) {
 			memcpy(ib->ptr, kptr, ib->length_dw * 4);

-- 
2.51.2

