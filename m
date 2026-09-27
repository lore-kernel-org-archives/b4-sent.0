From: Daniel Drake <dan@reactivated.net>
Subject: [PATCH v7 0/6] Add support for Broadcom BCM2712 IOMMU driver
 (Raspberry Pi 5)
Date: Sun, 27 Sep 2026 14:08:59 +0100
Message-Id: <20260927-bcm2712-iommu-submit-v7-0-dfa2b975cbc9@reactivated.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XPO27DMAwG4KsEmqtWpt6deo+igx5MrMF2IDlGi
 8B3r5QlBmqjE/ED5EfyTgrmhIW8n+4k45JKmsYa9MuJhN6NF6Qp1kyAgWK6A+rDAK2maRhutNz
 8kGYKyKyxFpUMgtTRa8Zz+n6wn181e1eQ+uzG0DdsyumSxrfBlRlz6+9Tmaf887hi6drUPwuXj
 jJqGHYsxIiA7iOjC3Na3IzxdcSZtLULbCjQBxRUioHQXgbGI5p9ij8pA/KA4pXS505w1GCsV/u
 UeFKWHT0oKmWj90pqqU3o9im5pewBJSsFktsgwYOwuE+pDQXigFLtQc+DC2iU1fwvta7rL1DEg
 rpVAgAA
X-Change-ID: 20260712-bcm2712-iommu-submit-2e09899e65c4
To: "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Florian Fainelli <florian.fainelli@broadcom.com>, 
 Broadcom internal kernel review list <bcm-kernel-feedback-list@broadcom.com>, 
 Daniel Drake <dan@reactivated.net>
Cc: iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-rpi-kernel@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, nick.hollinghurst@raspberrypi.com, 
 james.quinlan@broadcom.com, Jason Gunthorpe <jgg@ziepe.ca>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=6705; i=dan@reactivated.net;
 h=from:subject:message-id; bh=/satiGAup3MvwEQuGuW7WPwdFMZuAWo3ppOawHGJOmc=;
 b=owEBbQKS/ZANAwAKAcPmj7FTFEe7AcsmYgBquRWEh9z9/iyDIBx+HAzEEJ1yd1M1AVJqAulys
 8n+HKLL8nCJAjMEAAEKAB0WIQQ6Rf0sUP1iEhXfVfjD5o+xUxRHuwUCarkVhAAKCRDD5o+xUxRH
 uxXED/9ELkBTzi0FS9uWC69lXIKCenidL0fc9VO64NIrebRYQjhHU6U1hNx/m5aahMpBqoXUUQx
 K1IktWVsMKNUgwTWG+9oMdHeyVwY6grkJ+Li4c+vZt7pHLNsd19LHUokbnVusgrUrkt1KtJ4Y/D
 VbIdT/1PumNtPRu45CXtdeWfdYE+F6VC+eZCVeCjZ5wcLjOT+jehsvFZTYnQ8fOBEROWMqNWSZr
 M0ccFvJ2TyLkX+o+265mKvZA7Prvejadskmi0Nqc5nZtX73SnhmjV8C+X6YA4xhbCT8ECSRqZ2F
 DNxSbp4K4wz/3nEZHIv3YFJn91oYOIDnODZxAbLG4BZ2fISQDBok1cB9NtC95yTBpPRvetnp0IX
 THvRjDZcAYJ5nTgvUyuGiYzIj2bUTqGJNcCzpaN5tIYfi6j+g/9lzUEDPOCz3ot6q92dVF0RcMO
 NutN1lybkd0xwFVCXNgWkFPlc5JBM4OhMjkVRcZv4RNMmpmiXyhqbEub9u8LdKiq5yAecYCP8wy
 rs69POXXWi/JWEvxjMS+BHPKc29/AJ+nBqe1kfS92exrt1Q36hssQEjmbjLVWGiQFKaZ90s4Y6X
 HYMSZ6O1ASUWQfqvcdt3wOrm5avJ2PauXZt7SZWPNvwQad6XbDwy3A/X5QccybfHusUAUxERzhk
 cHBUU66l59gChxg==
X-Developer-Key: i=dan@reactivated.net; a=openpgp;
 fpr=3A45FD2C50FD621215DF55F8C3E68FB1531447BB
X-Endpoint-Received: by B4 Relay for dan@reactivated.net/default with auth_id=1070
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series adds a driver for the Broadcom BCM2712 IOMMU found on
Raspberry Pi 5, and hooks up the display controller IOMMU for efficient
management of graphics memory. This is adapted from the downstream driver
from Raspberry Pi (original author Nick Hollinghurst), with main changes:
 - In page mapping mode, operate the translation aperture from address 0,
   with no bypass window. More like a IOMMU and less like a GART.
 - Implement the page table management using generic_pt
 - Support 4MB hugepage mapping in top level page table
 - Implement brcm,iommu-cache as standards-compliant DT property
 - Drop the dma-iova-offset hack, used to work around some issue seen with
   dma-ranges. This will need to be investigated separately and solved
   properly. (It's not needed for display controller iommu support included
   here.)
 - Misc simplifications/standardisations/cleanups
 
The IOMMU works strictly with 4KB pages. This means that unfortunately
when the kernel is compiled with PAGE_SIZE=16KB (the Raspberry Pi 5
kernel default), 12KB is wasted in each page that is allocated for page
tables. I plan to address this in followup work.

It has been tested on Raspberry Pi 5 using a 3D-accelerated graphical
environment which causes plenty of IOMMU maps & unmaps.

Thanks for the review comments and discussion. Further feedback and
testing welcome!

Changes in v7:
- Add latest Reviewed-by / Acked-by 
- Otherwise no changes, resending due to email delivery issue
- Link to v6: https://lore.kernel.org/r/20260924-bcm2712-iommu-submit-v6-0-7b3cace86973@reactivated.net

Changes in v6:
- Add MAINTAINERS entry
- Drop unnecessary vc4 iommus property (it only needs to sit on the
  underlying hvs device)
- Add dt-bindings doc for hvs iommus property
- Link to v5: https://lore.kernel.org/r/20260909-bcm2712-iommu-submit-v5-0-2539c52b249e@reactivated.net

Changes in v5:
- Drop blocked_domain support as hardware always translates a minimum
  256MB aperture when enabled
- Restrict Kconfig dependency to ARCH_BCM2835, matching other RPi drivers
- Improved error handling in device attach
- Add missing iommu_put_pages_list() in iotlb sync
- Minor readability improvements
- Link to v4: https://lore.kernel.org/r/20260902-bcm2712-iommu-submit-v4-0-9dbb657578c1@reactivated.net

Changes in v4:
- Add Jim Quinlan and Florian Fainelli as bindings maintainers
- Replace MMU register access macros with static inline functions
- Clear illegal address register and flush caches on blocking domain attach
- Add __must_hold annotations in TLB helpers
- Use BIT() macro for MMUC_CONTROL definitions
- Link to v3: https://lore.kernel.org/r/20260825-bcm2712-iommu-submit-v3-0-7f143e7289b6@reactivated.net

Changes in v3:
- Switch from a aperture and bypass window GART-like approach
  to IOMMU-like 0-based translation
- Add 3 SW bits which seem unused (per the chipset docs); drop patch
  for NO_SW_BIT handling. This reduces the claimed address space, so I had
  to tweak a iommu_pt test accordingly.
- Disallow domain sharing across multiple hardware IOMMU instances
- Clear and flush local MMU TLB during domain attach
- Handle unattached domains safely during TLB sync
- Set cache platform driver data late during probe to prevent race condition
- Improved handling of cache flush timeouts
- Use format string for device name in iommu_device_sysfs_add()
- Use cleanup.h helpers for scope management
- Expand DT binding descriptions for IOMMU and IOMMUC
- Add iommus property to HVS display node in DT
- Drop iommuc back-compat with current RPi DT
- Link to v2: https://lore.kernel.org/r/20260727-bcm2712-iommu-submit-v2-0-0247b5c03de8@reactivated.net

Changes in v2:
- Use iommu_fwspec in xlate & probe_device
- Add blocked_domain support
- Simplify page size configuration between iommu driver and format
- Introduce PT_FEAT_NO_SW_BIT flag to allow formats to explicitly opt-in to
  a defensive flushing algorithm when no sw bit is available
- Implement 4MB pages at Level 1; this is more efficient and means the
  "allow full-table contiguous leaves in unit tests" commit has been
  dropped because it is no longer needed.
- Hardcode the aperture in an unused part of the address space, removing
  it from DT (it's a software-specific decision, not an attribute of the
  hardware), adding more explanatory comments
- Use pt_full_va_prefix to have the PT format operate within the aperture
  space, enabling use of IOMMU_PT_DOMAIN_OPS
- Add more dt-bindings explanation to brcm,iommu-cache and drop docs
  around the cache property used in RPi firmware (the driver still supports
  this however, for fw compat reasons)
- Correct iommu device address in bcm2712.dtsi
- Link to v1: https://lore.kernel.org/r/20260712-bcm2712-iommu-submit-v1-0-80e10cdde2ea@reactivated.net

---
Daniel Drake (6):
      iommu_pt: Fix test_pgsize_boundary() failure on narrow-OA formats
      dt-bindings: iommu: Add Broadcom BCM2712 IOMMU
      dt-bindings: display: brcm,bcm2835-hvs: Document iommus property
      iommu/generic_pt: Add Broadcom BCM2712 page table format
      iommu: Add Broadcom BCM2712 IOMMU driver
      arm64: dts: broadcom: bcm2712: Add GPU IOMMU and IOMMU cache nodes

 .../bindings/display/brcm,bcm2835-hvs.yaml         |   3 +
 .../bindings/iommu/brcm,bcm2712-iommu.yaml         |  54 ++
 .../bindings/iommu/brcm,bcm2712-iommuc.yaml        |  40 ++
 MAINTAINERS                                        |  12 +
 arch/arm64/boot/dts/broadcom/bcm2712.dtsi          |  14 +
 drivers/iommu/Kconfig                              |  15 +
 drivers/iommu/Makefile                             |   1 +
 drivers/iommu/bcm2712-iommu-cache.c                |  84 ++++
 drivers/iommu/bcm2712-iommu-cache.h                |   9 +
 drivers/iommu/bcm2712-iommu.c                      | 550 +++++++++++++++++++++
 drivers/iommu/generic_pt/.kunitconfig              |   1 +
 drivers/iommu/generic_pt/Kconfig                   |  10 +
 drivers/iommu/generic_pt/fmt/Makefile              |   2 +
 drivers/iommu/generic_pt/fmt/bcm2712.h             | 288 +++++++++++
 drivers/iommu/generic_pt/fmt/defs_bcm2712.h        |  18 +
 drivers/iommu/generic_pt/fmt/iommu_bcm2712.c       |   6 +
 drivers/iommu/generic_pt/kunit_iommu_pt.h          |   2 +-
 include/linux/generic_pt/common.h                  |   6 +
 include/linux/generic_pt/iommu.h                   |  12 +
 19 files changed, 1126 insertions(+), 1 deletion(-)
---
base-commit: 28924df2a08f440c73991b83028032c901de2ae4
change-id: 20260712-bcm2712-iommu-submit-2e09899e65c4

Best regards,
-- 
Daniel Drake <dan@reactivated.net>

