From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Thu, 26 Nov 2026 22:21:57 +0530
Subject: [PATCH v5 1/2] dt-bindings: pinctrl: qcom: Add Molokai TLMM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-molokai-tlmm-v5-1-ada44435bdd3@yahoo.com>
References: <20261126-molokai-tlmm-v5-0-ada44435bdd3@yahoo.com>
In-Reply-To: <20261126-molokai-tlmm-v5-0-ada44435bdd3@yahoo.com>
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795711916; l=5643;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=07NxyJj6byfV/chTiCSs0aVHTp28yRKPsTfaF+2gz3Y=;
 b=2RPqHbbunoaX+wyQ6XjF5cTTRpuLH2yCXb946b6jZKP9hluG6jPuvw/ZjOFa7GSWBJ+W3NNW1
 Wf/O1PeWmz+C1bvks9WbfZcSNmsCu24vrH8KfJsfzHa/l7oUjckwWGe
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Top Level Mode Multiplexer of the Qualcomm Molokai (SM8845)
SoC. It is a Kaanapali derivative, but has 205 GPIOs instead of 217, the
SDC2 lines muxed on GPIOs instead of dedicated SDC2 pads, and a different
set of pin functions.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
 .../bindings/pinctrl/qcom,molokai-tlmm.yaml        | 129 +++++++++++++++++++++
 1 file changed, 129 insertions(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/qcom,molokai-tlmm.yaml b/Documentation/devicetree/bindings/pinctrl/qcom,molokai-tlmm.yaml
new file mode 100644
index 000000000000..a93ef0abb1ae
--- /dev/null
+++ b/Documentation/devicetree/bindings/pinctrl/qcom,molokai-tlmm.yaml
@@ -0,0 +1,129 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/pinctrl/qcom,molokai-tlmm.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Qualcomm Technologies, Inc. Molokai TLMM block
+
+maintainers:
+  - Venkat Yadlapati <venkat.yadlapati@yahoo.com>
+
+description:
+  Top Level Mode Multiplexer pin controller in Qualcomm Molokai (SM8845) SoC.
+
+allOf:
+  - $ref: /schemas/pinctrl/qcom,tlmm-common.yaml#
+
+properties:
+  compatible:
+    const: qcom,molokai-tlmm
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+  gpio-reserved-ranges:
+    minItems: 1
+    maxItems: 103
+
+  gpio-line-names:
+    maxItems: 205
+
+patternProperties:
+  "-state$":
+    oneOf:
+      - $ref: "#/$defs/qcom-molokai-tlmm-state"
+      - patternProperties:
+          "-pins$":
+            $ref: "#/$defs/qcom-molokai-tlmm-state"
+        additionalProperties: false
+
+$defs:
+  qcom-molokai-tlmm-state:
+    type: object
+    description:
+      Pinctrl node's client devices use subnodes for desired pin configuration.
+      Client device subnodes use below standard properties.
+    $ref: qcom,tlmm-common.yaml#/$defs/qcom-tlmm-state
+    unevaluatedProperties: false
+
+    properties:
+      pins:
+        description:
+          List of gpio pins affected by the properties specified in this
+          subnode.
+        items:
+          oneOf:
+            - pattern: "^gpio([0-9]|[1-9][0-9]|1[0-9][0-9]|20[0-4])$"
+            - enum: [ ufs_reset ]
+        minItems: 1
+        maxItems: 36
+
+      function:
+        description:
+          Specify the alternative function to be configured for the specified
+          pins.
+        enum: [ gpio, aoss_cti, atest_char, atest_usb, audio_ext_mclk0,
+                audio_ext_mclk1, audio_ref_clk, cam_asc_mclk4, cam_mclk,
+                cci_async_in, cci_i2c_scl, cci_i2c_sda, cci_timer,
+                coex_uart1_rx, coex_uart1_tx, coex_uart2_rx, coex_uart2_tx,
+                dbg_out_clk, ddr_bist_complete, ddr_bist_fail, ddr_bist_start,
+                ddr_bist_stop, ddr_pxi0, ddr_pxi1, ddr_pxi2, ddr_pxi3, dp_hot,
+                egpio, gcc_gp1, gcc_gp2, gcc_gp3, gnss_adc0, gnss_adc1, gp_mn,
+                gp_pdm_mira, gp_pdm_mirb, grfc, host2wlan_sol, i2s0_data0,
+                i2s0_data1, i2s0_sck, i2s0_ws, i2s1_data0, i2s1_data1,
+                i2s1_sck, i2s1_ws, ibi_i3c, jitter_bist, mdp_esync0_out,
+                mdp_esync1_out, mdp_vsync, mdp_vsync0_out, mdp_vsync1_out,
+                mdp_vsync2_out, mdp_vsync3_out, mdp_vsync5_out, mdp_vsync_e,
+                nav_gpio0, nav_gpio1, nav_gpio2, nav_gpio3, pcie0_clk_req_n,
+                phase_flag, pll_bist_sync, pll_clk_aux, prng_rosc0, prng_rosc1,
+                prng_rosc2, prng_rosc3, qdss_cti, qdss_gpio_traceclk,
+                qdss_gpio_tracectl, qdss_gpio_tracedata, qlink_big_enable,
+                qlink_big_request, qlink_little_enable, qlink_little_request,
+                qlink_wmss, qspi0, qspi1, qspi2, qspi3, qspi_clk, qspi_cs,
+                qup1_se0, qup1_se1, qup1_se2, qup1_se3, qup1_se4,
+                qup1_se5_l2_mirb, qup1_se5_l3_mirb, qup1_se5_mira,
+                qup1_se5_mirb, qup1_se6, qup1_se7, qup2_se0, qup2_se1,
+                qup2_se2, qup2_se3, qup2_se4_mira, qup2_se4_mirb, qup2_se5,
+                qup2_se5_l6, qup2_se6, qup2_se7, qup3_se0, qup3_se1, qup3_se2,
+                qup3_se3, qup3_se4, resout_gpio_n, rffe, sd_write_protect,
+                sdc2_clk, sdc2_cmd, sdc2_data, sdc2_fb_clk, sys_throttle,
+                tb_trig_sdc2, tmess_prng0, tmess_prng1, tmess_prng2,
+                tmess_prng3, tsense_pwm1, tsense_pwm2, tsense_pwm3,
+                tsense_pwm4, tsense_pwm5, tsense_pwm6, tsense_pwm7, uim0_clk,
+                uim0_data, uim0_present, uim0_reset, uim1_clk, uim1_data,
+                uim1_present, uim1_reset, usb1_hs, usb_phy, vfr_0, vfr_1,
+                vsense_trigger_mirnat, wcn_sw, wcn_sw_ctrl ]
+
+    required:
+      - pins
+
+required:
+  - compatible
+  - reg
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+
+    tlmm: pinctrl@f100000 {
+        compatible = "qcom,molokai-tlmm";
+        reg = <0x0f100000 0x300000>;
+        interrupts = <GIC_SPI 208 IRQ_TYPE_LEVEL_HIGH>;
+        gpio-controller;
+        #gpio-cells = <2>;
+        gpio-ranges = <&tlmm 0 0 206>;
+        interrupt-controller;
+        #interrupt-cells = <2>;
+
+        qup-spi4-state {
+            pins = "gpio48", "gpio49", "gpio50", "gpio51";
+            function = "qup1_se4";
+        };
+    };
+...

-- 
2.56.1

