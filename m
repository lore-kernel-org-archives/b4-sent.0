From: Daejun Park <daejun7.park@samsung.com>
Subject: [PATCH v4 0/5] Support for Zoned UFS
Date: Thu, 26 Nov 2026 11:02:08 +0900
Message-Id: <20261126-zoned-ufs-v4b-v4-0-f90239d12a55@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACCTB2sC/x3MQQqAIBBA0avErBswkcCuEi00p5qNhUMSiXdPW
 r7F/wWEEpPA1BVIlFn4jA2m72A9XNwJOTSDVnocBj3ie0YKeG+C2XgMyjnrrFHeBGjNlWjj5//
 NS60fqOeeMl8AAAA=
To: qemu-devel@nongnu.org
Cc: Jeuk Kim <jeuk20.kim@samsung.com>, Paolo Bonzini <pbonzini@redhat.com>, 
 Fam Zheng <fam@euphon.net>, Kevin Wolf <kwolf@redhat.com>, 
 Hanna Reitz <hreitz@redhat.com>, qemu-block@nongnu.org, 
 Fabiano Rosas <farosas@suse.de>, Laurent Vivier <lvivier@redhat.com>, 
 Pierrick Bouvier <pierrick.bouvier@oss.qualcomm.com>, 
 Niklas Cassel <cassel@kernel.org>, Damien Le Moal <dlemoal@kernel.org>, 
 Sam Li <faithilikerun@gmail.com>, Stefan Hajnoczi <stefanha@redhat.com>, 
 Stanley Jhu <stanleyjhu@google.com>, 
 Keoseong Park <keosung.park@samsung.com>, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795658528; l=2731;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=/cLmwNv7b8jTqocxDAfhXcQSLNRD4e5NXiWZaGVu+Rc=;
 b=m63x4e6PgJ2mlQa1jXoOZuIYRXzIE8+Kb/AEA4xkstLq44yUC1SITEmEyCQmGx3j2pkulbfXQ
 Y0JfGuiRscbAPGcaxls4geXigoTahweg+AyxGTB3Co0/8CUtx44XG3s
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series makes a ufs-lu on a host-managed zoned qcow2 image a ZBC
host-managed device, so that f2fs and other zoned software can be
tested on UFS. As Niklas asked [1], the zones live in the image and the
logical unit uses the zoned block layer API.

The ZBC commands are emulated in hw/ufs on top of scsi-hd, which stays
a direct-access device, as scsi-disk serves its mode and VPD pages to
those only. They can move to scsi-disk if the SCSI maintainers prefer.

Tested with the UFS qtests (also under ASan and UBSan) and Linux 7.3-rc7
and android17-6.18 guests, legacy doorbell and MCQ: fio --zonemode=zbd
with verification, blkzone, sg_raw, and f2fs on android17-6.18. One
early android17-6.18 MCQ run retried unaligned writes (data verified),
fourteen later ones did not. Zoned host block devices are untested.

Two qcow2 v18 problems show with qemu-io alone. With detect-zeroes
on, a zero write at the write pointer does not move it, so the next
write fails as unaligned. A resized zoned image overflows its write
pointer table on a write past the old end, and qemu-img resize leaves
it unopenable.

Based-on: <20261124085529.1537572-1-cassel@kernel.org>

Changes in v4:
- Keep the zones in the image and use the zoned block layer API
  (Niklas). Drop the zoned properties and v3's Reviewed-by tags.
- Add patches 1 and 2 for the active zone limit and zone errors.
- Drop patches 1-3 of v3, which are in master.
- Link to v3: https://lore.kernel.org/qemu-devel/20261020001647epcms2p52cd58173164a43e252c33a3eb5935dc8@epcms2p5

[1] https://lore.kernel.org/qemu-devel/at9P9OWMQUQR501_@ryzen

---
Daejun Park (5):
      block: add an accessor for the active zone limit
      scsi-disk: Report zone errors with their ZBC sense codes
      docs/system: Document zoned UFS logical units
      hw/ufs: Support for Zoned UFS
      tests/qtest: Add tests for Zoned UFS

 block/block-backend.c             |   11 +
 docs/system/devices/ufs.rst       |   50 ++
 hw/scsi/scsi-disk.c               |   11 +-
 hw/ufs/lu.c                       |  886 ++++++++++++++++++++-
 hw/ufs/trace-events               |    5 +
 hw/ufs/ufs.c                      |   16 +
 hw/ufs/ufs.h                      |    8 +
 include/block/ufs.h               |   15 +
 include/scsi/utils.h              |    1 +
 include/system/block-backend-io.h |    1 +
 scsi/utils.c                      |   28 +
 tests/qtest/ufs-test.c            | 1587 +++++++++++++++++++++++++++++++++++++
 12 files changed, 2609 insertions(+), 10 deletions(-)
---
base-commit: ca3b685586976cc2a9b759c1e7ab7c184e5aed34
change-id: 20261126-zoned-ufs-v4b-d0aa9a940b4d

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

