From: Hugo Sales <hugo@hsal.es>
Subject: [PATCH v2 0/5] drm/amd/display: Commit panel_power_savings writes
 from the kernel
Date: Fri, 13 Nov 2026 20:24:47 +0000
Message-Id: <20261113-abm-sysfs-commit-v2-0-5808d17a7e89@hsal.es>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2WPS26EMBBEr4K8TkfYgDGsco9oFm27PTgKn9gGz
 Wg0d4+BRFlkWVL1q9cPFil4iqwvHizQ5qOfpxzES8HMgNOVwNucmSiF5LzkgHqEeI8ugpnH0Sf
 oJFbKEkcjJctnSyDnbwfy/XLmuOoPMmnn7I3BxzSH+7G58b33ixf/8RuHEqhBa53tmqrDtyHi5
 2vmX54nPdDXmr3TOfmnnb84qLwCHO11WWGJ4RhYF4uJYKJbAkui1EZUmgvTb2L30xjpZ74vNNa
 d1FpVrVKCNEfXKFfzphXOCNVRLU3bamWyzvMbtHizmk4BAAA=
X-Change-ID: 20261101-abm-sysfs-commit-96a38de1ac66
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=6571; i=hugo@hsal.es;
 h=from:subject:message-id; bh=Z+B7EYH/cs0wT10GwtFfFZ6Vmbt0trdeYZW28crr0lk=;
 b=owJ4nJvAy8zAJVbLU7f+5A3TBYyn1ZIYsr4X8Wvaqzzebetyj/E0W/ESY2XPZq0/zAcmHS28b
 bD8VrTkT8aOUhYGMS4GWTFFFt0bngwsEyfPzCl6vgRmDisTyBAGLk4BmIjBQ4b/8YnZug0bss98
 PXL9LqccT6+81PqjOoJ5MpukJ989EqEhxcgwQS3xWnXqm5AN9nzHKt5fsLQLfDPV9Ey5qcuZL5a
 iPJW8AD6bRqQ=
X-Developer-Key: i=hugo@hsal.es; a=openpgp;
 fpr=193D095149CF7E8737B39064D912B0DB205A91C1
X-Endpoint-Received: by B4 Relay for hugo@hsal.es/default with auth_id=1417
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A write to panel_power_savings stores the ABM level and sends a hotplug
uevent, but the level reaches the hardware only on the next atomic commit
that includes the eDP connector. Hyprland adds the connector to a commit
only on a modeset or when a connector property it sets changes, so on my
laptop the file read back the new level and the backlight never changed.
power-profiles-daemon writes this file on every profile and AC change, so
none of its ABM changes applied

This shouldn't need a fix in every compositor. The file is for writers
that aren't the DRM master, like power-profiles-daemon, and they can't
commit anything themselves. Today they depend on the master taking a
generic hotplug uevent as a cue to commit the connector again. Nothing
documents that, and a compositor has no reason to read a hotplug event as
"a property you never touched has changed". A compositor that wants to own
ABM sets the 'adaptive backlight modulation' property, and from then on
the file returns -EBUSY. The file has to work without the master's help.
The backlight device already does: a brightness write goes straight to DC,
with no commit at all

This series makes the write commit the level itself:

  1. Render the existing kernel-doc, which no rst file included
  2. Stop forcing a modeset when the connector's ABM level changes. DM
     already sends a new level as a stream update, and the modeset flag
     dates from before the CRTC was added to such commits
  3. Move the store tests onto a full pipe the store can commit to
  4. Commit the level from the store through a duplicated connector
     state. The write returns the commit's error and no longer sends a
     uevent
  5. KUnit cases for a connector with the CRTC on, off and failing
     atomic check

Patch 2 also asks, below its cut, whether scaling can leave the same
check

v1 of the patch that added this file had no flush [1], and Mario found
that the level only took effect on the next modeset [2]. That patch's v2
changelog says "force an atomic commit" [3], but what was merged, commit
63d0b87213a0 ("drm/amd/display: add panel_power_savings sysfs entry to
eDP connectors"), sends a hotplug event instead

Commit 8d20a066fa9b ("drm/amd/display: change the panel power savings
level without a modeset") later applied the level outside atomic. It
broke igt abm_gradual, and commit 95aaa207e9ef ("Revert "drm/amd/display:
change the panel power savings level without a modeset"") reverted it.
The objections back then were to sysfs overriding the DRM master at all
[4], which the property above now covers. I didn't find any discussion
that rejects an internal atomic commit

A write now returns the commit's error instead of storing a level the
hardware may never get. power-profiles-daemon logs the error and tries
again on its next profile, AC or battery change. Nothing I found reads
the uevent for more than a cue to commit the connector, which the kernel
now does itself

The commit is blocking, so a write can hold the CRTC locks for up to a
frame while a compositor commit waits

Tested on my laptop (ASUS ROG Flow X13 GV301QH, DCN 2.1) with v2 on 7.3,
under Hyprland with no modeset during the run:

  - 25 writes cycling levels 0 to 4 all succeeded and read back, with no
    -EBUSY and nothing in the kernel log. A write sends no uevent
  - I wrote 4, 0, 4, 0, 2 and 0 six seconds apart and read
    amdgpu_current_backlight_pwm and amdgpu_target_backlight_pwm every
    half second. After each 0, the backlight was back at full PWM by the
    next sample. After each 4 or 2, the target dropped, to 25% of full at
    4 and 52% at 2, and the backlight ramped down to it
  - With "drm/amd/display: Leave self-refresh before an ABM level update"
    applied, a commit that changes the level takes the panel out of
    self-refresh. All five writes that changed the level did. Four of
    five writes of the current level left the panel in self-refresh,
    since they no longer commit. The fifth most likely met another screen
    update
  - igt amd_abm passed all five subtests on v1. I haven't rerun it on v2

[1] https://lore.kernel.org/amd-gfx/20240126222300.119292-1-hamza.mahfooz@amd.com/
[2] https://lore.kernel.org/amd-gfx/1162e59e-3f53-4c84-b186-bb2f4642216b@amd.com/
[3] https://lore.kernel.org/amd-gfx/20240202152837.7388-1-hamza.mahfooz@amd.com/
[4] https://lore.kernel.org/amd-gfx/b117ccc0-6569-4753-9cb9-c304f9e50d30@amd.com/

Changes in v2:
- Patch 2: name commit b05e2c5e81f9 ("drm/amd/display: Update ABM crtc
  state on non-modeset") as the one that lets the non-modeset path carry
  the level, say the KMS property loses its modeset too, and
  say "drm/amd/display: Leave self-refresh before an ABM level update"
  has to go first
- Patch 3: set level 2 before the test that writes 0, so the write
  changes the level
- Patch 4: return without a commit when the level doesn't change
  (Harry). A write that changes nothing, or that the DRM master forbids,
  no longer wakes the GPU. A write that a signal interrupts restarts
  instead of failing with -EINTR
- Patch 5: test a write of the current level, check that it and a
  forbidden write leave a runtime-suspended GPU suspended, and fold the
  CRTC on and off cases into one parameterised test
- Link to v1: https://lore.kernel.org/r/20261102-abm-sysfs-commit-v1-0-e5addfd9539a@hsal.es

---
Hugo Sales (5):
      drm/amd/display: Render the panel power savings kernel-doc
      drm/amd/display: Don't force a modeset when the ABM level changes
      drm/amd/display: Give the panel_power_savings store tests a full pipe
      drm/amd/display: Commit panel_power_savings writes from the kernel
      drm/amd/display: Test panel_power_savings commits

 .../gpu/amdgpu/display/display-manager.rst         |   3 +
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c  |   3 +-
 .../amd/display/amdgpu_dm/amdgpu_dm_backlight.c    | 118 ++++++++-
 .../amdgpu_dm/tests/amdgpu_dm_backlight_test.c     | 271 ++++++++++++++++++++-
 4 files changed, 376 insertions(+), 19 deletions(-)
---
base-commit: ba496bb837882eb1af58f41572fc289e46c77b8c
change-id: 20261101-abm-sysfs-commit-96a38de1ac66
prerequisite-change-id: 20261113-amdgpu-psr-abm-update-next-de20bc23b12c:v2
prerequisite-patch-id: c6cbeb4671914753ab7526369c2612039ae16504
prerequisite-patch-id: efc64b5a0a1bc2d46494d4797b0d25447b174076
prerequisite-patch-id: 496307c9687a947cfbfdcf1b6d0ad6ba1b6d4089

Best regards,
--  
Hugo Sales <hugo@hsal.es>

