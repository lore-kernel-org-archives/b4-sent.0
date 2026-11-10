From: =?utf-8?q?Eren_=C3=96zen?= <erenozen@protonmail.com>
Subject: [PATCH 0/3] drm/amd/display: Fix FRL status polling work lifetime
Date: Tue, 10 Nov 2026 07:21:55 +0300
Message-Id: <20261110-frl-polling-wq-teardown-v1-0-0ff028d5c35b@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/x3MQQqDMBAF0KsMf+2ASSDQXKV0YeNoB0JiJ6UK4
 t0LfQd4J7qYSkeiEyZf7doqErmBkF9TXYV1RiL40Ufn3MiLFd5aKVpX3t/8kcnmtlf2zxBCzFl
 uEjEQNpNFj/98f1zXD1EbqQ1pAAAA
X-Change-ID: 20261110-frl-polling-wq-teardown-2b3336cce9e6
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794284542; l=3048;
 i=erenozen@protonmail.com; s=20261110; h=from:subject:message-id;
 bh=YcYq/sMmQ2Dt4zDzYoXhOXb5tw84PZDjWw85HQWmBF8=;
 b=JNJJ3FzZnLlnZp3PU0D/iAnSIMslTMd9PMPyeRy9A+SR5djYV2JIAwAC3CRzmsa3sFkVweZ7W
 qqlhjon2/GpBccJifSiYV6fU46ifzuTQ4U1eXb/BPm9fNF/tXHte9AE
X-Developer-Key: i=erenozen@protonmail.com; a=ed25519;
 pk=tPAwfVmIbYF3QziJ3LcoTIZDU12BsjVK+EkAB9nN1gA=
X-Endpoint-Received: by B4 Relay for erenozen@protonmail.com/20261110 with auth_id=1479
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HDMI FRL status polling work and its workqueue, added in commit
5c9b8b27a883 ("drm/amd/display: Tie FRL support into amdgpu_dm"), have
three lifetime problems:

1. The delayed work is initialized in amdgpu_dm_connector_init_helper(),
   which also runs at runtime for every new MST connector. A hotplug
   while FRL polling is armed re-initializes a pending delayed work.

2. amdgpu_dm_fini() never cancels the self-rearming work and never
   destroys the workqueue, so the workqueue and its rescuer thread
   leak on every unbind, and the work can run after dc_destroy().

3. If the workqueue allocation fails, amdgpu_dm_atomic_commit_tail()
   still passes the NULL workqueue to queue_delayed_work().

Patch 1 moves the initialization to amdgpu_dm_init(). Patch 2 tears
the work and workqueue down in amdgpu_dm_fini(), and depends on
patch 1. Patch 3 skips queueing when the workqueue does not exist.

These issues were pointed out by an automated review of the
workqueue rename patch earlier this year.

This series should combine cleanly with Timur's pending "Check HDMI
FRL support before creating polling workqueue". With that patch, the
workqueue is NULL on hardware without FRL, and the NULL checks in
patches 2 and 3 handle that case. If his patch lands first, patch 1
needs a trivial rebase because both touch the same context.

Testing:
- Built for x86_64 with GCC 16, no new warnings with W=1 on the
  changed files.
- amdgpu_dm KUnit suite (UML): 1910/1912 pass both with and without
  this series. The two failures are pre-existing
  (dm_test_detect_hides_secondary_tile and
  dm_test_dmub_sw_init_gtt_only_asic).
- Booted on a Cezanne (DCN 2.1) laptop with
  CONFIG_DEBUG_OBJECTS_WORK and CONFIG_DEBUG_OBJECTS_TIMERS: one
  polling workqueue thread, no ODEBUG warnings, and a clean s2idle
  suspend/resume.
- Unbinding amdgpu through sysfs on the same laptop, then counting the
  hdmi_frl_status_polling rescuer threads:
    without this series (Fedora 7.2.15): 1 before, 1 after (leaked)
    with this series:                    1 before, 0 after
  No ODEBUG warnings or splats during the unbind with this series.
- Not tested: MST hotplug with an active HDMI FRL stream, since I
  have no FRL sink or MST hub. Cezanne has no HDMI FRL, so the
  polling work itself never runs on my machine.

Signed-off-by: Eren Özen <erenozen@protonmail.com>
---
Eren Özen (3):
      drm/amd/display: Initialize FRL status polling work once at DM init
      drm/amd/display: Destroy FRL status polling workqueue in amdgpu_dm_fini()
      drm/amd/display: Don't queue FRL status polling on a NULL workqueue

 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c           | 12 +++++++++++-
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c |  2 --
 2 files changed, 11 insertions(+), 3 deletions(-)
---
base-commit: 47df73aa49d1988c8f684b7caf8be6570e966844
change-id: 20261110-frl-polling-wq-teardown-2b3336cce9e6

Best regards,
-- 
Eren Özen <erenozen@protonmail.com>

