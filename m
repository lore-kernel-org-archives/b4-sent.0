From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/7] drm/panfrost: Resume long jobs instead of resetting,
 and mapping error path fixes
Date: Tue, 10 Nov 2026 07:44:55 +0000
Message-Id: <20261110-panfrost-long-jobs-v1-0-24508939ae8d@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqEMAxA0atI1gZMFRWvIi5qJ2pkaKVxBkG8+
 3R0+Rb/n6AchRW67ITIX1EJPoHyDNxi/cwor2QwhamJqMDN+ikG3fEd/IxrGBWprkrTNtZYR5D
 CLfIkxz3th8f6GVd2+/8E1/UDRvr78XYAAAA=
X-Change-ID: 20261110-panfrost-long-jobs-1643287a2ac1
To: David Airlie <airlied@gmail.com>, 
 Thomas Zimmermann <tzimmermann@suse.de>, 
 =?utf-8?q?Adri=C3=A1n_Larumbe?= <adrian.larumbe@collabora.com>, 
 Steven Price <steven.price@arm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Rob Herring <robh@kernel.org>, Simona Vetter <simona@ffwll.ch>, 
 Maxime Ripard <mripard@kernel.org>, 
 Boris Brezillon <boris.brezillon@collabora.com>
Cc: linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794296695; l=4091;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=spi4oruI9Mu1XmSFEL9ByMYtDiQL6HJu09Q2+nsBdAI=;
 b=doXsrdVgudeHFP9TRuEw+MIqsZP2mBmCWKYTplTnRRshgc9927ATq5m1uebq/BfqiFmglLeoz
 eAcQkNAuu9wCBi9IF9AZT/DL06JdnOf9ibJAASsPdXGrbqvS+2Peg5D
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes problems found running the GLES, Vulkan and OpenCL
conformance tests with Mesa on an Orange Pi Zero2 (Allwinner H616,
Mali-G31 MP2, one shader core, 1 GB of RAM).

Patches 1-3 fix the error paths of BO mapping under memory pressure: a
WARN on an ordinary allocation failure, pages dropped while the cached
sg table still maps them, PTEs left behind by a partial map_pages(),
and the folios of a heap chunk kept after a failed fault, which makes
the next fault in that chunk WARN.

Patches 4-6 change what happens when a job runs into the 500 ms job
timeout. On a small GPU OpenCL kernels and heavy fragment jobs
legitimately run longer, and resetting the GPU loses their work: the
OpenCL CTS Integer Ops long math and Thread Dimensions tests, the
KHR-GLES31 advanced blend mixedSequence test and several dEQP-VK
spirv_assembly fragment cases fail that way. Following the Arm driver's
job scheduling, a job whose slot is still active is soft-stopped and
resumed from JS_TAIL without a reset, hard-stopped if it does not reach
a task boundary within 5 s, and the GPU is reset only if the hard stop
does not take effect either. Patch 4 makes sure a soft-stopped job is
never resumed after a GPU reset (its progress is in the L2 that the
reset discards), and patch 5 makes panfrost_reset() actually wait for
the soft-stops (JOB_INT_JS_STATE is a snapshot, not the live state);
both are needed by patch 6 and fix the reset path on their own.

Patch 7 adds the BOs around an unhandled page fault to the fault
report, which told a texture over-read apart from a kernel problem.

A job that keeps reaching task boundaries is resumed after every
timeout and is never killed. If a limit on the total run time of a job
is wanted, I can add one.

Testing: Orange Pi Zero2 (H616, Mali-G31), Mesa 26.2, with this series
backported to v7.3.3:
- OpenCL CTS Integer Ops quick_long_math/quick_ulong_math and Thread
  Dimensions quick_2d_explicit_local pass (they failed before); dEQP-VK
  spirv_assembly vec4 i8/u64 bit_field_insert count64 fragment cases
  pass in 4-6 s (timed out before); KHR-GLES31 blend_equation_advanced
  test_coherency.mixedSequence passes (failed before); none of them
  resets the GPU;
- a never-ending OpenCL kernel is hard-stopped after 5 s and the GPU
  keeps working;
- dEQP-GLES31 draw_indirect compute_interop large cases in memory
  cgroups of 450-600 MB: the processes get allocation errors or are
  OOM-killed, without a WARN, and the GPU keeps working;
- a forced page fault prints the fault BO report;
- no regressions in dEQP-GLES3 draw/occlusion_query/shaders.loops,
  dEQP-GLES31 compute, KHR-GLES31 compute_shader and a set of OpenCL
  CTS groups.
Each patch builds without warnings with W=1 for arm64 and arm.

These patches were developed with Claude (Anthropic) as a coding assistant:
it investigated the problems, wrote the code and the commit messages. I
reviewed them, and they were tested on an Orange Pi Zero2 (Allwinner H616,
Mali-G31) as described above.

---
Arun Iyengar (7):
      drm/panfrost: Don't WARN when a GEM mapping cannot get its pages
      drm/panfrost: Unwind a failed GPU mapping without dropping its pages
      drm/panfrost: Give back the pages of a heap chunk that failed to map
      drm/panfrost: Don't resume a soft-stopped job after a GPU reset
      drm/panfrost: Wait for the soft-stopped slots with the live slot status
      drm/panfrost: Soft-stop and resume a job that outlives the timeout
      drm/panfrost: Name the BOs around an unhandled page fault

 drivers/gpu/drm/panfrost/panfrost_device.h |   5 +
 drivers/gpu/drm/panfrost/panfrost_job.c    | 214 +++++++++++++++++++++++------
 drivers/gpu/drm/panfrost/panfrost_job.h    |   8 ++
 drivers/gpu/drm/panfrost/panfrost_mmu.c    | 139 +++++++++++++++++--
 4 files changed, 312 insertions(+), 54 deletions(-)
---
base-commit: 8deaade4a5a4ff635df91e246e42139ab2b33f6d
change-id: 20261110-panfrost-long-jobs-1643287a2ac1

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

