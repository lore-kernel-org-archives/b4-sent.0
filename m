From: Myria Sarvay <myrialsarvay@gmail.com>
Date: Tue, 03 Nov 2026 21:14:47 +1100
Subject: [PATCH 12/13] arm64: dts: apple: t8132: Add PMU Device Nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-m3-plus-pmu-events-v1-12-a8eb6c1139fe@gmail.com>
References: <20261103-m3-plus-pmu-events-v1-0-a8eb6c1139fe@gmail.com>
In-Reply-To: <20261103-m3-plus-pmu-events-v1-0-a8eb6c1139fe@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=890; i=myrialsarvay@gmail.com;
 h=from:subject:message-id; bh=SeQT+VS3NIGTbRle0pQmiDq0GYf1YozUCB1/EswjGUI=;
 b=owJ4nJvAy8zAJRbk4iixYu2/l4yn1ZIYsl5uEZ0erZPExbPb6eRx7+VCAYZtDotYNj7SPcCze
 FMey845V451lLIwiHExyIopsuibpmlPZmu4VLrMdQvMHFYmkCEMXJwCMJH21YwMdx7fmaS6SnGu
 YcYt+S/r1wtUSSq13JKbvYitX6LHZe/e5YwMZ29wvS7jeVDfXqJ+JVxc5vPxs0Z3pmpr3f5/d2+
 lELsvHwBjPUiE
X-Developer-Key: i=myrialsarvay@gmail.com; a=openpgp;
 fpr=2F35662B930680D275A645B452444118A8ADFEE9
X-Endpoint-Received: by B4 Relay for myrialsarvay@gmail.com/default with auth_id=1027
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds the PMU nodes to all t8132 devices.

Signed-off-by: Myria Sarvay <myrialsarvay@gmail.com>
---
 arch/arm64/boot/dts/apple/t8132.dtsi | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t8132.dtsi b/arch/arm64/boot/dts/apple/t8132.dtsi
index afec92a06015..d0f8a40097ee 100644
--- a/arch/arm64/boot/dts/apple/t8132.dtsi
+++ b/arch/arm64/boot/dts/apple/t8132.dtsi
@@ -189,6 +189,18 @@ clkref: clock-ref {
 		clock-output-names = "clkref";
 	};
 
+	pmu-e {
+		compatible = "apple,donan-e-pmu";
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_FIQ AIC_CPU_PMU_E IRQ_TYPE_LEVEL_HIGH>;
+	};
+
+	pmu-p {
+		compatible = "apple,donan-p-pmu";
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_FIQ AIC_CPU_PMU_P IRQ_TYPE_LEVEL_HIGH>;
+	};
+
 	soc: soc {
 		compatible = "simple-bus";
 		#address-cells = <2>;

-- 
2.56.0

