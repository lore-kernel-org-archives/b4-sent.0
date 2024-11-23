From: Janne Grunau <j@jannau.net>
Subject: [PATCH v2 0/2] Fix device removal order for Apple dart iommu
Date: Sat, 23 Nov 2024 22:44:03 +0100
Message-Id: <20241123-iommu_apple_dart_ordering-v2-0-cc2ade6dde97@jannau.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKNMQmcC/42NQQ6CMBBFr0JmbQ2tUJCV9zCEVDvCGGmbthAN6
 d2tnMDle8l/f4OAnjBAV2zgcaVA1mQQhwLukzIjMtKZQZSi4uWJM7LzvAzKuRcOWvk4WK9zwoy
 srluUQja85gLy3nl80HtvX/vME4Vo/We/WvnP/lNdOStZq2TbNOdKanm7PJUxajkajNCnlL6zw
 bBJwwAAAA==
X-Change-ID: 20241031-iommu_apple_dart_ordering-558e62671512
To: Mark Kettenis <kettenis@openbsd.org>, Tom Rini <trini@konsulko.com>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Simon Glass <sjg@chromium.org>, Rick Chen <rick@andestech.com>, 
 Leo <ycliang@andestech.com>, Bin Meng <bmeng.cn@gmail.com>
Cc: u-boot@lists.denx.de, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1713; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=vECMh0vXT2dkLSajgRKTGZ08ybszK/IzrNZIMpbD/Pg=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhnQnn6X7VDR4Z5/iXz5zX9Lxc0eONgguY/0y+8aPD4u3r
 LjPH3LNpKOUhUGMi0FWTJElSftlB8PqGsWY2gdhMHNYmUCGMHBxCsBEdDIZ/ifNuFRo23v8ROfO
 MsuOJ/ICtTuvrHwYmOMpw23PG1i7dSLD/8zpn96J+Orna926LPxinqeFU2rsZ65viwqDV2XZtaS
 I8wAA
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Starting with v2024.10 dev_iommu_dma_unmap calls during device removal
trigger a NULL pointer dereference in the Apple dart iommu driver. The
iommu device is removed before its user. The sparsely used DM_FLAG_VITAL
flag is intended to describe this dependency. Add it to the driver.

Adding this flag is unfortunately not enough since the boot routines
except the arm one simply remove all drivers. Add and use a new function
which calls
    dm_remove_devioce_flags(DM_REMOVE_ACTIVE_ALL | DM_REMOVE_NON_VITAL);
    dm_remove_devices_flags(DM_REMOVE_ACTIVE_ALL);
to ensure this order dependency is head consistently.

Signed-off-by: Janne Grunau <j@jannau.net>
---
Changes in v2:
- added Mark's Ab: for Patch 1
- add dm_remove_device_active() and replace existing
  dm_remove_device_flags(DM_REMOVE_ACTIVE_ALL) with it (ignoring test
  code)
- Link to v1: https://lore.kernel.org/r/20241031-iommu_apple_dart_ordering-v1-0-8a6877946d6b@jannau.net

---
Janne Grunau (2):
      iommu: apple: Mark device with DM_FLAG_VITAL
      dm: Add dm_remove_devices_active() for ordered device removal

 arch/arm/lib/bootm.c          |  7 +++---
 arch/riscv/lib/bootm.c        |  2 +-
 arch/x86/lib/bootm.c          |  2 +-
 drivers/core/root.c           |  7 ++++++
 drivers/iommu/apple_dart.c    |  2 +-
 include/dm/root.h             | 10 +++++++++
 lib/efi_loader/efi_boottime.c |  2 +-
 test/dm/core.c                | 50 +++++++++++++++++++++++++++++++++++++++++++
 8 files changed, 74 insertions(+), 8 deletions(-)
---
base-commit: cca05617a8f585f3a98a8fa82f75cc68a530d771
change-id: 20241031-iommu_apple_dart_ordering-558e62671512

Best regards,
-- 
Janne Grunau <j@jannau.net>

