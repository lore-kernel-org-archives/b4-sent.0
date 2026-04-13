From: Antony Kurniawan Soemardi <linux@smankusors.com>
Date: Tue, 14 Apr 2026 01:55:35 +0700
Subject: [PATCH 08/10] ARM: dts: qcom: msm8960: add SMSM & SPS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260414-msm8960-wifi-v1-8-007fda9d6134@smankusors.com>
References: <20260414-msm8960-wifi-v1-0-007fda9d6134@smankusors.com>
In-Reply-To: <20260414-msm8960-wifi-v1-0-007fda9d6134@smankusors.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Lee Jones <lee@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-arm-msm@vger.kernel.org, 
 linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Rudraksha Gupta <guptarud@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776106820; l=1581;
 i=linux@smankusors.com; s=20250609; h=from:subject:message-id;
 bh=ice+E8N1iDj8MEaStPEqyOOo7hv3tIlMXLbTqIjaYDc=;
 b=Yk21W0k8zlL0/bYPP9NL87tyKVDPHqY4ksvVwXhmruxG1NZLhBnkh8EEOfHJ1cjSMZHqWhkx6
 0SLQh4gKf0NDTia6p9G83ovur+6Yay+FyNwOOXjp4hHrfpi8c3KKycQ
X-Developer-Key: i=linux@smankusors.com; a=ed25519;
 pk=65wTy06fJl2/h/EJwjr704YG+yjHFhZObJBWzzK+N00=
X-Endpoint-Received: by B4 Relay for linux@smankusors.com/20250609 with auth_id=733
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Shared Memory State Machine node to coordinate state transitions
between the Applications processor and the Riva subsystem.

Tested-by: Rudraksha Gupta <guptarud@gmail.com>
Signed-off-by: Antony Kurniawan Soemardi <linux@smankusors.com>
---
 arch/arm/boot/dts/qcom/qcom-msm8960.dtsi | 30 ++++++++++++++++++++++++++++++
 1 file changed, 30 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi b/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
index 218cf3158dfb..107c5613aa4a 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
@@ -109,6 +109,31 @@ smem {
 		hwlocks = <&sfpb_mutex 3>;
 	};
 
+	smsm {
+		compatible = "qcom,smsm";
+
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		qcom,ipc-1 = <&l2cc 8 4>;
+		qcom,ipc-2 = <&l2cc 8 14>;
+		qcom,ipc-3 = <&l2cc 8 23>;
+		qcom,ipc-4 = <&sps_sic_non_secure 0x4094 0>;
+
+		apps_smsm: apps@0 {
+			reg = <0>;
+			#qcom,smem-state-cells = <1>;
+		};
+
+		wcnss_smsm: wcnss@3 {
+			reg = <3>;
+			interrupts = <GIC_SPI 204 IRQ_TYPE_EDGE_RISING>;
+
+			interrupt-controller;
+			#interrupt-cells = <2>;
+		};
+	};
+
 	soc: soc {
 		compatible = "simple-bus";
 		ranges;
@@ -455,6 +480,11 @@ clock-controller@4000000 {
 				      "hdmipll";
 		};
 
+		sps_sic_non_secure: interrupt-controller@12100000 {
+			compatible = "qcom,msm8960-sps-sic", "syscon";
+			reg = <0x12100000 0x10000>;
+		};
+
 		sdcc3: mmc@12180000 {
 			compatible = "arm,pl18x", "arm,primecell";
 			reg = <0x12180000 0x2000>;

-- 
2.34.1

