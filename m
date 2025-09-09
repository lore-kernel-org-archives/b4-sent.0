From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 09 Sep 2025 01:21:35 -0500
Subject: [PATCH v2 7/8] arm64: tegra: Add CPU OPP tables for Tegra186
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250909-tegra186-icc-v2-7-09413724e781@gmail.com>
References: <20250909-tegra186-icc-v2-0-09413724e781@gmail.com>
In-Reply-To: <20250909-tegra186-icc-v2-0-09413724e781@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757398893; l=9142;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=uZssU7heZXFbFMQlclW4XJXqxgp1LYUFan3iXKZGfg4=;
 b=QOq9Zgi2/T7xFuJ+D0DnP09EbkrRocXBH6KVeWk744qYlO8ThdXt414mNA025fl+bGNDyLD/W
 aZq+hfbaI3pAzNvBxgpIGxPViOCql2GI1YS0XCl4wuzWdpmd/nztv8r
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add OPP table and interconnects property to scale DDR frequency with
CPU frequency for better performance. Each operating point entry of
the OPP table has CPU freq to per MC channel bandwidth mapping. One
table is added for each cluster because the different cpu types have
different scaling curves.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra186.dtsi | 317 +++++++++++++++++++++++++++++++
 1 file changed, 317 insertions(+)

diff --git a/arch/arm64/boot/dts/nvidia/tegra186.dtsi b/arch/arm64/boot/dts/nvidia/tegra186.dtsi
index 5778c93af3e6e72f5f14a9fcee1e7abf80d2d2c5..d3f6a938a9b019a043ce2de7ec17bd00155b3eb2 100644
--- a/arch/arm64/boot/dts/nvidia/tegra186.dtsi
+++ b/arch/arm64/boot/dts/nvidia/tegra186.dtsi
@@ -1943,6 +1943,8 @@ cpus {
 		denver_0: cpu@0 {
 			compatible = "nvidia,tegra186-denver";
 			device_type = "cpu";
+			operating-points-v2 = <&dnv_opp_tbl>;
+			interconnects = <&mc TEGRA_ICC_MC_CPU_CLUSTER0 &emc>;
 			i-cache-size = <0x20000>;
 			i-cache-line-size = <64>;
 			i-cache-sets = <512>;
@@ -1956,6 +1958,8 @@ denver_0: cpu@0 {
 		denver_1: cpu@1 {
 			compatible = "nvidia,tegra186-denver";
 			device_type = "cpu";
+			operating-points-v2 = <&dnv_opp_tbl>;
+			interconnects = <&mc TEGRA_ICC_MC_CPU_CLUSTER0 &emc>;
 			i-cache-size = <0x20000>;
 			i-cache-line-size = <64>;
 			i-cache-sets = <512>;
@@ -1969,6 +1973,8 @@ denver_1: cpu@1 {
 		ca57_0: cpu@2 {
 			compatible = "arm,cortex-a57";
 			device_type = "cpu";
+			operating-points-v2 = <&a57_opp_tbl>;
+			interconnects = <&mc TEGRA_ICC_MC_CPU_CLUSTER1 &emc>;
 			i-cache-size = <0xC000>;
 			i-cache-line-size = <64>;
 			i-cache-sets = <256>;
@@ -1982,6 +1988,8 @@ ca57_0: cpu@2 {
 		ca57_1: cpu@3 {
 			compatible = "arm,cortex-a57";
 			device_type = "cpu";
+			operating-points-v2 = <&a57_opp_tbl>;
+			interconnects = <&mc TEGRA_ICC_MC_CPU_CLUSTER1 &emc>;
 			i-cache-size = <0xC000>;
 			i-cache-line-size = <64>;
 			i-cache-sets = <256>;
@@ -1995,6 +2003,8 @@ ca57_1: cpu@3 {
 		ca57_2: cpu@4 {
 			compatible = "arm,cortex-a57";
 			device_type = "cpu";
+			operating-points-v2 = <&a57_opp_tbl>;
+			interconnects = <&mc TEGRA_ICC_MC_CPU_CLUSTER1 &emc>;
 			i-cache-size = <0xC000>;
 			i-cache-line-size = <64>;
 			i-cache-sets = <256>;
@@ -2008,6 +2018,8 @@ ca57_2: cpu@4 {
 		ca57_3: cpu@5 {
 			compatible = "arm,cortex-a57";
 			device_type = "cpu";
+			operating-points-v2 = <&a57_opp_tbl>;
+			interconnects = <&mc TEGRA_ICC_MC_CPU_CLUSTER1 &emc>;
 			i-cache-size = <0xC000>;
 			i-cache-line-size = <64>;
 			i-cache-sets = <256>;
@@ -2182,4 +2194,309 @@ timer {
 		interrupt-parent = <&gic>;
 		always-on;
 	};
+
+	dnv_opp_tbl: opp-table-cluster0 {
+		compatible = "operating-points-v2";
+		opp-shared;
+
+		opp-998400000 {
+			  opp-hz = /bits/ 64 <998400000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-1036800000 {
+			  opp-hz = /bits/ 64 <1036800000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-1075200000 {
+			  opp-hz = /bits/ 64 <1075200000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-1113600000 {
+			  opp-hz = /bits/ 64 <1113600000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1152000000 {
+			  opp-hz = /bits/ 64 <1152000000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1190400000 {
+			  opp-hz = /bits/ 64 <1190400000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1228800000 {
+			  opp-hz = /bits/ 64 <1228800000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1267200000 {
+			  opp-hz = /bits/ 64 <1267200000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1305600000 {
+			  opp-hz = /bits/ 64 <1305600000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1344000000 {
+			  opp-hz = /bits/ 64 <1344000000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1382400000 {
+			  opp-hz = /bits/ 64 <1382400000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1420800000 {
+			  opp-hz = /bits/ 64 <1420800000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1459200000 {
+			  opp-hz = /bits/ 64 <1459200000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1497600000 {
+			  opp-hz = /bits/ 64 <1497600000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1536000000 {
+			  opp-hz = /bits/ 64 <1536000000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1574400000 {
+			  opp-hz = /bits/ 64 <1574400000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1612800000 {
+			  opp-hz = /bits/ 64 <1612800000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1651200000 {
+			  opp-hz = /bits/ 64 <1651200000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1689600000 {
+			  opp-hz = /bits/ 64 <1689600000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1728000000 {
+			  opp-hz = /bits/ 64 <1728000000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1766400000 {
+			  opp-hz = /bits/ 64 <1766400000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1804800000 {
+			  opp-hz = /bits/ 64 <1804800000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1843200000 {
+			  opp-hz = /bits/ 64 <1843200000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1881600000 {
+			  opp-hz = /bits/ 64 <1881600000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1920000000 {
+			  opp-hz = /bits/ 64 <1920000000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1958400000 {
+			  opp-hz = /bits/ 64 <1958400000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1996800000 {
+			  opp-hz = /bits/ 64 <1996800000>;
+			  opp-peak-kBps = <3732000>;
+		};
+
+		opp-2035200000 {
+			  opp-hz = /bits/ 64 <2035200000>;
+			  opp-peak-kBps = <3732000>;
+		};
+	};
+
+	a57_opp_tbl: opp-table-cluster1 {
+		compatible = "operating-points-v2";
+		opp-shared;
+
+		opp-883200000 {
+			  opp-hz = /bits/ 64 <883200000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-921600000 {
+			  opp-hz = /bits/ 64 <921600000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-960000000 {
+			  opp-hz = /bits/ 64 <960000000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-998400000 {
+			  opp-hz = /bits/ 64 <998400000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-1036800000 {
+			  opp-hz = /bits/ 64 <1036800000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-1075200000 {
+			  opp-hz = /bits/ 64 <1075200000>;
+			  opp-peak-kBps = <816000>;
+		};
+
+		opp-1113600000 {
+			  opp-hz = /bits/ 64 <1113600000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1152000000 {
+			  opp-hz = /bits/ 64 <1152000000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1190400000 {
+			  opp-hz = /bits/ 64 <1190400000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1228800000 {
+			  opp-hz = /bits/ 64 <1228800000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1267200000 {
+			  opp-hz = /bits/ 64 <1267200000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1305600000 {
+			  opp-hz = /bits/ 64 <1305600000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1344000000 {
+			  opp-hz = /bits/ 64 <1344000000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1382400000 {
+			  opp-hz = /bits/ 64 <1382400000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1420800000 {
+			  opp-hz = /bits/ 64 <1420800000>;
+			  opp-peak-kBps = <1600000>;
+		};
+
+		opp-1459200000 {
+			  opp-hz = /bits/ 64 <1459200000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1497600000 {
+			  opp-hz = /bits/ 64 <1497600000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1536000000 {
+			  opp-hz = /bits/ 64 <1536000000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1574400000 {
+			  opp-hz = /bits/ 64 <1574400000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1612800000 {
+			  opp-hz = /bits/ 64 <1612800000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1651200000 {
+			  opp-hz = /bits/ 64 <1651200000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1689600000 {
+			  opp-hz = /bits/ 64 <1689600000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1728000000 {
+			  opp-hz = /bits/ 64 <1728000000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1766400000 {
+			  opp-hz = /bits/ 64 <1766400000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1804800000 {
+			  opp-hz = /bits/ 64 <1804800000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1843200000 {
+			  opp-hz = /bits/ 64 <1843200000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1881600000 {
+			  opp-hz = /bits/ 64 <1881600000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1920000000 {
+			  opp-hz = /bits/ 64 <1920000000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1958400000 {
+			  opp-hz = /bits/ 64 <1958400000>;
+			  opp-peak-kBps = <3200000>;
+		};
+
+		opp-1996800000 {
+			  opp-hz = /bits/ 64 <1996800000>;
+			  opp-peak-kBps = <3732000>;
+		};
+
+		opp-2035200000 {
+			  opp-hz = /bits/ 64 <2035200000>;
+			  opp-peak-kBps = <3732000>;
+		};
+	};
 };

-- 
2.50.1

