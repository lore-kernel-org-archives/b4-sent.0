From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 31 Aug 2025 22:33:56 -0500
Subject: [PATCH 8/8] arm64: tegra: Add CPU OPP tables for Tegra194
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250831-tegra186-icc-v1-8-607ddc53b507@gmail.com>
References: <20250831-tegra186-icc-v1-0-607ddc53b507@gmail.com>
In-Reply-To: <20250831-tegra186-icc-v1-0-607ddc53b507@gmail.com>
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-pm@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756697663; l=16615;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=/lyxFq4FtwqFWSe2Uad7pZP8fOmf4A1pwq5iQ+AYobQ=;
 b=X78WLmcY/4LZPMDZZks8BfDNN+qSihsMN4LTQQVWUJuIaBUH2JpBAUbTZ6+mHjkJ2ipXNnf3z
 FfzqVqrvfj6CoNndjJ7FFf0Y9gUlB3GGJiDWjXJ9L3OLjq1GWgjj7q8
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add OPP table and interconnects property to scale DDR frequency with
CPU frequency for better performance. Each operating point entry of
the OPP table has CPU freq to per MC channel bandwidth mapping.
One table is added for each cluster even though the table data is
same because the bandwidth request is per cluster. This is done
because the OPP framework creates a single icc path and hence single
bandwidth request if the table is marked as 'opp-shared' and shared
among all clusters. For us, the OPP table data is same but the MC
Client ID argument to interconnects property is different for each
cluster. So, having per cluster tables makes different icc paths for
each cluster and helps to make per cluster BW requests.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra194.dtsi | 636 +++++++++++++++++++++++++++++++
 1 file changed, 636 insertions(+)

diff --git a/arch/arm64/boot/dts/nvidia/tegra194.dtsi b/arch/arm64/boot/dts/nvidia/tegra194.dtsi
index 1399342f23e1c4f73b278adc66dfb948fc30d326..a6c4c6c73707354f62f778bbea5afaec3fdbe22d 100644
--- a/arch/arm64/boot/dts/nvidia/tegra194.dtsi
+++ b/arch/arm64/boot/dts/nvidia/tegra194.dtsi
@@ -2890,6 +2890,8 @@ cpu0_0: cpu@0 {
 			device_type = "cpu";
 			reg = <0x000>;
 			enable-method = "psci";
+			operating-points-v2 = <&cl0_opp_tbl>;
+			interconnects = <&mc TEGRA_ICC_MC_CPU_CLUSTER0 &emc>;
 			i-cache-size = <131072>;
 			i-cache-line-size = <64>;
 			i-cache-sets = <512>;
@@ -2904,6 +2906,8 @@ cpu0_1: cpu@1 {
 			device_type = "cpu";
 			reg = <0x001>;
 			enable-method = "psci";
+			operating-points-v2 = <&cl0_opp_tbl>;
+			interconnects = <&mc TEGRA_ICC_MC_CPU_CLUSTER0 &emc>;
 			i-cache-size = <131072>;
 			i-cache-line-size = <64>;
 			i-cache-sets = <512>;
@@ -2918,6 +2922,8 @@ cpu1_0: cpu@100 {
 			device_type = "cpu";
 			reg = <0x100>;
 			enable-method = "psci";
+			operating-points-v2 = <&cl1_opp_tbl>;
+			interconnects = <&mc TEGRA_ICC_MC_CPU_CLUSTER1 &emc>;
 			i-cache-size = <131072>;
 			i-cache-line-size = <64>;
 			i-cache-sets = <512>;
@@ -2932,6 +2938,8 @@ cpu1_1: cpu@101 {
 			device_type = "cpu";
 			reg = <0x101>;
 			enable-method = "psci";
+			operating-points-v2 = <&cl1_opp_tbl>;
+			interconnects = <&mc TEGRA_ICC_MC_CPU_CLUSTER1 &emc>;
 			i-cache-size = <131072>;
 			i-cache-line-size = <64>;
 			i-cache-sets = <512>;
@@ -2946,6 +2954,8 @@ cpu2_0: cpu@200 {
 			device_type = "cpu";
 			reg = <0x200>;
 			enable-method = "psci";
+			operating-points-v2 = <&cl2_opp_tbl>;
+			interconnects = <&mc TEGRA_ICC_MC_CPU_CLUSTER2 &emc>;
 			i-cache-size = <131072>;
 			i-cache-line-size = <64>;
 			i-cache-sets = <512>;
@@ -2960,6 +2970,8 @@ cpu2_1: cpu@201 {
 			device_type = "cpu";
 			reg = <0x201>;
 			enable-method = "psci";
+			operating-points-v2 = <&cl2_opp_tbl>;
+			interconnects = <&mc TEGRA_ICC_MC_CPU_CLUSTER2 &emc>;
 			i-cache-size = <131072>;
 			i-cache-line-size = <64>;
 			i-cache-sets = <512>;
@@ -2974,6 +2986,8 @@ cpu3_0: cpu@300 {
 			device_type = "cpu";
 			reg = <0x300>;
 			enable-method = "psci";
+			operating-points-v2 = <&cl3_opp_tbl>;
+			interconnects = <&mc TEGRA_ICC_MC_CPU_CLUSTER3 &emc>;
 			i-cache-size = <131072>;
 			i-cache-line-size = <64>;
 			i-cache-sets = <512>;
@@ -2988,6 +3002,8 @@ cpu3_1: cpu@301 {
 			device_type = "cpu";
 			reg = <0x301>;
 			enable-method = "psci";
+			operating-points-v2 = <&cl3_opp_tbl>;
+			interconnects = <&mc TEGRA_ICC_MC_CPU_CLUSTER3 &emc>;
 			i-cache-size = <131072>;
 			i-cache-line-size = <64>;
 			i-cache-sets = <512>;
@@ -3181,4 +3197,624 @@ timer {
 		interrupt-parent = <&gic>;
 		always-on;
 	};
+
+	cl0_opp_tbl: opp-table-cluster0 {
+		compatible = "operating-points-v2";
+		opp-shared;
+
+		opp-115200000 {
+			  opp-hz = /bits/ 64 <115200000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-192000000 {
+			  opp-hz = /bits/ 64 <192000000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-268800000 {
+			  opp-hz = /bits/ 64 <268800000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-345600000 {
+			  opp-hz = /bits/ 64 <345600000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-422400000 {
+			  opp-hz = /bits/ 64 <422400000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-499200000 {
+			  opp-hz = /bits/ 64 <499200000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-576000000 {
+			  opp-hz = /bits/ 64 <576000000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-652800000 {
+			  opp-hz = /bits/ 64 <652800000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-729600000 {
+			  opp-hz = /bits/ 64 <729600000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-806400000 {
+			  opp-hz = /bits/ 64 <806400000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-883200000 {
+			  opp-hz = /bits/ 64 <883200000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-960000000 {
+			  opp-hz = /bits/ 64 <960000000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-1036800000 {
+			  opp-hz = /bits/ 64 <1036800000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-1113600000 {
+			  opp-hz = /bits/ 64 <1113600000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1190400000 {
+			  opp-hz = /bits/ 64 <1190400000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1267200000 {
+			  opp-hz = /bits/ 64 <1267200000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1344000000 {
+			  opp-hz = /bits/ 64 <1344000000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1420800000 {
+			  opp-hz = /bits/ 64 <1420800000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1497600000 {
+			  opp-hz = /bits/ 64 <1497600000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1574400000 {
+			  opp-hz = /bits/ 64 <1574400000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1651200000 {
+			  opp-hz = /bits/ 64 <1651200000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1728000000 {
+			  opp-hz = /bits/ 64 <1728000000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1804800000 {
+			  opp-hz = /bits/ 64 <1804800000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1881600000 {
+			  opp-hz = /bits/ 64 <1881600000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1907200000 {
+			  opp-hz = /bits/ 64 <1907200000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1958400000 {
+			  opp-hz = /bits/ 64 <1958400000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-2035200000 {
+			  opp-hz = /bits/ 64 <2035200000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-2112000000 {
+			  opp-hz = /bits/ 64 <2112000000>;
+			  opp-peak-kBps = <4266000>;
+		};
+
+		opp-2188800000 {
+			  opp-hz = /bits/ 64 <2188800000>;
+			  opp-peak-kBps = <4266000>;
+		};
+
+		opp-2265600000 {
+			  opp-hz = /bits/ 64 <2265600000>;
+			  opp-peak-kBps = <4266000>;
+		};
+	};
+
+	cl1_opp_tbl: opp-table-cluster1 {
+		compatible = "operating-points-v2";
+		opp-shared;
+
+		opp-115200000 {
+			  opp-hz = /bits/ 64 <115200000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-192000000 {
+			  opp-hz = /bits/ 64 <192000000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-268800000 {
+			  opp-hz = /bits/ 64 <268800000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-345600000 {
+			  opp-hz = /bits/ 64 <345600000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-422400000 {
+			  opp-hz = /bits/ 64 <422400000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-499200000 {
+			  opp-hz = /bits/ 64 <499200000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-576000000 {
+			  opp-hz = /bits/ 64 <576000000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-652800000 {
+			  opp-hz = /bits/ 64 <652800000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-729600000 {
+			  opp-hz = /bits/ 64 <729600000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-806400000 {
+			  opp-hz = /bits/ 64 <806400000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-883200000 {
+			  opp-hz = /bits/ 64 <883200000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-960000000 {
+			  opp-hz = /bits/ 64 <960000000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-1036800000 {
+			  opp-hz = /bits/ 64 <1036800000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-1113600000 {
+			  opp-hz = /bits/ 64 <1113600000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1190400000 {
+			  opp-hz = /bits/ 64 <1190400000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1267200000 {
+			  opp-hz = /bits/ 64 <1267200000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1344000000 {
+			  opp-hz = /bits/ 64 <1344000000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1420800000 {
+			  opp-hz = /bits/ 64 <1420800000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1497600000 {
+			  opp-hz = /bits/ 64 <1497600000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1574400000 {
+			  opp-hz = /bits/ 64 <1574400000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1651200000 {
+			  opp-hz = /bits/ 64 <1651200000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1728000000 {
+			  opp-hz = /bits/ 64 <1728000000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1804800000 {
+			  opp-hz = /bits/ 64 <1804800000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1881600000 {
+			  opp-hz = /bits/ 64 <1881600000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1907200000 {
+			  opp-hz = /bits/ 64 <1907200000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1958400000 {
+			  opp-hz = /bits/ 64 <1958400000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-2035200000 {
+			  opp-hz = /bits/ 64 <2035200000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-2112000000 {
+			  opp-hz = /bits/ 64 <2112000000>;
+			  opp-peak-kBps = <4266000>;
+		};
+
+		opp-2188800000 {
+			  opp-hz = /bits/ 64 <2188800000>;
+			  opp-peak-kBps = <4266000>;
+		};
+
+		opp-2265600000 {
+			  opp-hz = /bits/ 64 <2265600000>;
+			  opp-peak-kBps = <4266000>;
+		};
+	};
+
+	cl2_opp_tbl: opp-table-cluster2 {
+		compatible = "operating-points-v2";
+		opp-shared;
+
+		opp-115200000 {
+			  opp-hz = /bits/ 64 <115200000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-192000000 {
+			  opp-hz = /bits/ 64 <192000000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-268800000 {
+			  opp-hz = /bits/ 64 <268800000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-345600000 {
+			  opp-hz = /bits/ 64 <345600000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-422400000 {
+			  opp-hz = /bits/ 64 <422400000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-499200000 {
+			  opp-hz = /bits/ 64 <499200000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-576000000 {
+			  opp-hz = /bits/ 64 <576000000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-652800000 {
+			  opp-hz = /bits/ 64 <652800000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-729600000 {
+			  opp-hz = /bits/ 64 <729600000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-806400000 {
+			  opp-hz = /bits/ 64 <806400000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-883200000 {
+			  opp-hz = /bits/ 64 <883200000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-960000000 {
+			  opp-hz = /bits/ 64 <960000000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-1036800000 {
+			  opp-hz = /bits/ 64 <1036800000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-1113600000 {
+			  opp-hz = /bits/ 64 <1113600000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1190400000 {
+			  opp-hz = /bits/ 64 <1190400000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1267200000 {
+			  opp-hz = /bits/ 64 <1267200000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1344000000 {
+			  opp-hz = /bits/ 64 <1344000000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1420800000 {
+			  opp-hz = /bits/ 64 <1420800000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1497600000 {
+			  opp-hz = /bits/ 64 <1497600000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1574400000 {
+			  opp-hz = /bits/ 64 <1574400000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1651200000 {
+			  opp-hz = /bits/ 64 <1651200000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1728000000 {
+			  opp-hz = /bits/ 64 <1728000000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1804800000 {
+			  opp-hz = /bits/ 64 <1804800000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1881600000 {
+			  opp-hz = /bits/ 64 <1881600000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1907200000 {
+			  opp-hz = /bits/ 64 <1907200000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1958400000 {
+			  opp-hz = /bits/ 64 <1958400000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-2035200000 {
+			  opp-hz = /bits/ 64 <2035200000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-2112000000 {
+			  opp-hz = /bits/ 64 <2112000000>;
+			  opp-peak-kBps = <4266000>;
+		};
+
+		opp-2188800000 {
+			  opp-hz = /bits/ 64 <2188800000>;
+			  opp-peak-kBps = <4266000>;
+		};
+
+		opp-2265600000 {
+			  opp-hz = /bits/ 64 <2265600000>;
+			  opp-peak-kBps = <4266000>;
+		};
+	};
+
+	cl3_opp_tbl: opp-table-cluster3 {
+		compatible = "operating-points-v2";
+		opp-shared;
+
+		opp-115200000 {
+			  opp-hz = /bits/ 64 <115200000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-192000000 {
+			  opp-hz = /bits/ 64 <192000000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-268800000 {
+			  opp-hz = /bits/ 64 <268800000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-345600000 {
+			  opp-hz = /bits/ 64 <345600000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-422400000 {
+			  opp-hz = /bits/ 64 <422400000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-499200000 {
+			  opp-hz = /bits/ 64 <499200000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-576000000 {
+			  opp-hz = /bits/ 64 <576000000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-652800000 {
+			  opp-hz = /bits/ 64 <652800000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-729600000 {
+			  opp-hz = /bits/ 64 <729600000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-806400000 {
+			  opp-hz = /bits/ 64 <806400000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-883200000 {
+			  opp-hz = /bits/ 64 <883200000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-960000000 {
+			  opp-hz = /bits/ 64 <960000000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-1036800000 {
+			  opp-hz = /bits/ 64 <1036800000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-1113600000 {
+			  opp-hz = /bits/ 64 <1113600000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1190400000 {
+			  opp-hz = /bits/ 64 <1190400000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1267200000 {
+			  opp-hz = /bits/ 64 <1267200000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1344000000 {
+			  opp-hz = /bits/ 64 <1344000000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1420800000 {
+			  opp-hz = /bits/ 64 <1420800000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1497600000 {
+			  opp-hz = /bits/ 64 <1497600000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1574400000 {
+			  opp-hz = /bits/ 64 <1574400000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1651200000 {
+			  opp-hz = /bits/ 64 <1651200000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1728000000 {
+			  opp-hz = /bits/ 64 <1728000000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1804800000 {
+			  opp-hz = /bits/ 64 <1804800000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1881600000 {
+			  opp-hz = /bits/ 64 <1881600000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1907200000 {
+			  opp-hz = /bits/ 64 <1907200000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1958400000 {
+			  opp-hz = /bits/ 64 <1958400000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-2035200000 {
+			  opp-hz = /bits/ 64 <2035200000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-2112000000 {
+			  opp-hz = /bits/ 64 <2112000000>;
+			  opp-peak-kBps = <4266000>;
+		};
+
+		opp-2188800000 {
+			  opp-hz = /bits/ 64 <2188800000>;
+			  opp-peak-kBps = <4266000>;
+		};
+
+		opp-2265600000 {
+			  opp-hz = /bits/ 64 <2265600000>;
+			  opp-peak-kBps = <4266000>;
+		};
+	};
 };

-- 
2.50.1

