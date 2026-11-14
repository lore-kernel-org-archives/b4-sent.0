From: Joshua Horne <hornejd@etsu.edu>
Date: Fri, 13 Nov 2026 22:03:21 -0500
Subject: [PATCH 1/5] drm/amd/pm: keep smu8 sclk level lookups within the
 table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-smu8-overdrive-v1-1-763f07bdfca9@etsu.edu>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794625442; l=1580;
 i=hornejd@etsu.edu; s=20261109; h=from:subject:message-id;
 bh=Qw7ty5DZi+616ScsabYegzMjC3dI6GW4j0+vEMg4yZ0=;
 b=a1RH1Nq3WCshMtEv0rpbnrYJ3IMr5u998eGY8joSEyNDTw5z/ZJGR/4hZPM6PcQQwQC1MEU0Q
 ZS8Zgnn5j1TAbv/31Qe7YGPdqbGaqzAP0oKiYYAgJVs14wF8m3xGLWl
X-Developer-Key: i=hornejd@etsu.edu; a=ed25519;
 pk=HNOtiwerBbrJhfhzLHLxj3GDsUH9udRXflqnaI8sQmQ=
X-Endpoint-Received: by B4 Relay for hornejd@etsu.edu/20261109 with auth_id=1469
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smu8_get_sclk_level() returns the table size for a minimum clock above
the highest level and -1 for a maximum clock below the lowest level,
and the callers send that to the SMU as the level index.

This happens each time DPM is started, so at every driver load:
smu8_program_bootup_state() looks up the boot engine clock from the
IntegratedSystemInfo table, which is below the lowest graphics level on
at least some Carrizo VBIOS images (200 MHz vs. 300 MHz on an
A10-8700P), so PPSMC_MSG_SetSclkSoftMax is sent with 0xffffffff. A valid
limit is sent shortly after when the performance level is applied, so it
went unnoticed. The display's minimum engine clock is not taken from the
table either.

Select the nearest level instead.

Fixes: bdecc20a986b ("drm/amd/powerplay: add Carrizo dpm support")
Signed-off-by: Joshua Horne <hornejd@etsu.edu>
---
 drivers/gpu/drm/amd/pm/powerplay/hwmgr/smu8_hwmgr.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/amd/pm/powerplay/hwmgr/smu8_hwmgr.c b/drivers/gpu/drm/amd/pm/powerplay/hwmgr/smu8_hwmgr.c
index 8f82d7c07e8c..f17894b5301f 100644
--- a/drivers/gpu/drm/amd/pm/powerplay/hwmgr/smu8_hwmgr.c
+++ b/drivers/gpu/drm/amd/pm/powerplay/hwmgr/smu8_hwmgr.c
@@ -123,7 +123,9 @@ static uint32_t smu8_get_sclk_level(struct pp_hwmgr *hwmgr,
 	default:
 		break;
 	}
-	return i;
+
+	/* a clock outside of the table selects the nearest level */
+	return clamp(i, 0, (int)table->count - 1);
 }
 
 static uint32_t smu8_get_uvd_level(struct pp_hwmgr *hwmgr,

-- 
2.56.0

