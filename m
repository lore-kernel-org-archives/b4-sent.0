From: Myria Sarvay <myrialsarvay@gmail.com>
Date: Sat, 07 Nov 2026 21:48:57 +1100
Subject: [PATCH v2 10/15] arm64: dts: apple: t8140: Add core interrupt
 affinities
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-m3-plus-pmu-events-v2-10-acf1e78da039@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=919; i=myrialsarvay@gmail.com;
 h=from:subject:message-id; bh=d9exJCOstCv3xbTb3W263KlRtQt0JJIMHplbVx1DCmc=;
 b=owJ4nJvAy8zAJRbk4iixYu2/l4yn1ZIYst4zyXzZMyEgov1LIcf2Qpa/dVddui7fmxPJui1KY
 fHVwgfKZREdpSwMYlwMsmKKLPqmadqT2RoulS5z3QIzh5UJZAgDF6cATCS9lJHhzPS2jl8rNRuT
 /lywCZ684s+breoepWZBW1hXTDjYb2r7nOEPz1GrPKODqn3Bffezn9f/+W01WecttyxHuZ6p6IT
 0zcFsAGxqSbc=
X-Developer-Key: i=myrialsarvay@gmail.com; a=openpgp;
 fpr=2F35662B930680D275A645B452444118A8ADFEE9
X-Endpoint-Received: by B4 Relay for myrialsarvay@gmail.com/default with auth_id=1027
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the cpu interrupt affinities for the A18 Pro SoC

Signed-off-by: Myria Sarvay <myrialsarvay@gmail.com>
---
 arch/arm64/boot/dts/apple/t8140.dtsi | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t8140.dtsi b/arch/arm64/boot/dts/apple/t8140.dtsi
index 3b4f7695552b..89a26a1b2364 100644
--- a/arch/arm64/boot/dts/apple/t8140.dtsi
+++ b/arch/arm64/boot/dts/apple/t8140.dtsi
@@ -167,6 +167,19 @@ aic: interrupt-controller@301000000 {
 			#interrupt-cells = <3>;
 			interrupt-controller;
 			power-domains = <&ps_aic>;
+
+			affinities {
+				e-core-pmu-affinity {
+					apple,fiq-index = <AIC_CPU_PMU_E>;
+					cpus = <&cpu_e0 &cpu_e1
+						&cpu_e2 &cpu_e3>;
+				};
+
+				p-core-pmu-affinity {
+					apple,fiq-index = <AIC_CPU_PMU_P>;
+					cpus = <&cpu_p0 &cpu_p1>;
+				};
+			};
 		};
 
 		pinctrl_nub: pinctrl@3081f0000 {

-- 
2.55.0

