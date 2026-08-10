From: Junrui Luo <moonafterrain@outlook.com>
Date: Tue, 11 Aug 2026 00:13:13 +0800
Subject: [PATCH 4/5] drm/amdgpu: enforce UVD handle ownership on destroy
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-amdgpu-fixes-v1-4-4954a417b8ff@outlook.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2299;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=UtGNeM13NSreEA2vgkQPwwzgGSG/EJ+HK2TwqY3ru6I=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrMqfS40VjhmWnd2/6hD3na7ZrbHHfV8FbmefWj17e
 lyFd6J4TWdHKQuDGBeDrJgiy/GCS98sfLfobvHZkgwzh5UJZAgDF6cATMQrieGffnHOVano9rq9
 HMXn1TZyyjWGrQ8Ji//dz/WvaKP8bcHdjAynyuLigxq3Zwcmm+R/+VGSxGH59HiN/utz+bN4Pwe
 s+MQEAO2LS68=
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

amdgpu_uvd_cs_msg() validates that a decode message references a handle
owned by the submitting client, rejecting a mismatch between
adev->uvd.filp[i] and ctx->parser->filp. The handles[] and filp[] tables
are per-device and shared by every drm_file that opens the render node.

The destroy message performs no such check: it walks the whole table and
clears every slot matching the handle taken from the command stream
buffer. A client can therefore destroy a handle owned by another client,
clearing the victim's slot and tearing down its session in UVD firmware,
so subsequent decode submissions fail with -ENOENT. Since
amdgpu_uvd_free_handles() only reaps slots whose handle is non-zero, the
cleared slot also retains a stale filp pointer until reused.

Apply the decode arm's ownership test to the destroy arm. The kunmap
is hoisted above the loop, matching the create and decode arms, so
the new error return cannot leak the amdgpu_bo_kmap() reference.
Kernel-initiated teardown goes through amdgpu_uvd_send_msg() and never
runs the parser.

Fixes: 5146419e6feb ("drm/amdgpu: make UVD handle checking more strict")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 drivers/gpu/drm/amd/amdgpu/amdgpu_uvd.c | 14 ++++++++++++--
 1 file changed, 12 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/amd/amdgpu/amdgpu_uvd.c b/drivers/gpu/drm/amd/amdgpu/amdgpu_uvd.c
index e8b0c62f72be..8d3e5435cf52 100644
--- a/drivers/gpu/drm/amd/amdgpu/amdgpu_uvd.c
+++ b/drivers/gpu/drm/amd/amdgpu/amdgpu_uvd.c
@@ -918,9 +918,19 @@ static int amdgpu_uvd_cs_msg(struct amdgpu_uvd_cs_ctx *ctx,
 
 	case 2:
 		/* it's a destroy msg, free the handle */
-		for (i = 0; i < adev->uvd.max_handles; ++i)
-			atomic_cmpxchg(&adev->uvd.handles[i], handle, 0);
 		amdgpu_bo_kunmap(bo);
+
+		for (i = 0; i < adev->uvd.max_handles; ++i) {
+			if (atomic_read(&adev->uvd.handles[i]) != handle)
+				continue;
+
+			if (adev->uvd.filp[i] != ctx->parser->filp) {
+				DRM_ERROR("UVD handle collision detected!\n");
+				return -EINVAL;
+			}
+
+			atomic_cmpxchg(&adev->uvd.handles[i], handle, 0);
+		}
 		return 0;
 
 	default:

-- 
2.51.2

