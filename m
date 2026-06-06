From: Sam Day <me@samcday.com>
Subject: [PATCH 00/11] PM8916 PON support
Date: Sat, 06 Jun 2026 18:47:31 +1000
Message-Id: <20260606-pm8916-pon-v1-0-170c9cbe5099@samcday.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDMwNj3YJcC0tDM92C/Dxdc2OLFHMzsyQLAwMzJaCGgqLUtMwKsGHRsbW
 1APuEVJtcAAAA
X-Change-ID: 20260603-pm8916-pon-738d766b8006
To: u-boot@lists.denx.de, Sumit Garg <sumit.garg@kernel.org>, 
 u-boot-qcom@groups.io
Cc: Tom Rini <trini@konsulko.com>, 
 Casey Connolly <casey.connolly@linaro.org>, Peng Fan <peng.fan@nxp.com>, 
 Leo Yu-Chi Liang <ycliang@andestech.com>, Anshul Dalal <anshuld@ti.com>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Justin Klaassen <justin@tidylabs.net>, 
 Jamie Gibbons <jamie.gibbons@microchip.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Andrew Goodbody <andrew.goodbody@linaro.org>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Mateus Lima Alves <mateuslima.ti@gmail.com>, 
 Sughosh Ganu <sughosh.ganu@arm.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 George Chan <gchan9527@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Peter Robinson <pbrobinson@gmail.com>, 
 Ariel D'Alessandro <ariel.dalessandro@collabora.com>, 
 Dmitrii Merkurev <dimorinny@google.com>, Sam Day <me@samcday.com>, 
 Simon Glass <sjg@chromium.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780735669; l=3258;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=ticXsztP8o8s+OSoF+Wy8kc3BBouMVa5KxJj3EXqX6E=;
 b=NrkZfaEIEZBHcA+WCR/lELA1BCf+1KR7SKSDKXk6B+lRRIvYKPaJM8+4qmqiX/ifwomw1favI
 ZMOPQ4CXG4IA6NqjI9HsJaqc1PJsPwMlZ0EU90/q+RM/ujwLDBOdkbB
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series introduces sysreset + reboot-mode drivers for PM8916 PON.

Additionally, fastboot gains support for driving DM reboot-mode, so that
`fastboot reboot bootloader` works as you'd expect.

This series should be considered supplementary and slightly alternative
to Aswin's NVMEM-based approach currently on the list. I cherry-picked
Aswin's commit for adding reboot-mode detection to mach-snapdragon
board code.

I think a native PON driver for the older (non-SDAM) PMICs should exist,
rather than trying to bridge the gap with synthetic NVMEM DT nodes. The
main issue is that we'd need to define these overrides for every
device/SoC-family since those nodes don't (and won't?) exist in the
mainline kernel.

The other main differences between this series and Aswin's are:

 * A sysreset driver is implemented, in addition to reboot-mode. This is
   what makes the poweroff command work on MSM8916 and other older
   platforms lacking a (sane, or any at all) PSCI implementation.
 * The DM reboot-mode-driven fastboot_set_reboot_flag implementation,
   which is what makes `fastboot reboot bootloader` work.

I think the PON infra introduced in this series can be generalized out
beyond PM8916, but I decided to stop here and leave further
generalization up to a follow-up series (or follow-up version, depending
on feedback!)

Link: https://lore.kernel.org/u-boot/20260521180549.282377-1-aswin.murugan@oss.qualcomm.com/
Signed-off-by: Sam Day <me@samcday.com>
---
Aswin Murugan (1):
      mach-snapdragon: Integrate reboot-mode handling

Sam Day (10):
      button: qcom-pmic: introduce exported setup method
      drivers: misc: pm8916_pon: add glue driver
      qcom_defconfig: enable PM8916_PON
      drivers: misc: pm8916_pon: support setting reboot type
      sysreset: qcom-pshold: PM8916 PON reset type support
      qcom_defconfig: enable poweroff command
      reboot-mode: pm8916-pon: add new driver
      reboot-mode: reboot method activation support
      fastboot: DM_REBOOT_MODE reset support
      qcom_defconfig: enable reboot modes

 arch/arm/mach-snapdragon/board.c             |  56 +++++++--
 configs/qcom_defconfig                       |   5 +
 drivers/button/button-qcom-pmic.c            |   7 +-
 drivers/fastboot/Kconfig                     |   7 ++
 drivers/fastboot/Makefile                    |   1 +
 drivers/fastboot/fb_reboot_mode.c            |  51 ++++++++
 drivers/misc/Kconfig                         |   7 ++
 drivers/misc/Makefile                        |   1 +
 drivers/misc/pm8916_pon.c                    | 167 +++++++++++++++++++++++++++
 drivers/reboot-mode/Makefile                 |   1 +
 drivers/reboot-mode/reboot-mode-pm8916-pon.c |  88 ++++++++++++++
 drivers/reboot-mode/reboot-mode-uclass.c     |  18 +++
 drivers/sysreset/sysreset_qcom-pshold.c      |   9 ++
 include/button/qcom-pmic.h                   |  17 +++
 include/pm8916_pon.h                         |  18 +++
 include/reboot-mode/reboot-mode.h            |  12 ++
 16 files changed, 450 insertions(+), 15 deletions(-)
---
base-commit: 75daa277941702bf58c88d65c0cb6ed962899d9e
change-id: 20260603-pm8916-pon-738d766b8006

Best regards,
-- 
Sam Day <me@samcday.com>

