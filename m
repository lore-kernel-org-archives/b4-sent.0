From: Janne Grunau <j@jannau.net>
Subject: [PATCH v3 0/4] Fix IOVA allocation in Apple dart iommu after
 global LMB mem map changes
Date: Mon, 11 Nov 2024 07:56:30 +0100
Message-Id: <20241111-io_lmb_apple_dart_iommu-v3-0-32c05da51d72@jannau.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJ6qMWcC/4XN0Q6CIBTG8VdxXEcDJM2ueo/WGMghaQkOlNWc7
 x56VRety/+3nd+ZUYRgIaJTMaMAyUbrXY5yV6C2k+4G2OrciBHGKSUUWy8evRJyGB4gtAyjsL7
 vJ6xbVtUcTEPKCuXrIYCxz02+XHN3No4+vLZHia7rfzNRTLABrhpZc83r9nyXzslp72BEK5rYJ
 1T9hliGyOFIDFdaEVZ+QcuyvAHWtC6oCAEAAA==
X-Change-ID: 20241101-io_lmb_apple_dart_iommu-dc2674ef9036
To: Tom Rini <trini@konsulko.com>, Mark Kettenis <kettenis@openbsd.org>, 
 Sughosh Ganu <sughosh.ganu@linaro.org>, Simon Glass <sjg@chromium.org>
Cc: u-boot@lists.denx.de, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2485; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=i9VLEKBIO+/qeIiUD07iM6FlYuOVMwzSQ1shqKu3MPU=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhnTDVasrgxKixCN2J+yImnbEJHyNpwUjw7PY1obXWe5ZZ
 5ev+BvVUcrCIMbFICumyJKk/bKDYXWNYkztgzCYOaxMIEMYuDgF4CbPYvgr5xzCabj7/Qnvxe8P
 7dqxvj1hnltrTdSzNzEnP7gzPTHRZ/jvfDDvi/G892dOfRX6wb/jxbfvU350nOw5eHbPSffQBZy
 rOAA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The changes in "Make LMB memory map global and persistent" [1] break
mapping DMA memory in the USB xHCI driver when using the apple_dart
iommu present on Apple silicon systems.

The IOVA space used by the u-boot driver (low 4GB) and physical memory
do not overlap. The physical memory on this systems starts depending on
the SoC either at 0x10_0000_0000 or 0x100_0000_0000. It make no sense to
manage these distinct regions in a single LMB map. In addition every
device has its own iommu and IO address space so sharing a single memory
map between all iommu instances is not necessary.

To fix this issue restore the used subset (add, alloc and free) of the
previous pointer based LMB interface with "io_" as prefix.

To ensure that low level lmb functions do not use the global LMB
variable reorder lib/lmb.c so that the variable is not visible.

Tested with patches from my "Fix device removal order for Apple dart
iommu" series [2] to fix a separate issue.

The cosmetic commit has two checkpatch warnings in existing code which I
ignored.

[1] https://lore.kernel.org/u-boot/20240826115940.3233167-1-sughosh.ganu@linaro.org/
[2] https://lore.kernel.org/u-boot/20241031-iommu_apple_dart_ordering-v1-0-8a6877946d6b@jannau.net/

Signed-off-by: Janne Grunau <j@jannau.net>
---
Changes in v3:
- rebased onto master
- redo "lmb: cosmetic: reorder functions and global LMB variable" to
  account for changes in lib/lmb.c (removed Rb:)
- Link to v2: https://lore.kernel.org/r/20241106-io_lmb_apple_dart_iommu-v2-0-0580f4bdb023@jannau.net

Changes in v2:
- added io_lmb_teardown() and use it in dart's remove callback
- removed leftover from copy-n-paste in io_lmb_setup() documentation
- added Tom's Rb:
- Link to v1: https://lore.kernel.org/r/20241101-io_lmb_apple_dart_iommu-v1-0-fe4b9a74d47c@jannau.net

---
Janne Grunau (4):
      lmb: Do not use global LMB variable in _lmb_free()
      lmb: cosmetic: reorder functions and global LMB variable
      lmb: Add basic io_lmb functionality
      iommu: apple: Manage IOVA separately from global LMB mem map

 drivers/iommu/apple_dart.c |  18 +-
 include/lmb.h              |  51 ++++
 lib/lmb.c                  | 608 ++++++++++++++++++++++++++-------------------
 3 files changed, 415 insertions(+), 262 deletions(-)
---
base-commit: 9c25cd563179cf32cf3b119d5ae78ef8348d0335
change-id: 20241101-io_lmb_apple_dart_iommu-dc2674ef9036

Best regards,
-- 
Janne Grunau <j@jannau.net>

