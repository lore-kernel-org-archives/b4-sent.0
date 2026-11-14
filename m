From: Joshua Horne <hornejd@etsu.edu>
Date: Fri, 13 Nov 2026 22:03:25 -0500
Subject: [PATCH 5/5] drm/amd/pm: stop disabling overdrive on Carrizo and
 Stoney
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-smu8-overdrive-v1-5-763f07bdfca9@etsu.edu>
References: <20261113-smu8-overdrive-v1-0-763f07bdfca9@etsu.edu>
In-Reply-To: <20261113-smu8-overdrive-v1-0-763f07bdfca9@etsu.edu>
To: Alex Deucher <alexander.deucher@amd.com>, 
 Kenneth Feng <kenneth.feng@amd.com>
Cc: =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 =?utf-8?q?Timur_Krist=C3=B3f?= <timur.kristof@gmail.com>, 
 Lijo Lazar <lijo.lazar@amd.com>, amd-gfx@lists.freedesktop.org, 
 dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Joshua Horne <hornejd@etsu.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794625442; l=2145;
 i=hornejd@etsu.edu; s=20261109; h=from:subject:message-id;
 bh=VKahiMDOwea9yzvvuGDSewIcoDKB3SmzTv8wZiIV9IQ=;
 b=KErygZMEC8XajtvxXESCTHrx0CU9sOSsqn8cFaSxKmFHw9mnLjjBDAuxxWM8OZAAi0L2f6qMJ
 beK8j/3QEDkAsxbdGhsLSXiBnsQ725mYhH8xNG2f32mAI1jFVHXWtWu
X-Developer-Key: i=hornejd@etsu.edu; a=ed25519;
 pk=HNOtiwerBbrJhfhzLHLxj3GDsUH9udRXflqnaI8sQmQ=
X-Endpoint-Received: by B4 Relay for hornejd@etsu.edu/20261109 with auth_id=1469
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit b7e919b9403f ("drm/amd/pp: Disable OD feature on APU/Iceland")
disabled overdrive on these APUs, which the smu8 backend did not
implement then. Now that it does, let the PP_OVERDRIVE_MASK bit of
amdgpu.ppfeaturemask decide, as on Tonga and newer dGPUs. The bit is
clear by default and taints the kernel when set.

Raven, disabled by the same commit, gained overdrive support with
commit 12a6727dee5d ("drm/amd/powerplay: add one sysfs file to support
the feature to modify gfx clock on Raven/Raven2/Picasso APU.").

Document the pp_od_clk_voltage format for Carrizo and Stoney.

Signed-off-by: Joshua Horne <hornejd@etsu.edu>
---
 drivers/gpu/drm/amd/pm/amdgpu_pm.c             | 6 ++++++
 drivers/gpu/drm/amd/pm/powerplay/hwmgr/hwmgr.c | 1 -
 2 files changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/amd/pm/amdgpu_pm.c b/drivers/gpu/drm/amd/pm/amdgpu_pm.c
index 48c52ac0fc77..aeee31cc08c9 100644
--- a/drivers/gpu/drm/amd/pm/amdgpu_pm.c
+++ b/drivers/gpu/drm/amd/pm/amdgpu_pm.c
@@ -705,6 +705,12 @@ static ssize_t amdgpu_set_pp_table(struct device *dev,
  * "c" (commit) to the file to commit your changes.  If you want to reset to the
  * default power levels, write "r" (reset) to the file to reset them.
  *
+ * < For Carrizo and Stoney APUs >
+ *
+ * As for Vega10 and previous ASICs, without OD_MCLK. The voltages are
+ * those of the graphics (VDDGFX) rail. A level switches to its new clock
+ * and voltage the next time the GPU enters that level.
+ *
  *
  * < For Vega20 and newer ASICs >
  *
diff --git a/drivers/gpu/drm/amd/pm/powerplay/hwmgr/hwmgr.c b/drivers/gpu/drm/amd/pm/powerplay/hwmgr/hwmgr.c
index 4d553be56396..1567b8fa2a6b 100644
--- a/drivers/gpu/drm/amd/pm/powerplay/hwmgr/hwmgr.c
+++ b/drivers/gpu/drm/amd/pm/powerplay/hwmgr/hwmgr.c
@@ -120,7 +120,6 @@ int hwmgr_early_init(struct pp_hwmgr *hwmgr)
 		break;
 	case AMDGPU_FAMILY_CZ:
 		adev->pm.pp_feature &= ~PP_GFXOFF_MASK;
-		hwmgr->od_enabled = false;
 		hwmgr->smumgr_funcs = &smu8_smu_funcs;
 		hwmgr->feature_mask &= ~PP_GFXOFF_MASK;
 		smu8_init_function_pointers(hwmgr);

-- 
2.56.0

