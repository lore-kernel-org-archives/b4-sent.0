From: Myria Sarvay <myrialsarvay@gmail.com>
Date: Tue, 03 Nov 2026 21:14:44 +1100
Subject: [PATCH 09/13] arm64: dts: apple: t603x: Add PMU Device Nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-m3-plus-pmu-events-v1-9-a8eb6c1139fe@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1592;
 i=myrialsarvay@gmail.com; h=from:subject:message-id;
 bh=SO/LMlSi+PPXYEpOttKEw7SF2blcwlqNjHvogmCvFiQ=;
 b=owJ4nJvAy8zAJRbk4iixYu2/l4yn1ZIYsl5uEX2/rmXrrU8TQ94dUlC9uIUxVE57efZzvTKjm
 QEhUwyl2CZ3lLIwiHExyIopsuibpmlPZmu4VLrMdQvMHFYmkCEMXJwCMJG//Az/45m+Tjx8ib/Y
 ss3u2mmxHRUndM3Pahz4a/VgZbYd7yf3Xwz//fYobzmeJezKutn578RLz9cXspy+qbkkYOs+pkk
 rn3FUsAEAaN9LrA==
X-Developer-Key: i=myrialsarvay@gmail.com; a=openpgp;
 fpr=2F35662B930680D275A645B452444118A8ADFEE9
X-Endpoint-Received: by B4 Relay for myrialsarvay@gmail.com/default with auth_id=1027
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds the PMU nodes to all t603x devices.

Signed-off-by: Myria Sarvay <myrialsarvay@gmail.com>
---
 arch/arm64/boot/dts/apple/t6030.dtsi      | 12 ++++++++++++
 arch/arm64/boot/dts/apple/t6031-base.dtsi | 12 ++++++++++++
 2 files changed, 24 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t6030.dtsi b/arch/arm64/boot/dts/apple/t6030.dtsi
index 85a16d03e22f..c3779e1584c2 100644
--- a/arch/arm64/boot/dts/apple/t6030.dtsi
+++ b/arch/arm64/boot/dts/apple/t6030.dtsi
@@ -239,6 +239,18 @@ l2_cache_1: l2-cache-1 {
 		};
 	};
 
+	pmu-e {
+		compatible = "apple,sawtooth-pmu";
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_FIQ AIC_CPU_PMU_E IRQ_TYPE_LEVEL_HIGH>;
+	};
+
+	pmu-p {
+		compatible = "apple,everest-pmu";
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_FIQ AIC_CPU_PMU_P IRQ_TYPE_LEVEL_HIGH>;
+	};
+
 	reserved-memory {
 		ranges;
 		#address-cells = <2>;
diff --git a/arch/arm64/boot/dts/apple/t6031-base.dtsi b/arch/arm64/boot/dts/apple/t6031-base.dtsi
index f62ce0690182..3b97c1240934 100644
--- a/arch/arm64/boot/dts/apple/t6031-base.dtsi
+++ b/arch/arm64/boot/dts/apple/t6031-base.dtsi
@@ -308,6 +308,18 @@ l2_cache_2: l2-cache-2 {
 		};
 	};
 
+	pmu-e {
+		compatible = "apple,sawtooth-pmu";
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_FIQ 0 AIC_CPU_PMU_E IRQ_TYPE_LEVEL_HIGH>;
+	};
+
+	pmu-p {
+		compatible = "apple,everest-pmu";
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_FIQ 0 AIC_CPU_PMU_P IRQ_TYPE_LEVEL_HIGH>;
+	};
+
 	reserved-memory {
 		ranges;
 		#address-cells = <2>;

-- 
2.56.0

