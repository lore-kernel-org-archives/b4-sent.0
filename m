From: Sam Day <me@samcday.com>
Subject: [PATCH 00/13] Generate Android boot images with binman
Date: Sat, 06 Jun 2026 10:52:34 +1000
Message-Id: <20260606-android-binman-v1-0-c7a3c14b8a3d@samcday.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MMQqAMAxA0atIZgtVi1KvIg7RpJrBVFoQQby7x
 fEN/z+QOQlnGKsHEl+SJWpBU1ew7qgbG6FiaG3b2946g0opCplF9EA1SAO6Ljj2nqBEZ+Ig9z+
 c5vf9AKuTJqlgAAAA
X-Change-ID: 20260604-android-binman-ad7a43f4e99d
To: u-boot@lists.denx.de, Sumit Garg <sumit.garg@kernel.org>, 
 u-boot-qcom@groups.io
Cc: Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Alper Nebi Yasak <alpernebiyasak@gmail.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, Bryan Brattlof <bb@ti.com>, 
 Yannic Moog <y.moog@phytec.de>, Wojciech Dubowik <Wojciech.Dubowik@mt.com>, 
 Yegor Yefremov <yegorslists@googlemail.com>, 
 Denis Mukhin <dmukhin@ford.com>, Rasmus Villemoes <ravi@prevas.dk>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, Javier Tia <floss@jetm.me>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Tien Fong Chee <tien.fong.chee@altera.com>, Peng Fan <peng.fan@nxp.com>, 
 Anshul Dalal <anshuld@ti.com>, 
 Alif Zakuan Yuslaimi <alif.zakuan.yuslaimi@altera.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Tingting Meng <tingting.meng@altera.com>, Alice Guo <alice.guo@nxp.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Minkyu Kang <mk7.kang@samsung.com>, 
 Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Henrik Grimler <henrik@grimler.se>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780707158; l=4605;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=ODQrbTXJbY1PGG3lHlFJSANiRvb70foev7oSN9WSeRM=;
 b=VbDxWUJGpWOfYtLnlL5X089FcG53VTycqbaVoNyxDr/iuE9kKmcMwfP0zrLcyklGlIscrWZ9s
 4cyJ2RRjXhhA1hT274oZcgG57NQD5L6bW1+34wH2B1ofPqQfFM1o0kb
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

U-Boot is seeing increasing adoption on pocket computers, many of which
(sadly) have fused bootloader chains. Many of these bootloaders have a
very rigid definition of what a "valid" downstream payload looks like.
Sometimes it's just a boring old v0/v2 Android boot image. Sometimes
it's something decidedly more grotesque.

To date, this last-mile packaging step has been trapped in downstream CI
pipelines, blogposts, documentation, etc. This patch series aims to
gather up all that esoterica and institutional knowledge and codify it
in U-Boot's build system, using binman.

Put differently: an overwhelming majority of these pocket computer
devices have a "canonical" payload format that U-Boot currently has no
support for. Let's fix that.

The first patches in this series introduce an `android_boot` etype. To
begin with, this is a "typical" abootimg, as defined by canonical AOSP
sources and reference `fastboot`/`mkbootimg` implementation. There's
plenty of devices out there with a sane(-ish, nothing in Android-land is
ever truly sane) bootloader that will happily chain a U-Boot rolled into
the kernel section of an abootimg.

With that out of the way, the cursed bootloaders are next to be
supported. Binman etypes for Qualcomm's "QCDT" and Samsung's "DTBH"
formats are implemented. These are non-standard vendor-specific
devicetree containers, which the previous bootloader uses to pick a FDT
to boot the downstream with.

In both cases, these vendor-specific formats are tacked on to the end of
a v0 abootimg, with the header_version being hijacked to encode the
length of this following payload. Thus, the android_boot etype is
retrofitted to allow these shenanigans.

Binman configs that produce flashable boot artifacts are introduced for
the following devices:

 * google-sargo (vanilla v2)
 * oneplus-fajita (vanilla v2)
 * samsung-a5u-eur (QCDT v0)
 * samsung-gt510 (QCDT v0)
 * samsung-j7xelte (DTBH v0)

I also successfully tested a vanilla v0 on my samsung-expressltexx, in
conjunction with the qcom-armv7 series already on the list. However,
since that work is still in-flight and the expressltexx DTS is
downstream, I opted not to include it here.

Signed-off-by: Sam Day <me@samcday.com>
---
Sam Day (13):
      binman: Android boot image support
      .gitignore: ignore binman-generated blobs
      arch: arm: qcom: google-sargo binman config
      qcom: arch: arm: qcom: sdm845-fajita binman configs
      mach-snapdragon: enable BINMAN
      binman: android_boot: vendor-dt support
      binman: Add QCDT support
      binman: android_boot: SEANDROIDENFORCE support
      arch: arm: qcom: samsung-a5u-eur binman config
      arch: arm: qcom: samsung-gt510 binman config
      binman: Add DTBH support
      arch: arm: exynos: add j7xelte binman config
      configs: exynos-mobile: pull in BINMAN

 .gitignore                                         |   1 +
 arch/arm/Kconfig                                   |   1 +
 arch/arm/dts/exynos-mobile.dtsi                    |   5 +
 arch/arm/dts/exynos7870-j7xelte-u-boot.dtsi        |  24 ++
 arch/arm/dts/msm8916-samsung-a5u-eur-u-boot.dtsi   |  39 ++
 arch/arm/dts/msm8916-samsung-gt510-u-boot.dtsi     |  39 ++
 arch/arm/dts/qcom.dtsi                             |   5 +
 arch/arm/dts/sdm670-google-sargo-u-boot.dtsi       |  27 ++
 arch/arm/dts/sdm845-oneplus-fajita-u-boot.dtsi     |  25 ++
 arch/arm/mach-exynos/Kconfig                       |   1 +
 configs/exynos-mobile_defconfig                    |   1 +
 configs/qcom_defconfig                             |   1 +
 tools/binman/etype/android_boot.py                 | 408 +++++++++++++++++++++
 tools/binman/etype/dtbh.py                         | 173 +++++++++
 tools/binman/etype/qcdt.py                         | 160 ++++++++
 tools/binman/ftest.py                              | 127 +++++++
 .../test/vendor/android_boot_seandroidenforce.dts  |  22 ++
 tools/binman/test/vendor/android_boot_v0.dts       |  29 ++
 tools/binman/test/vendor/android_boot_v2.dts       |  46 +++
 .../binman/test/vendor/android_boot_vendor_dt.dts  |  27 ++
 tools/binman/test/vendor/dtbh.dts                  |  29 ++
 tools/binman/test/vendor/dtbh_bad_model_info.dts   |  19 +
 tools/binman/test/vendor/qcdt.dts                  |  20 +
 tools/binman/test/vendor/qcdt_bad_msm_id.dts       |  17 +
 24 files changed, 1246 insertions(+)
---
base-commit: a4c8728f225b0d7d591fb9199ce7efb72f48290e
change-id: 20260604-android-binman-ad7a43f4e99d

Best regards,
-- 
Sam Day <me@samcday.com>

