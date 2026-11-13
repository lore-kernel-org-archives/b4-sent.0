From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v3 00/14] drm/panfrost: Resume long jobs instead of
 resetting, and mapping error path fixes
Date: Fri, 13 Nov 2026 09:02:52 +0000
Message-Id: <20261113-panfrost-long-jobs-v3-0-80ae78d38f6e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NTQ6CMBgFr0K6tqY/iMWV9zAuPtoCJdiSFhsN4
 e62uGFhXE7y3syCgvZGB3QpFuR1NME4m4AfCiR7sJ3GRiVGjLCKUkrwBLb1Lsx4dLbDg2sCplX
 JmTgDA0lROk5et+a1SW/3L4dnM2g5Z1Ne9CbMzr+3aqR59zcQKSaYlScial6DFuraPcCMR+keK
 Aci2yvYTwVLCiCV4EQBV3W9V6zr+gE5qElMCQEAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794560572; l=9448;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=IxtBMMvFFuN/KQnCGzJuFHwoPLZqK+o5uI8iM8M4qlY=;
 b=AgGRGJ87CguVE0DmjQPe+Y1aq48lZg9L2sHejwJ+uQ8lHyyAbWmqu/VBmRGzmbxnLIAN7RQKf
 KGQITZRfa98BXJoH3e/RnCxlS3Z/pin/nCiRwfbqSorncVJQOoA2Ecx
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixes for problems found running the GLES, Vulkan and OpenCL conformance
tests with Mesa on an Orange Pi Zero2 (Allwinner H616, Mali-G31 MP2, one
shader core, 1 GB of RAM), and for problems the Sashiko reviews of v1
and v2 found in the code around them.

Patches 1-3: the reset work touches a runtime or system suspended GPU, a
CPU cache sync of a heap BO walks its sparse page array, and the GPU
fault handler revives a mapping that is being freed.

Patches 4-7, BO mapping error paths under memory pressure: a WARN on an
ordinary allocation failure, pages dropped while the cached sg table
still maps them, PTEs left behind by a partial map_pages(), folios of a
heap chunk kept after a failed fault, and a false WARN for folios larger
than the 2 MB chunk (16K and 64K pages).

Patches 8-11, races around panfrost_reset(): a job cancelled from _NEXT
is taken for done, a job that completes during the reset is reported as
cancelled, a job queued while a reset is pending drops a cycle counter
reference it never took, and such a job is taken for done without having
run. Patch 13 widens these windows.

Patches 12 and 13: a job that runs into the 500 ms timeout no longer
gets the GPU reset. On a small GPU OpenCL kernels and heavy fragment
jobs legitimately run longer: OpenCL CTS Integer Ops long math and
Thread Dimensions, KHR-GLES31 advanced blend mixedSequence and several
dEQP-VK spirv_assembly fragment cases fail that way. As in the Arm
driver, a job whose slot is still active is soft-stopped and resumed
from JS_TAIL, hard-stopped if it has not reached a task boundary after
5 s, and the GPU is reset only if the hard stop fails too. Patch 12
makes panfrost_reset() wait on the live slot status (JOB_INT_JS_STATE is
a snapshot); patch 13 needs it, and it fixes the reset path on its own.

Patch 14 reports the BOs around an unhandled page fault, which told a
texture over-read apart from a kernel problem.

Open points:
- A job that keeps reaching task boundaries is resumed after every
  timeout and never killed. I can add a limit on its total run time.
- While a long job is being stopped (5.5 s at worst), patch 13 keeps the
  job interrupts masked and all schedulers stopped, as panfrost_reset()
  does today around a reset. The other slot starts no job in that time,
  and a job that finishes on it is signalled only afterwards. Over two
  runs of the tests below this took at most 85 ms for a compute job
  (median 0.3 ms, 206 timeouts) and 349 ms for a fragment job (6
  timeouts). Mainline resets the GPU at that point, under the jobs on
  both slots. Stopping only the slot that timed out needs reset.pending,
  the interrupt mask and the scheduler stop made per slot; I can do that
  as a follow-up.
- I can split the independent fixes (1-11, 14) from the soft-stop rework
  (12, 13).

Tested on the Orange Pi Zero2 with Mesa 26.2 and this series backported
to v7.3.3:
- OpenCL CTS Integer Ops quick_long_math/quick_ulong_math, Thread
  Dimensions quick_2d_explicit_local and KHR-GLES31
  blend_equation_advanced test_coherency.mixedSequence pass (failed
  before); dEQP-VK spirv_assembly vec4 i8/u64 bit_field_insert count64
  fragment cases pass in 4-6 s (timed out before). 107 job timeouts, all
  soft-stopped and resumed, no GPU reset.
- A never-ending OpenCL kernel is hard-stopped after 5 s; with the hard
  stop withheld (*), the GPU is reset instead. Both times a devcoredump
  is taken and the GPU keeps working.
- The reset work queued (*) while the GPU is runtime suspended resumes
  it before the reset (patch 1). Queued five times while Integer Ops and
  Thread Dimensions run side by side: both pass. Most of these resets
  found the GPU suspended between two jobs; the trace does not show
  whether a job was on a slot at any of them.
- s2idle entered while the reset work runs (*), and resets requested (*)
  during suspend, idle and under Integer Ops: suspend waits for the
  work, the pending reset runs after resume, Integer Ops passes
  (patch 1).
- With a 200 ms delay before the stop (*) and the cycle counter forced
  on (*): 10 jobs queued while a reset was pending were drained without
  a cycle counter reference (patch 10), one on a slot that had gone idle
  was kept (patch 11), the use count ends at 0, and the tests pass.
- dEQP-GLES31 draw_indirect compute_interop large cases in memory
  cgroups of 450-600 MB: allocation errors or OOM kills, no WARN, and
  the GPU keeps working.
- A forced page fault prints the BO report.
- PANFROST_SYNC_BO fails with -EINVAL on a heap BO and succeeds on a
  plain one.
- No regressions in dEQP-GLES3 draw/occlusion_query/shaders.loops (964
  cases), dEQP-GLES31 compute (195), KHR-GLES31 compute_shader (37, two
  not supported) and 9 OpenCL CTS groups.
(*) test-only module parameter, not part of this series.

The problems patches 1-3 and 8-11 fix were not reproduced. The fixed
paths of patches 1, 2, 10 and 11 ran in the tests above; patches 3, 8
and 9, the larger-folio cases of patches 6 and 7 (4K pages here) and the
races patch 13 handles rest on code review. Each patch builds without
warnings with W=1 for arm64 and arm.

These patches were developed with Claude (Anthropic) as a coding
assistant: it investigated the problems and wrote the code and the
commit messages. I reviewed them, and they were tested as described
above.

---
Changes in v3:
- Patch 1: disable the reset work across system sleep, as
  pm_runtime_force_suspend() ignores the usage count, and queue it again
  on resume if a reset is pending (Sashiko,
  https://lore.kernel.org/all/sashiko-outbox-210830@kernel.org/).
- New patch 7 (Sashiko,
  https://lore.kernel.org/all/sashiko-outbox-210837@kernel.org/).
- New patches 10 and 11 (Sashiko on v2 10/11,
  https://lore.kernel.org/all/sashiko-outbox-210891@kernel.org/).
- Patch 13 (v2 10/11): rebased onto 10.
- All patches: shorter commit messages and comments; no other code
  change.
- Renumbered: v2 7 and 8 are now 8 and 9, v2 9-11 are now 12-14.
- Rebased onto the current drm-misc-next.
- Link to v2: https://patch.msgid.link/20261112-panfrost-long-jobs-v2-0-a06830da3d99@gmail.com

Changes in v2:
- New patches 1-3, 7 and 8, for problems the Sashiko review of v1 found
  in the code around the series (3: by analogy with a finding):
  https://lore.kernel.org/all/sashiko-outbox-206548@kernel.org/
  https://lore.kernel.org/all/sashiko-outbox-206561@kernel.org/
  https://lore.kernel.org/all/sashiko-outbox-206570@kernel.org/
  https://lore.kernel.org/all/sashiko-outbox-206581@kernel.org/
- Patch 6 (v1 3/7): clear the page array range the fault filled, whole
  folios, which can exceed the 2 MB chunk, and leave folios owned by a
  neighbouring chunk alone (Sashiko).
- Patch 10 (v1 6/7), after the Sashiko review: a job that does not stop
  within 5 s gets karma and a devcoredump; a reset asked for while the
  slots are being stopped is done, not dropped; jobs on other slots that
  only had the 10 ms of an ordinary reset are restarted, not failed; a
  job that completes just as its timeout fires no longer triggers a
  reset.
- Patch 11 (v1 7/7): skip mappings whose last reference is gone, and
  drop the "mapped" flag (Sashiko).
- Dropped v1 4/7 ("Don't resume a soft-stopped job after a GPU reset"):
  I have no evidence that a reset loses results of a soft-stopped job,
  and the Arm driver resumes soft-stopped atoms without such a check.
- Cover letter: which paths the tests did not run, what stopping a long
  job costs the other slot, and tests of the GPU reset path.
- Renumbered: v1 1-3 are now 4-6, v1 5-7 are now 9-11.
- Rebased onto the current drm-misc-next.
- Link to v1: https://lore.kernel.org/r/20261110-panfrost-long-jobs-v1-0-24508939ae8d@gmail.com

---
Arun Iyengar (14):
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
      drm/panfrost: Soft-stop and resume a job that outlives the timeout
      drm/panfrost: Name the BOs around an unhandled page fault

 drivers/gpu/drm/panfrost/panfrost_device.c |  26 ++-
 drivers/gpu/drm/panfrost/panfrost_gem.c    |   4 +
 drivers/gpu/drm/panfrost/panfrost_job.c    | 272 +++++++++++++++++++++++------
 drivers/gpu/drm/panfrost/panfrost_job.h    |   4 +
 drivers/gpu/drm/panfrost/panfrost_mmu.c    | 159 +++++++++++++++--
 5 files changed, 396 insertions(+), 69 deletions(-)
---
base-commit: c88084027d0e922dd925b96e5a0d184ba04a8f43
change-id: 20261110-panfrost-long-jobs-1643287a2ac1

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

