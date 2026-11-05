From: Rajan Yadav <rajanyadav0307@gmail.com>
Date: Wed, 04 Nov 2026 22:40:59 -0600
Subject: [PATCH 4/6] arm64: dts: allwinner: a100: Add A133 speed grade
 efuse cells
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-a133-series-v1-4-58217cb33a87@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793853656; l=1561;
 i=rajanyadav0307@gmail.com; s=20261103; h=from:subject:message-id;
 bh=/IybJoRS+RCeafxjvBtCrPNxM5kYK6ctY7B27mLTNVg=;
 b=NgBTLrOPCIZQ/56YuWB9qFnXvWIEKYUbNUchtr1oEcU4Ll5eeGgzPWYJLFIgfVLIeJDA9sL71
 dhuIeKxEsVpC3qoVoVyJ6nEXPP+mXZUgXiMEbe8nOvVpG9YSewD6k5c
X-Developer-Key: i=rajanyadav0307@gmail.com; a=ed25519;
 pk=4ZPeiP5qrv2b44q/Obxi2koUS70Q6npbttJnpUoTlgg=
X-Endpoint-Received: by B4 Relay for rajanyadav0307@gmail.com/20261103 with auth_id=1391
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The A133 speed grade selection also needs the chip marking ID (SID
offset 0x00), the word at 0x20, whose low 12 bits the vendor BSP calls
PCPU, and the word at 0x28 with the bin extension bit. Add nvmem cells
for them at the offsets the BSP uses. The H616 reads the same kind of
marking ID at offset 0x00 as its speed grade.

The cells are used by the A133 OPP table added later in this series;
the A100 OPP table keeps using only the existing 0x1c cell.

Claude Code (Anthropic) drafted this change and its message from the
vendor BSP device tree; I reviewed it and checked it with dtbs_check.

Signed-off-by: Rajan Yadav <rajanyadav0307@gmail.com>
---
 arch/arm64/boot/dts/allwinner/sun50i-a100.dtsi | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/arch/arm64/boot/dts/allwinner/sun50i-a100.dtsi b/arch/arm64/boot/dts/allwinner/sun50i-a100.dtsi
index ba6020989ce..d1164f3b549 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-a100.dtsi
+++ b/arch/arm64/boot/dts/allwinner/sun50i-a100.dtsi
@@ -176,6 +176,10 @@ efuse@3006000 {
 			#address-cells = <1>;
 			#size-cells = <1>;
 
+			chip_marking: chip-marking@0 {
+				reg = <0x0 0x2>;
+			};
+
 			ths_calibration: calib@14 {
 				reg = <0x14 8>;
 			};
@@ -183,6 +187,14 @@ ths_calibration: calib@14 {
 			cpu_speed_grade: cpu-speed-grade@1c {
 				reg = <0x1c 0x2>;
 			};
+
+			cpu_pcpu: cpu-pcpu@20 {
+				reg = <0x20 0x2>;
+			};
+
+			cpu_bin_ext: cpu-bin-ext@28 {
+				reg = <0x28 0x4>;
+			};
 		};
 
 		watchdog@30090a0 {

-- 
2.34.1

