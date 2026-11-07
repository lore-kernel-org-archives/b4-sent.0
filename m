From: Myria Sarvay <myrialsarvay@gmail.com>
Date: Sat, 07 Nov 2026 21:49:01 +1100
Subject: [PATCH v2 14/15] arm64: dts: apple: t8132: Add PMU Device Nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-m3-plus-pmu-events-v2-14-acf1e78da039@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=844; i=myrialsarvay@gmail.com;
 h=from:subject:message-id; bh=3BrxbOYqTLNeyKHRZvsGvB9dy6HUAnTkRir0SxA2U9k=;
 b=owJ4nJvAy8zAJRbk4iixYu2/l4yn1ZIYst4zyZ7OiDOQDNK9237x7IW7s5Pa7zM8UpQ/5rJy+
 6StHyK+vU7tKGFhEONikBVTZNE3TdOezNZwqXSZ6xaYOaxMIEMYuDgFYCLKQQyf2f3f/VI7fX3R
 vy1exd/159YsjZk4Ldu31eCLtbxRhjQrI8OBOzYqbUW8d/995o7S+Na9lf20dsCFX3f5DWM73ns
 VMnADAGOFSaQ=
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
index e2e79c7e7fd0..767e622136c3 100644
--- a/arch/arm64/boot/dts/apple/t8132.dtsi
+++ b/arch/arm64/boot/dts/apple/t8132.dtsi
@@ -197,6 +197,18 @@ l2_cache_1: l2-cache-1 {
 		};
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
 

-- 
2.55.0

