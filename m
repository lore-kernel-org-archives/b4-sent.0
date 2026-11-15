From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Mon, 16 Nov 2026 01:50:19 +0530
Subject: [PATCH 11/11] arm64: dts: qcom: Add Motorola Signature (vantage)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-molokai-soc-v1-11-3b2ee920fa3b@yahoo.com>
References: <20261116-molokai-soc-v1-0-3b2ee920fa3b@yahoo.com>
In-Reply-To: <20261116-molokai-soc-v1-0-3b2ee920fa3b@yahoo.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794774008; l=17498;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=NITDn7NKFpay7mf1gMGiNiv4+ZKRb/FptfNq7ROlyrM=;
 b=coMY6Cyd0LguJ/d74E1uoI04o/PbpXFPAcabenwmllewed2aV4YGV7po498JI9Gq1vNyfII7Z
 1Eyy+kBFn0UAiq3WfHbG/mq8h/VK8dKsaWv5SvnYP0+pRp9FfMulKIS
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the devicetree for the Motorola Signature (vantage), a phone built
on the Molokai (SM8845) SoC, with:

- UFS storage, the device reset is on GPIO 205
- USB with role switching, and the Type-C connector handled by the
  charger firmware on SoCCP through pmic-glink, which also provides the
  battery and USB power supplies
- the volume and AI keys: volume up is GPIO 6 of the PM8550, the AI key
  TLMM GPIO 124 and volume down the RESIN input of the PMK8550
- the bootloader's splash buffer as a simple-framebuffer

The memory map follows the firmware the phone ships with. The CoreSight
blocks are disabled: they are not accessible on production devices and
reading their peripheral ID registers is a synchronous external abort.

Assisted-by: LLM
Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
 arch/arm64/boot/dts/qcom/Makefile                  |   1 +
 .../boot/dts/qcom/molokai-motorola-vantage.dts     | 737 +++++++++++++++++++++
 2 files changed, 738 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/Makefile b/arch/arm64/boot/dts/qcom/Makefile
index 9553e3aaeccb..17d4374e2a5d 100644
--- a/arch/arm64/boot/dts/qcom/Makefile
+++ b/arch/arm64/boot/dts/qcom/Makefile
@@ -79,6 +79,7 @@ dtb-$(CONFIG_ARCH_QCOM)	+= mahua-lenovo-thinkpad-t14s-gen7-lcd.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= mahua-qcb.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= milos-fairphone-fp6.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= milos-nothing-asteroids.dtb
+dtb-$(CONFIG_ARCH_QCOM)	+= molokai-motorola-vantage.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= monaco-arduino-monza.dtb
 
 monaco-arduino-monza-el2-dtbs	:= monaco-arduino-monza.dtb monaco-el2.dtbo
diff --git a/arch/arm64/boot/dts/qcom/molokai-motorola-vantage.dts b/arch/arm64/boot/dts/qcom/molokai-motorola-vantage.dts
new file mode 100644
index 000000000000..c3a0fa5f4e0e
--- /dev/null
+++ b/arch/arm64/boot/dts/qcom/molokai-motorola-vantage.dts
@@ -0,0 +1,737 @@
+// SPDX-License-Identifier: BSD-3-Clause
+/*
+ * Copyright (c) 2026 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
+ */
+
+/dts-v1/;
+
+#include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/regulator/qcom,rpmh-regulator.h>
+#include <dt-bindings/spmi/spmi.h>
+#include "molokai.dtsi"
+#include "pmk8850.dtsi"
+
+/delete-node/ &camera_mem;
+/delete-node/ &camera_2_mem;
+/delete-node/ &cdsp_mem;
+/delete-node/ &cvp_mem;
+/delete-node/ &dsm_partition_1_mem;
+/delete-node/ &dsm_partition_2_mem;
+/delete-node/ &q6_adsp_dtb_mem;
+/delete-node/ &q6_cdsp_dtb_mem;
+/delete-node/ &adspslpi_mem;
+/delete-node/ &soccp_mem;
+/delete-node/ &soccp_dtb_mem;
+/delete-node/ &video_mem;
+
+/ {
+	model = "Motorola Signature";
+	compatible = "motorola,vantage", "qcom,molokai";
+	chassis-type = "handset";
+
+	aliases {
+		serial0 = &uart7;
+	};
+
+	chosen {
+		#address-cells = <2>;
+		#size-cells = <2>;
+		ranges;
+
+		framebuffer0: framebuffer@fc800000 {
+			compatible = "simple-framebuffer";
+			reg = <0x0 0xfc800000 0x0 0x2b00000>;
+			width = <1264>;
+			height = <2780>;
+			stride = <(1264 * 4)>;
+			format = "a8r8g8b8";
+		};
+	};
+
+	clocks {
+		xo_board: xo-board {
+			compatible = "fixed-clock";
+			clock-frequency = <76800000>;
+			#clock-cells = <0>;
+		};
+
+		sleep_clk: sleep-clk {
+			compatible = "fixed-clock";
+			clock-frequency = <32764>;
+			#clock-cells = <0>;
+		};
+
+		bi_tcxo_div2: bi-tcxo-div2-clk {
+			compatible = "fixed-factor-clock";
+			#clock-cells = <0>;
+
+			clocks = <&rpmhcc RPMH_CXO_CLK>;
+			clock-mult = <1>;
+			clock-div = <2>;
+		};
+
+		bi_tcxo_ao_div2: bi-tcxo-ao-div2-clk {
+			compatible = "fixed-factor-clock";
+			#clock-cells = <0>;
+
+			clocks = <&rpmhcc RPMH_CXO_CLK_A>;
+			clock-mult = <1>;
+			clock-div = <2>;
+		};
+	};
+
+	/* Memory map of the SM8845 firmware shipped with A171WVH.21-16-16 */
+	gpio-keys {
+		compatible = "gpio-keys";
+
+		pinctrl-0 = <&key_vol_up_default>, <&key_ai_default>;
+		pinctrl-names = "default";
+
+		key-ai {
+			label = "AI Key";
+			linux,code = <KEY_ASSISTANT>;
+			gpios = <&tlmm 124 GPIO_ACTIVE_LOW>;
+			debounce-interval = <15>;
+			linux,can-disable;
+			wakeup-source;
+		};
+
+		key-volume-up {
+			label = "Volume Up";
+			linux,code = <KEY_VOLUMEUP>;
+			gpios = <&pm8550_gpios 6 GPIO_ACTIVE_LOW>;
+			debounce-interval = <15>;
+			linux,can-disable;
+			wakeup-source;
+		};
+	};
+
+	pmic-glink {
+		compatible = "qcom,kaanapali-pmic-glink",
+			     "qcom,pmic-glink";
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		connector@0 {
+			compatible = "usb-c-connector";
+			reg = <0>;
+
+			power-role = "dual";
+			data-role = "dual";
+
+			ports {
+				#address-cells = <1>;
+				#size-cells = <0>;
+
+				port@0 {
+					reg = <0>;
+
+					pmic_glink_hs_in: endpoint {
+						remote-endpoint = <&usb_dwc3_hs>;
+					};
+				};
+
+				port@1 {
+					reg = <1>;
+
+					pmic_glink_ss_in: endpoint {
+						remote-endpoint = <&usb_dp_qmpphy_out>;
+					};
+				};
+
+				port@2 {
+					reg = <2>;
+
+					pmic_glink_sbu: endpoint {
+					};
+				};
+			};
+		};
+	};
+
+	reserved-memory {
+		gunyah_hyp_mem: gunyah-hyp@80000000 {
+			reg = <0x0 0x80000000 0x0 0xe00000>;
+			no-map;
+		};
+
+		cpucp_mem: cpucp@81200000 {
+			reg = <0x0 0x81200000 0x0 0x100000>;
+			no-map;
+		};
+
+		xbl_dtlog_mem: xbl-dtlog@81a00000 {
+			reg = <0x0 0x81a00000 0x0 0x60000>;
+			no-map;
+		};
+
+		aop_image_mem: aop-image@81c00000 {
+			reg = <0x0 0x81c00000 0x0 0x60000>;
+			no-map;
+		};
+
+		aop_config_mem: aop-config@81c80000 {
+			reg = <0x0 0x81c80000 0x0 0x20000>;
+			no-map;
+		};
+
+		tme_crash_dump_mem: tme-crash-dump@81ca0000 {
+			reg = <0x0 0x81ca0000 0x0 0x40000>;
+			no-map;
+		};
+
+		tme_log_mem: tme-log@81ce0000 {
+			reg = <0x0 0x81ce0000 0x0 0x4000>;
+			no-map;
+		};
+
+		uefi_log_mem: uefi-log@81ce4000 {
+			reg = <0x0 0x81ce4000 0x0 0x10000>;
+			no-map;
+		};
+
+		cpucp_scandump_mem: cpucp-scandump@82000000 {
+			reg = <0x0 0x82000000 0x0 0x380000>;
+			no-map;
+		};
+
+		adsp_mhi_mem: adsp-mhi@82380000 {
+			reg = <0x0 0x82380000 0x0 0x20000>;
+			no-map;
+		};
+
+		soccp_sdi_mem: soccp-sdi@823a0000 {
+			reg = <0x0 0x823a0000 0x0 0x40000>;
+			no-map;
+		};
+
+		pmic_minidump_mem: pmic-minidump@823e0000 {
+			reg = <0x0 0x823e0000 0x0 0x80000>;
+			no-map;
+		};
+
+		qup_fw_mem: qup-fw@82460000 {
+			reg = <0x0 0x82460000 0x0 0x18000>;
+			no-map;
+		};
+
+		pvm_fw_mem: pvm-fw@824a0000 {
+			reg = <0x0 0x824a0000 0x0 0x100000>;
+			no-map;
+		};
+
+		hyp_mem_database_mem: hyp-mem-database@825a0000 {
+			reg = <0x0 0x825a0000 0x0 0x60000>;
+			no-map;
+		};
+
+		tz_stat_mem: tz-stat@82700000 {
+			reg = <0x0 0x82700000 0x0 0x100000>;
+			no-map;
+		};
+
+		qdss_apps_mem: qdss-apps@82800000 {
+			compatible = "shared-dma-pool";
+			reg = <0x0 0x82800000 0x0 0x2000000>;
+			alignment = <0x0 0x400000>;
+			reusable;
+		};
+
+		dsm_partition_1_mem: dsm-partition-1@84a00000 {
+			reg = <0x0 0x84a00000 0x0 0x5100000>;
+			no-map;
+		};
+
+		camera_mem: camera@9b800000 {
+			reg = <0x0 0x9b800000 0x0 0x800000>;
+			no-map;
+		};
+
+		camera_2_mem: camera-2@9c000000 {
+			reg = <0x0 0x9c000000 0x0 0x800000>;
+			no-map;
+		};
+
+		video_mem: video@9c800000 {
+			reg = <0x0 0x9c800000 0x0 0x800000>;
+			no-map;
+		};
+
+		cvp_mem: cvp@9d000000 {
+			reg = <0x0 0x9d000000 0x0 0x700000>;
+			no-map;
+		};
+
+		cdsp_mem: cdsp@9d700000 {
+			reg = <0x0 0x9d700000 0x0 0x1900000>;
+			no-map;
+		};
+
+		q6_cdsp_dtb_mem: q6-cdsp-dtb@9f000000 {
+			reg = <0x0 0x9f000000 0x0 0x80000>;
+			no-map;
+		};
+
+		dcp_dtb_mem: dcp-dtb@a4080000 {
+			reg = <0x0 0xa4080000 0x0 0x80000>;
+			no-map;
+		};
+
+		dcp_mem: dcp@a4100000 {
+			reg = <0x0 0xa4100000 0x0 0x300000>;
+			no-map;
+		};
+
+		soccp_mem: soccp@a4400000 {
+			reg = <0x0 0xa4400000 0x0 0x600000>;
+			no-map;
+		};
+
+		soccp_dtb_mem: soccp-dtb@a4a00000 {
+			reg = <0x0 0xa4a00000 0x0 0x40000>;
+			no-map;
+		};
+
+		mmi_annotate_mem: mmi-annotate@adfff000 {
+			reg = <0x0 0xadfff000 0x0 0x1000>;
+			no-map;
+		};
+
+		ramoops_mem: ramoops@ae000000 {
+			compatible = "ramoops";
+			reg = <0x0 0xae000000 0x0 0x60000>;
+			console-size = <0x40000>;
+			record-size = <0x20000>;
+			no-map;
+		};
+
+		q6_adsp_dtb_mem: q6-adsp-dtb@b8280000 {
+			reg = <0x0 0xb8280000 0x0 0x80000>;
+			no-map;
+		};
+
+		adspslpi_mem: adspslpi@b8300000 {
+			reg = <0x0 0xb8300000 0x0 0x5e00000>;
+			no-map;
+		};
+
+		xbl_ramdump_mem: xbl-ramdump@d5d00000 {
+			reg = <0x0 0xd5d00000 0x0 0x1c0000>;
+			no-map;
+		};
+
+		hyp_ext_heap_mem: hyp-ext-heap@d63d0000 {
+			reg = <0x0 0xd63d0000 0x0 0x800000>;
+			no-map;
+		};
+
+		global_sync_mem: global-sync@d7a00000 {
+			reg = <0x0 0xd7a00000 0x0 0x200000>;
+			no-map;
+		};
+
+		tz_merged_mem: tz-merged@d8000000 {
+			reg = <0x0 0xd8000000 0x0 0x3a00000>;
+			no-map;
+		};
+
+		oem_vm_mem: oem-vm@f7c00000 {
+			compatible = "shared-dma-pool";
+			reg = <0x0 0xf7c00000 0x0 0x4c00000>;
+			alignment = <0x0 0x400000>;
+			reusable;
+		};
+
+		splash_mem: splash@fc800000 {
+			reg = <0x0 0xfc800000 0x0 0x2b00000>;
+			no-map;
+		};
+
+		llcc_lpi_mem: llcc-lpi@ff800000 {
+			reg = <0x0 0xff800000 0x0 0x600000>;
+			no-map;
+		};
+
+		lcp_dare_mem: lcp-dare@880000000 {
+			compatible = "shared-dma-pool";
+			reg = <0x8 0x80000000 0x0 0x6000000>;
+			alignment = <0x0 0x400000>;
+			reusable;
+		};
+	};
+};
+
+/*
+ * The CoreSight/QDSS debug blocks are not accessible on these production-fused
+ * phones; reading their peripheral ID registers is a synchronous external abort.
+ */
+&{/soc@0/stm@10002000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@10003000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpda@10004000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@1000f000} {
+	status = "disabled";
+};
+
+&{/soc@0/funnel@10041000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@11000000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpda@11004000} {
+	status = "disabled";
+};
+
+&{/soc@0/funnel@11005000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@1102c000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@11180000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@11183000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@11184000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@11185000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@11186000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpda@11188000} {
+	status = "disabled";
+};
+
+&{/soc@0/funnel@11189000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@111a3000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@111a4000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@111a5000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@111a6000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@111a7000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@111a8000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@111a9000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@111aa000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@111ab000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@111ac000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@111ad000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@111ae000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@111af000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@111b3000} {
+	status = "disabled";
+};
+
+&{/soc@0/tn@111b8000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@111d0000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@11303000} {
+	status = "disabled";
+};
+
+&{/soc@0/funnel@11304000} {
+	status = "disabled";
+};
+
+&{/soc@0/tmc@11305000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpda@11308000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@11309000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@1130a000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@1130b000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@1130c000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@1130d000} {
+	status = "disabled";
+};
+
+&{/soc@0/tpdm@11422000} {
+	status = "disabled";
+};
+
+&apps_rsc {
+	regulators-0 {
+		compatible = "qcom,pmh0101-rpmh-regulators";
+		qcom,pmic-id = "B_E0";
+
+		vreg_l5b_3p1: ldo5 {
+			regulator-name = "vreg_l5b_3p1";
+			regulator-min-microvolt = <3100000>;
+			regulator-max-microvolt = <3148000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_AUTO>;
+			regulator-allow-set-load;
+			regulator-allowed-modes = <RPMH_REGULATOR_MODE_LPM
+						   RPMH_REGULATOR_MODE_AUTO>;
+		};
+
+		vreg_l15b_1p8: ldo15 {
+			regulator-name = "vreg_l15b_1p8";
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <1800000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_AUTO>;
+			regulator-allow-set-load;
+			regulator-allowed-modes = <RPMH_REGULATOR_MODE_LPM
+						   RPMH_REGULATOR_MODE_AUTO>;
+		};
+
+		vreg_l17b_2p5: ldo17 {
+			regulator-name = "vreg_l17b_2p5";
+			regulator-min-microvolt = <2504000>;
+			regulator-max-microvolt = <2504000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
+			regulator-allow-set-load;
+			regulator-allowed-modes = <RPMH_REGULATOR_MODE_LPM
+						   RPMH_REGULATOR_MODE_HPM>;
+		};
+	};
+
+	regulators-2 {
+		compatible = "qcom,pmh0110-rpmh-regulators";
+		qcom,pmic-id = "F_E0";
+
+		vreg_l2f_1p2: ldo2 {
+			regulator-name = "vreg_l2f_1p2";
+			regulator-min-microvolt = <1200000>;
+			regulator-max-microvolt = <1200000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_AUTO>;
+			regulator-allow-set-load;
+			regulator-allowed-modes = <RPMH_REGULATOR_MODE_LPM
+						   RPMH_REGULATOR_MODE_AUTO>;
+		};
+
+		vreg_l3f_1p2: ldo3 {
+			regulator-name = "vreg_l3f_1p2";
+			regulator-min-microvolt = <1200000>;
+			regulator-max-microvolt = <1200000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_AUTO>;
+			regulator-allow-set-load;
+			regulator-allowed-modes = <RPMH_REGULATOR_MODE_LPM
+						   RPMH_REGULATOR_MODE_AUTO>;
+		};
+	};
+
+	regulators-4 {
+		compatible = "qcom,pmh0110-rpmh-regulators";
+		qcom,pmic-id = "I_E0";
+
+		vreg_l1i_0p9: ldo1 {
+			regulator-name = "vreg_l1i_0p9";
+			regulator-min-microvolt = <866000>;
+			regulator-max-microvolt = <958000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_AUTO>;
+			regulator-allow-set-load;
+			regulator-allowed-modes = <RPMH_REGULATOR_MODE_LPM
+						   RPMH_REGULATOR_MODE_AUTO>;
+		};
+
+		vreg_l2i_0p9: ldo2 {
+			regulator-name = "vreg_l2i_0p9";
+			regulator-min-microvolt = <880000>;
+			regulator-max-microvolt = <920000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_AUTO>;
+			regulator-allow-set-load;
+			regulator-allowed-modes = <RPMH_REGULATOR_MODE_LPM
+						   RPMH_REGULATOR_MODE_AUTO>;
+		};
+
+		vreg_l3i_0p8: ldo3 {
+			regulator-name = "vreg_l3i_0p8";
+			regulator-min-microvolt = <880000>;
+			regulator-max-microvolt = <920000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_AUTO>;
+			regulator-allow-set-load;
+			regulator-allowed-modes = <RPMH_REGULATOR_MODE_LPM
+						   RPMH_REGULATOR_MODE_AUTO>;
+		};
+	};
+};
+
+&tlmm {
+	gpio-reserved-ranges = <36 8>, <46 1>, <56 4>, <72 1>, <148 2>;
+
+	key_ai_default: key-ai-default-state {
+		pins = "gpio124";
+		function = "gpio";
+		output-disable;
+		bias-pull-up;
+	};
+};
+
+&pon_resin {
+	linux,code = <KEY_VOLUMEDOWN>;
+
+	status = "okay";
+};
+
+&spmi_bus0 {
+	pmic@1 {
+		compatible = "qcom,pm8550", "qcom,spmi-pmic";
+		reg = <0x1 SPMI_USID>;
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		pm8550_gpios: gpio@8800 {
+			compatible = "qcom,pm8550-gpio", "qcom,spmi-gpio";
+			reg = <0x8800>;
+			gpio-controller;
+			gpio-ranges = <&pm8550_gpios 0 0 12>;
+			#gpio-cells = <2>;
+			interrupt-controller;
+			#interrupt-cells = <2>;
+
+			key_vol_up_default: key-vol-up-default-state {
+				pins = "gpio6";
+				function = "normal";
+				power-source = <1>;
+				bias-pull-up;
+				input-enable;
+			};
+		};
+	};
+
+	pmic@7 {
+		compatible = "qcom,pmih0108", "qcom,spmi-pmic";
+		reg = <0x7 SPMI_USID>;
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		pmih0108_eusb2_repeater: phy@fd00 {
+			compatible = "qcom,pm8550b-eusb2-repeater";
+			reg = <0xfd00>;
+			#phy-cells = <0>;
+
+			vdd18-supply = <&vreg_l15b_1p8>;
+			vdd3-supply = <&vreg_l5b_3p1>;
+		};
+	};
+};
+
+&usb {
+	status = "okay";
+};
+
+&usb_dp_qmpphy {
+	vdda-phy-supply = <&vreg_l2i_0p9>;
+	vdda-pll-supply = <&vreg_l2f_1p2>;
+
+	status = "okay";
+};
+
+&usb_hsphy {
+	vdd-supply = <&vreg_l3i_0p8>;
+	vdda12-supply = <&vreg_l2f_1p2>;
+
+	phys = <&pmih0108_eusb2_repeater>;
+
+	status = "okay";
+};
+
+&ufs_mem_hc {
+	reset-gpios = <&tlmm 205 GPIO_ACTIVE_LOW>;
+
+	vcc-supply = <&vreg_l17b_2p5>;
+	vcc-max-microamp = <1200000>;
+	vccq-supply = <&vreg_l3f_1p2>;
+	vccq-max-microamp = <1200000>;
+
+	status = "okay";
+};
+
+&ufs_mem_phy {
+	vdda-phy-supply = <&vreg_l1i_0p9>;
+	vdda-pll-supply = <&vreg_l2f_1p2>;
+
+	status = "okay";
+};
+
+&usb_dp_qmpphy_out {
+	remote-endpoint = <&pmic_glink_ss_in>;
+};
+
+&usb_dwc3_hs {
+	remote-endpoint = <&pmic_glink_hs_in>;
+};

-- 
2.56.0

