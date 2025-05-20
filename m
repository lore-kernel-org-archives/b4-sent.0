From: George Chan <gchan9527@gmail.com>
Subject: [PATCH 0/4] A series of patch for enable sc7180 android boot
Date: Tue, 20 May 2025 22:25:55 +0800
Message-Id: <20250520-sc7180-android-boot-v1-0-3075a84ea094@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPSQLGgC/x3MQQqAIBBA0avErBtQUZKuEi1Mx5qNhkYE0t2Tl
 m/xf4NKhanCPDQodHPlnDrkOIA/XNoJOXSDEsoIowRWP0kr0KVQMgfccr7QWW3IR22dttDLs1D
 k578u6/t+A/ESvGUAAAA=
To: Tom Rini <trini@konsulko.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>, Simon Glass <sjg@chromium.org>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Lukasz Majewski <lukma@denx.de>, Marek Vasut <marex@denx.de>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, 
 George Chan <gchan9527@gmail.com>, Vitalii Skorkin <nikroks@mainlining.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747751157; l=1755;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=FGMvhL5VzJ+FRv+Wa1Xojc0aHPnOaZO+iDim/8NByws=;
 b=KC/bYCrZM7IzlfMx9GLPIzy29T/JQFMbkMdexijPcjYu4Jrf9GIkEraj+qyOhBTW8RPxf3NSX
 VEfjmCEtIqCBCODX71AxzMlTvNLYhsNKbit+cF0hbb0qNgJAdcsJrJt
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

Some one-liners patch is included to enable device driver for sc7180
soc. It is about iommu for usb, usb gadget vendor/product id, and
abootimg dependency.

Worth mentioning is as always, the EL1 jump_linux[2] logic to boot.

[1]https://lists.denx.de/pipermail/u-boot/2025-May/588828.html
[2]https://lists.denx.de/pipermail/u-boot/2025-April/585995.html

Signed-off-by: George Chan <gchan9527@gmail.com>
---
George Chan (4):
      image-android: Prepend/postpend default bootargs value with given bootcmd
      iommu: qcom-smmu: Introduce sc7180 compatible string
      boot: bootmeth_android: Conditionally dependent on abootimg
      usb: gadget: Introduce usb gadget vendor/product default id for ARCH_QCOM

 boot/Kconfig                  |  8 ++++++++
 boot/bootmeth_android.c       |  4 +++-
 boot/image-android.c          | 10 ++++++++--
 drivers/iommu/qcom-hyp-smmu.c |  1 +
 drivers/usb/gadget/Kconfig    |  2 ++
 5 files changed, 22 insertions(+), 3 deletions(-)
---
base-commit: 126a88d49bcae04bbfc0d6723097cd6341355ade
change-id: 20250520-sc7180-android-boot-a845ecf48a48

Best regards,
-- 
George Chan <gchan9527@gmail.com>

