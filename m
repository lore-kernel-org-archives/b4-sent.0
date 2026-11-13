From: Hugo Sales <hugo@hsal.es>
Subject: [PATCH v2 0/3] drm/amd/display: Leave self-refresh before an ABM
 level update
Date: Fri, 13 Nov 2026 19:40:37 +0000
Message-Id: <20261113-amdgpu-psr-abm-update-next-v2-0-27ce790856ea@hsal.es>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSwqDMBAA0KvIrDtgRuiiVxEX+UztFIwhkxRBv
 HujLt/m7aCchRVe3Q6Zf6KyxgZ6dOA/Ns6MEpqBenoaYwa0S5hTxaQZrVuwpmALY+StYGDqnaf
 BGfLQgpT5LduVj9Ntre7LvpwjHMcfyxIo634AAAA=
X-Change-ID: 20261113-amdgpu-psr-abm-update-next-de20bc23b12c
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: Roman Li <Roman.Li@amd.com>, 
 Nicholas Kazlauskas <Nicholas.Kazlauskas@amd.com>, 
 Chenyu Chen <chen-yu.chen@amd.com>, amd-gfx@lists.freedesktop.org, 
 dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Hugo Sales <hugo@hsal.es>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2896; i=hugo@hsal.es;
 h=from:subject:message-id; bh=l8jc4NsRdgsccOogzVgaadplkZp52O9iy+YV0TvTNG0=;
 b=owJ4nJvAy8zAJVbLU7f+5A3TBYyn1ZIYsr6nb9M50DXd5PTP5fpTLqQktyk71sg3aGjntxrba
 jysTRN9vbujlIVBjItBVkyRRfeGJwPLxMkzc4qeL4GZw8oEMoSBi1MAJmLPyfA/vquOdUtvm4vd
 Rb9D269WeQsbbuGa9e1+zLrIG2s1+xb5MPyVvRNdHpFba9zBrm+0Ki3khErs/SaXdSIfNJ6yPt7
 XpcIKAAJFSNw=
X-Developer-Key: i=hugo@hsal.es; a=openpgp;
 fpr=193D095149CF7E8737B39064D912B0DB205A91C1
X-Endpoint-Received: by B4 Relay for hugo@hsal.es/default with auth_id=1417
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Writing panel_power_savings while the eDP is in PSR hangs DMUB on a
Cezanne laptop (DCN 2.1). An ABM level change on its own is a fast
update, so the new level reaches DMUB with the panel still in
self-refresh. Chenyu Chen confirmed the same on Renoir

Patch 1 adds helpers that tell whether a PSR or Replay event is already
set on a stream. Patch 2 is the fix. It sets the PSR and Replay
hw_programming events around the DC update that carries the new level,
and clears only the events it set. An event that a full update, a
modeset or a PSR SU dirty rect change set stays set, for that code to
clear. Patch 3 stops amdgpu_dm_commit_planes() from sending the same
level again after the connector update loop sent it, so one level change
leaves self-refresh once

"drm/amd/display: Don't force a modeset when the ABM level changes" [1]
sends property changes down this fast path, so it needs this series first

HDR metadata may have the same problem. When the HDR static metadata
changes while HDR stays on, the commit is a fast update too, and the
connector loop in amdgpu_dm_atomic_commit_tail() sends the new HDR
infopacket to DC with the panel still in self-refresh. I have no panel
with HDR and PSR or Replay to try it on, and the VRR and AVI infopackets
already reach DC the same way. Does an infopacket update in self-refresh
need the same pause?

v2:
- Clear the events right after the DC update, under dc_lock, instead of
  on the next fast commit (Chenyu)
- Only clear the events this update set, so an event that a full
  update, a modeset or a dirty rect change set in the same commit stays
  set
- Add amdgpu_dm_psr_event_is_set() and amdgpu_dm_replay_event_is_set(),
  with KUnit tests
- Send a changed level once per commit, so it leaves self-refresh once

v1: https://lore.kernel.org/r/20261031130002.2335615-1-hugo@hsal.es

[1] https://lore.kernel.org/r/20261102-abm-sysfs-commit-v1-2-e5addfd9539a@hsal.es

---
Hugo Sales (3):
      drm/amd/display: Add helpers to check PSR and Replay events
      drm/amd/display: Leave self-refresh before an ABM level update
      drm/amd/display: Send a changed ABM level once per commit

 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c  |  83 +++++++++++++++--
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_psr.c  |  24 +++++
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_psr.h  |   2 +
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_replay.c   |  25 +++++
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_replay.h   |   3 +
 .../display/amdgpu_dm/tests/amdgpu_dm_psr_test.c   |  60 ++++++++++++
 .../amdgpu_dm/tests/amdgpu_dm_replay_test.c        | 102 +++++++++++++++------
 7 files changed, 263 insertions(+), 36 deletions(-)
---
base-commit: ba496bb837882eb1af58f41572fc289e46c77b8c
change-id: 20261113-amdgpu-psr-abm-update-next-de20bc23b12c

Best regards,
--  
Hugo Sales <hugo@hsal.es>

