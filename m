From: Dang Huynh <dang.huynh@mainlining.org>
Date: Wed, 17 Sep 2025 03:25:09 +0700
Subject: [PATCH 12/25] dts: unisoc: rda8810pl: Add OPP for CPU and define
 L2 cache
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250917-rda8810pl-drivers-v1-12-9ca9184ca977@mainlining.org>
References: <20250917-rda8810pl-drivers-v1-0-9ca9184ca977@mainlining.org>
In-Reply-To: <20250917-rda8810pl-drivers-v1-0-9ca9184ca977@mainlining.org>
To: Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Sebastian Reichel <sre@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Ulf Hansson <ulf.hansson@linaro.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-unisoc@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-rtc@vger.kernel.org, 
 linux-clk@vger.kernel.org, linux-pm@vger.kernel.org, 
 dmaengine@vger.kernel.org, linux-hardening@vger.kernel.org, 
 linux-mmc@vger.kernel.org, Dang Huynh <dang.huynh@mainlining.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758054322; l=1899;
 i=dang.huynh@mainlining.org; s=20250917; h=from:subject:message-id;
 bh=GGuxO6sraElHWuAQ/FHMGYb5YyRNyQdi3IohZFnJO8o=;
 b=45yf1gKixsaK1bkMYGoKRUqzU4uJvxee7LDvXHPDAXh0W7cXAZpeAuF2mOgWJyZNK24hfZKsM
 GIqqJqEHIYuDn891fKiP8cE0LCeJJW/uSiFgTzEbed0Tkmppo8BGIdV
X-Developer-Key: i=dang.huynh@mainlining.org; a=ed25519;
 pk=RyzH4CL4YU/ItXYUurA51EVBidfx4lIy8/E4EKRJCUk=
X-Endpoint-Received: by B4 Relay for dang.huynh@mainlining.org/20250917 with auth_id=526
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add available frequency table came from downstream kernel, this
ensures that the CPU clock can be dynamically tuned.

Signed-off-by: Dang Huynh <dang.huynh@mainlining.org>
---
 arch/arm/boot/dts/unisoc/rda8810pl.dtsi | 52 +++++++++++++++++++++++++++++++++
 1 file changed, 52 insertions(+)

diff --git a/arch/arm/boot/dts/unisoc/rda8810pl.dtsi b/arch/arm/boot/dts/unisoc/rda8810pl.dtsi
index 1f7a6908d68367441e5dc865216cc7a5c39feb35..299b29e4df6e0a04c5769a568eba73ed1684a9e5 100644
--- a/arch/arm/boot/dts/unisoc/rda8810pl.dtsi
+++ b/arch/arm/boot/dts/unisoc/rda8810pl.dtsi
@@ -16,6 +16,54 @@ / {
 	#address-cells = <1>;
 	#size-cells = <1>;
 
+	/*
+	 * There are two frequency table for CPU.
+	 *
+	 * "High" table is used when operating in normal mode
+	 * "Low" table is used when operating in power saving mode
+	 */
+	cpu_high_opp_table: opp-table-0 {
+		compatible = "operating-points-v2";
+		opp-shared;
+
+		opp-329333333 {
+			opp-hz = /bits/ 64 <329333333>;
+		};
+
+		opp-395200000 {
+			opp-hz = /bits/ 64 <395200000>;
+		};
+
+		opp-494000000 {
+			opp-hz = /bits/ 64 <494000000>;
+		};
+
+		opp-988000000 {
+			opp-hz = /bits/ 64 <988000000>;
+		};
+	};
+
+	cpu_low_opp_table: opp-table-1 {
+		compatible = "operating-points-v2";
+		opp-shared;
+
+		opp-266666666 {
+			opp-hz = /bits/ 64 <266666666>;
+		};
+
+		opp-320000000 {
+			opp-hz = /bits/ 64 <320000000>;
+		};
+
+		opp-400000000 {
+			opp-hz = /bits/ 64 <400000000>;
+		};
+
+		opp-800000000 {
+			opp-hz = /bits/ 64 <800000000>;
+		};
+	};
+
 	cpus {
 		#address-cells = <1>;
 		#size-cells = <0>;
@@ -24,6 +72,10 @@ cpu@0 {
 			device_type = "cpu";
 			compatible = "arm,cortex-a5";
 			reg = <0x0>;
+			next-level-cache = <&l2>;
+
+			clocks = <&ap_syscon CLK_CPU>;
+			operating-points-v2 = <&cpu_high_opp_table>;
 		};
 	};
 

-- 
2.51.0

