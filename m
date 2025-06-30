From: George Chan <gchan9527@gmail.com>
Subject: [PATCH v4 0/6] A series of patch for enable sc7180 android boot
Date: Mon, 30 Jun 2025 15:56:49 +0800
Message-Id: <20250630-sc7180-android-boot-v4-0-24cdb50e860f@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEFDYmgC/33NTQ7CIBCG4asY1mIGCoW68h7GBfLTkthioCGap
 neXdmMTG5fvl8wzE0o2epvQ+TChaLNPPgwl2PGAdKeG1mJvSiMKlAOngJMWRAJWg4nBG3wPYcR
 KMm61Y1IxicrlM1rnX6t6vZXufBpDfK9PMlnW/14mGHAFghfYKmjYpe2Vf5x06NHiZfo1ahD7B
 i0GNY4b4WpC6I9RbQwq942qGAQ4NFKRhtR8a8zz/AF6aLvaPgEAAA==
To: Tom Rini <trini@konsulko.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>, Simon Glass <sjg@chromium.org>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Lukasz Majewski <lukma@denx.de>, Marek Vasut <marex@denx.de>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, gchan9527@gmail.com, 
 Vitalii Skorkin <nikroks@mainlining.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751270223; l=3271;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=TEIhbyiLASh+uLslJ10eWzVDzNJXy0lerC1nZOO4DwY=;
 b=VcB1DrC1z5YA7NYypQ1BBBPkQ/pgjWM2hYFmugGt7fIHykt48bIzEnfqhDlBiB/8Ro037Ofuu
 XRtZ2++HajED7UBbaojROQ6jKbVloMuch+kuF1pDfdf01IOzeRnOjiW
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since attempt[1] to embed android specific boot param into fdt bootargs,
a new idea is formed as to make use of env file to contain default param
value. Current code logic is already working fine, unless the priority
of param at begining is higher than at tail. From env file, bootargs is
treated important, and prepend at begining. So there is a need to
reverse the logic, and make sure default bootargs value at the end, and
let androidboot img bootargs value sit at begining.

So a new kconfig item is introduced. Once enabled, the bootargs strcat
param will get reversed.

A similar logic is needed for fastboot->bootm glue function, so split 
function of patch #1 into 2 functions as #2, fixed some issues #3, and 
apply #4 with same trick to glue function too.

Some one-liners patch is included to enable device driver for sc7180
soc. It is about iommu for usb, usb gadget vendor/product id.

Reduce dependency on abootimg when androidboot v3 or greater is not
needed. Since Tom suggested to reduce __maybe_unused directive and 
use IS_ENABLE() instead; two __weak func proto need to add into image.h

[1]https://lists.denx.de/pipermail/u-boot/2025-May/588828.html
[2]https://lists.denx.de/pipermail/u-boot/2025-May/589926.html

Signed-off-by: George Chan <gchan9527@gmail.com>
---
Changes in v4:
- Drop patch #3.
- Refine #2 to remove intermediate variables and code style.
- Link to v3: https://lore.kernel.org/r/20250628-sc7180-android-boot-v3-0-105098a19165@gmail.com

Changes in v3:
- Collect acks-by and review-by.
- Split function and replace old #2 into #2-#4, code reuse in #4
- Modify changelog and Kconfig description of #1, suggested by Mattijs
- Slightly modify #5, add back line break.
- Rebase to latest next
- Link to v2: https://lore.kernel.org/r/20250607-sc7180-android-boot-v2-0-2df5d7f61124@gmail.com

Changes in v2:
- Add new patch #2 that is same trick as #1 to fastboot->bootm glue layer.
- Remove default n to patch #1, suggested by Tom.
- Use IS_ENABLE() instead, suggested by Tom.
- Collect review-by from Casey and Neil.
- Rebase to u-boot/next branch.
- CCing myself too.
- Link to v1: https://lore.kernel.org/r/20250520-sc7180-android-boot-v1-0-3075a84ea094@gmail.com

---
George Chan (6):
      image-android: Prepend/postpend default bootargs value with given bootcmd
      boot/image-android.c: Split android_image_get_kernel into two functions
      bootm: Append bootargs value when bootmeth_android provide cmdline
      boot: bootmeth_android: Conditionally dependent on abootimg
      iommu: qcom-smmu: Introduce sc7180 compatible string
      usb: gadget: Introduce usb gadget vendor/product default id for ARCH_QCOM

 boot/Kconfig                  |  9 ++++
 boot/bootm.c                  |  2 +-
 boot/bootmeth_android.c       |  2 +-
 boot/image-android.c          | 97 ++++++++++++++++++++++++++++---------------
 drivers/iommu/qcom-hyp-smmu.c |  1 +
 drivers/usb/gadget/Kconfig    |  2 +
 include/image.h               | 14 +++++++
 7 files changed, 92 insertions(+), 35 deletions(-)
---
base-commit: 490ae8ceae2d5999c9de863e014e463f5c1495a6
change-id: 20250520-sc7180-android-boot-a845ecf48a48

Best regards,
-- 
George Chan <gchan9527@gmail.com>

