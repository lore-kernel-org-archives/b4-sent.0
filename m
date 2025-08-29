From: Aaron Kling <webgeek1234@gmail.com>
Date: Thu, 28 Aug 2025 23:01:33 -0500
Subject: [PATCH RFC 7/7] arm64: tegra: Add OPP tables on Tegra210
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250828-t210-actmon-v1-7-aeb19ec1f244@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756440091; l=4992;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=BuMztMnAqa18LOpanMPfXZmvaUGQqA9O6CgvPF/UAwU=;
 b=t58Jl/MjwMo2gUy677GZjB/GgnJvNSlR6znbV/W6KphphRrNn/NET7LRBxnDkjOJpZpeEzhQz
 5Ez4CZTMG1BBYWTfQcYWuEvjG7qVAF/iUtfqnzFTHeV4CPRfh9VL9aE
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds OPP tables for actmon and emc, enabling dynamic frequency
scaling for ram.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 .../boot/dts/nvidia/tegra210-peripherals-opp.dtsi  | 135 +++++++++++++++++++++
 arch/arm64/boot/dts/nvidia/tegra210.dtsi           |   7 ++
 2 files changed, 142 insertions(+)

diff --git a/arch/arm64/boot/dts/nvidia/tegra210-peripherals-opp.dtsi b/arch/arm64/boot/dts/nvidia/tegra210-peripherals-opp.dtsi
new file mode 100644
index 0000000000000000000000000000000000000000..bf2527d737932a1f41aa83d61f44d87ba52b0519
--- /dev/null
+++ b/arch/arm64/boot/dts/nvidia/tegra210-peripherals-opp.dtsi
@@ -0,0 +1,135 @@
+// SPDX-License-Identifier: GPL-2.0
+
+/ {
+	/* EMC DVFS OPP table */
+	emc_icc_dvfs_opp_table: opp-table-dvfs0 {
+		compatible = "operating-points-v2";
+
+		opp-40800000-800 {
+			opp-microvolt = <800000 800000 1150000>;
+			opp-hz = /bits/ 64 <40800000>;
+			opp-supported-hw = <0x0003>;
+		};
+
+		opp-68000000-800 {
+			opp-microvolt = <800000 800000 1150000>;
+			opp-hz = /bits/ 64 <68000000>;
+			opp-supported-hw = <0x0003>;
+		};
+
+		opp-102000000-800 {
+			opp-microvolt = <800000 800000 1150000>;
+			opp-hz = /bits/ 64 <102000000>;
+			opp-supported-hw = <0x0003>;
+		};
+
+		opp-204000000-800 {
+			opp-microvolt = <800000 800000 1150000>;
+			opp-hz = /bits/ 64 <204000000>;
+			opp-supported-hw = <0x0007>;
+			opp-suspend;
+		};
+
+		opp-408000000-812 {
+			opp-microvolt = <812000 812000 1150000>;
+			opp-hz = /bits/ 64 <408000000>;
+			opp-supported-hw = <0x0003>;
+		};
+
+		opp-665600000-825 {
+			opp-microvolt = <825000 825000 1150000>;
+			opp-hz = /bits/ 64 <665600000>;
+			opp-supported-hw = <0x0003>;
+		};
+
+		opp-800000000-825 {
+			opp-microvolt = <825000 825000 1150000>;
+			opp-hz = /bits/ 64 <800000000>;
+			opp-supported-hw = <0x0003>;
+		};
+
+		opp-1065600000-837 {
+			opp-microvolt = <837000 837000 1150000>;
+			opp-hz = /bits/ 64 <1065600000>;
+			opp-supported-hw = <0x0003>;
+		};
+
+		opp-1331200000-850 {
+			opp-microvolt = <850000 850000 1150000>;
+			opp-hz = /bits/ 64 <1331200000>;
+			opp-supported-hw = <0x0003>;
+		};
+
+		opp-1600000000-887 {
+			opp-microvolt = <887000 887000 1150000>;
+			opp-hz = /bits/ 64 <1600000000>;
+			opp-supported-hw = <0x0007>;
+		};
+	};
+
+	/* EMC bandwidth OPP table */
+	emc_bw_dfs_opp_table: opp-table-dvfs1 {
+		compatible = "operating-points-v2";
+
+		opp-40800000 {
+			opp-hz = /bits/ 64 <40800000>;
+			opp-supported-hw = <0x0003>;
+			opp-peak-kBps = <652800>;
+		};
+
+		opp-68000000 {
+			opp-hz = /bits/ 64 <68000000>;
+			opp-supported-hw = <0x0003>;
+			opp-peak-kBps = <1088000>;
+		};
+
+		opp-102000000 {
+			opp-hz = /bits/ 64 <102000000>;
+			opp-supported-hw = <0x0003>;
+			opp-peak-kBps = <1632000>;
+		};
+
+		opp-204000000 {
+			opp-hz = /bits/ 64 <204000000>;
+			opp-supported-hw = <0x0007>;
+			opp-peak-kBps = <3264000>;
+			opp-suspend;
+		};
+
+		opp-408000000 {
+			opp-hz = /bits/ 64 <408000000>;
+			opp-supported-hw = <0x0003>;
+			opp-peak-kBps = <6528000>;
+		};
+
+		opp-665600000 {
+			opp-hz = /bits/ 64 <665600000>;
+			opp-supported-hw = <0x0003>;
+			opp-peak-kBps = <10649600>;
+		};
+
+		opp-800000000 {
+			opp-hz = /bits/ 64 <800000000>;
+			opp-supported-hw = <0x001F>;
+			opp-peak-kBps = <12800000>;
+		};
+
+		opp-1065600000 {
+			opp-hz = /bits/ 64 <1065600000>;
+			opp-supported-hw = <0x0003>;
+			opp-peak-kBps = <17049600>;
+		};
+
+		opp-1331200000 {
+			opp-hz = /bits/ 64 <1331200000>;
+			opp-supported-hw = <0x0003>;
+			opp-peak-kBps = <21299200>;
+		};
+
+		opp-1600000000 {
+			opp-hz = /bits/ 64 <1600000000>;
+			opp-supported-hw = <0x0007>;
+			opp-peak-kBps = <25600000>;
+		};
+	};
+};
diff --git a/arch/arm64/boot/dts/nvidia/tegra210.dtsi b/arch/arm64/boot/dts/nvidia/tegra210.dtsi
index 2fcc7a28690f7100d49e8b93c4fb77de7947b002..f2961c9e12db1cf91254b75389779955f2a0956d 100644
--- a/arch/arm64/boot/dts/nvidia/tegra210.dtsi
+++ b/arch/arm64/boot/dts/nvidia/tegra210.dtsi
@@ -9,6 +9,8 @@
 #include <dt-bindings/thermal/tegra124-soctherm.h>
 #include <dt-bindings/soc/tegra-pmc.h>
 
+#include "tegra210-peripherals-opp.dtsi"
+
 / {
 	compatible = "nvidia,tegra210";
 	interrupt-parent = <&lic>;
@@ -516,6 +518,9 @@ actmon@6000c800 {
 		clock-names = "actmon", "emc";
 		resets = <&tegra_car 119>;
 		reset-names = "actmon";
+		operating-points-v2 = <&emc_bw_dfs_opp_table>;
+		interconnects = <&mc TEGRA210_MC_MPCORER &emc>;
+		interconnect-names = "cpu-read";
 		#cooling-cells = <2>;
 	};
 
@@ -1024,6 +1029,8 @@ emc: external-memory-controller@7001b000 {
 		clock-names = "emc";
 		interrupts = <GIC_SPI 78 IRQ_TYPE_LEVEL_HIGH>;
 		nvidia,memory-controller = <&mc>;
+		operating-points-v2 = <&emc_icc_dvfs_opp_table>;
+
 		#interconnect-cells = <0>;
 		#cooling-cells = <2>;
 	};

-- 
2.50.1

