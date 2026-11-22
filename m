From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Mon, 23 Nov 2026 00:50:07 +0530
Subject: [PATCH v2] drm/msm/a6xx: Fall back to MX when GMxC has no levels
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-msm-gmxc-fallback-v2-1-5dccc6a2ce34@yahoo.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ6CMBBFr0JmbY3TxCquvIdhMW0HqFJqWmwgh
 LsLuHf5kvffnyFxdJzgVswQObvkQr+CPBRgWuobFs6uDPIkFSIq4ZMXjR+NqKnrNJmX0OdS81W
 yMtLCuntHrt24Nx/Vj9NHP9kMW2gzWpeGEKf9NOPm/etnFCiotET2goqQ7xO1IRxN8FAty/IFD
 UHZzMQAAAA=
X-Change-ID: 20261116-msm-gmxc-fallback-b59be82e6c2d
To: Rob Clark <robin.clark@oss.qualcomm.com>, Sean Paul <sean@poorly.run>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Akhil P Oommen <akhilpo@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795375206; l=2880;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=74LSQlZzTqbucHJa48m+yacr8Q6+5YkDPUtVvz3s7XI=;
 b=aEtKP5ytT/G03Oi/XzEJJ2yuRfncR5R23fxPdUIQoJgbniRN+eFd3+1vRKQ0DlpKmsIGJZok4
 4V81jjzLMIGBeSuYsDPNh73cWkMC4ITk2dVMlnAuFM+uIci8c1Bo8MR
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The command DB of Molokai (SM8845) lists the gmxc.lvl resource without
any level. Since a6xx_gmu_rpmh_read_arc() trims the trailing zero
levels, reading it now fails with -EINVAL, so the GX votes are never
built and the GMU of the Adreno 829 hangs on the first GX vote:

  Message HFI_H2F_MSG_GX_BW_PERF_VOTE id 8 timed out waiting for response
  Timeout waiting for GMU OOB set GPU_SET: 0x4
  gpu hw init failed: -110

Before, the empty list made the GX votes use the lowest GMxC corner and
the GPU worked. Read gmxc.lvl the same way when choosing the secondary
rail, so that a GMxC without levels is treated like a missing one and
the GX votes use MX.

Fixes: b5269bf0e1ad ("drm/msm/a6xx: Factor out RPMh arc-vote helpers")
Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
Found while bringing up the Adreno 829 of the Motorola Signature
(Qualcomm Molokai, SM8845) on next-20261113: the GMU firmware loads but
never answers the first GX vote. Bisecting the arc vote rework points at
commit b5269bf0e1ad: the Molokai command DB lists gmxc.lvl without any
level, which the new helper rejects, so the GX votes are never built.

Tested on the Motorola Signature: the GMU answers, the GPU comes up and
Phosh renders on it.

I used an LLM (Claude) to help write this patch and its commit message.
I reviewed it, bisected the regression on the device and tested the
result there.
---
Changes in v2:
- Drop the Assisted-by trailers and the LLM notes from the commit
  messages, the LLM use is stated in this cover letter.
- Link to v1: https://patch.msgid.link/20261116-msm-gmxc-fallback-v1-1-a9daad716a1e@yahoo.com
---
 drivers/gpu/drm/msm/adreno/a6xx_gmu.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/msm/adreno/a6xx_gmu.c b/drivers/gpu/drm/msm/adreno/a6xx_gmu.c
index 662f09bec9d5..914434b49eed 100644
--- a/drivers/gpu/drm/msm/adreno/a6xx_gmu.c
+++ b/drivers/gpu/drm/msm/adreno/a6xx_gmu.c
@@ -1889,13 +1889,17 @@ static int a6xx_gmu_rpmh_votes_init(struct a6xx_gmu *gmu)
 	struct msm_gpu *gpu = &adreno_gpu->base;
 	const char *sec_id;
 	const u16 *gmxc;
+	size_t gmxc_count;
 	int ret;
 
-	gmxc = cmd_db_read_aux_data("gmxc.lvl", NULL);
+	gmxc = a6xx_gmu_rpmh_read_arc("gmxc.lvl", &gmxc_count);
 	if (gmxc == ERR_PTR(-EPROBE_DEFER))
 		return -EPROBE_DEFER;
 
-	/* If GMxC is present, prefer that as secondary rail for GX votes */
+	/*
+	 * If GMxC is present, prefer that as secondary rail for GX votes. Some
+	 * SoCs list it in the command DB without any level, use MX there.
+	 */
 	sec_id = IS_ERR_OR_NULL(gmxc) ? "mx.lvl" : "gmxc.lvl";
 
 	/* Build the GX votes */

---
base-commit: d024361c631b3f020a26c07d683e5103404b0fbf
change-id: 20261116-msm-gmxc-fallback-b59be82e6c2d

Best regards,
--  
Venkat Yadlapati <venkat.yadlapati@yahoo.com>

