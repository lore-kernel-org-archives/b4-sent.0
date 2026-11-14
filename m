From: Volodymyr Chapman <volodymyrchapman@gmail.com>
Date: Sat, 14 Nov 2026 14:12:49 +0000
Subject: [PATCH] ARM: tegra: nyan: Enable the 32 kHz clock for the Wi-Fi
 module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-nyan-wifi-32k-v1-1-311c6f2163d4@gmail.com>
X-B4-Tracking: v=1; b=H4sIAGBs+GoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0MT3bzKxDzd8sy0TF1jo2xdS0szkxRjU0PjJPNUJaCegqLUtMwKsHn
 RsbW1AMJLh35fAAAA
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Volodymyr Chapman <volodymyrchapman@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794665582; l=1933;
 i=volodymyrchapman@gmail.com; s=20261114; h=from:subject:message-id;
 bh=ZYcx9OmFDEjiXweNhRDW+WsVewYRwZNRDfsX+1SjsDc=;
 b=NMdixx4IBeNvJhZM1A6u2yGr3+ELQuQjkDfkP8V8Bcrh/XFhHeTIMPhoj9VEJ16PrrFP1lz20
 sN18NkBfuSPAcuuarT8GdILuCfV9gx2CI+nazixyLImdiEMivERyqGw
X-Developer-Key: i=volodymyrchapman@gmail.com; a=ed25519;
 pk=MFRHEFOAD35s30Ob7oHqbHPECBoWpPLCMrM4ekqB900=
X-Endpoint-Received: by B4 Relay for volodymyrchapman@gmail.com/20261114 with auth_id=1527
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Marvell SD8897 Wi-Fi/Bluetooth module on the Nyan Chromebooks needs
a 32.768 kHz sleep clock, which these boards take from the PMC blink
output (CLK_32K_OUT_PA0). Nothing in the device tree requests that
clock, so whether it is running when the SDIO card is brought up
depends on the state the firmware left it in. On warm reboots it is
usually off, and every attempt to bring up the card fails with:

  mmc2: error -110 whilst initialising SDIO card

leaving the system without Wi-Fi. Toggling the reset GPIO on each retry
does not help.

Describe the clock in the SDIO power sequence, as the Tegra30 Asus
Transformer and Nexus 7 device trees already do for their Wi-Fi
modules, so that mmc-pwrseq-simple enables it before releasing the
module from reset.

Tested on an HP Chromebook 14 G3 (nyan-blaze) running v6.6.144: with
this change Wi-Fi came up on 8 out of 8 warm reboots, against 1 out of
22 before, and on 5 out of 5 cold boots (4 of them on battery), and
the clock summary shows pmc_blink enabled by pwrseq-sdhci0 (ext_clock).
nyan-big shares this file but was not tested.

Signed-off-by: Volodymyr Chapman <volodymyrchapman@gmail.com>
---
 arch/arm/boot/dts/nvidia/tegra124-nyan.dtsi | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/arch/arm/boot/dts/nvidia/tegra124-nyan.dtsi b/arch/arm/boot/dts/nvidia/tegra124-nyan.dtsi
index 89a749c..c98de0d 100644
--- a/arch/arm/boot/dts/nvidia/tegra124-nyan.dtsi
+++ b/arch/arm/boot/dts/nvidia/tegra124-nyan.dtsi
@@ -645,6 +645,9 @@
 	sdhci0_pwrseq: pwrseq-sdhci0 {
 		compatible = "mmc-pwrseq-simple";
 
+		clocks = <&tegra_pmc TEGRA_PMC_CLK_BLINK>;
+		clock-names = "ext_clock";
+
 		reset-gpios = <&gpio TEGRA_GPIO(X, 7) GPIO_ACTIVE_LOW>;
 	};
 

---
base-commit: 97d73c8251226cf27cc6656b4c542869bb8c69fa
change-id: 20261114-nyan-wifi-32k-9964d3513b7e

Best regards,
-- 
Volodymyr Chapman <volodymyrchapman@gmail.com>

