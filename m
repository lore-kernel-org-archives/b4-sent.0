From: Sam Day <me@samcday.com>
Subject: [PATCH v3 00/10] Generate Android boot images with binman
Date: Wed, 10 Jun 2026 11:27:38 +1000
Message-Id: <20260610-android-binman-v3-0-710298a38fcc@samcday.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2XMSw6DIBSF4a0YxqVBoIgddR9NB1fAegeCgYbUG
 PdeNGnSx/A/yfkWklxEl8i5Wkh0GRMGX0IcKmIG8HdH0ZYmnHHFFJMUvI0BLe3Qj+Ap2Aak6KV
 rW0vKaYqux+cOXm+lB0yPEOfdz/W2vin1S+WaMmoaEKaWnQZhLwlGY2E+mjCSDcv8E9B/AC9Ap
 zkTSvMTa/pvYF3XF5Gft1jvAAAA
X-Change-ID: 20260604-android-binman-ad7a43f4e99d
To: u-boot@lists.denx.de
Cc: Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Alper Nebi Yasak <alpernebiyasak@gmail.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, Bryan Brattlof <bb@ti.com>, 
 Yannic Moog <y.moog@phytec.de>, Wojciech Dubowik <Wojciech.Dubowik@mt.com>, 
 Yegor Yefremov <yegorslists@googlemail.com>, 
 Patrice Chotard <patrice.chotard@foss.st.com>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Rasmus Villemoes <ravi@prevas.dk>, Javier Tia <floss@jetm.me>, 
 Minkyu Kang <mk7.kang@samsung.com>, 
 Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Henrik Grimler <henrik@grimler.se>, yan wang <yan.wang@softathome.com>, 
 Marek Vasut <marex@nabladev.com>, Denis Mukhin <dmukhin@ford.com>, 
 Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781054859; l=7539;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=CoHwscL2RYphSG3WMdK+FvIJJljTqSB3VUCvC61XO80=;
 b=VCGWOaYm82T/fVV3zS4ZcBX7sIbrYiclHJjOYBZbdnCXn7ukerdKjf6x6AJjsSRm9f988K25+
 Yrgp8B0NHnwAk/mNu+133wV1CNxk5C0sBhuMH3JBSBUImM6WUcg9SdT
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

Note that, I dropped the commits that introduce this support for
Qualcomm devices, as it was NAK'd by "Qualcomm". I still think this is
worth inclusion upstream for a couple of reasons:

 * It's still useful for Exynos devices.
 * If/when other non-qcom devices with fused Android bootloaders come
   along, it will likely be useful there as well.
 * Downstreams can easily carry DTSI overlays for qcom devices to take
   advantage of this new native U-Boot support there.
 * Maybe the hard position against binman will change/soften on the
   Qualcomm side, in which case we can simply start dropping in DTSIs to
   add support for those devices.

Signed-off-by: Sam Day <me@samcday.com>
---
Changes in v3:
- android_boot etype:
  - collapse _GetOptionalEntryData into _GetEntryData
  - use self.Raise consistently for sane errors
  - clean up and expand tests for 100% coverage
  - fix docstring examples formatting
  - remove unnecessary restriction on os-version in conjunction with
    vendor-dt
- introduce Entry_Android_vendor_dt_table shared base class for
  QCDT+DTBH.
- qcdt+dtbh etypes:
  - formalize header/record format/size constants
  - rework tests and hit 100% coverage
- binman:
  - fix support for listing multiple names to `binman test`
  - add fnmatch globbing support to `binman test`
- Link to v2: https://lore.kernel.org/r/20260608-android-binman-v2-0-b8203682507f@samcday.com

Changes in v2:
- Rebase on next
- Drop all qcom-related work as it has been NAK'd from mach-snapdragon
- Link to v1: https://lore.kernel.org/r/20260606-android-binman-v1-0-c7a3c14b8a3d@samcday.com

---
Sam Day (10):
      binman: support running multiple tests
      binman: test name globbing support
      binman: section: add AlignUp+PadToAlignment helpers
      binman: Android boot image support
      .gitignore: ignore binman-generated blobs
      binman: android_boot: vendor-dt support
      binman: Add QCDT support
      binman: Add DTBH support
      arch: arm: exynos: add j7xelte binman config
      configs: exynos-mobile: pull in binman

 .gitignore                                         |   1 +
 arch/arm/dts/exynos-mobile.dtsi                    |   5 +
 arch/arm/dts/exynos7870-j7xelte-u-boot.dtsi        |  26 ++
 arch/arm/mach-exynos/Kconfig                       |   1 +
 configs/exynos-mobile_defconfig                    |   1 +
 tools/binman/android_vendor_dt_table.py            | 104 ++++++
 tools/binman/cmdline.py                            |   2 +-
 tools/binman/etype/android_boot.py                 | 376 +++++++++++++++++++++
 tools/binman/etype/dtbh.py                         | 108 ++++++
 tools/binman/etype/qcdt.py                         |  80 +++++
 tools/binman/etype/section.py                      |   9 +
 tools/binman/ftest.py                              | 365 ++++++++++++++++++++
 tools/binman/main.py                               |   8 +-
 tools/binman/test/android_boot_chonky_cells.dts    |  13 +
 tools/binman/test/android_boot_dtb_in_v0.dts       |  12 +
 tools/binman/test/android_boot_invalid_addr.dts    |  13 +
 .../binman/test/android_boot_invalid_pagesize.dts  |  11 +
 tools/binman/test/android_boot_invalid_subnode.dts |  12 +
 tools/binman/test/android_boot_missing_kernel.dts  |   9 +
 .../test/android_boot_oversized_bootname.dts       |  12 +
 .../test/android_boot_unsupported_version.dts      |  11 +
 tools/binman/test/android_boot_v0.dts              |  34 ++
 .../test/android_boot_v0_pagesize_too_smol.dts     |  12 +
 tools/binman/test/android_boot_v2.dts              |  50 +++
 tools/binman/test/android_boot_v2_missing_dtb.dts  |  12 +
 .../test/android_boot_v2_pagesize_too_smol.dts     |  13 +
 tools/binman/test/android_boot_v2_vendor_dt.dts    |  14 +
 tools/binman/test/android_boot_vendor_dt.dts       |  27 ++
 tools/binman/test/dtbh.dts                         |  22 ++
 tools/binman/test/dtbh_bad_model_info.dts          |  20 ++
 tools/binman/test/dtbh_invalid_pagesize.dts        |  12 +
 tools/binman/test/dtbh_missing_model_info.dts      |  16 +
 tools/binman/test/dtbh_missing_payload.dts         |  15 +
 tools/binman/test/dtbh_missing_subnodes.dts        |  10 +
 tools/binman/test/dtbh_multi.dts                   |  29 ++
 tools/binman/test/dtbh_multiple_dtbs.dts           |  22 ++
 tools/binman/test/dtbh_page_size_from_abootimg.dts |  30 ++
 tools/binman/test/dtbh_special_subnodes.dts        |  11 +
 tools/binman/test/qcdt.dts                         |  36 ++
 tools/binman/test/qcdt_bad_msm_id.dts              |  17 +
 tools/binman/test/qcdt_invalid_pagesize.dts        |  12 +
 tools/binman/test/qcdt_missing_msm_id.dts          |  12 +
 tools/binman/test/qcdt_missing_payload.dts         |  14 +
 tools/binman/test/qcdt_missing_subnodes.dts        |  13 +
 tools/binman/test/qcdt_multiple_dtbs.dts           |  34 ++
 tools/binman/test/qcdt_page_size_from_abootimg.dts |  33 ++
 tools/binman/test/qcdt_zero_pagesize.dts           |  12 +
 tools/u_boot_pylib/test_util.py                    |  25 +-
 48 files changed, 1724 insertions(+), 12 deletions(-)
---
base-commit: e91911169bc737ee4a79963a1cba8db2aab7c1c0
change-id: 20260604-android-binman-ad7a43f4e99d

Best regards,
-- 
Sam Day <me@samcday.com>

