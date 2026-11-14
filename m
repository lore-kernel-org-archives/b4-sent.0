From: Hugo Sales <hugo@hsal.es>
Date: Sat, 14 Nov 2026 23:09:12 +0000
Subject: [PATCH 1/8] drm/amd/display: Drop the unadvertised mode check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-amdgpu-modes-four-v1-1-f11e2a6cd407@hsal.es>
References: <20261114-amdgpu-modes-four-v1-0-f11e2a6cd407@hsal.es>
In-Reply-To: <20261114-amdgpu-modes-four-v1-0-f11e2a6cd407@hsal.es>
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Ray Wu <ray.wu@amd.com>, Fangzhi Zuo <jerry.zuo@amd.com>, 
 Roman Li <roman.li@amd.com>, Alex Hung <alex.hung@amd.com>
Cc: amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Ville_Syrj=C3=A4l=C3=A4?= <ville.syrjala@linux.intel.com>, 
 Aurabindo Pillai <aurabindo.pillai@amd.com>, Hugo Sales <hugo@hsal.es>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2729; i=hugo@hsal.es;
 h=from:subject:message-id; bh=lnT9nVoFlXidbyLYsCe0y4wiJYQVxKPy6EIUZH0LbBw=;
 b=owJ4nJvAy8zAJVbLU7f+5A3TBYyn1ZIYsn68kph8fspS4XBNK2Mrfn4Wv9g9Lq9ucfqa7KtmS
 bMV0iniKOgoZWEQ42KQFVNk0b3hycAycfLMnKLnS2DmsDKBDGHg4hSAicTFMTJsLn0svbRX0ulB
 xrzqTR9PVJnM/Trl1dTqWXoXf00pbTW+w8jQGyN5c/vy9NY3N9+Kf1T+IHxqtoCYfOieb69k1E1
 Fr9fyAgCaXEg9
X-Developer-Key: i=hugo@hsal.es; a=openpgp;
 fpr=193D095149CF7E8737B39064D912B0DB205A91C1
X-Endpoint-Received: by B4 Relay for hugo@hsal.es/default with auth_id=1417
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit fa129ff3b6a7 ("drm/amd/display: warn on unadvertised modes
without scaling") made create_stream_for_sink() log "Unadvertised mode
... with RMX_OFF" when the requested mode isn't one the connector
advertises. Commit 828cfa384e23 ("drm/amd/display: Fix unadvertised mode
detection") made is_duplicate_mode() search connector->modes as well as
probed_modes

mode_config.mutex protects both lists, and atomic_check, where
create_stream_for_sink() runs, holds only the modeset locks. A probe on
another thread can free modes in connector->modes during the walk.
atomic_check can't take mode_config.mutex, since the probe takes it
before connection_mutex

The check's only effect is the debug message, so drop it.
is_duplicate_mode() stays for add_fs_modes()

Fixes: fa129ff3b6a7 ("drm/amd/display: warn on unadvertised modes without scaling")
Fixes: 828cfa384e23 ("drm/amd/display: Fix unadvertised mode detection")
Signed-off-by: Hugo Sales <hugo@hsal.es>
---
Fangzhi, fa129ff3b6a7 says the message is there to advise users to pick
an advertised mode when they see a visual defect. Do you plan to build
more on it, like rejecting such modes or a warning userspace can see? If
you'd rather keep the message, I can do that instead. atomic_check would
take mode_config.mutex with mutex_trylock() and skip the check while a
probe holds it. The walk is then safe, and the message only goes missing
while a probe runs
---
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c | 8 --------
 1 file changed, 8 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
index e8f050feb6e39..89f8427433af0 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
@@ -1495,7 +1495,6 @@ create_stream_for_sink(struct drm_connector *connector,
 	struct drm_display_mode saved_mode;
 	struct drm_display_mode *freesync_mode = NULL;
 	bool recalculate_timing = false;
-	bool unadvertised_mode = false;
 	bool scale = dm_state->scaling != RMX_OFF;
 	int mode_refresh;
 	int preferred_refresh = 0;
@@ -1627,13 +1626,6 @@ create_stream_for_sink(struct drm_connector *connector,
 					&mode, preferred_mode, scale);
 
 			preferred_refresh = drm_mode_vrefresh(preferred_mode);
-			unadvertised_mode = !is_duplicate_mode(aconnector, drm_mode);
-
-			if (unadvertised_mode && dm_state->scaling == RMX_OFF)
-				drm_dbg_driver(dev,
-					       "Unadvertised mode %dx%d@%d with RMX_OFF\n",
-					       drm_mode->hdisplay, drm_mode->vdisplay,
-					       drm_mode_vrefresh(drm_mode));
 		}
 	}
 

-- 
2.56.0

