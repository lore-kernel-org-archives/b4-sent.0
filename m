From: Igor Velkov <iav@iav.lv>
Date: Wed, 21 Oct 2026 02:02:29 +0000
Subject: [PATCH] arm64: dts: rockchip: Add vdd_log and vdd_center to Kobol
 Helios64
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261021-helios64-vdd-log-center-v1-1-4cafd110e0e5@iav.lv>
X-B4-Tracking: v=1; b=H4sIADUd2GoC/x3MQQqAIBBA0avErBtoTCy6SrQwnWogNDQiiO6et
 HyL/x/InIQzDNUDiS/JEkMB1RW4zYaVUXwxqEYZahThxrvEbDRe3uMeV3QcTk44U+sXPZuutwS
 lPhIvcv/ncXrfDzkFkdJpAAAA
To: Heiko Stuebner <heiko@sntech.de>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2557; i=iav@iav.lv;
 h=from:subject:message-id; bh=RDt7P+CwOHiaEZvswLkEBaOOUqR15G5E3l+XUXhUTd8=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFk3ZM28ok6uurQ4RuGJvaChU8C3vtWXs34WMTzvOV6gO
 ofBseBRRykLgxgXg6yYIsuEQxq3MpZc/evvYf4AZg4rE8gQBi5OAZhI8SmG/1lfjils1Jsu0lPc
 klw6+daeKx4PfI8siAiqF+btd3xrHsjIsCsy+OKF7YymHVIti1g23t9sLJ3R8S8h2Svyb/PRd0d
 jGQE=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Helios64 feeds VDD_LOG from a PWM regulator driven by PWM2 and
VDD_CENTER from DCDC_REG1 of the RK808, but the device tree describes
neither of them.

Describe both. The vdd_log range comes from the schematic (sheet 8):
0.83 V with 3.0 V on LOG_DVS_PWM and 1.4 V with 0 V, so the PWM is
inverted. vdd_center gets the same limits as vdd_cpu_l.

With U-Boot setting both rails to 950 mV, Linux 7.3-rc7 reports 949 mV
and 950 mV.

Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
No regulator-state-mem: deep suspend does not resume on this board yet,
so no suspend value is tested.

U-Boot sets both rails to 950 mV:
https://lore.kernel.org/r/20261021-b4-helios64-v1-1-74afe8aa6d72@iav.lv

This conflicts with the pending power tree series in the list of fixed
regulators; I will rebase whichever goes in second:
https://lore.kernel.org/r/20261016-helios64-power-tree-v1-0-31d6c8dc5092@iav.lv
---
 .../boot/dts/rockchip/rk3399-kobol-helios64.dts    | 24 ++++++++++++++++++++++
 1 file changed, 24 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
index 63ad79b4c8ac..3c2ba805e999 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
@@ -271,6 +271,17 @@ vcc12v_dcin_bkup: regulator-vcc12v-dcin-bkup {
 		regulator-max-microvolt = <12000000>;
 		vin-supply = <&vcc12v_dcin>;
 	};
+
+	vdd_log: regulator-vdd-log {
+		compatible = "pwm-regulator";
+		pwms = <&pwm2 0 25000 1>;
+		pwm-supply = <&vcc5v0_sys>;
+		regulator-name = "vdd_log";
+		regulator-always-on;
+		regulator-boot-on;
+		regulator-min-microvolt = <830000>;
+		regulator-max-microvolt = <1400000>;
+	};
 };
 
 /*
@@ -370,6 +381,15 @@ rk808: pmic@1b {
 		#clock-cells = <1>;
 
 		regulators {
+			vdd_center: DCDC_REG1 {
+				regulator-name = "vdd_center";
+				regulator-always-on;
+				regulator-boot-on;
+				regulator-min-microvolt = <750000>;
+				regulator-max-microvolt = <1350000>;
+				regulator-ramp-delay = <6001>;
+			};
+
 			vdd_cpu_l: DCDC_REG2 {
 				regulator-name = "vdd_cpu_l";
 				regulator-always-on;
@@ -580,6 +600,10 @@ &pwm1 {
 	status = "okay";
 };
 
+&pwm2 {
+	status = "okay";
+};
+
 &saradc {
 	vref-supply = <&vcc1v8_s3>;
 	status = "okay";

---
base-commit: d2abcbb905b0e4b2e06b257fa1e5bcf4faa6dbda
change-id: 20261021-helios64-vdd-log-center-b13df4b678a1

Best regards,
-- 
Igor Velkov <iav@iav.lv>

