From: Hugo Sales <hugo@hsal.es>
Date: Mon, 16 Nov 2026 14:01:04 +0000
Subject: [PATCH v3 2/6] drm/amd/display: Add the CRTC's planes when the ABM
 level changes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-abm-sysfs-commit-v3-2-7a3d84a5328e@hsal.es>
References: <20261116-abm-sysfs-commit-v3-0-7a3d84a5328e@hsal.es>
In-Reply-To: <20261116-abm-sysfs-commit-v3-0-7a3d84a5328e@hsal.es>
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>
Cc: Mario Limonciello <mario.limonciello@amd.com>, Ray Wu <ray.wu@amd.com>, 
 Alex Hung <alex.hung@amd.com>, 
 Bhawanpreet Lakha <bhawanpreet.lakha@amd.com>, 
 Ivan Lipski <ivan.lipski@amd.com>, Chenyu Chen <chen-yu.chen@amd.com>, 
 David Weber <weber.aulendorf@gmail.com>, 
 Shivam Kalra <shivamkalra98@zohomail.in>, 
 Hamza Mahfooz <hamzamahfooz@linux.microsoft.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hugo Sales <hugo@hsal.es>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2571; i=hugo@hsal.es;
 h=from:subject:message-id; bh=qEE0S9PbkvyPum4bGl1VMgQGUMbMKntSfo2X6VR25RU=;
 b=owJ4nJvAy8zAJVbLU7f+5A3TBYyn1ZIYsn7zzL8b2R3Z9DqkuuSfSMa5K2p3l/+ZnPRA/IiV2
 r2VpZ+jVPU6SlkYxLgYZMUUWXRveDKwTJw8M6fo+RKYOaxMIEMYuDgFYCKXbBn+qSzicZ//LPpJ
 4mvPFcek79awlLNnLf2vPUG+3q2NQ3DRNkaGyZYTS1uOlXW63Jr/jkVzhe+fi9MUrj6eWxVgqLa
 p32QXKwA1Lkup
X-Developer-Key: i=hugo@hsal.es; a=openpgp;
 fpr=193D095149CF7E8737B39064D912B0DB205A91C1
X-Endpoint-Received: by B4 Relay for hugo@hsal.es/default with auth_id=1417
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

An upcoming patch stops a change of the connector's ABM level from
forcing a modeset. The modeset adds every plane on the CRTC to the
commit. Without it, a commit that changes only the level carries the
planes the CRTC check pulls in, which with VRR active is the primary
plane alone. DC then updates the stream with that one surface and drops
an active overlay plane until the next flip

Add the CRTC's planes when the level changes, as atomic check already
does for color management and VRR changes

Signed-off-by: Hugo Sales <hugo@hsal.es>
---
This was reported on v2 [1]. On my laptop (GV301QH, DCN 2.1), with v2
and VRR active, a panel_power_savings write took the overlay off the
screen. The DTN log went from four pipes, primary and overlay each split
over two, to the two primary ones, and a flip of both planes brought the
overlay back. With VRR off, the overlay stayed. With this patch, it
stayed with VRR on too, and all four pipes were still there after the
write

This only covers commits that change the ABM level. From my reading,
other commits that add the CRTC but no planes, like a change of the HDR
metadata, can drop an overlay the same way while VRR is active. That
needs a fix in the CRTC check that pulls in only the primary plane, which
I'll send as a separate series

[1] https://lore.kernel.org/all/sashiko-outbox-213691@kernel.org/
---
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
index dfbc384fbbdb4..cf75450066451 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
@@ -6307,6 +6307,20 @@ STATIC_IFN_KUNIT int amdgpu_dm_atomic_check(struct drm_device *dev,
 		if (dm_old_con_state->abm_level != dm_new_con_state->abm_level ||
 		    dm_old_con_state->scaling != dm_new_con_state->scaling)
 			new_crtc_state->connectors_changed = true;
+
+		/*
+		 * With VRR active, the CRTC check adds only the primary plane,
+		 * and DC would drop any other plane from the stream
+		 */
+		if (dm_old_con_state->abm_level != dm_new_con_state->abm_level) {
+			ret = drm_atomic_add_affected_planes(state, new_con_state->crtc);
+			if (ret) {
+				drm_dbg_atomic(dev,
+					       "drm_atomic_add_affected_planes() failed: %pe\n",
+					       ERR_PTR(ret));
+				goto fail;
+			}
+		}
 	}
 
 	if (dc_resource_is_dsc_encoding_supported(dc)) {

-- 
2.56.0

