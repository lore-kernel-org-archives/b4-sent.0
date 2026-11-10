From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 06:07:02 +0000
Subject: [PATCH] clocksource/drivers/sun5i: Allow enabling the driver on
 64-bit sunxi
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-sun5i-hstimer-arch-sunxi-v1-1-9016f63e186f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM0QqDMAyF4VeRXC9gCir4KmMXbc1shHUjURHEd
 7fOy+/A+XcwVmGDvtpBeRWTby6gRwUx+TwyylAMrnYtEdVoS24Ek83yYUWvMV3TJkhtx95xiGH
 ooNx/ym/Z/unn67YtYeI4Xz04jhMsPfcIfAAAAA==
X-Change-ID: 20261110-sun5i-hstimer-arch-sunxi-167ea2ebcbd7
To: Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>
Cc: linux-kernel@vger.kernel.org, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Michal Piekos <michal.piekos@mmpsystems.pl>, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794290821; l=2552;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=JuIHgoMW4UEdB04flY1z4eCSsxuIeVm+zZ4kA091Ln8=;
 b=qT9bZuPBCA4Hv8LzVHeLlQ9t6bZS2UTSiDBMfA2GoO3ow4Zi8c5uqjz0rwUkGwKsLY4zchDjQ
 uZVIryz/vz7Buw5w8euq7lOs32V14cdbWJEkLjIeTxYh5nSCXywOtA8
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The high-speed timer driver binds "allwinner,sun20i-d1-hstimer", which
the H616 device tree uses as the fallback compatible of its
"allwinner,sun50i-h616-hstimer" node and the D1/T113 device tree uses
directly. SUN5I_HSTIMER, however, only has a prompt under COMPILE_TEST
and is selected by the 32-bit sunxi machine Kconfig alone, so arm64 and
RISC-V sunxi kernels cannot enable it and these nodes never probe.

Make the prompt visible on ARCH_SUNXI. The driver registers its
clocksource and clockevent at rating 340: below the architected timer's
clocksource (400) and below the sun4i timer (350), which ARCH_SUNXI
already selects on arm64 and RISC-V. Enabling it therefore adds a
second hardware time base without changing which one the kernel uses.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
The H616 and D1/T113 hstimer nodes and the D1 driver support were merged
for 7.2, but the driver still cannot be enabled outside COMPILE_TEST on
arm64 and RISC-V.

Tested on an Orange Pi Zero2 (H616) with a 7.3 kernel carrying this
patch and CONFIG_SUN5I_HSTIMER=y: the hstimer node at 0x3005000
probes and available_clocksource lists "arch_sys_counter timer
hstimer".

This patch was developed with Claude (Anthropic) as a coding
assistant. It investigated the problem and wrote the code and the commit
message; I reviewed it, and it was tested on an Orange Pi Zero2 (H616)
as described above.
---
 drivers/clocksource/Kconfig | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/clocksource/Kconfig b/drivers/clocksource/Kconfig
index da83483296d5..971491d2e584 100644
--- a/drivers/clocksource/Kconfig
+++ b/drivers/clocksource/Kconfig
@@ -172,12 +172,17 @@ config SUN4I_TIMER
 	  Enables support for the Sun4i timer.
 
 config SUN5I_HSTIMER
-	bool "Sun5i timer driver" if COMPILE_TEST
+	bool "Sun5i timer driver" if COMPILE_TEST || ARCH_SUNXI
 	select CLKSRC_MMIO
 	depends on COMMON_CLK
 	help
 	  Enables support the Sun5i timer.
 
+	  The 32-bit sunxi platforms that have this timer select it. On
+	  64-bit (ARM64, RISC-V) sunxi SoCs such as the H616 and D1 it
+	  registers an additional clocksource and clockevent device, rated
+	  below the ones the kernel already uses there.
+
 config TEGRA_TIMER
 	bool "Tegra timer driver" if COMPILE_TEST
 	select CLKSRC_MMIO

---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261110-sun5i-hstimer-arch-sunxi-167ea2ebcbd7

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

