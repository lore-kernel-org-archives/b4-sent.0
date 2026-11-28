From: Dickson Wu <dickson.wu@certik.com>
Date: Sat, 28 Nov 2026 08:10:35 +0000
Subject: [PATCH 6.1.y] drm/amdgpu/vcn4: avoid rereading IB param length
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-amdgpu-vcn4-61c-v1-1-0f4b00ae33c2@certik.com>
X-B4-Tracking: v=1; b=H4sIAHqMCmsC/12NzQ6CMBCEX4Xs2UXbaBVexXjozwI12pIuEA3h3
 W315nG+zHyzAlPyxNBWKyRaPPsYchC7CuygQ0/oXc4gD1IJIS+on64fZ1xsOKISFrvGOXk2nTr
 JBvJqTNT519d4BVWL+g23H+bZ3MlOxVaKRjOhSTrYoSCm4KYYH1j4/u8Ftu0D9DmZo6oAAAA=
X-Change-ID: 20261128-amdgpu-vcn4-61c-f9dd27bf6529
To: stable@vger.kernel.org
Cc: Boyuan Zhang <boyuan.zhang@amd.com>, David Rosca <david.rosca@amd.com>, 
 Alex Deucher <alexander.deucher@amd.com>, amd-gfx@lists.freedesktop.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795853434; l=3713;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=B+Yz49Bh1ZXTZrWyQ6EaWYVQ18dVN1NAYdlgp9oDZIo=;
 b=VN0w0FK7GEQeCtbfURpyQ6h84Y7Jk7uCkQ2EKL98dKjnG2GEnKXU+wE9OfX5/gMooCA/936Fu
 ZC29xmdLv1rBXJD1vt39OSwnqtJvnzrgM2R16xVVHW9TUr2I7MecZ12
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Boyuan Zhang <boyuan.zhang@amd.com>

commit 3b4082fabc67c9780b06eb959e59dd92fa79c0f0 upstream.

Reuse the parameter length returned by
vcn_v4_0_enc_find_ib_param() instead of rereading it from
the IB.

This avoids a potential TOCTOU issue if the IB contents
change between reads.

Signed-off-by: Boyuan Zhang <boyuan.zhang@amd.com>
Reviewed-by: David Rosca <david.rosca@amd.com>
Signed-off-by: Alex Deucher <alexander.deucher@amd.com>
(cherry picked from commit dbb02b4755f8c1f3773263f2d779872c1c0c073a)
Cc: stable@vger.kernel.org
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
This one went to 6.6.y in 6.6.148, but 6.1.y didn't have the VCN4 IB
parser fixes yet at that point. Those came to 6.1.y in 6.1.191
(d19dd814b5b7 and 92724364702f), so 6.1 now has the loop this fixes
and the patch applies cleanly.

Tested on 6.1.193: allmodconfig W=1 build of vcn_v4_0.o, base vs
patched, no new warnings, and the patched kernel boots under QEMU. No
VCN4 hardware here, so the encode path itself wasn't exercised.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.
---
 drivers/gpu/drm/amd/amdgpu/vcn_v4_0.c | 15 +++++++++------
 1 file changed, 9 insertions(+), 6 deletions(-)

diff --git a/drivers/gpu/drm/amd/amdgpu/vcn_v4_0.c b/drivers/gpu/drm/amd/amdgpu/vcn_v4_0.c
index 83d997f8d500..5df81a21c522 100644
--- a/drivers/gpu/drm/amd/amdgpu/vcn_v4_0.c
+++ b/drivers/gpu/drm/amd/amdgpu/vcn_v4_0.c
@@ -1719,14 +1719,17 @@ static int vcn_v4_0_dec_msg(struct amdgpu_cs_parser *p, struct amdgpu_job *job,
 #define RENCODE_IB_PARAM_SESSION_INIT			0x00000003
 
 /* return the offset in ib if id is found, -1 otherwise */
-static int vcn_v4_0_enc_find_ib_param(struct amdgpu_ib *ib, uint32_t id, int start)
+static int vcn_v4_0_enc_find_ib_param(struct amdgpu_ib *ib, uint32_t id, int start, uint32_t *length)
 {
 	int i;
 	uint32_t len;
 
 	for (i = start; (len = amdgpu_ib_get_value(ib, i)) >= 8; i += len / 4) {
-		if (amdgpu_ib_get_value(ib, i + 1) == id)
+		if (amdgpu_ib_get_value(ib, i + 1) == id) {
+			if (length)
+				*length = len;
 			return i;
+		}
 	}
 	return -1;
 }
@@ -1736,14 +1739,14 @@ static int vcn_v4_0_ring_patch_cs_in_place(struct amdgpu_cs_parser *p,
 					   struct amdgpu_ib *ib)
 {
 	struct amdgpu_ring *ring = amdgpu_job_ring(job);
-	uint32_t val;
+	uint32_t val, len;
 	int idx = 0, sidx;
 
 	/* The first instance can decode anything */
 	if (!ring->me)
 		return 0;
 
-	while ((idx = vcn_v4_0_enc_find_ib_param(ib, RADEON_VCN_ENGINE_INFO, idx)) >= 0) {
+	while ((idx = vcn_v4_0_enc_find_ib_param(ib, RADEON_VCN_ENGINE_INFO, idx, &len)) >= 0) {
 		val = amdgpu_ib_get_value(ib, idx + 2); /* RADEON_VCN_ENGINE_TYPE */
 		if (val == RADEON_VCN_ENGINE_TYPE_DECODE) {
 			uint32_t valid_buf_flag = amdgpu_ib_get_value(ib, idx + 6);
@@ -1756,12 +1759,12 @@ static int vcn_v4_0_ring_patch_cs_in_place(struct amdgpu_cs_parser *p,
 				amdgpu_ib_get_value(ib, idx + 8);
 			return vcn_v4_0_dec_msg(p, job, msg_buffer_addr);
 		} else if (val == RADEON_VCN_ENGINE_TYPE_ENCODE) {
-			sidx = vcn_v4_0_enc_find_ib_param(ib, RENCODE_IB_PARAM_SESSION_INIT, idx);
+			sidx = vcn_v4_0_enc_find_ib_param(ib, RENCODE_IB_PARAM_SESSION_INIT, idx, NULL);
 			if (sidx >= 0 &&
 			    amdgpu_ib_get_value(ib, sidx + 2) == RENCODE_ENCODE_STANDARD_AV1)
 				return vcn_v4_0_limit_sched(p, job);
 		}
-		idx += amdgpu_ib_get_value(ib, idx) / 4;
+		idx += len / 4;
 	}
 	return 0;
 }

---
base-commit: 1ca1436ccc68275d0b43b6a730b3940fcc46b7c2
change-id: 20261128-amdgpu-vcn4-61c-f9dd27bf6529

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

