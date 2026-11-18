From: =?utf-8?q?Eren_=C3=96zen?= <erenozen@protonmail.com>
Subject: [PATCH v2 0/3] drm/amd/display: Fix FRL status polling work
 lifetime
Date: Wed, 18 Nov 2026 15:10:51 +0300
Message-Id: <20261118-frl-polling-wq-teardown-v2-0-957e61c0b698@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/4XNTQqDMBBA4auEWTslPyitq96juNA40YGYaCLaI
 t691At0+xbfOyBTYspQiwMSbZw5BqiFLgTYsQ0DIfdQC9BSV0opiS55nKP3HAbcF1ypTX3cA+r
 OGFNZSw+qoBAwJ3L8vuRXUwgYOa8xfa7Rpn71v7kplCidk/rel9aU3XNOcY1hatnfbJygOc/zC
 5kZYLrDAAAA
X-Change-ID: 20261110-frl-polling-wq-teardown-2b3336cce9e6
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795003852; l=4876;
 i=erenozen@protonmail.com; s=20261110; h=from:subject:message-id;
 bh=o4xp1XWRc/cv7WWAhJEyxTWE3Q7ktwDyLfzkelJnCZc=;
 b=AgfFfB9uvzQRRPn5Cpfcvxl2Ctp2Doit/H49xJSknhBcNbfN2Sd3Kgdb0xcebzwQHvUuKZ5C9
 uUnV/OtTe8uBjdvR4JQBLMYz3OE0CYYjJ089JVHXCxfswPtY1fd9QRL
X-Developer-Key: i=erenozen@protonmail.com; a=ed25519;
 pk=tPAwfVmIbYF3QziJ3LcoTIZDU12BsjVK+EkAB9nN1gA=
X-Endpoint-Received: by B4 Relay for erenozen@protonmail.com/20261110 with auth_id=1479
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HDMI FRL status polling work and its workqueue, added in commit
5c9b8b27a883 ("drm/amd/display: Tie FRL support into amdgpu_dm"), have
two remaining lifetime problems:

1. Since commit 0e967e086e75 ("drm/amd/display: Extract connector and
   encoder code to amdgpu_dm_connector"), the delayed work is
   initialized in amdgpu_dm_connector_init_helper(), which also runs
   at runtime for every new MST connector. An MST hotplug while FRL
   polling is armed re-initializes a pending delayed work. Because the
   work is only initialized once connectors exist, the cancel that
   commit 8bcad6d7acbb ("drm/amd/display: Stop HDMI FRL status polling
   on fini") added to amdgpu_dm_fini() can also run on a work item
   that was never initialized, if amdgpu_dm_init() fails after the
   workqueue is created but before the first connector is set up.

2. If the workqueue allocation fails, amdgpu_dm_commit_streams() still
   passes the NULL workqueue to queue_delayed_work().

Patch 1 moves the initialization to amdgpu_dm_init(), before the
workqueue is created. Patch 2 skips queueing when the workqueue does
not exist. Patch 3 adds a KUnit test for the MST case of patch 1.

These issues were pointed out by an automated review of the workqueue
rename patch earlier this year.

This series should still combine cleanly with Timur's "Check HDMI FRL
support before creating polling workqueue", which is not in
amd-staging-drm-next yet. With that patch, the workqueue is NULL on
hardware without FRL, and the NULL checks in amdgpu_dm_fini() and in
patch 2 handle that case. If his patch lands first, patch 1 needs a
trivial rebase because both touch the same context.

Testing:
- Built on amd-staging-drm-next 8dd68a79583a with GCC 16. W=1 build
  of amdgpu_dm.o and amdgpu_dm_connector.o: no warnings.
- Booted on a Cezanne laptop with CONFIG_DEBUG_OBJECTS_WORK and
  CONFIG_DEBUG_OBJECTS_TIMERS: one hdmi_frl_status_polling_wq thread,
  no ODEBUG or workqueue warnings, s2idle suspend/resume works. Sysfs
  unbind of amdgpu: the FRL thread count goes from 1 to 0, with no
  warnings.
- amdgpu_dm KUnit suite (UML), with CONFIG_DEBUG_OBJECTS_WORK and
  CONFIG_DEBUG_OBJECTS_TIMERS: all FRL polling and connector init
  tests pass, including the new one from patch 3. Without patch 1,
  the new test fails and ODEBUG reports "init active" on the polling
  work's timer. On this tree the suite needs a local workaround first:
  since commit 48b8c06b05ad ("drm/amd/display: Route connector DDC
  over AUX for native DP sinks"), dm_test_i2c_xfer_no_ddc_pin
  dereferences a NULL ddc->link and crashes the UML kernel. With the
  test given a zeroed dc_link, 1931 of 1932 tests pass. The remaining
  failure, dm_test_fs_caps_dp_vsdb_version, also fails without this
  series.
- v1 testing with a debug-only change that forces the polling work to
  run (lockdep, ODEBUG, about 1200 runs, s2idle, unbind) still applies
  to patch 1.
- Not tested: MST hotplug with an active HDMI FRL stream and real FRL
  link training, since I have no FRL sink or MST hub.

Signed-off-by: Eren Özen <erenozen@protonmail.com>
---
Changes in v2:
- Rebased onto amd-staging-drm-next with the "DC Patches November 16,
  2026" batch.
- Dropped v1 patch 2/3 ("Destroy FRL status polling workqueue in
  amdgpu_dm_fini()"). The same change went in from the DC batch as
  commit 8bcad6d7acbb, as agreed with Wayne Lin:
  https://lore.kernel.org/all/20261113031935.53510-1-Wayne.Lin@amd.com/
- Patch 1: the commit message now also explains the init error path
  in amdgpu_dm_fini().
- Patch 1: Fixes tag corrected to 0e967e086e75, which moved the
  initialization into amdgpu_dm_connector_init_helper() (pointed out
  by sashiko-bot).
- Patch 2 (v1 3/3): trivial rebase over "Move HDMI FRL Polling Outside
  dc_lock". The code change is unchanged. The commit message now
  compares with amdgpu_dm_crtc_set_vblank(); v1 wrongly said
  amdgpu_dm_atomic_commit_tail() checks vblank_control_workqueue.
- New patch 3: KUnit test for patch 1.
- Link to v1: https://lore.kernel.org/r/20261110-frl-polling-wq-teardown-v1-0-0ff028d5c35b@protonmail.com

---
Eren Özen (3):
      drm/amd/display: Initialize FRL status polling work once at DM init
      drm/amd/display: Don't queue FRL status polling on a NULL workqueue
      drm/amd/display: Test connector init with FRL status polling pending

 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c  |  6 +++-
 .../amd/display/amdgpu_dm/amdgpu_dm_connector.c    |  2 --
 .../amdgpu_dm/tests/amdgpu_dm_connector_test.c     | 34 ++++++++++++++++++++++
 3 files changed, 39 insertions(+), 3 deletions(-)
---
base-commit: 8dd68a79583aaf6df6fe4feea3ee9e9f26b02993
change-id: 20261110-frl-polling-wq-teardown-2b3336cce9e6

Best regards,
-- 
Eren Özen <erenozen@protonmail.com>

