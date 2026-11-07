From: Myria Sarvay <myrialsarvay@gmail.com>
Date: Sat, 07 Nov 2026 21:48:56 +1100
Subject: [PATCH v2 09/15] arm64: dts: apple: t603*: Add core interrupt
 affinities
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-m3-plus-pmu-events-v2-9-acf1e78da039@gmail.com>
References: <20261107-m3-plus-pmu-events-v2-0-acf1e78da039@gmail.com>
In-Reply-To: <20261107-m3-plus-pmu-events-v2-0-acf1e78da039@gmail.com>
To: Will Deacon <will@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sven Peter <sven@kernel.org>, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Marc Zyngier <maz@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-perf-users@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, Yuvan Shen <yuvanshen09@gmail.com>, 
 Myria Sarvay <myrialsarvay@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2753;
 i=myrialsarvay@gmail.com; h=from:subject:message-id;
 bh=SZxjnnpiAPlBmETm50YHBvKw+Yyj82CoILY577jql1M=;
 b=owJ4nJvAy8zAJRbk4iixYu2/l4yn1ZIYst4zyfzUbnvhuLJuflbhzknTfj3MmiYc0i+4beGK3
 VG5ubWLmlZ1lLIwiHExyIopsuibpmlPZmu4VLrMdQvMHFYmkCEMXJwCMBENIYa/4keYJyVoPOP2
 tFdn03+01fh6k35+VGVJwL3oHPGtBz6EMTLMvXvPIufUqccvO/doqXteVD6/hb3U6uvTEtY304S
 ufbjNAAAay0pP
X-Developer-Key: i=myrialsarvay@gmail.com; a=openpgp;
 fpr=2F35662B930680D275A645B452444118A8ADFEE9
X-Endpoint-Received: by B4 Relay for myrialsarvay@gmail.com/default with auth_id=1027
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the cpu interrupt affinities for M3 Pro/Max SoCs

Signed-off-by: Myria Sarvay <myrialsarvay@gmail.com>
---
 arch/arm64/boot/dts/apple/t6030.dtsi | 14 ++++++++++++++
 arch/arm64/boot/dts/apple/t6031.dtsi | 18 ++++++++++++++++++
 arch/arm64/boot/dts/apple/t6032.dtsi | 20 ++++++++++++++++++++
 3 files changed, 52 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t6030.dtsi b/arch/arm64/boot/dts/apple/t6030.dtsi
index 85a16d03e22f..d49210572e19 100644
--- a/arch/arm64/boot/dts/apple/t6030.dtsi
+++ b/arch/arm64/boot/dts/apple/t6030.dtsi
@@ -451,6 +451,20 @@ aic: interrupt-controller@351000000 {
 			#interrupt-cells = <3>;
 			interrupt-controller;
 			power-domains = <&ps_aic>;
+
+			affinities {
+				e-core-pmu-affinity {
+					cpus = <&cpu_e00 &cpu_e01 &cpu_e02
+						&cpu_e03 &cpu_e04 &cpu_e05>;
+					apple,fiq-index = <AIC_CPU_PMU_E>;
+				};
+
+				p-core-pmu-affinity {
+					cpus = <&cpu_p00 &cpu_p01 &cpu_p02
+						&cpu_p03 &cpu_p04 &cpu_p05>;
+					apple,fiq-index = <AIC_CPU_PMU_P>;
+				};
+			};
 		};
 
 		pinctrl_nub: pinctrl@3641f0000 {
diff --git a/arch/arm64/boot/dts/apple/t6031.dtsi b/arch/arm64/boot/dts/apple/t6031.dtsi
index 30a91c1a47d2..e226a45fe530 100644
--- a/arch/arm64/boot/dts/apple/t6031.dtsi
+++ b/arch/arm64/boot/dts/apple/t6031.dtsi
@@ -45,3 +45,21 @@ soc: soc {
 #undef DIE
 #undef DIE_NO
 #undef SOC_NODE
+
+&aic {
+	affinities {
+		e-core-pmu-affinity {
+			cpus = <&cpu_e00 &cpu_e01
+				&cpu_e02 &cpu_e03>;
+			apple,fiq-index = <AIC_CPU_PMU_E>;
+		};
+
+		p-core-pmu-affinity {
+			cpus = <&cpu_p00 &cpu_p01 &cpu_p02
+				&cpu_p03 &cpu_p04 &cpu_p05
+				&cpu_p10 &cpu_p11 &cpu_p12
+				&cpu_p13 &cpu_p14 &cpu_p15>;
+			apple,fiq-index = <AIC_CPU_PMU_P>;
+		};
+	};
+};
diff --git a/arch/arm64/boot/dts/apple/t6032.dtsi b/arch/arm64/boot/dts/apple/t6032.dtsi
index 2a3a1fed59df..627027f8cd14 100644
--- a/arch/arm64/boot/dts/apple/t6032.dtsi
+++ b/arch/arm64/boot/dts/apple/t6032.dtsi
@@ -371,6 +371,26 @@ die1: soc@2200000000 {
 #undef DIE_NO
 #undef SOC_NODE
 
+&aic {
+	affinities {
+		e-core-pmu-affinity {
+			cpus = <&cpu_e00 &cpu_e01 &cpu_e02 &cpu_e03
+				&cpu_e10 &cpu_e11 &cpu_e12 &cpu_e13>;
+			apple,fiq-index = <AIC_CPU_PMU_E>;
+		};
+
+		p-core-pmu-affinity {
+			cpus = <&cpu_p00 &cpu_p01 &cpu_p02 &cpu_p03
+				&cpu_p04 &cpu_p05 &cpu_p10 &cpu_p11
+				&cpu_p12 &cpu_p13 &cpu_p14 &cpu_p15
+				&cpu_p20 &cpu_p21 &cpu_p22 &cpu_p23
+				&cpu_p24 &cpu_p25 &cpu_p30 &cpu_p31
+				&cpu_p32 &cpu_p33 &cpu_p34 &cpu_p35>;
+			apple,fiq-index = <AIC_CPU_PMU_P>;
+		};
+	};
+};
+
 /* delete non-present DISP power-states */
 /delete-node/ &ps_disp_cpu;
 /delete-node/ &ps_disp_cpu_die1;

-- 
2.55.0

