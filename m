From: Joshua Horne <hornejd@etsu.edu>
Date: Fri, 13 Nov 2026 22:03:22 -0500
Subject: [PATCH 2/5] drm/amd/pm: move smu8_populate_umdpstate_clocks() up
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-smu8-overdrive-v1-2-763f07bdfca9@etsu.edu>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794625442; l=1905;
 i=hornejd@etsu.edu; s=20261109; h=from:subject:message-id;
 bh=icmV43/CUmi9JTSvBavBf9yqPU75EIUiWd54ROphH10=;
 b=7Di0r+wjCP88MGByT7D4MXRavnJh4bNqjOFbaUoSgaCDch4WZ/lYVHmpV4AlPtegHbAyqs9YC
 bFjztJvP1A2CPkaFkUKWJi1cFIqRBQpjFNqP7hHj9gGt1QGB25odhi1
X-Developer-Key: i=hornejd@etsu.edu; a=ed25519;
 pk=HNOtiwerBbrJhfhzLHLxj3GDsUH9udRXflqnaI8sQmQ=
X-Endpoint-Received: by B4 Relay for hornejd@etsu.edu/20261109 with auth_id=1469
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The overdrive support added next updates the UMD pstate clocks from a
new helper placed before smu8_set_power_state_tasks(). Move the function
above it, so that no forward declaration is needed.

No functional change.

Signed-off-by: Joshua Horne <hornejd@etsu.edu>
---
 .../gpu/drm/amd/pm/powerplay/hwmgr/smu8_hwmgr.c    | 24 +++++++++++-----------
 1 file changed, 12 insertions(+), 12 deletions(-)

diff --git a/drivers/gpu/drm/amd/pm/powerplay/hwmgr/smu8_hwmgr.c b/drivers/gpu/drm/amd/pm/powerplay/hwmgr/smu8_hwmgr.c
index f17894b5301f..77ab96bae4b0 100644
--- a/drivers/gpu/drm/amd/pm/powerplay/hwmgr/smu8_hwmgr.c
+++ b/drivers/gpu/drm/amd/pm/powerplay/hwmgr/smu8_hwmgr.c
@@ -848,6 +848,18 @@ static int smu8_update_low_mem_pstate(struct pp_hwmgr *hwmgr, const void *input)
 	return 0;
 }
 
+static void smu8_populate_umdpstate_clocks(struct pp_hwmgr *hwmgr)
+{
+	struct phm_clock_voltage_dependency_table *table =
+				hwmgr->dyn_state.vddc_dependency_on_sclk;
+
+	hwmgr->pstate_sclk = table->entries[0].clk / 100;
+	hwmgr->pstate_mclk = 0;
+
+	hwmgr->pstate_sclk_peak = table->entries[table->count - 1].clk / 100;
+	hwmgr->pstate_mclk_peak = 0;
+}
+
 static int smu8_set_power_state_tasks(struct pp_hwmgr *hwmgr, const void *input)
 {
 	int ret = 0;
@@ -988,18 +1000,6 @@ static void smu8_reset_acp_boot_level(struct pp_hwmgr *hwmgr)
 	data->acp_boot_level = 0xff;
 }
 
-static void smu8_populate_umdpstate_clocks(struct pp_hwmgr *hwmgr)
-{
-	struct phm_clock_voltage_dependency_table *table =
-				hwmgr->dyn_state.vddc_dependency_on_sclk;
-
-	hwmgr->pstate_sclk = table->entries[0].clk / 100;
-	hwmgr->pstate_mclk = 0;
-
-	hwmgr->pstate_sclk_peak = table->entries[table->count - 1].clk / 100;
-	hwmgr->pstate_mclk_peak = 0;
-}
-
 static int smu8_enable_dpm_tasks(struct pp_hwmgr *hwmgr)
 {
 	smu8_program_voting_clients(hwmgr);

-- 
2.56.0

