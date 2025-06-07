From: George Chan <gchan9527@gmail.com>
Subject: [PATCH v2 0/5] A series of patch for enable sc7180 android boot
Date: Sat, 07 Jun 2025 13:24:55 +0800
Message-Id: <20250607-sc7180-android-boot-v2-0-2df5d7f61124@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACfNQ2gC/32NQQ6CMBBFr0Jm7ZihtqG68h6GRW0HmEQoaQnRE
 O5u5QAu30v++xtkTsIZbtUGiVfJEqcC6lSBH9zUM0ooDIqUIaMIs29qS+imkKIEfMa4oLPasO+
 0ddpCWc6JO3kf1UdbeJC8xPQ5Ttb6Z//31hoJL9SYEmZHV33vRyevs48jtPu+fwFb2uv3tgAAA
 A==
To: Tom Rini <trini@konsulko.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>, Simon Glass <sjg@chromium.org>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Lukasz Majewski <lukma@denx.de>, Marek Vasut <marex@denx.de>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, gchan9527@gmail.com, 
 Vitalii Skorkin <nikroks@mainlining.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749273923; l=2810;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=o6Dc3OjZTQDblXuNtvbL5BLeplo2kqAnNlOHfk1Scdk=;
 b=7nRmVit32kUOw/XBQJdkE3NFGuId3d2kxa2dPxkihwQTbDuki8bPZnxFdkMMTDPNgA1Mcub4q
 KSRrcSOglbYBUr0yRnYELBJDzb793RbimVfVKRdIVhlzw5PLgvEIFub
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

A similar logic is needed for fastboot->bootm glue function, so apply
same trick to glue function too.

Some one-liners patch is included to enable device driver for sc7180
soc. It is about iommu for usb, usb gadget vendor/product id.

Reduce dependency on abootimg when androidboot v3 or greater is not
needed. Since Tom suggested to reduce __maybe_unused directive and 
use IS_ENABLE() instead; two __weak func proto need to add into image.h

This series is independent, but modified boot/Kconfig that roughly same
location to another patch series[2], so directly apply both would fail.
Please let me know if maintainer wanna to let the one gets applied
first and rebase _OR_ combine two series as one.

[1]https://lists.denx.de/pipermail/u-boot/2025-May/588828.html
[2]https://lists.denx.de/pipermail/u-boot/2025-May/589926.html

Signed-off-by: George Chan <gchan9527@gmail.com>
---
Changes in v2:
- Add new patch #2 that is same trick as #1 to fastboot->bootm glue layer.
- Remove default n to patch #1, suggested by Tom.
- Use IS_ENABLE() instead, suggested by Tom.
- Collect review-by from Casey and Neil.
- Rebase to u-boot/next branch.
- CCing myself too.
- Link to v1: https://lore.kernel.org/r/20250520-sc7180-android-boot-v1-0-3075a84ea094@gmail.com

---
George Chan (5):
      image-android: Prepend/postpend default bootargs value with given bootcmd
      bootm: Append bootargs value when bootmeth_android provide cmdline
      boot: bootmeth_android: Conditionally dependent on abootimg
      iommu: qcom-smmu: Introduce sc7180 compatible string
      usb: gadget: Introduce usb gadget vendor/product default id for ARCH_QCOM

 boot/Kconfig                  |  7 +++++++
 boot/bootm.c                  | 29 ++++++++++++++++++++++++++++-
 boot/bootmeth_android.c       |  2 +-
 boot/image-android.c          | 10 ++++++++--
 drivers/iommu/qcom-hyp-smmu.c |  1 +
 drivers/usb/gadget/Kconfig    |  2 ++
 include/image.h               |  3 ++-
 7 files changed, 49 insertions(+), 5 deletions(-)
---
base-commit: a822b95da4b799bdc2a42c06923af4359238dc9e
change-id: 20250520-sc7180-android-boot-a845ecf48a48

Best regards,
-- 
George Chan <gchan9527@gmail.com>

