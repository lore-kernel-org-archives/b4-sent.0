From: Suyuan Wang <shyckless@gmail.com>
Date: Sat, 21 Nov 2026 15:29:18 +0000
Subject: [PATCH] drm/imagination: Destroy the common FW object when HWRT
 data setup fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-pvr-hwrt-common-v1-1-784ce45b782a@gmail.com>
X-B4-Tracking: v=1; b=H4sIAM24AWsC/yXMMQ6DMAxA0asgz1giBjJwFcRAgwFXIkEOUCTE3
 Unb8Q3/XxBZhSM02QXKh0QJPsHkGbi59xOjDMlABVljyOB6KM4f3dCFZQkey9LWNfXEthohVav
 yKOfv2HZ/x/31Zrd9N3DfD/nSUn5zAAAA
X-Change-ID: 20261121-pvr-hwrt-common-336552a2e64f
To: luigi.santivetti@imgtec.com, alessio.belle@imgtec.com
Cc: linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 maarten.lankhorst@linux.intel.com, tzimmermann@suse.de, airlied@gmail.com, 
 imagination@lists.freedesktop.org, simona@ffwll.ch, mripard@kernel.org, 
 donald.robson@imgtec.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795274958; l=1761;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=gTwojV2jRtpN5KQz6nKYwAtp0ctHyB+2xD/Uq99tn18=;
 b=fUJWQ3b9eG2WOJijLLHTxd2hrgzc3IQsxR9Wa1uYizjt7UAmN0zr4RFfmXTC0DUwM0xAaI1R+
 a7k+iYFMlEbBng0sRa0TQdAKsfgNfKlS8QiHdzy/H90yh4hlipzRQ+B
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

If hwrt_data_init_fw_structure() fails in pvr_hwrt_dataset_create(),
the error path frees the per-data FW structures and then jumps straight
to err_fini_kernel_structure, skipping hwrt_fini_common_fw_structure().
The common FW object created just before is never destroyed, and its
init callback data is the hwrt that is then freed:

	err = pvr_fw_object_create(pvr_dev, ...,
				   hwrtdata_common_init, hwrt,
				   &hwrt->common_fw_obj);

Besides leaking the object, this leaves it on the device's FW object
list, so a later pvr_fw_hard_reset() calls hwrtdata_common_init() with
the freed hwrt, and pvr_fw_fini() warns that the list is not empty.

Destroy the common FW object on that path, in the same order as
pvr_hwrt_dataset_release().

Found with a static analysis tool and checked by hand.

Fixes: 6eedddab733b ("drm/imagination: Implement free list and HWRT create and destroy ioctls")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested on arm64 with clang (W=1, no new warnings). I don't have PowerVR hardware.
---
 drivers/gpu/drm/imagination/pvr_hwrt.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/gpu/drm/imagination/pvr_hwrt.c b/drivers/gpu/drm/imagination/pvr_hwrt.c
index 05c68c78da22..6057f8dd1eaf 100644
--- a/drivers/gpu/drm/imagination/pvr_hwrt.c
+++ b/drivers/gpu/drm/imagination/pvr_hwrt.c
@@ -487,6 +487,8 @@ pvr_hwrt_dataset_create(struct pvr_file *pvr_file,
 	while (--i >= 0)
 		hwrt_data_fini_fw_structure(hwrt, i);
 
+	hwrt_fini_common_fw_structure(hwrt);
+
 err_fini_kernel_structure:
 	hwrt_fini_kernel_structure(hwrt);
 



