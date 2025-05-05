From: George Chan <gchan9527@gmail.com>
Subject: [PATCH v2 0/5] u-boot chain-loading LineageOS bootimg
Date: Mon, 05 May 2025 17:17:08 +0800
Message-Id: <20250505-android-boot-v2-0-92dcb5bf59c8@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABSCGGgC/3XMQQ7CIBCF4as0sxYDqMW68h6mC2ag7SS2GGiIp
 uHuYvcu/5e8b4PkI/sEt2aD6DMnDksNfWiAJruMXrCrDVrqizxrI+ziYmAnMIRVeEI07ZWcNRr
 q5RX9wO+de/S1J05riJ9dz+q3/oGyElIgtngy1FE3qPs4W34eKczQl1K+4I3Sf6gAAAA=
To: Tom Rini <trini@konsulko.com>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Simon Glass <sjg@chromium.org>, Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, 
 George Chan <gchan9527@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746436629; l=2879;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=i+ZlovZEnLGX/kPfltDnno5IJKQcdOsA6wgnh+nHz+E=;
 b=8hUtv0gRT53ovYMEBV06NQBj9jbAHpt0on4FBwlrMiQfsIQXYAufuB0FqTHN30YMlPw49ENcM
 oXDoAoNj/0MDbuHs2qzM9eoXIb6lCaWSY+yQXsll9nxFjj7qxTgQtCn
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is a series of patches to enable chainloading LineageOS on qcom SOC.

Patch #1 introduce kconfig to ignore those default value and use loadaddr
instead. That workaround some androidboot image have invalid kernel/ramdisk
loadaddr.

Patch #2 override qcom soc loadaddr with fastboot_addr_r as a band-aid.
Casey confirmed loadaddr and kernel_addr_r are purposely set to same
address for memory-constrain case. A proper fix is far from get ready so
this patch can work as a band-aid for maintainer atm.

Patch #3 optionally introduce new kconfig and env_var to get hold of legacy
OS boot param for boot compatibility. It is designed initially for
booting legacy Android, but newer AOSP greatly dependent on kernel
bootconfig feature with vendor_boot partition so not very useful for new
AOSP based OS.

Patch #4 is an example for #3 with snapdragon soc env file

Patch #5 is oprtional to default enable #1 for snapdragon machine.

Worth mentioning a patch[1] to enable EL1 chainloading kernel is needed.

[1] https://lists.denx.de/pipermail/u-boot/2025-April/585995.html

To: Tom Rini <trini@konsulko.com>
To: Mattijs Korpershoek <mkorpershoek@kernel.org>
To: Simon Glass <sjg@chromium.org>
To: Casey Connolly <casey.connolly@linaro.org>
To: Neil Armstrong <neil.armstrong@linaro.org>
To: Sumit Garg <sumit.garg@kernel.org>
To: Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>
Cc: u-boot@lists.denx.de
Cc: u-boot-qcom@groups.io
Signed-off-by: George Chan <gchan9527@gmail.com>

Changes in v2:
- Revised patch #1 to control by kconfig, suggested by Casey
- Split old #1 into new #1 and #5 for maintainer to choose.
- Revised Casey's approach for #2 and make it as band-aid atm.
- Revised Casey's approach for #3 and leave user to bake their own param set.
- Introduce example for #1
- Introduce kconfig default for #1 with snapdragon soc, suggested by Casey
- Link to v1: https://lore.kernel.org/r/20250427-android-boot-v1-0-bb6b37c9c9f1@gmail.com

---
George Chan (5):
      boot/image-android: Workaround kernel/ramdisk invalid addr
      mach-snapdragon: Enhance android image handling memory footprint
      fdt_support: Add support for extra var for bootargs
      qcom-phone.env: Example of new env var legacy_os_boot_param
      mach-snapdragon: Enable workaround of ignoring androidboot addr

 arch/arm/Kconfig                 |  1 +
 arch/arm/mach-snapdragon/board.c |  8 ++++++--
 board/qualcomm/qcom-phone.env    |  4 ++++
 boot/Kconfig                     | 15 +++++++++++++++
 boot/fdt_support.c               | 20 +++++++++++++++++++-
 boot/image-android.c             |  9 ++++++---
 6 files changed, 51 insertions(+), 6 deletions(-)
---
base-commit: 5a0a93a768487e55ebe50a34cc90d751bf99cc56
change-id: 20250427-android-boot-ecbb768cda72

Best regards,
-- 
George Chan <gchan9527@gmail.com>

