From: =?utf-8?q?Eren_=C3=96zen?= <erenozen@protonmail.com>
Date: Tue, 10 Nov 2026 07:21:56 +0300
Subject: [PATCH 1/3] drm/amd/display: Initialize FRL status polling work
 once at DM init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261110-frl-polling-wq-teardown-v1-1-0ff028d5c35b@protonmail.com>
References: <20261110-frl-polling-wq-teardown-v1-0-0ff028d5c35b@protonmail.com>
In-Reply-To: <20261110-frl-polling-wq-teardown-v1-0-0ff028d5c35b@protonmail.com>
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Fangzhi Zuo <Jerry.Zuo@amd.com>
Cc: amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Eren_=C3=96zen?= <erenozen@protonmail.com>, 
 timur.kristof@gmail.com
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794284542; l=2549;
 i=erenozen@protonmail.com; s=20261110; h=from:subject:message-id;
 bh=4zCR7FWd/Rw2U/71QTZKamg0Naz8wle0ENFip0uSKOY=;
 b=WVNoWmMUWIbkrp0eWabJ8ElOrvblUBCy1lVLDi0tnKc1rpDNNaabvHBdCeJOEzD8zvPY+pgrj
 dJdF8fCvoJ9DGCJVKEb0C6RfMSTvFOYJ8cQ2rN5tkg2vjy3Wly9dzUj
X-Developer-Key: i=erenozen@protonmail.com; a=ed25519;
 pk=tPAwfVmIbYF3QziJ3LcoTIZDU12BsjVK+EkAB9nN1gA=
X-Endpoint-Received: by B4 Relay for erenozen@protonmail.com/20261110 with auth_id=1479
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hdmi_frl_status_polling_work is a single delayed work item shared by the
whole display manager, but it is initialized from
amdgpu_dm_connector_init_helper(), which runs once for every connector.
That helper is also called at runtime from dm_dp_add_mst_connector()
when a DisplayPort MST branch device is plugged in. If an HDMI FRL
stream is active at that moment, the polling work is queued and
re-arming itself every 200ms, and INIT_DELAYED_WORK() on it
reinitializes the timer and work entry of a pending item, which can
corrupt the timer and workqueue state.

The work item belongs to the display manager, not to a connector, so
initialize it, along with its polling delay, once in amdgpu_dm_init()
next to the workqueue it runs on.

Fixes: 5c9b8b27a883 ("drm/amd/display: Tie FRL support into amdgpu_dm")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Eren Özen <erenozen@protonmail.com>
---
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c           | 4 ++++
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c | 2 --
 2 files changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
index 33c73ca9cf..bf2f74d7d9 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
@@ -774,6 +774,10 @@ static int amdgpu_dm_init(struct amdgpu_device *adev)
 
 		dc_init_callbacks(adev->dm.dc, &init_params);
 	}
+
+	adev->dm.hdmi_frl_status_polling_delay_ms = 200;
+	INIT_DELAYED_WORK(&adev->dm.hdmi_frl_status_polling_work,
+			  hdmi_frl_status_polling_work);
 	if (adev->dm.dc->caps.max_links > 0) {
 		adev->dm.hdmi_frl_status_polling_wq =
 			create_singlethread_workqueue("hdmi_frl_status_polling_wq");
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
index e8f050feb6..b1bdb94d74 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
@@ -3327,8 +3327,6 @@ void amdgpu_dm_connector_init_helper(struct amdgpu_display_manager *dm,
 		aconnector->hdmi_hpd_debounce_delay_ms = 0;
 	}
 
-	dm->hdmi_frl_status_polling_delay_ms = 200;
-	INIT_DELAYED_WORK(&dm->hdmi_frl_status_polling_work, hdmi_frl_status_polling_work);
 	/*
 	 * configure support HPD hot plug connector_>polled default value is 0
 	 * which means HPD hot plug not supported

-- 
2.56.0

