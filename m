From: =?utf-8?q?Eren_=C3=96zen?= <erenozen@protonmail.com>
Date: Tue, 10 Nov 2026 07:21:57 +0300
Subject: [PATCH 2/3] drm/amd/display: Destroy FRL status polling workqueue
 in amdgpu_dm_fini()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261110-frl-polling-wq-teardown-v1-2-0ff028d5c35b@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794284542; l=2076;
 i=erenozen@protonmail.com; s=20261110; h=from:subject:message-id;
 bh=nSnFtyY4RWcYmXN82YzydEazOQbnaksZ2tg8UGonC7Y=;
 b=p7xud7+AnHh1+yaI6BBSJlf/a4bYAOe0Mq5UUG/cdz7J/gotbKLmFTjh1JmU3VsGLnkUK8vA1
 yIYVBdeOqnbDLT2P8jn50l7815mOZEWoW8gAAJnj4GWTvxn6Z+0Cf4w
X-Developer-Key: i=erenozen@protonmail.com; a=ed25519;
 pk=tPAwfVmIbYF3QziJ3LcoTIZDU12BsjVK+EkAB9nN1gA=
X-Endpoint-Received: by B4 Relay for erenozen@protonmail.com/20261110 with auth_id=1479
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

amdgpu_dm_init() allocates hdmi_frl_status_polling_wq on every device
with at least one display link, but amdgpu_dm_fini() never destroys it,
unlike the other display manager workqueues. Every unbind or unload of
amdgpu leaks the workqueue and its rescuer thread, and each rebind adds
another one, visible as an extra kworker/R-hdmi_frl_status_polling_wq
thread.

The polling work also re-queues itself every 200ms while an HDMI FRL
stream is active and dereferences dm->dc under dm->dc_lock. Nothing on
the teardown path cancels it, so if it is still pending when
amdgpu_dm_fini() runs, it can run after dc_destroy() and
mutex_destroy(&dm->dc_lock).

Cancel the polling work and destroy its workqueue at the start of
amdgpu_dm_fini(), next to the vblank control workqueue. With the
previous patch, the work item is initialized before the workqueue is
allocated, so checking the workqueue pointer is enough to know that
both are valid, including on the amdgpu_dm_init() error path. This
patch depends on that ordering.

Fixes: 5c9b8b27a883 ("drm/amd/display: Tie FRL support into amdgpu_dm")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Eren Özen <erenozen@protonmail.com>
---
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
index bf2f74d7d9..fed1893d2f 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
@@ -889,6 +889,12 @@ static void amdgpu_dm_fini(struct amdgpu_device *adev)
 		adev->dm.vblank_control_workqueue = NULL;
 	}
 
+	if (adev->dm.hdmi_frl_status_polling_wq) {
+		cancel_delayed_work_sync(&adev->dm.hdmi_frl_status_polling_work);
+		destroy_workqueue(adev->dm.hdmi_frl_status_polling_wq);
+		adev->dm.hdmi_frl_status_polling_wq = NULL;
+	}
+
 	if (adev->dm.idle_workqueue) {
 		if (adev->dm.idle_workqueue->running) {
 			adev->dm.idle_workqueue->enable = false;

-- 
2.56.0

