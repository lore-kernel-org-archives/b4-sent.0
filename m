From: Max Boone <mboone@akamai.com>
Date: Tue, 17 Mar 2026 16:07:45 +0100
Subject: [PATCH] vfio/type1: Retry follow_pfnmap_start() when PFNMAP is
 zapped
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260317-retry-pin-on-reclaimed-pud-v1-1-1f0d0a23f78d@akamai.com>
X-B4-Tracking: v=1; b=H4sIAEBuuWkC/x3MQQqDMBAF0KvIrB3QCLZ6FXGhyU87UGOY2KKId
 zd0+TbvpAQVJOqLkxQ/SbKGjLosyL6n8AKLyyZTmbZq6gcrNj04SuA1ZNjPJAscx69j5+cOpsX
 8tJ5yEBVe9n8+jNd1A2Wt4g5sAAAA
X-Change-ID: 20260317-retry-pin-on-reclaimed-pud-dfb9e26eb8cf
To: Alex Williamson <alex@shazbot.org>
Cc: kvm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Max Boone <mboone@akamai.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773760067; l=2028;
 i=mboone@akamai.com; s=20260317; h=from:subject:message-id;
 bh=b2j73waNF0S5HuzVon7vQ+MYHgI3mNVa+AVmFCvIi3w=;
 b=7xTZNEDX40oqQAxYCRx209sugRRIcmmUHTQXOgPlFSP+GvJ/znoV8z5HCrd3iwy17TATbR+ZE
 Scmbbbu2iNSAQegKpxl0SkrHLBDsmcOHOjVj1zVDbbLDnYUY6mHcsFZ
X-Developer-Key: i=mboone@akamai.com; a=ed25519;
 pk=jWdC/h5H2KWQCiC2kpr/puMVX0mJmP9W5sM8YTGBXA4=
X-Endpoint-Received: by B4 Relay for mboone@akamai.com/20260317 with auth_id=685
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A race between page table walking (e.g. via procfs numa_maps) and VFIO DMA
pinning can lead to temporary failures in follow_pfnmap_start(). When a
PUD entry is split and concurrently refaulted, the PFNMAP mapping may be
temporarily zapped, causing follow_pfnmap_start() to return an error.

Although follow_pfnmap_start() returns an -EINVAL this is not due to
invalid parameters, but rather because of the pfnmap being non-present.
Treat it as such, and retry by returning -EAGAIN, similar to how GUP
handles such races.

This avoids propagating an unexpected -EINVAL to userspace, like follows:
[dma_map]
dma_map iova=0x000000000000 size=0x000004000000 vaddr=0x00007f7800000000
dma_map FAILED iova=0x020000000000: [Errno 22] Invalid argument
dma_map iova=0x040000000000 size=0x000002000000 vaddr=0x00007f5780000000

Which would've succeeded on a retry.

Cc: stable@vger.kernel.org
Fixes: a77f9489f1d7 ("vfio: use the new follow_pfnmap API")
Signed-off-by: Max Boone <mboone@akamai.com>
---
 drivers/vfio/vfio_iommu_type1.c | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/drivers/vfio/vfio_iommu_type1.c b/drivers/vfio/vfio_iommu_type1.c
index 5167bec14..3a0d0bbb9 100644
--- a/drivers/vfio/vfio_iommu_type1.c
+++ b/drivers/vfio/vfio_iommu_type1.c
@@ -559,9 +559,17 @@ static int follow_fault_pfn(struct vm_area_struct *vma, struct mm_struct *mm,
 		if (ret)
 			return ret;
 
+		/*
+		 * follow_pfnmap_start() returns -EINVAL for
+		 * invalid parameters and non-present entries.
+		 * If that happens here after a successful
+		 * fixup_user_fault(), it is likely that the
+		 * pfnmap has been zapped. Retry instead of
+		 * failing.
+		 */
 		ret = follow_pfnmap_start(&args);
 		if (ret)
-			return ret;
+			return -EAGAIN;
 	}
 
 	if (write_fault && !args.writable) {

---
base-commit: 96ca4caf9066f5ebd35b561a521af588a8eb0215
change-id: 20260317-retry-pin-on-reclaimed-pud-dfb9e26eb8cf

Best regards,
-- 
Max Boone <mboone@akamai.com>

