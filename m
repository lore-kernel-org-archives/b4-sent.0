From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/2] sunxi: H6/H616: SPL PMIC access over RSB, use it on
 the OrangePi Zero2
Date: Tue, 10 Nov 2026 06:19:35 +0000
Message-Id: <20261110-h616-rsb-spl-v1-0-bf91cc26507e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0MD3QwzQzPdouIk3eKCHN0kS9NE4ySLFFMzk1QloJaCotS0zAqwcdG
 xEH5xaVJWanIJyAyl2loArw6r7HAAAAA=
X-Change-ID: 20261110-h616-rsb-spl-b95a3b8d564e
To: u-boot@lists.u-boot-project.org
Cc: Andre Przywara <andre.przywara@arm.com>, Tom Rini <trini@konsulko.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Heiko Schocher <hs@nabladev.com>, Arun Iyengar <aiyengar1990@gmail.com>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794291575; l=2079;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=aMnnAG5SZDw5T5D+CG0C0FFS+7JltfHPunUls57Ms9s=;
 b=rkt142fKq14S+nlyY8UKKi9kg/xHaSRtg28hoLPj1YLFEQUGedg+fO3EJFLjGhONPXtGDsmJU
 ekh4JWuEUHUCBaryzrixcUZFsmZI8pqKxxK4MO19tUFL93TTPfqNTO4
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On H6/H616 boards the AXP305/AXP805/AXP806 PMIC can be wired to R_RSB,
as on the OrangePi Zero2. TF-A then switches the PMIC to RSB mode (Linux
uses RSB too), and it stays there until it loses power. The SPL can only
reach it over R_I2C on these SoCs, so after every warm reboot axp_init()
fails with "Failed to set core voltage! Can't set CPU frequency" and the
CPU stays at 408 MHz until Linux cpufreq takes over.

Patch 1 adds the H6 generation to the SPL part of the sun8i RSB driver
and uses the RSB address of the AXP305/805/806. Nothing changes for
boards that do not select CONFIG_SYS_I2C_SUN8I_RSB.
Patch 2 switches the OrangePi Zero2 SPL to RSB.

Tested on an OrangePi Zero2 (H616, AXP305): cold boot and warm reboots
come up without the core voltage error, TF-A and Linux still find the
PMIC on RSB. A v2027.01-rc2 build with these patches (together with my
sunxi DRAM and USB hub series) also came up from a warm reboot without
the error and with 1 GiB. Build-tested for orangepi_zero2,
orangepi_zero3, x96_mate, orangepi_3, pine_h64 and Cubieboard4 (sun9i,
the other SPL RSB user) with no new warnings.

These patches were developed with Claude (Anthropic) as a
coding assistant: it investigated the problems, wrote the code and the
commit messages. I reviewed them, and they were tested on an Orange Pi
Zero2 (H616) as described above.

---
Arun Iyengar (2):
      sunxi: H6/H616: support the RSB bus for the SPL PMIC access
      sunxi: configs: OrangePi Zero2: talk to the AXP305 over RSB

 arch/arm/include/asm/arch-sunxi/cpu_sun50i_h6.h |  1 +
 arch/arm/include/asm/arch-sunxi/prcm_sun50i.h   |  3 +++
 arch/arm/mach-sunxi/pmic_bus.c                  | 22 ++++++++++++++++++----
 configs/orangepi_zero2_defconfig                |  6 +-----
 drivers/i2c/sun8i_rsb.c                         | 10 ++++++++++
 5 files changed, 33 insertions(+), 9 deletions(-)
---
base-commit: ecdcf9e365df6249a57cd8cc946e7026804ff4ae
change-id: 20261110-h616-rsb-spl-b95a3b8d564e

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

