From: Myria Sarvay <myrialsarvay@gmail.com>
Date: Sat, 07 Nov 2026 21:49:00 +1100
Subject: [PATCH v2 13/15] arm64: dts: apple: t604x: Add PMU Device Nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-m3-plus-pmu-events-v2-13-acf1e78da039@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=848; i=myrialsarvay@gmail.com;
 h=from:subject:message-id; bh=tOGj1AVK13sDoleZ1GDPbZJP7wjR8LAHjlBELHNHOOg=;
 b=owJ4nJvAy8zAJRbk4iixYu2/l4yn1ZIYst4zyUY8vKgjKjL3andcg8Nk5dDey0+fn1xW4bX8d
 OXNJ3n3bsl3lLIwiHExyIopsuibpmlPZmu4VLrMdQvMHFYmkCEMXJwCMJFJ/xn+O+079oU58cMB
 rTVteXkGz9uSNldLm/3b1Sn2qYfVRGitOcNvtmWTsmfy6O3jqNv6PDL94/oJPE1qVlfPH6+4dvj
 u5RtnGQAEvU4K
X-Developer-Key: i=myrialsarvay@gmail.com; a=openpgp;
 fpr=2F35662B930680D275A645B452444118A8ADFEE9
X-Endpoint-Received: by B4 Relay for myrialsarvay@gmail.com/default with auth_id=1027
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds the PMU nodes to all t604x devices.

Signed-off-by: Myria Sarvay <myrialsarvay@gmail.com>
---
 arch/arm64/boot/dts/apple/t6041.dtsi | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t6041.dtsi b/arch/arm64/boot/dts/apple/t6041.dtsi
index 9110d05c896d..62d7c63042db 100644
--- a/arch/arm64/boot/dts/apple/t6041.dtsi
+++ b/arch/arm64/boot/dts/apple/t6041.dtsi
@@ -314,6 +314,18 @@ l2_cache_2: l2-cache-2 {
 		};
 	};
 
+	pmu-e {
+		compatible = "apple,brava-e-pmu";
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_FIQ AIC_CPU_PMU_E IRQ_TYPE_LEVEL_HIGH>;
+	};
+
+	pmu-p {
+		compatible = "apple,brava-p-pmu";
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_FIQ AIC_CPU_PMU_P IRQ_TYPE_LEVEL_HIGH>;
+	};
+
 	soc {
 		compatible = "simple-bus";
 		ranges;

-- 
2.55.0

