From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v2 00/11] drm/panfrost: Resume long jobs instead of
 resetting, and mapping error path fixes
Date: Thu, 12 Nov 2026 08:48:33 +0000
Message-Id: <20261112-panfrost-long-jobs-v2-0-a06830da3d99@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ6CMBBFr0K6dkynIAIr72FYlDLAEGhJi0RDu
 LuAe5cvef/9VQTyTEEU0So8LRzY2R3UJRKm07Yl4HpnoaRKEVHCpG3jXZhhcLaF3lUBME1ild2
 10gbFPpw8Nfw+o8/yx+FV9WTmo3QYHYfZ+c/5uuDh/T1YECSo5CazPM41ZfWjHTUPV+NGUW7b9
 gW3Dxj2xgAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794473314; l=9538;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=mJjrSXChj8hiozxDNnHErnSYufbbEW4Z6NG3wERgC5s=;
 b=Y9zlQhchj2navN4rLe/JJS2hL2/1iv9zJ2p52ZRnkPUhtunv8ykqitzPkOrmFl1/N17wKgmKM
 5APTcha0at8DA2suWWoWD2PA5s+UkwRliTKXef0WfITELveoSil9Rm/
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes problems found running the GLES, Vulkan and OpenCL
conformance tests with Mesa on an Orange Pi Zero2 (Allwinner H616,
Mali-G31 MP2, one shader core, 1 GB of RAM), and problems the Sashiko
review of v1 found in the code around them.

Patches 1-3 are fixes from the v1 review for problems that were already
there: the reset work touching the GPU while it is runtime suspended, a
CPU cache sync of a heap BO walking its sparse page array, and the GPU
fault handler reviving a mapping that is being freed.

Patches 4-6 fix the error paths of BO mapping under memory pressure: a
WARN on an ordinary allocation failure, pages dropped while the cached
sg table still maps them, PTEs left behind by a partial map_pages(),
and the folios of a heap chunk kept after a failed fault, which makes
the next fault in that chunk WARN.

Patches 7 and 8 fix two races in panfrost_reset(): a job waiting in
_NEXT that the reset cancels is taken for done when the running job
completes instead of stopping, and a job that completes while the GPU
is being reset is reported as cancelled. Patch 10 makes both windows
much wider.

Patches 9 and 10 change what happens when a job runs into the 500 ms job
timeout. On a small GPU OpenCL kernels and heavy fragment jobs
legitimately run longer, and resetting the GPU loses their work: the
OpenCL CTS Integer Ops long math and Thread Dimensions tests, the
KHR-GLES31 advanced blend mixedSequence test and several dEQP-VK
spirv_assembly fragment cases fail that way. Following the Arm driver's
job scheduling, a job whose slot is still active is soft-stopped and
resumed from JS_TAIL without a reset, hard-stopped if it does not reach
a task boundary within 5 s, and the GPU is reset only if the hard stop
does not take effect either. Patch 9 makes panfrost_reset() actually
wait for the soft-stops (JOB_INT_JS_STATE is a snapshot, not the live
state); patch 10 needs it, and it fixes the reset path on its own.

Patch 11 adds the BOs around an unhandled page fault to the fault
report, which told a texture over-read apart from a kernel problem.

A job that keeps reaching task boundaries is resumed after every
timeout and is never killed. If a limit on the total run time of a job
is wanted, I can add one.

While a job that outlived the timeout is being stopped, patch 10 keeps
the job interrupts masked and the schedulers of all slots stopped, as
panfrost_reset() does today around a reset, but now for as long as the
job needs to reach a task boundary, 5.5 s at worst (the Arm driver's
JS_HARD_STOP_TICKS_SS and JS_RESET_TICKS_SS). The slot of the long job
is busy with that job either way. What the wait costs is the other slot
(panfrost uses two, one for fragment jobs and one for vertex, tiler and
compute jobs): it starts no new job, and a job that finishes on it is
signalled only when the wait is over. In two runs of the tests below,
the time from stopping the schedulers to starting them again was at
most 85 ms for a compute job (median 0.3 ms, 206 timeouts) and at most
349 ms for a fragment job (6 timeouts). Stopping only the slot that
timed out would avoid that cost, but reset.pending, the interrupt mask
and the scheduler stop are all per device, so that is a larger rework
than I wanted in this series. Mainline resets the GPU at that point,
under the jobs on both slots. I can do the per-slot stop as a follow-up
if you want it.

If you would rather take the independent fixes (1-8, 11) first and look
at the soft-stop rework (9, 10) separately, I can split the series.

Testing: Orange Pi Zero2 (H616, Mali-G31), Mesa 26.2, with this series
backported to v7.3.3:
- OpenCL CTS Integer Ops quick_long_math/quick_ulong_math and Thread
  Dimensions quick_2d_explicit_local pass (they failed before); dEQP-VK
  spirv_assembly vec4 i8/u64 bit_field_insert count64 fragment cases
  pass in 5 s (timed out before); KHR-GLES31 blend_equation_advanced
  test_coherency.mixedSequence passes (failed before); 107 job timeouts
  in these tests, all soft-stopped and resumed, none resets the GPU;
- a never-ending OpenCL kernel is hard-stopped after 5 s, a devcoredump
  of it is taken, and the GPU keeps working;
- with a test-only switch that withholds the hard stop, the GPU is reset
  under that kernel instead: the job ends, a devcoredump of it is taken,
  and the GPU keeps working;
- the reset work, queued with a test-only switch the way the MMU code
  queues it while the GPU is runtime suspended, resumes the GPU before
  it resets it (patch 1), and the GPU keeps working;
- the reset work queued the same way five times while Integer Ops and
  Thread Dimensions run side by side: both pass, and the GPU keeps
  working. Most of these resets found the GPU suspended between two
  jobs; the trace does not show whether a job was on a slot at any of
  them;
- dEQP-GLES31 draw_indirect compute_interop large cases in memory
  cgroups of 450-600 MB: the processes get allocation errors or are
  OOM-killed, without a WARN, and the GPU keeps working;
- a forced page fault prints the fault BO report;
- PANFROST_SYNC_BO fails with -EINVAL on a heap BO and succeeds on a
  plain one;
- no regressions in dEQP-GLES3 draw/occlusion_query/shaders.loops (964
  cases), dEQP-GLES31 compute (195), KHR-GLES31 compute_shader (37, two
  not supported) and 9 OpenCL CTS groups.
The two test-only switches are module parameters on the test kernel,
not part of this series. The problems patches 1-3, 7 and 8 fix were not
reproduced. The fixed paths of patches 1 and 2 run in the tests above;
patches 3, 7 and 8, the larger-folio case of patch 6 and the races
patch 10 now handles rest on code review, as their windows cannot be
forced here.
Each patch builds without warnings with W=1 for arm64 and arm.

These patches were developed with Claude (Anthropic) as a coding assistant:
it investigated the problems, wrote the code and the commit messages. I
reviewed them, and they were tested on an Orange Pi Zero2 (Allwinner H616,
Mali-G31) as described above.

---
Changes in v2:
- New patches 1-3, 7 and 8, for problems the Sashiko review of v1 found
  in the code around the series (1, 2, 7, 8) or by analogy with a
  finding (3):
  https://lore.kernel.org/all/sashiko-outbox-206548@kernel.org/
  https://lore.kernel.org/all/sashiko-outbox-206561@kernel.org/
  https://lore.kernel.org/all/sashiko-outbox-206570@kernel.org/
  https://lore.kernel.org/all/sashiko-outbox-206581@kernel.org/
- Patch 6 (v1 3/7): clear the page array range the fault filled, whole
  folios, which differs from the 2 MB chunk for folios larger than 2 MB,
  and leave folios owned by a neighbouring chunk alone (Sashiko).
- Patch 10 (v1 6/7), after the Sashiko review: a job that does not stop
  within 5 s gets its karma raised and a devcoredump; a reset asked for
  while the slots are being stopped is done instead of dropped; jobs on
  other slots that only had the 10 ms of an ordinary reset are restarted
  as before instead of failed; a job that completes just as its timeout
  fires no longer triggers a reset.
- Patch 11 (v1 7/7): skip mappings whose last reference is gone instead
  of reviving them, drop the "mapped" flag, which said nothing useful,
  and describe what the report can tell apart (Sashiko).
- Dropped v1 4/7 ("Don't resume a soft-stopped job after a GPU reset"),
  and the comments of v1 6/7 that said the same. It assumed that a
  soft-stopped job leaves results in the L2 that a GPU reset then loses.
  I have no evidence of that: it was never observed here, and the Arm
  driver resumes soft-stopped atoms without such a check (its comment in
  kbase_gpu_complete_hw() says the cache is not flushed after a failed
  job chain only on a T60x or with BASE_JD_REQ_SKIP_CACHE_END).
- Cover letter: say which paths the tests did not run, and what stopping
  a long job costs the other slot, with the times measured here; tests
  of the GPU reset path added.
- Patches renumbered: v1 1-3 are now 4-6, v1 5-7 are now 9-11.
- Rebased onto the current drm-misc-next (no conflicts, no code change).
- Link to v1: https://lore.kernel.org/r/20261110-panfrost-long-jobs-v1-0-24508939ae8d@gmail.com

---
Arun Iyengar (11):
      drm/panfrost: Power the GPU up for a reset queued from the MMU code
      drm/panfrost: Refuse to sync the CPU caches of a heap BO
      drm/panfrost: Don't take a reference on a mapping that is being freed
      drm/panfrost: Don't WARN when a GEM mapping cannot get its pages
      drm/panfrost: Unwind a failed GPU mapping without dropping its pages
      drm/panfrost: Give back the pages of a heap chunk that failed to map
      drm/panfrost: Don't signal a job cancelled from _NEXT at a reset as done
      drm/panfrost: Don't cancel a job that completed during a reset
      drm/panfrost: Wait for the soft-stopped slots with the live slot status
      drm/panfrost: Soft-stop and resume a job that outlives the timeout
      drm/panfrost: Name the BOs around an unhandled page fault

 drivers/gpu/drm/panfrost/panfrost_gem.c |   8 +
 drivers/gpu/drm/panfrost/panfrost_job.c | 316 +++++++++++++++++++++++++++-----
 drivers/gpu/drm/panfrost/panfrost_mmu.c | 171 +++++++++++++++--
 3 files changed, 434 insertions(+), 61 deletions(-)
---
base-commit: cb0a63f0c96e8ecb90199eeb99cc2a7fcfa703d4
change-id: 20261110-panfrost-long-jobs-1643287a2ac1

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

