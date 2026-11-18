From: =?utf-8?q?Eren_=C3=96zen?= <erenozen@protonmail.com>
Date: Wed, 18 Nov 2026 15:10:53 +0300
Subject: [PATCH v2 2/3] drm/amd/display: Don't queue FRL status polling on
 a NULL workqueue
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261118-frl-polling-wq-teardown-v2-2-957e61c0b698@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795003852; l=1573;
 i=erenozen@protonmail.com; s=20261110; h=from:subject:message-id;
 bh=L6rmCXG8rWbzkEb2UeE14jkkgdwDWWDYe5UpCq0jUx8=;
 b=MHC0w+W4PsQGM/SRCe5A+mV5DkXSpx9/eRclAWzq890I57i8dhx0ONdq+MZhHmbj4sDBGVo+t
 ZaDyR51rlVCAsZDK4e4uoWlOQo2Joehbl2Wg1AE0BQanQ4xfepPqlxk
X-Developer-Key: i=erenozen@protonmail.com; a=ed25519;
 pk=tPAwfVmIbYF3QziJ3LcoTIZDU12BsjVK+EkAB9nN1gA=
X-Endpoint-Received: by B4 Relay for erenozen@protonmail.com/20261110 with auth_id=1479
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If create_singlethread_workqueue() fails in amdgpu_dm_init(), the
driver only logs an error and continues with
hdmi_frl_status_polling_wq set to NULL. The next atomic commit whose
state contains an HDMI FRL stream then passes that NULL pointer to
queue_delayed_work(). When the 200ms timer fires,
delayed_work_timer_fn() dereferences it in __queue_work() and the
kernel oopses in softirq context.

Skip the polling when the workqueue is missing, the same way
amdgpu_dm_crtc_set_vblank() only queues vblank control work when
vblank_control_workqueue exists. FRL link status is then not polled,
but the display keeps working.

Fixes: 5c9b8b27a883 ("drm/amd/display: Tie FRL support into amdgpu_dm")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Eren Özen <erenozen@protonmail.com>
---
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
index af7acfbbf9e0..201aba79e43b 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
@@ -4891,7 +4891,7 @@ static void amdgpu_dm_commit_streams(struct drm_atomic_commit *state,
 		}
 	}
 
-	if (frl_stream_found) {
+	if (frl_stream_found && dm->hdmi_frl_status_polling_wq) {
 		if (queue_delayed_work(dm->hdmi_frl_status_polling_wq,
 				       &dm->hdmi_frl_status_polling_work,
 				       msecs_to_jiffies(dm->hdmi_frl_status_polling_delay_ms)))

-- 
2.56.0

