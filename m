From: =?utf-8?q?Eren_=C3=96zen?= <erenozen@protonmail.com>
Date: Tue, 10 Nov 2026 07:21:58 +0300
Subject: [PATCH 3/3] drm/amd/display: Don't queue FRL status polling on a
 NULL workqueue
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261110-frl-polling-wq-teardown-v1-3-0ff028d5c35b@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794284542; l=1442;
 i=erenozen@protonmail.com; s=20261110; h=from:subject:message-id;
 bh=wLsy0qXzGivFIS3RenLXXCnUX13c+lf2i/HaM9PsxK8=;
 b=mR+ljlJwk2WHYubtbTwRbaDnmBRskhXtjq5q620BGufNFrws1x9+Eh96bJeVCjWQqvlfWV7ME
 7k6oDP58V+lAirwDZ3KlPRpCE5oku0XdIw3J8IiZEdO+cDrVPMbRbFD
X-Developer-Key: i=erenozen@protonmail.com; a=ed25519;
 pk=tPAwfVmIbYF3QziJ3LcoTIZDU12BsjVK+EkAB9nN1gA=
X-Endpoint-Received: by B4 Relay for erenozen@protonmail.com/20261110 with auth_id=1479
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If create_singlethread_workqueue() fails in amdgpu_dm_init(), the
driver only logs an error and continues with
hdmi_frl_status_polling_wq set to NULL. The next atomic commit that
enables an HDMI FRL stream then passes that NULL pointer to
queue_delayed_work() and crashes.

Skip the polling when the workqueue is missing, the same way
amdgpu_dm_atomic_commit_tail() already checks vblank_control_workqueue
before using it. FRL link status is then not polled, but the display
keeps working.

Fixes: 5c9b8b27a883 ("drm/amd/display: Tie FRL support into amdgpu_dm")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Eren Özen <erenozen@protonmail.com>
---
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
index fed1893d2f..798e4401fe 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
@@ -4769,7 +4769,7 @@ static void amdgpu_dm_commit_streams(struct drm_atomic_commit *state,
 			break;
 		}
 	}
-	if (frl_stream_found) {
+	if (frl_stream_found && dm->hdmi_frl_status_polling_wq) {
 		if (queue_delayed_work(dm->hdmi_frl_status_polling_wq,
 				       &dm->hdmi_frl_status_polling_work,
 				       msecs_to_jiffies(dm->hdmi_frl_status_polling_delay_ms)))

-- 
2.56.0

