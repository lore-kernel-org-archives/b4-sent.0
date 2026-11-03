From: Myria Sarvay <myrialsarvay@gmail.com>
Date: Tue, 03 Nov 2026 21:14:45 +1100
Subject: [PATCH 10/13] arm64: dts: apple: t8122: Add PMU Device Nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-m3-plus-pmu-events-v1-10-a8eb6c1139fe@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=849; i=myrialsarvay@gmail.com;
 h=from:subject:message-id; bh=rNa2BkUs4YYaDGXSrrZeznuk/MnM9Ng1trURn1MGr4U=;
 b=owJ4nJvAy8zAJRbk4iixYu2/l4yn1ZIYsl5uEb16urq0R9FsThrb09xdr40Xu/WpFJstOdzOp
 lvWtudNuW5HKQuDGBeDrJgii75pmvZktoZLpctct8DMYWUCGcLAxSkAEwl5zfBX+O3Lz38XXelm
 Pm+XKvxsLWPDjNk+Kzi5zxg6SJ488/xLL8P/TEureyEhnVIt4k9es8aUWD/j2LWc/e/11Z4Omz/
 NN7/KDgCApkwq
X-Developer-Key: i=myrialsarvay@gmail.com; a=openpgp;
 fpr=2F35662B930680D275A645B452444118A8ADFEE9
X-Endpoint-Received: by B4 Relay for myrialsarvay@gmail.com/default with auth_id=1027
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds the PMU nodes to all t8122 devices.

Signed-off-by: Myria Sarvay <myrialsarvay@gmail.com>
---
 arch/arm64/boot/dts/apple/t8122.dtsi | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t8122.dtsi b/arch/arm64/boot/dts/apple/t8122.dtsi
index 959ddf36efa1..c9e81a6cc9b7 100644
--- a/arch/arm64/boot/dts/apple/t8122.dtsi
+++ b/arch/arm64/boot/dts/apple/t8122.dtsi
@@ -180,6 +180,18 @@ l2_cache_1: l2-cache-1 {
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
 	soc {
 		compatible = "simple-bus";
 		ranges;

-- 
2.56.0

