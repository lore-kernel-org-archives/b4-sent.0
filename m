From: Mingcong Bai <jeffbai@aosc.io>
Subject: [PATCH 0/5] drm/xe: enable driver usage on non-4KiB kernels
Date: Wed, 26 Feb 2025 10:00:17 +0800
Message-Id: <20250226-xe-non-4k-fix-v1-0-80f23b5ee40e@aosc.io>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALF1vmcC/x2MQQqAIBAAvyJ7bsEW9dBXooPlVkugoRCC9Pek4
 wzMNCichQtMqkHmR4qk2GEcFGynjwejhM5AmqwmclgZY4poLtyloluJAwftrTPQmztz1/9vXt7
 3A+VGO45fAAAA
X-Change-ID: 20250226-xe-non-4k-fix-6b2eded0a564
To: Lucas De Marchi <lucas.demarchi@intel.com>, 
 =?utf-8?q?Thomas_Hellstr=C3=B6m?= <thomas.hellstrom@linux.intel.com>, 
 Rodrigo Vivi <rodrigo.vivi@intel.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 =?utf-8?q?Jos=C3=A9_Roberto_de_Souza?= <jose.souza@intel.com>, 
 Francois Dugast <francois.dugast@intel.com>, 
 Matthew Brost <matthew.brost@intel.com>, 
 Alan Previn <alan.previn.teres.alexis@intel.com>, 
 Zhanjun Dong <zhanjun.dong@intel.com>, 
 Matt Roper <matthew.d.roper@intel.com>, 
 Mateusz Naklicki <mateusz.naklicki@intel.com>
Cc: Mauro Carvalho Chehab <mauro.chehab@linux.intel.com>, 
 =?utf-8?q?Zbigniew_Kempczy=C5=84ski?= <zbigniew.kempczynski@intel.com>, 
 intel-xe@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Kexy Biscuit <kexybiscuit@aosc.io>, 
 Shang Yatsen <429839446@qq.com>, Mingcong Bai <jeffbai@aosc.io>, 
 stable@vger.kernel.org, Haien Liang <27873200@qq.com>, 
 Shirong Liu <lsr1024@qq.com>, Haofeng Wu <s2600cw2@126.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740535218; l=4506;
 i=jeffbai@aosc.io; s=20250225; h=from:subject:message-id;
 bh=A9ejl1O+HrZTCsb9J1JPq9c6GX36Sh+YgeDcLZTKdjY=;
 b=p9NnNXi4quZqnKVTwOpkskDHDTalG5zIr5IMx0pjwy4MMb3Qu3KeRPlKHo+p2JevzvuVTYXEB
 DJIL+X2VFm8AtaW88Z7RVxswmG86MttPx1Aixfi0/s/jptw8bLFwecj
X-Developer-Key: i=jeffbai@aosc.io; a=ed25519;
 pk=PShXLX1m130BHsde1t/EjBugyyOjSVdzV0dYuYejXYU=
X-Endpoint-Received: by B4 Relay for jeffbai@aosc.io/20250225 with auth_id=349
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series attempts to enable the use of xe DRM driver on non-4KiB
kernel page platforms. This involves fixing the ttm/bo interface, as well
as parts of the userspace API to make use of kernel `PAGE_SIZE' for
alignment instead of the assumed `SZ_4K', it also fixes incorrect usage of
`PAGE_SIZE' in the GuC and ring buffer interface code to make sure all
instructions/commands were aligned to 4KiB barriers (per the Programmer's
Manual for the GPUs covered by this DRM driver).

This issue was first discovered and reported by members of the LoongArch
user communities, whose hardware commonly ran on 16KiB-page kernels. The
patch series began on an unassuming branch of a downstream kernel tree
maintained by Shang Yatsen.[^1]

It worked well but remained sparsely documented, a lot of the work done
here relied on Shang Yatsen's original patch.

AOSC OS then picked it up[^2] to provide Intel Xe/Arc support for users of
its LoongArch port, for which I worked extensively on. After months of
positive user feedback and from encouragement from Kexy Biscuit, my
colleague at the community, I decided to examine its potential for
upstreaming, cross-reference kernel and Intel documentation to better
document and revise this patch.

Now that this series has been tested good (for boot up, OpenGL, and
playback of a standardised set of video samples[^3]... with the exception
of the Intel Arc B580, which seems to segfault at intel-media-driver -
iHD_drv_video.so, but strangely, hardware accelerated video playback works
well with Firefox?) on the following platforms (motherboard + GPU model):

- x86-64, 4KiB kernel page:
    - MS-7D42 + Intel Arc A580
- LoongArch, 16KiB kernel page:
    - XA61200 + GUNNIR DG1 Blue Halberd (Intel DG1)
    - XA61200 + ASRock Arc A380 Challenger ITX OC (Intel Arc 380)
    - XA61200 + Intel Arc 580
    - XA61200 + GUNNIR Intel Arc A750 Photon 8G OC (Intel Arc A750)
    - ASUS XC-LS3A6M + GUNNIR Intel Arc B580 INDEX 12G (Intel Arc B580)

On these platforms, basic functionalities tested good but the driver was
unstable with occasional resets (I do suspect however, that this platform
suffers from PCIe coherence issues, as instability only occurs under heavy
VRAM I/O load):

- AArch64, 4KiB/64KiB kernel pages:
    - ERUN-FD3000 (Phytium D3000) + GUNNIR Intel Arc A750 Photon 8G OC
      (Intel Arc A750)

I think that this patch series is now ready for your comment and review.
Please forgive me if I made any simple mistake or used wrong terminologies,
but I have never worked on a patch for the DRM subsystem and my experience
is still quite thin.

But anyway, just letting you all know that Intel Xe/Arc works on non-4KiB
kernel page platforms (and honestly, it's great to use, especially for
games and media playback)!

[^1]: https://github.com/FanFansfan/loongson-linux/tree/loongarch-xe
[^2]: We maintained Shang Yatsen's patch until our v6.13.3 tree, until
      we decided to test and send this series upstream,
      https://github.com/AOSC-Tracking/linux/tree/aosc/v6.13.3
[^3]: Delicious hot pot!
      https://repo.aosc.io/ahvl/sample-videos-20250223.tar.zst

Suggested-by: Kexy Biscuit <kexybiscuit@aosc.io>
Co-developed-by: Shang Yatsen <429839446@qq.com>
Signed-off-by: Shang Yatsen <429839446@qq.com>
Signed-off-by: Mingcong Bai <jeffbai@aosc.io>
---
Mingcong Bai (5):
      drm/xe/bo: fix alignment with non-4K kernel page sizes
      drm/xe/guc: use SZ_4K for alignment
      drm/xe/regs: fix RING_CTL_SIZE(size) calculation
      drm/xe: use 4K alignment for cursor jumps
      drm/xe/query: use PAGE_SIZE as the minimum page alignment

 drivers/gpu/drm/xe/regs/xe_engine_regs.h |  3 +--
 drivers/gpu/drm/xe/xe_bo.c               |  8 ++++----
 drivers/gpu/drm/xe/xe_guc.c              |  4 ++--
 drivers/gpu/drm/xe/xe_guc_ads.c          | 32 ++++++++++++++++----------------
 drivers/gpu/drm/xe/xe_guc_capture.c      |  8 ++++----
 drivers/gpu/drm/xe/xe_guc_ct.c           |  2 +-
 drivers/gpu/drm/xe/xe_guc_log.c          |  4 ++--
 drivers/gpu/drm/xe/xe_guc_pc.c           |  4 ++--
 drivers/gpu/drm/xe/xe_migrate.c          |  4 ++--
 drivers/gpu/drm/xe/xe_query.c            |  2 +-
 include/uapi/drm/xe_drm.h                |  2 +-
 11 files changed, 36 insertions(+), 37 deletions(-)
---
base-commit: d082ecbc71e9e0bf49883ee4afd435a77a5101b6
change-id: 20250226-xe-non-4k-fix-6b2eded0a564

Best regards,
-- 
Mingcong Bai <jeffbai@aosc.io>

