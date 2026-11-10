From: Joshua Horne <hornejd@etsu.edu>
Date: Mon, 09 Nov 2026 21:01:45 -0500
Subject: [PATCH] drm/amd/pm: send smu8 sclk level indices, not the level
 mask
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-smu8-sclk-fix-v1-1-47c6c0c8c2c9@etsu.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQwNL3eLcUgvd4uScbN20zApdo9TE5KREo+SktGQDJaCegqJUoDDYvOh
 YCL+4NCkrNbkEZIhSbS0A6099aHEAAAA=
X-Change-ID: 20261109-smu8-sclk-fix-2eacba2cbfc0
To: Kenneth Feng <kenneth.feng@amd.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Eric Huang <JinHuiEric.Huang@amd.com>
Cc: amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Joshua Horne <hornejd@etsu.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794276267; l=3289;
 i=hornejd@etsu.edu; s=20261109; h=from:subject:message-id;
 bh=58O5MHeXCEaVD9HsyyZFkQq4n4nbwD/ow9aQHlfmGAI=;
 b=7NCjH5LDUPWBhzAljm0F65Im6wf9GUvisZyEkg17V/rX8UK+kyCSlYt68xZyk4rCmJRF7jaLM
 Uw13hNjQa9bD3HQbVNQ4VUXfHUjJlhwfDY+OtCcgmAqm6N/JfXh4qna
X-Developer-Key: i=hornejd@etsu.edu; a=ed25519;
 pk=HNOtiwerBbrJhfhzLHLxj3GDsUH9udRXflqnaI8sQmQ=
X-Endpoint-Received: by B4 Relay for hornejd@etsu.edu/20261109 with auth_id=1469
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smu8_force_clock_level() passes the pp_dpm_sclk level mask straight to
PPSMC_MSG_SetSclkSoftMin and PPSMC_MSG_SetSclkSoftMax, which take a
level index, as the other smu8 callers do through smu8_get_sclk_level().
In manual mode, "echo 0 > pp_dpm_sclk" thus selects level 1, "echo 2"
selects level 4, and masks above the highest level index are out of
range for the SMU, so e.g. "echo 3", "echo 7" or "echo 0 1 2 3 4 5 6 7"
do not select the requested levels. The original single level version
sent 1 << level and had the same problem.

Send the lowest and highest level in the mask, as smu10 does, and reject
levels above those the SMU has enabled, as smu10 and vega20 do.

Fixes: d7341ef66870 ("drm/amd/powerplay: add some hwmgr functions for sysfs interface on Carrizo")
Signed-off-by: Joshua Horne <hornejd@etsu.edu>
---
I found this while working on overdrive support for Carrizo/Stoney on my
laptop (ASUS X555DA, A10-8700P); that series will follow separately.

Tested on that laptop, 7.3.1 with this patch applied to amdgpu. In manual
mode:
- "echo N > pp_dpm_sclk" for each N from 0 to 7 moves the current level
  marker to N
- under GPU load, "echo 2 3 4 5" keeps the clock between levels 2 and 5,
  and "echo 0 1 2 3 4 5 6 7" lets it reach level 7 again
- "echo 8" and "echo 0 8" fail with -EINVAL and leave the level unchanged
Without the patch, "echo 0" selected level 1, "echo 3" and "echo 7" did not
select the requested level, and "echo 8" was accepted.
On amd-staging-drm-next the patch applies unchanged and builds without new
warnings with W=1, sparse and smatch.

I used an AI coding assistant (Claude Code) while working on this. It
found the bug, wrote the change and a draft of the changelog, and wrote
and ran the build checks and test scripts. I reviewed the change and the
changelog, ran the tests on my hardware, and I am responsible for the
patch.
---
 drivers/gpu/drm/amd/pm/powerplay/hwmgr/smu8_hwmgr.c | 14 ++++++++++++--
 1 file changed, 12 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/amd/pm/powerplay/hwmgr/smu8_hwmgr.c b/drivers/gpu/drm/amd/pm/powerplay/hwmgr/smu8_hwmgr.c
index 8f82d7c07e8c..5a3f697a37a2 100644
--- a/drivers/gpu/drm/amd/pm/powerplay/hwmgr/smu8_hwmgr.c
+++ b/drivers/gpu/drm/amd/pm/powerplay/hwmgr/smu8_hwmgr.c
@@ -1483,15 +1483,25 @@ static int smu8_store_cc6_data(struct pp_hwmgr *hwmgr, uint32_t separation_time,
 static int smu8_force_clock_level(struct pp_hwmgr *hwmgr,
 		enum pp_clock_type type, uint32_t mask)
 {
+	struct phm_clock_voltage_dependency_table *table =
+				hwmgr->dyn_state.vddc_dependency_on_sclk;
+	uint32_t low, high;
+
 	switch (type) {
 	case PP_SCLK:
+		/* the SMU takes level indices, not a mask of levels */
+		low = mask ? (ffs(mask) - 1) : 0;
+		high = mask ? (fls(mask) - 1) : 0;
+		if (high >= min(table->count, smu8_get_max_sclk_level(hwmgr)))
+			return -EINVAL;
+
 		smum_send_msg_to_smc_with_parameter(hwmgr,
 				PPSMC_MSG_SetSclkSoftMin,
-				mask,
+				low,
 				NULL);
 		smum_send_msg_to_smc_with_parameter(hwmgr,
 				PPSMC_MSG_SetSclkSoftMax,
-				mask,
+				high,
 				NULL);
 		break;
 	default:

---
base-commit: 47df73aa49d1988c8f684b7caf8be6570e966844
change-id: 20261109-smu8-sclk-fix-2eacba2cbfc0

