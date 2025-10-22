From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 21 Oct 2025 22:13:22 -0500
Subject: [PATCH v5 1/3] arm64: tegra: tegra210: Add actmon
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251021-t210-actmon-p4-v5-1-4a4dbc49fbc8@gmail.com>
References: <20251021-t210-actmon-p4-v5-0-4a4dbc49fbc8@gmail.com>
In-Reply-To: <20251021-t210-actmon-p4-v5-0-4a4dbc49fbc8@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761102805; l=1154;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=wlz7VuhgvpflHfZWQNafqWTwhXBSYIJPNM/UlFKQ87I=;
 b=DaMDkkK2cHyMy2Ob070gvtLJNUxq+kymJLdh642Ql5BFy5V32+ILLY7kEKOLbxpxmY++qMo2y
 u5XxHDkYywPDSP24LZEjdKBpmnty7XbnL1r5C05ZMdowUZeKD8ReWik
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
2.51.0

