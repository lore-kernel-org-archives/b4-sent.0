From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Thu, 15 Oct 2026 19:54:10 +0200
Subject: [PATCH v6 2/4] arm64: dts: amlogic: t7: Add thermal sensor nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-add-thermal-t7-vim4-v6-2-37d1c954390c@aliel.fr>
References: <20261015-add-thermal-t7-vim4-v6-0-37d1c954390c@aliel.fr>
In-Reply-To: <20261015-add-thermal-t7-vim4-v6-0-37d1c954390c@aliel.fr>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3560;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=rtWuGUHxUnyMFKCauIYV7dFBkIsewyYeUUnSeGS6n8c=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ9ZF4crr27gbc+/+KZlwe8beud67tyo4//VcolZrevxHj
 H9Bw7YnHaUsDGJcDLJiiiz9cy1PvLt89MzXPeopMHNYmUCGMHBxCsBEFs5nZDjqbx2Z33Ez4fLk
 zEcF1eoapcpfYz+eUitKcD4jLW4xrYORoeVgcI/D5Kv8P0omt81ZprT9b/ulePbXu3J53v5ckX5
 XkBUA
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add six temperature sensor nodes using the amlogic,t7-thermal compatible:
a73, a53, gpu, nna, vpu, and hevc. Each sensor retrieves its calibration
data from the secure monitor via the amlogic,secure-monitor phandle with
the corresponding tsensor_id argument.

Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi | 66 +++++++++++++++++++++++++++++
 1 file changed, 66 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
index 8aa85aab30469..c81632d3984e8 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
@@ -696,6 +696,26 @@ sec_ao: ao-secure@10220 {
 				amlogic,has-chip-id;
 			};
 
+			a73_tsensor: temperature-sensor@20000 {
+				compatible = "amlogic,t7-thermal";
+				reg = <0x0 0x20000 0x0 0x50>;
+				interrupts = <GIC_SPI 31 IRQ_TYPE_LEVEL_HIGH>;
+				clocks = <&clkc_periphs CLKID_SYS_TS_A73>, <&clkc_periphs CLKID_TS>;
+				clock-names = "bus", "core";
+				#thermal-sensor-cells = <0>;
+				amlogic,secure-monitor = <&sm 1>;
+			};
+
+			a53_tsensor: temperature-sensor@22000 {
+				compatible = "amlogic,t7-thermal";
+				reg = <0x0 0x22000 0x0 0x50>;
+				interrupts = <GIC_SPI 30 IRQ_TYPE_LEVEL_HIGH>;
+				clocks = <&clkc_periphs CLKID_SYS_TS_A53>, <&clkc_periphs CLKID_TS>;
+				clock-names = "bus", "core";
+				#thermal-sensor-cells = <0>;
+				amlogic,secure-monitor = <&sm 2>;
+			};
+
 			pwm_ao_ef: pwm@30000 {
 				compatible = "amlogic,t7-pwm", "amlogic,meson-s4-pwm";
 				reg = <0x0 0x30000 0x0 0x24>;
@@ -818,6 +838,52 @@ sd_emmc_c: mmc@8c000 {
 				assigned-clock-parents = <&xtal>;
 				status = "disabled";
 			};
+
+			gpu_tsensor: temperature-sensor@94000 {
+				compatible = "amlogic,t7-thermal";
+				reg = <0x0 0x94000 0x0 0x50>;
+				interrupts = <GIC_SPI 83 IRQ_TYPE_LEVEL_HIGH>;
+				clocks = <&clkc_periphs CLKID_SYS_TS_GPU>, <&clkc_periphs CLKID_TS>;
+				clock-names = "bus", "core";
+				power-domains = <&pwrc PWRC_T7_MALI_TOP_ID>;
+				#thermal-sensor-cells = <0>;
+				amlogic,secure-monitor = <&sm 3>;
+			};
+
+			nna_tsensor: temperature-sensor@96000 {
+				compatible = "amlogic,t7-thermal";
+				reg = <0x0 0x96000 0x0 0x50>;
+				interrupts = <GIC_SPI 84 IRQ_TYPE_LEVEL_HIGH>;
+				clocks = <&clkc_periphs CLKID_SYS_TS_NNA>, <&clkc_periphs CLKID_TS>;
+				clock-names = "bus", "core";
+				power-domains = <&pwrc PWRC_T7_NNA_TOP_ID>;
+				#thermal-sensor-cells = <0>;
+				amlogic,secure-monitor = <&sm 4>;
+			};
+
+			vpu_tsensor: temperature-sensor@98000 {
+				compatible = "amlogic,t7-thermal";
+				reg = <0x0 0x98000 0x0 0x50>;
+				interrupts = <GIC_SPI 85 IRQ_TYPE_LEVEL_HIGH>;
+				clocks = <&clkc_periphs CLKID_SYS_TS_VPU>, <&clkc_periphs CLKID_TS>;
+				clock-names = "bus", "core";
+				power-domains = <&pwrc PWRC_T7_VPU_HDMI_ID>;
+				#thermal-sensor-cells = <0>;
+				amlogic,secure-monitor = <&sm 6>;
+			};
+
+			hevc_tsensor: temperature-sensor@9a000 {
+				compatible = "amlogic,t7-thermal";
+				reg = <0x0 0x9a000 0x0 0x50>;
+				interrupts = <GIC_SPI 86 IRQ_TYPE_LEVEL_HIGH>;
+				clocks =
+					<&clkc_periphs CLKID_SYS_TS_HEVC>,
+					<&clkc_periphs CLKID_TS>;
+				clock-names = "bus", "core";
+				power-domains = <&pwrc PWRC_T7_DOS_HEVC_ID>;
+				#thermal-sensor-cells = <0>;
+				amlogic,secure-monitor = <&sm 5>;
+			};
 		};
 
 	};

-- 
2.49.0

