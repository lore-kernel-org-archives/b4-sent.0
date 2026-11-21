From: Suyuan Wang <shyckless@gmail.com>
Subject: [PATCH v2 0/2] drm/imagination: Fix leaks in HWRT data set
 handling
Date: Sat, 21 Nov 2026 15:47:18 +0000
Message-Id: <20261121-pvr-hwrt-common-v2-0-9f53bdf954de@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAa9AWsC/yXMQQqDMBBA0avIrDtgJiK2V5Euahx1BBOZqC2Id
 2/U5Vv8v0NkFY7wynZQ3iRK8An0yMANH98zSpsMlFNpDBmcN8Xhqwu6ME3BY5U/HdnCNpY7SNW
 s3MnvOtbv23FtRnbLuYHj+AOOuSqTcwAAAA==
X-Change-ID: 20261121-pvr-hwrt-common-809c2343b3ef
To: alessio.belle@imgtec.com, luigi.santivetti@imgtec.com
Cc: donald.robson@imgtec.com, mripard@kernel.org, 
 dri-devel@lists.freedesktop.org, maarten.lankhorst@linux.intel.com, 
 airlied@gmail.com, simona@ffwll.ch, tzimmermann@suse.de, 
 linux-kernel@vger.kernel.org, imagination@lists.freedesktop.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795276038; l=1054;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=iAyx4VKD3Xv1616eFxfmrsRynviVXNZ24B8giwun1Vc=;
 b=mt/gzNvH8FhV/6IA+g7Buh16qvErqpTF/q1qscdAwycxY2+4UFHd09K3xpXY7hz6p/8lwyYPA
 1sJDj/8t6vECtMAcPFmhuVtJrrTUChVtLzidkrvHvidJBewqMAZZWO7
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Patch 1 is v1 with the Fixes tag corrected: the error path that skips
hwrt_fini_common_fw_structure() came with f1f55ed3ffe4, not with the
commit that added the ioctl (thanks to the Sashiko review).

Patch 2 fixes the other leak that review pointed out: the 32-bit layer
count is truncated into the 16-bit max_rts, so the SRTC and RAA objects
allocated for layers > 1 can be skipped on destroy.

Found with a static analysis tool and checked by hand. Compile tested on
arm64 (W=1, all files that include pvr_hwrt.h); I don't have the
hardware.

Changes in v2:
- 1/2: Fixes tag now points to f1f55ed3ffe4. No code change.
- 2/2: new.

v1: https://lore.kernel.org/all/20261121-pvr-hwrt-common-v1-1-784ce45b782a@gmail.com/
---
Suyuan Wang (2):
      drm/imagination: Destroy the common FW object when HWRT data setup fails
      drm/imagination: Don't truncate the layer count in max_rts

 drivers/gpu/drm/imagination/pvr_hwrt.c | 2 ++
 drivers/gpu/drm/imagination/pvr_hwrt.h | 2 +-
 2 files changed, 3 insertions(+), 1 deletion(-)

