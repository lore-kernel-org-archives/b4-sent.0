From: Aaron Kling <webgeek1234@gmail.com>
Date: Thu, 28 Aug 2025 23:01:31 -0500
Subject: [PATCH RFC 5/7] arm64: tegra: tegra210: Add actmon
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250828-t210-actmon-v1-5-aeb19ec1f244@gmail.com>
References: <20250828-t210-actmon-v1-0-aeb19ec1f244@gmail.com>
In-Reply-To: <20250828-t210-actmon-v1-0-aeb19ec1f244@gmail.com>
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 MyungJoo Ham <myungjoo.ham@samsung.com>, 
 Kyungmin Park <kyungmin.park@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, Dmitry Osipenko <digetx@gmail.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-pm@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756440091; l=1154;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=JRVT2B6B9kttupzRP71VsPsEx2g3JnQatmD4nEG5i7w=;
 b=ume6WM1Y/mV4gjJyWs58SkXgqzr3RBXtRyPd9dWA37DL7gi6M86+yC2bKVfR7xONdBiuW1wnK
 zBH3x8J3/brDJtppA8RPePAZgMcvmxiuczXJvx83Ut3ICkdmRgTeVA5
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This enables the action monitor to facilitate dynamic frequency scaling.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra210.dtsi | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/arch/arm64/boot/dts/nvidia/tegra210.dtsi b/arch/arm64/boot/dts/nvidia/tegra210.dtsi
index 402b0ede1472af625d9d9e811f5af306d436cc98..6da10db893add44a98fde1666c382511212fd43c 100644
--- a/arch/arm64/boot/dts/nvidia/tegra210.dtsi
+++ b/arch/arm64/boot/dts/nvidia/tegra210.dtsi
@@ -485,6 +485,18 @@ flow-controller@60007000 {
 		reg = <0x0 0x60007000 0x0 0x1000>;
 	};
 
+	actmon@6000c800 {
+		compatible = "nvidia,tegra210-actmon", "nvidia,tegra124-actmon";
+		reg = <0x0 0x6000c800 0x0 0x400>;
+		interrupts = <GIC_SPI 45 IRQ_TYPE_LEVEL_HIGH>;
+		clocks = <&tegra_car TEGRA210_CLK_ACTMON>,
+			 <&tegra_car TEGRA210_CLK_EMC>;
+		clock-names = "actmon", "emc";
+		resets = <&tegra_car 119>;
+		reset-names = "actmon";
+		#cooling-cells = <2>;
+	};
+
 	gpio: gpio@6000d000 {
 		compatible = "nvidia,tegra210-gpio", "nvidia,tegra30-gpio";
 		reg = <0x0 0x6000d000 0x0 0x1000>;

-- 
2.50.1

