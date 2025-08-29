From: Aaron Kling <webgeek1234@gmail.com>
Date: Thu, 28 Aug 2025 23:01:32 -0500
Subject: [PATCH RFC 6/7] arm64: tegra: Add interconnect properties to
 Tegra210 device-tree
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250828-t210-actmon-v1-6-aeb19ec1f244@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756440091; l=2042;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=dV5rTm0DsZp/CMwTv4aBWDsgqy68fQx2GO3uvjxraWo=;
 b=WDTcNH5WeHRSVd90SNxLit8Cedm7pa1Pc+r0tDsWu6b4u4jRrgiS7i7w4hBy31nWDDG5az3EG
 0L0evK0pYWUBodLmrLebCJxGo1zMMPVy/56sDIo34T8TXq0QQBEz7rV
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add interconnect properties to the Memory Controller, External Memory
Controller and the Display Controller nodes in order to describe hardware
interconnection.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra210.dtsi | 24 ++++++++++++++++++++++++
 1 file changed, 24 insertions(+)

diff --git a/arch/arm64/boot/dts/nvidia/tegra210.dtsi b/arch/arm64/boot/dts/nvidia/tegra210.dtsi
index 6da10db893add44a98fde1666c382511212fd43c..2fcc7a28690f7100d49e8b93c4fb77de7947b002 100644
--- a/arch/arm64/boot/dts/nvidia/tegra210.dtsi
+++ b/arch/arm64/boot/dts/nvidia/tegra210.dtsi
@@ -202,6 +202,19 @@ dc@54200000 {
 
 			nvidia,outputs = <&dsia &dsib &sor0 &sor1>;
 			nvidia,head = <0>;
+
+			interconnects = <&mc TEGRA210_MC_DISPLAY0A &emc>,
+					<&mc TEGRA210_MC_DISPLAY0B &emc>,
+					<&mc TEGRA210_MC_DISPLAY0C &emc>,
+					<&mc TEGRA210_MC_DISPLAYHC &emc>,
+					<&mc TEGRA210_MC_DISPLAYD &emc>,
+					<&mc TEGRA210_MC_DISPLAYT &emc>;
+			interconnect-names = "wina",
+					     "winb",
+					     "winc",
+					     "cursor",
+					     "wind",
+					     "wint";
 		};
 
 		dc@54240000 {
@@ -217,6 +230,15 @@ dc@54240000 {
 
 			nvidia,outputs = <&dsia &dsib &sor0 &sor1>;
 			nvidia,head = <1>;
+
+			interconnects = <&mc TEGRA210_MC_DISPLAY0AB &emc>,
+					<&mc TEGRA210_MC_DISPLAY0BB &emc>,
+					<&mc TEGRA210_MC_DISPLAY0CB &emc>,
+					<&mc TEGRA210_MC_DISPLAYHCB &emc>;
+			interconnect-names = "wina",
+					     "winb",
+					     "winc",
+					     "cursor";
 		};
 
 		dsia: dsi@54300000 {
@@ -990,6 +1012,7 @@ mc: memory-controller@70019000 {
 
 		#iommu-cells = <1>;
 		#reset-cells = <1>;
+		#interconnect-cells = <1>;
 	};
 
 	emc: external-memory-controller@7001b000 {
@@ -1001,6 +1024,7 @@ emc: external-memory-controller@7001b000 {
 		clock-names = "emc";
 		interrupts = <GIC_SPI 78 IRQ_TYPE_LEVEL_HIGH>;
 		nvidia,memory-controller = <&mc>;
+		#interconnect-cells = <0>;
 		#cooling-cells = <2>;
 	};
 

-- 
2.50.1

