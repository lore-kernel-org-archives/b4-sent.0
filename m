From: =?utf-8?q?Eren_=C3=96zen?= <erenozen@protonmail.com>
Date: Wed, 18 Nov 2026 15:10:52 +0300
Subject: [PATCH v2 1/3] drm/amd/display: Initialize FRL status polling work
 once at DM init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261118-frl-polling-wq-teardown-v2-1-957e61c0b698@protonmail.com>
References: <20261118-frl-polling-wq-teardown-v2-0-957e61c0b698@protonmail.com>
In-Reply-To: <20261118-frl-polling-wq-teardown-v2-0-957e61c0b698@protonmail.com>
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Fangzhi Zuo <Jerry.Zuo@amd.com>, Chenyu Chen <chen-yu.chen@amd.com>, 
 Bhawanpreet Lakha <bhawanpreet.lakha@amd.com>, 
 Alex Hung <alex.hung@amd.com>
Cc: Wayne Lin <Wayne.Lin@amd.com>, 
 =?utf-8?q?Timur_Krist=C3=B3f?= <timur.kristof@gmail.com>, 
 amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Eren_=C3=96zen?= <erenozen@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795003852; l=3225;
 i=erenozen@protonmail.com; s=20261110; h=from:subject:message-id;
 bh=acr9azNHV4DrR5AOD/x83axcCIQ8+yKBRupLY4OPr38=;
 b=QwOf7v5a8WSFCoej3uB8MXnl8fZP6UenjHa4qtEEAeDHvZhKMP1RuR3QmToxu6G90Zt8q9Izz
 9QyqH/JsQjwCJN+uTziUFTTrykKCkSiLBgO+O6hED1ZXYXqjkmOZ/DV
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

This also keeps the work valid on the amdgpu_dm_init() error path.
Commit 8bcad6d7acbb ("drm/amd/display: Stop HDMI FRL status polling on
fini") cancels the work in amdgpu_dm_fini() whenever the workqueue
exists. The workqueue is created before amdgpu_dm_initialize_drm_device(),
but the work was only initialized when the first connector was set up.
If amdgpu_dm_init() failed in between, for example when allocating
dmub_notify or delayed_hpd_wq, the cancel ran on a work item that was
never initialized and hit WARN_ON(!work->func) in __flush_work(). With
the work initialized first, it is valid whenever the workqueue exists.

Fixes: 0e967e086e75 ("drm/amd/display: Extract connector and encoder code to amdgpu_dm_connector")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Eren Özen <erenozen@protonmail.com>
---
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c           | 4 ++++
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c | 2 --
 2 files changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
index 3d2201285888..af7acfbbf9e0 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
@@ -773,6 +773,10 @@ static int amdgpu_dm_init(struct amdgpu_device *adev)
 
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
index 1bc8547d5777..35d975262114 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
@@ -3331,8 +3331,6 @@ void amdgpu_dm_connector_init_helper(struct amdgpu_display_manager *dm,
 		aconnector->hdmi_hpd_debounce_delay_ms = 0;
 	}
 
-	dm->hdmi_frl_status_polling_delay_ms = 200;
-	INIT_DELAYED_WORK(&dm->hdmi_frl_status_polling_work, hdmi_frl_status_polling_work);
 	/*
 	 * configure support HPD hot plug connector_>polled default value is 0
 	 * which means HPD hot plug not supported

-- 
2.56.0

