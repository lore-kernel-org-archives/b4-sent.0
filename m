From: Sam Day <me@samcday.com>
Subject: [PATCH RESEND 00/16] MSM8960 / mach-snapdragon ARMv7 support
Date: Mon, 01 Jun 2026 18:12:41 +1000
Message-Id: <20260601-qcom-armv7-v1-0-05a08d87e476@samcday.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDU2MD3cLk/FzdxKLcMnNdQxMLM2MDi0QLY9NkJaCGgqLUtMwKsGHRSkG
 uwa5+LkqxtbUAP+oIp2QAAAA=
X-Change-ID: 20260530-qcom-armv7-1486308a835c
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Michal Simek <michal.simek@amd.com>, 
 Angelo Dureghello <angelo@kernel-space.org>, 
 Eugen Hristev <ehristev@kernel.org>, Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Yao Zi <me@ziyao.cc>, Simon Glass <sjg@chromium.org>, 
 Sughosh Ganu <sughosh.ganu@arm.com>, George Chan <gchan9527@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>, 
 Tien Fong Chee <tien.fong.chee@altera.com>, Peng Fan <peng.fan@nxp.com>, 
 Alif Zakuan Yuslaimi <alif.zakuan.yuslaimi@altera.com>, 
 Anshul Dalal <anshuld@ti.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Tingting Meng <tingting.meng@altera.com>, Alice Guo <alice.guo@nxp.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 David Wronek <david.wronek@mainlining.org>, 
 Danila Tikhonov <danila@jiaxyga.com>, 
 Varadarajan Narayanan <quic_varada@quicinc.com>, 
 Lukasz Majewski <lukma@denx.de>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Jens Reidel <adrian@mainlining.org>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780301569; l=4310;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=T28585uIMl15AFNyBkNqXazma/ZKb0VkseG4bs9GO9s=;
 b=M+hVSqZm4fN3d95/6RME7bk4b6nv78t76yiazJBPnEIzVMzyWOWuEHRrECWjPRLw0bHR2owox
 0zKmDY4dWGwBEAH3bfT8gT3ZfbWYQ2+yxQhYfaxSMCKCR1ACO6QA8Mh
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

** Resending because I found new ways to dislike Proton Mail (it failed
the series midway due to "spamming". Sigh.). **

This patch series introduces support for ARMv7 Qualcomm SoCs, starting
with MSM8960/MSM8930/MSM8227.

An overview of the changes:
 * serial_msm reintroduces the previous packed RX/TX software mode
   operation, as this is compatible with all UARTDM versions (1.4 and
   older). It's added alongside the newer single-char mode for 1.4.
 * A timer driver is introduced for KPSS. I don't know if *all* ARMv7
   qcom SoCs lack generic ARM CP15 debug timer support, but at least
   MSM8960/MSM8930 do.
 * mach-snapdragon board code is shuffled around a bit to build cleanly
   on ARM64.
 * prev_bl_data support is extended to ARM32 (which uses r2 for passing
   FDT/ATAGS pointers, rather than r0)
 * qcom_parse_memory is revised to support arm32 memory nodes (which are
   1-cell rather than 2-cell).
 * Basic ATAGS support is introduced, so that the memory info can be
   used from previous bootloaders that do not understand FDTs at all.
 * PS_HOLD sysreset and pinctrl-qcom needed some minor tweaks to handle
   some nuances that challenge the current assumptions.
 * A pinctrl driver is introduced for MSM8960.
 * Initial MSM8960 GCC infra is introduced.

I tested this series on:
 * Nokia Lumia 520 (msm8227). No working buttons yet as these are
   exposed as GPIO-over-PMIC-over-SSBI (drivers will be proposed at a
   later date).
 * Samsung Galaxy Express GT-I8730 (msm8930). Volume rockers + home
   button are working via the new pinctrl-msm8960 driver. Power
   button not working yet (needs PMIC driver infra).
 * I have no msm8960/apq8064 devices, looking for folks to test those.

To confirm there was no regressions with ARM64 and/or newer devices, I
also tested on:
 * db410c (msm8916)
 * google-sargo (sdm670)

Signed-off-by: Sam Day <me@samcday.com>
---
Sam Day (16):
      serial: msm: UARTDM <1.4 support
      timer: Qualcomm KPSS timer support
      arm: save_prev_bl_data: ARM32 support
      mach-snapdragon: qcom_parse_memory 32-bit support
      mach-snapdragon: gate ARM64 features
      mach-snapdragon: introduce ARCH_SNAPDRAGON_ARM32
      configs: introduce qcom_armv7_defconfig
      board: qualcomm: add MSM8960 debug UART config
      sysreset: qcom-pshold: offset support
      pinctrl: qcom: configurable GPIO offset/stride
      pinctrl: qcom: introduce MSM8960 driver
      mach-snapdragon: parse incoming ARM32 ATAGS
      clk: qcom: MSM8960 GCC driver
      clk: qcom: arch-agnostic pointer fmtstrings
      serial: msm: wait for TX empty before reinit
      button: remap phone HOMEPAGE button

 arch/arm/Kconfig                             |  11 +-
 arch/arm/lib/save_prev_bl_data.c             |  49 ++++---
 arch/arm/mach-snapdragon/Kconfig             |   6 +
 arch/arm/mach-snapdragon/board.c             | 188 ++++++++++++++++++--------
 arch/arm/mach-snapdragon/include/mach/gpio.h |  12 +-
 board/qualcomm/debug-msm8960.config          |   5 +
 configs/qcom_armv7_defconfig                 |  61 +++++++++
 drivers/button/Kconfig                       |   2 +-
 drivers/button/button-uclass.c               |   1 +
 drivers/clk/qcom/Kconfig                     |   8 ++
 drivers/clk/qcom/Makefile                    |   1 +
 drivers/clk/qcom/clock-msm8960.c             | 189 +++++++++++++++++++++++++++
 drivers/clk/qcom/clock-qcom.c                |   8 +-
 drivers/gpio/msm_gpio.c                      |   2 +-
 drivers/pinctrl/qcom/Kconfig                 |   9 ++
 drivers/pinctrl/qcom/Makefile                |   1 +
 drivers/pinctrl/qcom/pinctrl-msm8960.c       | 135 +++++++++++++++++++
 drivers/pinctrl/qcom/pinctrl-qcom.c          |   2 +-
 drivers/serial/serial_msm.c                  | 142 +++++++++++++++++---
 drivers/sysreset/sysreset_qcom-pshold.c      |   9 +-
 drivers/timer/Kconfig                        |   7 +
 drivers/timer/Makefile                       |   1 +
 drivers/timer/qcom-kpss-timer.c              |  98 ++++++++++++++
 23 files changed, 843 insertions(+), 104 deletions(-)
---
base-commit: 8d3ba3753bdb5068884196ff696cc48177bfdda5
change-id: 20260530-qcom-armv7-1486308a835c

Best regards,
-- 
Sam Day <me@samcday.com>

