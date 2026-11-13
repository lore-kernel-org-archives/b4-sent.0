From: Hugo Sales <hugo@hsal.es>
Date: Fri, 13 Nov 2026 20:24:49 +0000
Subject: [PATCH v2 2/5] drm/amd/display: Don't force a modeset when the ABM
 level changes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-abm-sysfs-commit-v2-2-5808d17a7e89@hsal.es>
References: <20261113-abm-sysfs-commit-v2-0-5808d17a7e89@hsal.es>
In-Reply-To: <20261113-abm-sysfs-commit-v2-0-5808d17a7e89@hsal.es>
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>
Cc: Mario Limonciello <mario.limonciello@amd.com>, Ray Wu <ray.wu@amd.com>, 
 Alex Hung <alex.hung@amd.com>, 
 Bhawanpreet Lakha <bhawanpreet.lakha@amd.com>, 
 Ivan Lipski <ivan.lipski@amd.com>, Chenyu Chen <chen-yu.chen@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hugo Sales <hugo@hsal.es>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4107; i=hugo@hsal.es;
 h=from:subject:message-id; bh=xkxTHSYlhA1Rapyn9Rq/uQBMthqBcGbtIpbLJ9hNvwY=;
 b=owJ4nJvAy8zAJVbLU7f+5A3TBYyn1ZIYsr4XCWiXrjWzPLC+v/PkdtcXoVVzVAz1dNbevfC5R
 Jrn4Id3HzI6SlkYxLgYZMUUWXRveDKwTJw8M6fo+RKYOaxMIEMYuDgFYCI7+Rn+yqj8bNYrT1Y3
 +8Vl0Lq25S7zt8pTy3g/xy+q23X4UV9XKMM/7cepD22+Vp9dIdh3e53V6k0R55cUurqrmXWk/nS
 eWbaOFQAJrU1+
X-Developer-Key: i=hugo@hsal.es; a=openpgp;
 fpr=193D095149CF7E8737B39064D912B0DB205A91C1
X-Endpoint-Received: by B4 Relay for hugo@hsal.es/default with auth_id=1417
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

An upcoming patch commits panel_power_savings writes from the kernel
without a modeset. amdgpu_dm_atomic_check() sets connectors_changed on the
CRTC when the connector's ABM level changes, so that commit would fail
with -EINVAL

The flag came in with commit c5892a102182 ("drm/amd/display: Fix dmesg
warning from setting abm level"), which also added the CRTC to the commit.
Setting the level alone left the CRTC out, so no stream update reached DC.
Adding the CRTC is enough for that. Since commit b05e2c5e81f9
("drm/amd/display: Update ABM crtc state on non-modeset"),
dm_update_crtc_state() copies the level from the connector to the CRTC
state on the non-modeset path, and the commit tail sends a changed level
as stream_update.abm_level. Neither needs the planes in the commit. The
commit tail walks the connectors and takes the surfaces from the stream
status in DC

This applies to every commit that changes the level. A compositor that
sets the "adaptive backlight modulation" KMS property no longer gets a
modeset either

The forced modeset also took the panel out of PSR or Panel Replay before
the level reached DC. The non-modeset path relies on "drm/amd/display:
Leave self-refresh before an ABM level update" for that, so it has to be
applied first

Keep the flag for scaling changes, which move the stream's source and
destination rectangles

Signed-off-by: Hugo Sales <hugo@hsal.es>
---
This needs "drm/amd/display: Leave self-refresh before an ABM level
update" [1] applied first. Without it, a level change on the
non-modeset path reaches DC while PSR or Panel Replay is active

[1] https://lore.kernel.org/r/20261113-amdgpu-psr-abm-update-next-v2-0-27ce790856ea@hsal.es

Upstream, a level already reaches DC this way when a compositor commits
the connector after a panel_power_savings write. The store has already
written the level into the current connector state, so the old and new
connector states match and atomic check doesn't ask for a modeset. Only
the CRTC state, which still holds the old level, sees the change. With
this series, the hardware tests in the cover letter apply every level this
way

When a commit changes the level and also has planes on that CRTC, for
example a compositor that sets the property and flips in the same
commit, upstream sends the level to DC twice: from the connector loop in
the commit tail and from amdgpu_dm_commit_planes(). The same already
happens upstream after a panel_power_savings write, when the
compositor's next commit has both the connector and planes. [1] sends it
from the connector loop only

If a level change through the KMS property should still force a modeset,
the store could flag its own commits instead. It would set a flag in
dm_connector_state that atomic check reads to skip connectors_changed.
duplicate_state wouldn't copy the flag, so it only lasts for that one
commit. I think it's simpler to treat the change the same way whoever made
it, but I can send that version

Scaling has been in the same check since commit 3c6d1aeb4342
("drm/amd/display: Fix set scaling doesn's work"). From my reading the
non-modeset path handles it too, as a src/dst stream update, but it
changes the scaler ratio and I can't tell whether DC needs the full
validation for that. Could it go as well?
---
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
index dfbc384fbbdb4..256699cdd0b5c 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
@@ -6304,8 +6304,7 @@ STATIC_IFN_KUNIT int amdgpu_dm_atomic_check(struct drm_device *dev,
 			goto fail;
 		}
 
-		if (dm_old_con_state->abm_level != dm_new_con_state->abm_level ||
-		    dm_old_con_state->scaling != dm_new_con_state->scaling)
+		if (dm_old_con_state->scaling != dm_new_con_state->scaling)
 			new_crtc_state->connectors_changed = true;
 	}
 

-- 
2.56.0

