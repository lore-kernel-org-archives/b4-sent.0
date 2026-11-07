From: Myria Sarvay <myrialsarvay@gmail.com>
Date: Sat, 07 Nov 2026 21:49:02 +1100
Subject: [PATCH v2 15/15] arm64: dts: apple: t8140: Add PMU Device Nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-m3-plus-pmu-events-v2-15-acf1e78da039@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=855; i=myrialsarvay@gmail.com;
 h=from:subject:message-id; bh=ADJFLFxUOqHDJmF0uWXvDM8Pu3rq+xTOczYNKGGrtjQ=;
 b=owJ4nJvAy8zAJRbk4iixYu2/l4yn1ZIYst4zye751bpeaN9342JHH9YXiyyEWxe9ZZz5++2qO
 7o9r38+FKnpKGVhEONikBVTZNE3TdOezNZwqXSZ6xaYOaxMIEMYuDgFYCKHjRj++ytNaT+7x0Yy
 bFXdoYizK07knvyZkDF38cm1zrqTbY/KlzD8U2brm624fd69kHqLo08FubYfsC1fVHZoeX+LUM/
 me5fusQAADO5Nkw==
X-Developer-Key: i=myrialsarvay@gmail.com; a=openpgp;
 fpr=2F35662B930680D275A645B452444118A8ADFEE9
X-Endpoint-Received: by B4 Relay for myrialsarvay@gmail.com/default with auth_id=1027
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds the PMU nodes to all t8140 devices.

Signed-off-by: Myria Sarvay <myrialsarvay@gmail.com>
---
 arch/arm64/boot/dts/apple/t8140.dtsi | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t8140.dtsi b/arch/arm64/boot/dts/apple/t8140.dtsi
index 89a26a1b2364..6fd671d1f088 100644
--- a/arch/arm64/boot/dts/apple/t8140.dtsi
+++ b/arch/arm64/boot/dts/apple/t8140.dtsi
@@ -143,6 +143,18 @@ l2_cache_1: l2-cache-1 {
 		};
 	};
 
+	pmu-e {
+		compatible = "apple,tahiti-e-pmu";
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_FIQ AIC_CPU_PMU_E IRQ_TYPE_LEVEL_HIGH>;
+	};
+
+	pmu-p {
+		compatible = "apple,tahiti-p-pmu";
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_FIQ AIC_CPU_PMU_P IRQ_TYPE_LEVEL_HIGH>;
+	};
+
 	soc: soc {
 		compatible = "simple-bus";
 		ranges;

-- 
2.55.0

