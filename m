From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v5 00/17] drm/panfrost: Resume long jobs instead of
 resetting, and mapping error path fixes
Date: Sat, 28 Nov 2026 17:26:31 +0000
Message-Id: <20261128-panfrost-long-jobs-v5-0-e7d62045a676@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33PQW7DIBAF0KtErEMFg40hq9yj6mICY4coMRG4V
 qvIdy+kGyuysvzSn/c1D5YpBcrssHuwRHPIIY4ltPsdc2ccB+LBl8xAgJZSCn7HsU8xT/wax4F
 f4ilzqRsFpkNAJ1k5vCfqw88T/fz6z/n7dCE3Vak2ziFPMf0+V2dZe28HZskFh6YVxiqLZPxxu
 GG4frh4Y3VghjUBmwQUAoU2SnhU3tpXQq0JtUmoQhiB1BmvTK/plWhWBOhNoqmPqLazGqwjh2t
 iWZY/2VU3FI8BAAA=
X-Change-ID: 20261110-panfrost-long-jobs-1643287a2ac1
To: Boris Brezillon <boris.brezillon@collabora.com>, 
 Rob Herring <robh@kernel.org>, Steven Price <steven.price@arm.com>, 
 =?utf-8?q?Adri=C3=A1n_Larumbe?= <adrian.larumbe@collabora.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795886791; l=4105;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=tbGXclzDNAiP/j4k7NypV21beVZq1GlBQ+HrjBtK+lE=;
 b=T+np9opIWW5EvZmOEOKmlyWVLoHcIjSSqJjNLA98w5T3XAnuVB/jEIK2nxSL2IwqWNsnCWApd
 COUuI0H/kAxCGB6pkX2shyMG2RNdIp3s59q4oiGA2+WQCa0lsdJOPMq
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixes for problems found running the GLES, Vulkan and OpenCL
conformance tests with Mesa on a Mali-G31 (Allwinner H616), and for
problems Sashiko found around them:
- 1-4, 14, 15: reset and timeout paths vs power management, heap BO
  cache sync, a mapping being freed.
- 5-8: BO mapping error paths.
- 9-13: races around panfrost_reset().
- 16: soft-stop and resume a job still active at the timeout.
- 17: name the BOs around an unhandled page fault.

Open points: a job that keeps reaching task boundaries is never killed;
stopping a long job holds all slots (here at most 349 ms); 16 can go
separately.

Tested v4 on v7.3 with Mesa 26.2: no regressions in 1196 dEQP/KHR
cases and 9 OpenCL CTS groups; v5's 15 was run through the reset and
long-job tests. 2-4 and 9-12 were not reproduced.

Developed with Claude (Anthropic) as coding assistant (investigation,
code, commit messages); I reviewed them and ran the tests.

---
Changes in v5:
- Patch 15: job_lock around the mask and the IRQ thread's unmask
  instead of a second mask write (Sashiko on v4). The hard IRQ
  handler still does not touch the GPU while it is suspended.
- Link to v4: https://patch.msgid.link/20261126-panfrost-long-jobs-v4-0-23579629ceca@gmail.com

Changes in v4:
- New patches 1, 14 and 15 (Sashiko on v3). Patch 2 clears
  reset.pending in runtime resume and leaves system sleep to patch 1.
- Shorter commit messages and comments; test results in 1, 6, 7, 14
  and 15.
- Renumbered: v3 1-12 are now 2-13, v3 13 and 14 are now 16 and 17.
- Rebased onto the current drm-misc-next.
- Link to v3: https://patch.msgid.link/20261113-panfrost-long-jobs-v3-0-80ae78d38f6e@gmail.com

Changes in v3:
- Patch 1: disable the reset work across system sleep (Sashiko).
- New patches 7, 10 and 11 (Sashiko); shorter messages and comments.
- Renumbered and rebased onto the current drm-misc-next.
- Link to v2: https://patch.msgid.link/20261112-panfrost-long-jobs-v2-0-a06830da3d99@gmail.com

Changes in v2:
- New patches 1-3, 7 and 8 for Sashiko's findings on v1.
- Patches 6, 10 and 11 reworked and v1 4/7 dropped after Sashiko's review.
- Renumbered and rebased onto the current drm-misc-next.
- Link to v1: https://lore.kernel.org/r/20261110-panfrost-long-jobs-v1-0-24508939ae8d@gmail.com

---
Arun Iyengar (17):
      drm/panfrost: Freeze the reset workqueue during system sleep
      drm/panfrost: Power the GPU up for a reset queued from the MMU code
      drm/panfrost: Refuse to sync the CPU caches of a heap BO
      drm/panfrost: Don't take a reference on a mapping that is being freed
      drm/panfrost: Don't WARN when a GEM mapping cannot get its pages
      drm/panfrost: Unwind a failed GPU mapping without dropping its pages
      drm/panfrost: Give back the pages of a heap chunk that failed to map
      drm/panfrost: Don't WARN for a heap folio a neighbouring chunk filled
      drm/panfrost: Don't signal a job cancelled from _NEXT at a reset as done
      drm/panfrost: Don't cancel a job that completed during a reset
      drm/panfrost: Drop the cycle counter only for a job that holds it
      drm/panfrost: Don't take a job that was never started for done
      drm/panfrost: Wait for the soft-stopped slots with the live slot status
      drm/panfrost: Keep the GPU powered in the job timeout handler
      drm/panfrost: Keep the job interrupts masked during a reset
      drm/panfrost: Soft-stop and resume a job that outlives the timeout
      drm/panfrost: Name the BOs around an unhandled page fault

 drivers/gpu/drm/panfrost/panfrost_device.c |   1 +
 drivers/gpu/drm/panfrost/panfrost_gem.c    |   3 +
 drivers/gpu/drm/panfrost/panfrost_job.c    | 259 ++++++++++++++++++++++-------
 drivers/gpu/drm/panfrost/panfrost_job.h    |   3 +
 drivers/gpu/drm/panfrost/panfrost_mmu.c    | 145 ++++++++++++++--
 5 files changed, 337 insertions(+), 74 deletions(-)
---
base-commit: 8a6e49c8557d3ba0fe4c7f1cb7f428289b13bfed
change-id: 20261110-panfrost-long-jobs-1643287a2ac1

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

