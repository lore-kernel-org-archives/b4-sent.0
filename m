From: Suyuan Wang <shyckless@gmail.com>
Date: Fri, 13 Nov 2026 00:47:28 +0000
Subject: [PATCH] vfio/spapr: Check the whole IOVA range in
 VFIO_IOMMU_MAP_DMA
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-vfio-spapr-v1-1-e3107da71f5c@gmail.com>
X-B4-Tracking: v=1; b=H4sIAB9e9moC/yXMQQqAIBBA0avIrBNSKairRAvLqaaFiVMSRHfPa
 vkW/1/AGAkZWnFBxERMm89QhYBxsX5GSS4bdKlrpZSRaaJNcrAhSluhLSvdDKZxkIMQcaLzm3X
 9bz6GFcf9PcB9P3bpoIFuAAAA
X-Change-ID: 20261113-vfio-spapr-a5ea0529b39d
To: alex@shazbot.org, tpearson@raptorengineering.com
Cc: linux-kernel@vger.kernel.org, kvm@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794531212; l=3170;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=9BK/s46bs5g6IksgcgM4VCdYbHZgPl56YVsnMO2gB94=;
 b=uG9dqKsbXc/iJ+FJP43GK6Aj4pUwI+80tlxxpH7Pxo8VCcrTLl86bFrFV25OH7nrSaebJ3eyM
 rgtqDGgz8XnDkGxYvgadf+jfa6RcqyEpU2jdjSUgecW8FHRUUyKbL4q
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

VFIO_IOMMU_MAP_DMA checks the request with iommu_tce_put_param_check(),
which only checks one page against the DMA window:

    #define iommu_tce_put_param_check(tbl, ioba, gpa)          \
            (iommu_tce_check_ioba((tbl)->it_page_shift,        \
                            (tbl)->it_offset, (tbl)->it_size,  \
                            (ioba), 1) ||                      \

tce_iommu_ioctl() then maps the whole size:

    ret = iommu_tce_put_param_check(tbl, param.iova, param.vaddr);
    ...
    ret = tce_iommu_build(container, tbl,
                    param.iova >> tbl->it_page_shift,
                    param.vaddr,
                    param.size >> tbl->it_page_shift,
                    direction);

tce_iommu_build() and tce_iommu_build_v2() write one TCE per page,
entry + i for i up to the page count, and nothing below them checks the
index. On PowerNV, iommu_tce_xchg_no_kill() goes through pnv_tce_xchg()
to pnv_tce(), which for a single level table ends with

    return tmp + idx;

where tmp is it_base. So a mapping that starts inside the window and
runs past its end writes TCEs past the end of the table. Each of them
holds the host physical address of one of the caller's pages plus
permission bits. v2 also stores the caller's userspace addresses past
the end of it_userspace, through the same pnv_tce() lookup.

To get there the caller needs an enabled SPAPR TCE container with a
group attached and valid memory behind the whole range (preregistered
for v2), which is what QEMU sets up for device passthrough.

VFIO_IOMMU_UNMAP_DMA already checks the whole range. Do the same for
MAP_DMA. This relies on commit 0b271f7d7f5e ("powerpc/iommu: Fix the
overflow validation in iommu_tce_check_ioba"), before which
iommu_tce_check_ioba() ignored npages, so stable trees need that commit
too.

Found with a static analysis tool and checked by hand.

Fixes: 5ffd229c0273 ("powerpc/vfio: Implement IOMMU driver for VFIO")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested only, I don't have a PowerNV machine to try passthrough.
---
 drivers/vfio/vfio_iommu_spapr_tce.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/vfio/vfio_iommu_spapr_tce.c b/drivers/vfio/vfio_iommu_spapr_tce.c
index 1c0eec228cc6..bf0df5a74963 100644
--- a/drivers/vfio/vfio_iommu_spapr_tce.c
+++ b/drivers/vfio/vfio_iommu_spapr_tce.c
@@ -952,6 +952,13 @@ static long tce_iommu_ioctl(void *iommu_data,
 		if (ret)
 			return ret;
 
+		/* The check above only covers the first page */
+		ret = iommu_tce_check_ioba(tbl->it_page_shift, tbl->it_offset,
+					   tbl->it_size, param.iova,
+					   param.size >> tbl->it_page_shift);
+		if (ret)
+			return ret;
+
 		if (container->v2)
 			ret = tce_iommu_build_v2(container, tbl,
 					param.iova >> tbl->it_page_shift,

---
base-commit: 630059a5a632377b9b7b487baccde92b7ae1dd47
change-id: 20261113-vfio-spapr-a5ea0529b39d

Best regards,
--  
Suyuan Wang <shyckless@gmail.com>

