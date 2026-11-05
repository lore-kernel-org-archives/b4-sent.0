From: Rajan Yadav <rajanyadav0307@gmail.com>
Date: Wed, 04 Nov 2026 22:41:01 -0600
Subject: [PATCH 6/6] arm64: dts: allwinner: a133: Use the A133 CPU OPP
 table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-a133-series-v1-6-58217cb33a87@gmail.com>
References: <20261104-a133-series-v1-0-58217cb33a87@gmail.com>
In-Reply-To: <20261104-a133-series-v1-0-58217cb33a87@gmail.com>
To: Yangtao Li <tiny.windzz@gmail.com>, Viresh Kumar <vireshk@kernel.org>, 
 Nishanth Menon <nm@ti.com>, Stephen Boyd <sboyd@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Cody Eksal <masterr3c0rd@epochal.quest>, 
 Alexander Sverdlin <alex@sverdlin.org>, 
 Rajan Yadav <rajanyadav0307@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793853656; l=3324;
 i=rajanyadav0307@gmail.com; s=20261103; h=from:subject:message-id;
 bh=x5FE0Mhj6qYPFUq6zvVIYk5BeSBjVopTztLIpG1kUCM=;
 b=piOPG5YLJZp9HRQREOhbgGNTbR72tV2osHC80xB2c/s04EqF2pecIuVVvVFrmA7bNITkzMaP1
 rEp1ItCY4kyCpCPkzegLvgQs+BLD8k0cHTkALKaQm76R1ezINQbZfyN
X-Developer-Key: i=rajanyadav0307@gmail.com; a=ed25519;
 pk=4ZPeiP5qrv2b44q/Obxi2koUS70Q6npbttJnpUoTlgg=
X-Endpoint-Received: by B4 Relay for rajanyadav0307@gmail.com/20261103 with auth_id=1391
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Switch the three A133 boards in mainline (Baijie Helperboard A133,
Liontron H-A133L and Teclast P80) from the A100 OPP table to the A133
one, so the speed grade is selected as the vendor does it.

What changes depends on the chip:
- revision A-E parts with a normal marking ID get a0-a2 from the bin
  field, as they get speed0-2 today, with the same voltages; only
  1080 MHz becomes 1008 MHz. The exception is a part whose ICPU and
  PCPU values are in the range for which the BSP forces a0.
- revision F and later parts with a normal marking ID get the a3-a6
  voltages: higher at 408 and 600 MHz, equal or lower from 1008 MHz,
  and 1008 instead of 1080 MHz.
- "high speed" parts get the b grades, with 1416 and 1512 MHz instead
  of 1464 MHz.
- if the firmware does not provide SMCCC SOC_ID, the driver keeps the
  A100 selection, adds the BSP's a0 rule for normal parts and warns at
  boot.

All three boards supply the CPUs from AXP803 DCDC2 with a 0.81-1.2 V
range, which covers every new voltage. Without the A133 support in
sun50i-cpufreq-nvmem the A100 fallback applies. The Teclast P80 also
needs "cpufreq: sun50i: Handle boards with the allwinner,sun50i-a133
compatible" to get cpufreq at all.

Claude Code (Anthropic) drafted this change and its message; I
reviewed it. I tested the A133 table on a KickPi K5C; I cannot test
these three boards.

Suggested-by: Andre Przywara <andre.przywara@arm.com>
Signed-off-by: Rajan Yadav <rajanyadav0307@gmail.com>
---
 arch/arm64/boot/dts/allwinner/sun50i-a133-helperboard-core.dtsi | 2 +-
 arch/arm64/boot/dts/allwinner/sun50i-a133-liontron-h-a133l.dts  | 2 +-
 arch/arm64/boot/dts/allwinner/sun50i-a133-teclast-p80.dts       | 2 +-
 3 files changed, 3 insertions(+), 3 deletions(-)

diff --git a/arch/arm64/boot/dts/allwinner/sun50i-a133-helperboard-core.dtsi b/arch/arm64/boot/dts/allwinner/sun50i-a133-helperboard-core.dtsi
index 545972d2324..3a89d3f74b3 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-a133-helperboard-core.dtsi
+++ b/arch/arm64/boot/dts/allwinner/sun50i-a133-helperboard-core.dtsi
@@ -7,7 +7,7 @@
 /dts-v1/;
 
 #include "sun50i-a100.dtsi"
-#include "sun50i-a100-cpu-opp.dtsi"
+#include "sun50i-a133-cpu-opp.dtsi"
 
 /{
 	model = "Baijie A133 HelperBoard Core";
diff --git a/arch/arm64/boot/dts/allwinner/sun50i-a133-liontron-h-a133l.dts b/arch/arm64/boot/dts/allwinner/sun50i-a133-liontron-h-a133l.dts
index 90a50910f07..1b9cbcbe5f3 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-a133-liontron-h-a133l.dts
+++ b/arch/arm64/boot/dts/allwinner/sun50i-a133-liontron-h-a133l.dts
@@ -6,7 +6,7 @@
 /dts-v1/;
 
 #include "sun50i-a100.dtsi"
-#include "sun50i-a100-cpu-opp.dtsi"
+#include "sun50i-a133-cpu-opp.dtsi"
 
 #include <dt-bindings/gpio/gpio.h>
 #include <dt-bindings/leds/common.h>
diff --git a/arch/arm64/boot/dts/allwinner/sun50i-a133-teclast-p80.dts b/arch/arm64/boot/dts/allwinner/sun50i-a133-teclast-p80.dts
index 47b5f2ac824..7d4c346276e 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-a133-teclast-p80.dts
+++ b/arch/arm64/boot/dts/allwinner/sun50i-a133-teclast-p80.dts
@@ -6,7 +6,7 @@
 /dts-v1/;
 
 #include "sun50i-a100.dtsi"
-#include "sun50i-a100-cpu-opp.dtsi"
+#include "sun50i-a133-cpu-opp.dtsi"
 
 #include <dt-bindings/gpio/gpio.h>
 

-- 
2.34.1

