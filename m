From: YanXin Li <fadouse@pm.me>
Date: Sun, 22 Nov 2026 20:46:37 +0800
Subject: [PATCH v2] iommufd: reject mmap() of not-yet-finalized objects
 with iommufd_try_inc_users()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-04-iommufd-mmap-uaf-v2-a67fd4229347-v2-1-5c108f208c89@pm.me>
X-B4-Tracking: v=1; b=H4sIACzkAmsC/yWNQQ7CIBBFr2JYOxGGkVavYlwMMCjGtgas0TS9u
 60u38vP+5OqUrJUddxMqsgr1zz0C+B2o8KV+4tAjgsr1OiMQQRPoAny0HVjitB1/ICRE7wQ2DU
 pEuLBUgMcvY4m7Y0JWi2xR5GU37+j0/nPdfQ3Cc+1vi48VwFfuA/XVRW58wdWuQtERlOyjjByg
 9o40oQOrVBrsbWOJcXYiprnL5okshDQAAAA
X-Change-ID: 20261122-b4-04-iommufd-mmap-uaf-v2-a67fd4229347-adb0d1f511c0
To: Jason Gunthorpe <jgg@ziepe.ca>, Kevin Tian <kevin.tian@intel.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>
Cc: Robin Murphy <robin.murphy@arm.com>, Nicolin Chen <nicolinc@nvidia.com>, 
 iommu@lists.linux.dev, linux-kernel@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795351630; l=3039;
 i=fadouse@pm.me; s=b4-relay-20261122; h=from:subject:message-id;
 bh=Z84dv3tFgdoJmnVouiJISUeePaqORmrrqKd4RPqN3QM=;
 b=ToN2PGJXB+5WFnyUW173WnInnUMjF3W3Cd1ZCMQzK9yMGN309zX2gytW39ZMzuE0oIp/aITtJ
 dHH8X6KtIzjATSBu6TXFoRlCD19Gp5zoxCKN65pYAa+fdkUvgcFd4ZG
X-Developer-Key: i=fadouse@pm.me; a=ed25519;
 pk=b4DyzHJDRd8853IHUSKPA5wwzChj8eF4MTnZuyPz1PQ=
X-Endpoint-Received: by B4 Relay for fadouse@pm.me/b4-relay-20261122 with auth_id=1597
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

iommufd_fops_mmap() pins the owner of an mmap region with
refcount_inc_not_zero(&immap->owner->users).  This can also pin an
object still being constructed: IOMMU_VIOMMU_ALLOC publishes its
immap in ictx->mt_mmap before the object is finalized, while
ictx->objects still holds XA_ZERO_ENTRY and obj->users is 1.

A concurrent mmap() can take the reference.  If the creation ioctl
then fails, for example when iommufd_ucmd_respond() faults on a
read-only command buffer, iommufd_object_abort_and_destroy() erases
and frees the immap.  iommufd_object_abort() warns about the extra
users reference; a later VMA close dereferences the freed immap.  On
the unpatched kernel, a CONFIG_IOMMUFD_TEST reproducer reported:

  WARNING: drivers/iommu/iommufd/main.c:126 at iommufd_object_abort
  BUG: KASAN: slab-use-after-free in iommufd_fops_vma_close

The reproducer needs no hardware IOMMU.  On production kernels, this
requires a driver that publishes an mmap region before its creation
ioctl can still fail, such as tegra241-cmdqv on real hardware.

Use iommufd_try_inc_users() to check under the objects xarray lock
that the owner is published before increasing users.  It returns
-EBUSY for an unfinalized object, so mmap() returns -ENXIO.  The mmap
path takes the objects lock under the mt_mmap lock; object teardown
releases the objects lock before erasing the mmap entry.

With this change, a finalized viommu can still be mmap()ed and
unmapped.  In an x86-64 QEMU/KVM guest running mainline after
v7.4-rc3 with Generic KASAN, UBSAN, lockdep, and DEBUG_OBJECTS, 3000
aborted allocations racing two mmap()/munmap() loops produced no
kernel splats.

Fixes: 56e9a0d8e53f ("iommufd: Add mmap interface")
Cc: stable@vger.kernel.org
Signed-off-by: YanXin Li <fadouse@pm.me>
---
Changes in v2:
- Resend via b4 because the archived v1 email gained a blank line in
  the diff context and cannot be applied.
- Shorten the commit message and correct the tested kernel version wording.
- Link to v1: https://lore.kernel.org/r/20261122032416.11746-1-fadouse@pm.me

Test baseline: c44104f3642d
---
 drivers/iommu/iommufd/main.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iommu/iommufd/main.c b/drivers/iommu/iommufd/main.c
index 9a921b15316..f0b4308fe34 100644
--- a/drivers/iommu/iommufd/main.c
+++ b/drivers/iommu/iommufd/main.c
@@ -601,7 +601,7 @@ static int iommufd_fops_mmap(struct file *filp, struct vm_area_struct *vma)
 	mtree_lock(&ictx->mt_mmap);
 	/* vma->vm_pgoff carries a page-shifted start position to an immap */
 	immap = mtree_load(&ictx->mt_mmap, vma->vm_pgoff << PAGE_SHIFT);
-	if (!immap || !refcount_inc_not_zero(&immap->owner->users)) {
+	if (!immap || iommufd_try_inc_users(ictx, immap->owner)) {
 		mtree_unlock(&ictx->mt_mmap);
 		return -ENXIO;
 	}

---
base-commit: c44104f3642da720164042623e4832836aefdd8e
change-id: 20261122-b4-04-iommufd-mmap-uaf-v2-a67fd4229347-adb0d1f511c0

Best regards,
--  
YanXin Li <fadouse@pm.me>

