From: Junrui Luo <moonafterrain@outlook.com>
Date: Thu, 06 Aug 2026 12:45:25 +0800
Subject: [PATCH 2/3] drm/amdgpu: fix VM update overrun on non-4K page
 kernels
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260806-amdgpu-fixes-v1-2-ce247012d4da@outlook.com>
References: <20260806-amdgpu-fixes-v1-0-ce247012d4da@outlook.com>
In-Reply-To: <20260806-amdgpu-fixes-v1-0-ce247012d4da@outlook.com>
To: Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Jammy Zhou <Jammy.Zhou@amd.com>, Madhav Chauhan <madhav.chauhan@amd.com>, 
 Felix Kuehling <Felix.Kuehling@amd.com>
Cc: amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Junrui Luo <moonafterrain@outlook.com>, 
 Yuhao Jiang <danisjiang@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2456;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=RZz+TFSeftgnMAQF9ZGjSUuynkvUNb8BqbEu73b+W2w=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrBLB/OLTuwuNp3tJBO+8KlctJP3i6dLA+V+8Fh8+V
 tAbknUte2tHKQuDGBeDrJgiy/GCS98sfLfobvHZkgwzh5UJZAgDF6cAXESO4a94HfMmCXVP5a4H
 wf17MkVZ/0x6x9x3Y6bxcWujI5HiU7czMvR/Ngl4lL7UZcnehNYtrj1bGqb/W8jw/uCje8d2el6
 s72MHAEbVS7g=
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The contiguity scan in amdgpu_vm_update_range() rounds num_entries up to
count * AMDGPU_GPU_PAGES_IN_CPU_PAGE, but count is only constrained by
the loop bound when the loop body executes. The guard
num_entries > AMDGPU_GPU_PAGES_IN_CPU_PAGE proves that
tmp = num_entries / AMDGPU_GPU_PAGES_IN_CPU_PAGE is at least 1, while
the initial count of 2 needs tmp >= 2.

Each iteration consumes a multiple of AMDGPU_GPU_PAGES_IN_CPU_PAGE, so a
mapping whose GPU page count is not a multiple of it eventually reaches
an iteration where num_entries is above AMDGPU_GPU_PAGES_IN_CPU_PAGE but
below twice that. tmp is then 1, the loop body never runs, count keeps
its initial value, and num_entries is rounded up past what the cursor
holds, tripping BUG_ON(size > cur->remaining) in amdgpu_res_next().
AMDGPU_GEM_VA is DRM_RENDER_ALLOW and amdgpu_vm_verify_parameters() only
requires map_size to be a multiple of AMDGPU_GPU_PAGE_SIZE, so an
unprivileged caller can reach this. On 4K page hosts
AMDGPU_GPU_PAGES_IN_CPU_PAGE is 1, tmp >= 2 always holds, and the bug is
unreachable.

Clamp the rounded-up value against num_entries, mirroring the min() that
amdgpu_res_first() already applies to cur->size. A contiguous short tail
is then mapped in full, and a non-contiguous one falls back to a single
CPU page so the loop still makes forward progress.

Fixes: a39f2a8d7066 ("drm/amdgpu: nuke amdgpu_vm_bo_split_mapping v2")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
Found by code inspection; not tested on hardware. I have no access to a
64K-page host with an AMD GPU, so the BUG_ON() path was not exercised at
runtime.
---
 drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c b/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c
index dc6a9d7dd0b2..365a1c4a4527 100644
--- a/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c
+++ b/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c
@@ -1193,8 +1193,9 @@ int amdgpu_vm_update_range(struct amdgpu_device *adev, struct amdgpu_vm *vm,
 				}
 				if (!contiguous)
 					count--;
-				num_entries = count *
-					AMDGPU_GPU_PAGES_IN_CPU_PAGE;
+				num_entries = min(count *
+						  AMDGPU_GPU_PAGES_IN_CPU_PAGE,
+						  num_entries);
 			}
 
 			if (!contiguous) {

-- 
2.51.2

