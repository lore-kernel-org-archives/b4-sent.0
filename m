From: Suyuan Wang <shyckless@gmail.com>
Date: Sat, 21 Nov 2026 15:47:20 +0000
Subject: [PATCH v2 2/2] drm/imagination: Don't truncate the layer count in
 max_rts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-pvr-hwrt-common-v2-2-9f53bdf954de@gmail.com>
References: <20261121-pvr-hwrt-common-v2-0-9f53bdf954de@gmail.com>
In-Reply-To: <20261121-pvr-hwrt-common-v2-0-9f53bdf954de@gmail.com>
To: alessio.belle@imgtec.com, luigi.santivetti@imgtec.com
Cc: donald.robson@imgtec.com, mripard@kernel.org, 
 dri-devel@lists.freedesktop.org, maarten.lankhorst@linux.intel.com, 
 airlied@gmail.com, simona@ffwll.ch, tzimmermann@suse.de, 
 linux-kernel@vger.kernel.org, imagination@lists.freedesktop.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795276038; l=1689;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=o9CYMe+Nds/S6RqTPnGZR4pVb5VMi2qOsqYHSAh9ASQ=;
 b=PN14VgJ1BlQIAM6U2DDGPcc41e4M99u6xxvK7PdP5tg6I+L4uPQ7E7sFuRL3LGTzVG0sXYRYO
 GaQLLPkM09JCMD0/KyVPn0DA24dRqlagax3fkHUkAfs9xwScNAyCf6S
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

hwrt_init_kernel_structure() stores the 32-bit args->layers from
userspace in the 16-bit hwrt->max_rts:

	hwrt->max_rts = args->layers;

hwrt_data_init_fw_structure() then allocates the SRTC and RAA objects
when args->layers > 1, but hwrt_data_fini_fw_structure() only frees them
when hwrt->max_rts > 1. With layers = 0x10000 or 0x10001, max_rts ends
up as 0 or 1, so both firmware objects are leaked when the data set is
destroyed or its creation fails. Any user who can open the render node
can do this with DRM_IOCTL_PVR_CREATE_HWRT_DATASET, and the objects
grow with the layer count.

Make max_rts a u32, like args->layers and the max_rts field of the
firmware's struct rogue_fwif_rta_ctl, so that both checks see the same
value.

Found with a static analysis tool and checked by hand.

Fixes: 6eedddab733b ("drm/imagination: Implement free list and HWRT create and destroy ioctls")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
 drivers/gpu/drm/imagination/pvr_hwrt.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/imagination/pvr_hwrt.h b/drivers/gpu/drm/imagination/pvr_hwrt.h
index 676070b20c3b..7c215e2bd35a 100644
--- a/drivers/gpu/drm/imagination/pvr_hwrt.h
+++ b/drivers/gpu/drm/imagination/pvr_hwrt.h
@@ -74,7 +74,7 @@ struct pvr_hwrt_dataset {
 	struct pvr_free_list *free_lists[ROGUE_FWIF_NUM_RTDATA_FREELISTS];
 
 	/** @max_rts: Maximum render targets for this HWRT data set. */
-	u16 max_rts;
+	u32 max_rts;
 };
 
 struct pvr_hwrt_dataset *

-- 
2.34.1

