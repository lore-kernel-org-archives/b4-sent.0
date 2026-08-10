From: Junrui Luo <moonafterrain@outlook.com>
Date: Tue, 11 Aug 2026 00:13:14 +0800
Subject: [PATCH 5/5] drm/amdgpu: free userptr HMM ranges on the CS error
 path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-amdgpu-fixes-v1-5-4954a417b8ff@outlook.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2404;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=L6QMfmjG08GEYgq6Lvgjn+rT+rJCq+Q7xLdhBvY9+GU=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrMqfy6RfzJuy89+X84usVeOvsxZ2dRd+fvO2Y3GL7
 G0m597euRkdpSwMYlwMsmKKLMcLLn2z8N2iu8VnSzLMHFYmkCEMXJwCMJHHnxkZvjsd3j4/vThq
 p2rz6jjX/GVveLbFf9zL6NGSKFRhWnulg5Fh2dX9fdNlpNndDOxbPjf+kJn0MMVvVnP40Zi8st8
 xCrz8AHwXTaI=
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

amdgpu_cs_parser_bos() allocates a struct amdgpu_hmm_range for every
userptr entry of the BO list and returns with them live. They are only
released in two places: the out_free_user_pages label in
amdgpu_cs_parser_bos() itself, and the invalidation check loop in
amdgpu_cs_submit().

Every error edge between those two points leaks. A failure in
amdgpu_cs_patch_jobs(), amdgpu_cs_vm_handling() or amdgpu_cs_sync_rings(),
or an early return from amdgpu_cs_submit() before its release loop, jumps
to error_fini and falls into amdgpu_cs_parser_fini(), which never walks
the BO list for userptr ranges. An IB address with no VM mapping is enough
to get there: amdgpu_cs_patch_ibs() returns the -EINVAL that
amdgpu_cs_find_mapping() hands back, so the leak is repeatable at will
from an unprivileged render node fd. Each leaked entry costs a struct
amdgpu_hmm_range plus its hmm_pfns array, a kvmalloc_array() of one entry
per page of the userptr mapping, allocated with plain GFP_KERNEL and so
not charged to the caller's memory cgroup.

Release the ranges in amdgpu_cs_parser_fini(), which every path out of
amdgpu_cs_ioctl() passes through. amdgpu_hmm_range_free() ignores a NULL
range, so the success path, where amdgpu_cs_submit() has already freed and
cleared them, is unaffected.

Fixes: fec8fdb54e8f ("drm/amdgpu: fix userptr HMM range handling v2")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 drivers/gpu/drm/amd/amdgpu/amdgpu_cs.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/drivers/gpu/drm/amd/amdgpu/amdgpu_cs.c b/drivers/gpu/drm/amd/amdgpu/amdgpu_cs.c
index 617f53f135f3..17c4fec21402 100644
--- a/drivers/gpu/drm/amd/amdgpu/amdgpu_cs.c
+++ b/drivers/gpu/drm/amd/amdgpu/amdgpu_cs.c
@@ -1416,6 +1416,16 @@ static void amdgpu_cs_parser_fini(struct amdgpu_cs_parser *parser)
 				amdgpu_vm_bo_invalidate(bo, false);
 			}
 		}
+
+		/*
+		 * Release the ranges still live on the error paths;
+		 * amdgpu_cs_submit() already freed and cleared them when it
+		 * got far enough to check them for invalidation.
+		 */
+		amdgpu_bo_list_for_each_userptr_entry(e, parser->bo_list) {
+			amdgpu_hmm_range_free(e->range);
+			e->range = NULL;
+		}
 		amdgpu_bo_list_put(parser->bo_list);
 	}
 

-- 
2.51.2

