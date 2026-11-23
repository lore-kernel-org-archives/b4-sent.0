From: David Heidelberg <david@ixit.cz>
Date: Mon, 23 Nov 2026 16:47:01 +0100
Subject: [PATCH v9] arm64: dts: qcom: sdm845-google: Add STM FTS
 touchscreen support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-stmfts5-v9-1-3ab247cd32c0@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/13Qy07DMBAF0F+pvCZoPH6MzYr/QCz8pF7QojiKC
 lX+HadIOMny2nOuRnNnNY0lVfZyurMxzaWW66UF+3Ri4ewuH2kosWWGgBqQy6FOn3mqavCSBOf
 ZRxLI2vTXmHK5PZre3ls+lzpdx+9H8czX178OAfy/Y+YDDIhBKuOtC9q8lluZnsMPWxtm3Ciuu
 sKmCHwwIiWrLN8r0ZUE0ZVoSkVH2oQcEQ5KbpXtSjalZU66fVH0aq9UV4ZDV6opCCQoWrSW9F7
 prizorvS6IWSftcuG+OEatFXUFTUlnRLC8BBBHJTZKNzc0Kwb5pClTRiMyl0ty/ILzIIP/RYCA
 AA=
X-Change-ID: 20260214-stmfts5-b47311fbd732
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Henrik Rydberg <rydberg@bitmath.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>, linux-input@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Abel Vesa <abel.vesa@oss.qualcomm.com>, David Heidelberg <david@ixit.cz>, 
 Abel Vesa <abelvesa@kernel.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=7114; i=david@ixit.cz;
 h=from:subject:message-id; bh=BZ0jNhMewCco0W3GXqptMNj2qzAX+JOz+BtCMJgBCLQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrBF/2l+atC2bSO1qox+encpqS3x3oTwbR9q7P1
 lPMQNUewEOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawRf9gAKCRBgAj/E00kg
 ckQkD/wLWCfHtUy1Alv7HMK0uwsEWGQx7am6tJx3Xevd6TXHu3eW0yb3UPBFvEVDMTnrw9I/7uJ
 L0pvQj0EKAPLLRxfF+IOpYfOgYae/siKX3/Ybq76Rna6oxqBnjrroXC87AJG3iDyykB+SWKME1i
 WGfOJ2eBYx6G0rVwP3p17VwH4SGe9KgLZdAN7vpyGxJHJkHTXUqaqWhDD2wYLxLh579ro/0OZsp
 TD/LdMuqnPsRpEC3YyQ5x8fwOipEe5iO8X6eGEgFpqe8O/fb5c0vwV98VjJMe42HoDHeJmEKCaM
 ymOPyKevexWYrQIeiMCnaVJtFEDuCE16SBNvAzvR1EK4qtanVjpJITPPcM2GvemKy++TJNtuv5Y
 3tu9ezw9RmJPjfBcgs9kWixfwqe7QaMUJjxBdp+9uMkox4JqZ8YyBBumsMNbjs/+bDxpr2KkOZz
 FDArT1MI5ZMB3CIE6ATcYP9uq0eFRuMA02JK1U+tuFtpHVBzTEJ7GtLyerNIkyihM3t7T6WDh40
 SIoguFUqZgc0iqC2/ZQmtIUAmeV8v02DP9EiLOM8SfMcSpxf1NIFZqz0+WRfDHmalyupW33H7OE
 fDVlfEFPWnTyeH5hYzC+LJrnlwTU7uiFj9tL2JGzxekvqCkbNhbxdZn10u45/XHepZ0/wHcuW8E
 F87mQ3iaVyufD/Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Petr Hodina <petr.hodina@protonmail.com>

Basic touchscreen connected to second i2c bus.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Reviewed-by: Abel Vesa <abel.vesa@oss.qualcomm.com>
Co-developed-by: David Heidelberg <david@ixit.cz>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v9:
- Only Device-tree patch remains, rebased against next-20261120.
- Link to v8: https://patch.msgid.link/20260925-stmfts5-v8-0-0fcf49e2c85f@ixit.cz

Changes in v8:
- Split DT binding example changes into own commit (Krzysztof, Dmitry)
- Refectored the stmfts_power_on fix. (Dmitry)
- Added ABS_MT_TOOL_TYPE. (Dmitry, Sashiko)
- Link to v7: https://patch.msgid.link/20260907-stmfts5-v7-0-4a53381cd038@ixit.cz

Changes in v7:
- Added 'Input: stmfts - wait for controller ready after reset',
  the waiting is done for both FTS4 and FTS5, similarly to the
  downstream driver. Should improve reliability everywhere.
- Link to v6: https://patch.msgid.link/20260906-stmfts5-v6-0-50fbf6af8718@ixit.cz

Changes in v6:
- Enable only the multi-touch scan on FTS5 sense-on (0xff was wrong,
  only 0x01 is needed. This broke Xiaomi Mi 8 toucschreen).
- Fixed Y-coordinate comments. (Dmitry)
- Corrected event[0] parsing. (Dmitry)
- Dropped checking < 0 on unsigned area. (Dmitry)
- Dropped unnecessary i2c writes after reset. Verified against
  downstream driver. (Dmitry, Sashiko)
- Added pieces for supporting non-OF integration. (Sashiko)
- Shared input open/close into one impl. (Dmitry).
- Link to v5: https://patch.msgid.link/20260810-stmfts5-v5-0-0c737d929976@ixit.cz

Changes in v5:
- 3.3V is analog, 1.8V is digital supply. Fix that.
- Name the error variables "err" (Dmitry)
- Use scoped_guard() for ->running, and only set it once the scan
  mode has actually been enabled. (Dmitry)
- Use i2c_master_send() instead of open-coding a single-message
  i2c_transfer(). (Dmitry)
- Drivers may report coordinates outside the declared min/max, so
  remove the clamping. (Dmitry)
- BTN_TOUCH and INPUT_PROP_DIRECT are already set up by
  input_mt_init_slots(..., INPUT_MT_DIRECT). (Dmitry)
- Let the input core track contacts: drop the touch_id/stylus_id
  bitmaps and the hand-rolled BTN_TOUCH reporting, and sync the frame
  once per interrupt with input_mt_sync_frame() instead of calling
  input_sync() per contact event. The controller pushes contacts one
  by one into the event FIFO and only resends the ones that changed,
  so INPUT_MT_DROP_UNUSED is wrong here and is dropped as well. (Dmitry)
- Restore the FTS4 interrupts accidentally dropped by introduction of
  FTS5.
- mode-switch-gpios isn't required with stmfts5. Some designs, such as
  Xiaomi Mi 8, has no such GPIO connected and is limited to AP mode.
- Nit: updated example to use interrupts-extended.
- Nit: (maximum x/y coordinate reported + 1), corrected example.
- Link to v4: https://lore.kernel.org/r/20260409-stmfts5-v4-0-64fe62027db5@ixit.cz

Changes in v4:
- Wrap everything below enabling the supplies into stmfts_configure()
  to avoid bunch of gotos to power off on error (Dmitry T.)
- Finished chip specific ops and removed is_fts5. (Dmitry T.)
- Link to v3: https://lore.kernel.org/r/20260403-stmfts5-v3-0-5da768cfd201@ixit.cz

Changes in v3:
- s/touchscreen_pins/touchscreen_irq_n. (Konrad)
- Use interrupts-extended. (Konrad)
- Fixed rebase conflict against 8665ceb926ec ("Input: stmfts - use guard notation when acquiring mutex")
- Rename switch-gpios to mode-switch-gpios.
- Do not define properties in if:then: branches. (Krzysztof)
- Link to v2: https://lore.kernel.org/r/20260315-stmfts5-v2-0-70bc83ee9591@ixit.cz

Changes in v2:
- Fix typo in the binding s/switch-gpio/switch-gpios/.
- Deduplacate allOf. (Rob yamllint)
- Add missing S-off-by. (Dmitry B.)
- Dropped irq-gpios as it's not needed. (Konrad)
- Correct x and y touchscreen area size. (Konrad)
- Correct reset introduction commit description. (Krzysztof)
- Partially implemented chip specific ops. (Dmitry T.)
- Separeted license naming cleanup into separate commit (Dmitry T.)
- Link to v1: https://lore.kernel.org/r/20260301-stmfts5-v1-0-22c458b9ac68@ixit.cz

To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
To: Maxime Coquelin <mcoquelin.stm32@gmail.com>
To: Alexandre Torgue <alexandre.torgue@foss.st.com>
To: Petr Hodina <petr.hodina@protonmail.com>
To: David Heidelberg <david@ixit.cz>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Henrik Rydberg <rydberg@bitmath.org>
To: Bjorn Andersson <andersson@kernel.org>
To: Konrad Dybcio <konradybcio@kernel.org>
To: Abel Vesa <abelvesa@kernel.org>
Cc: linux-input@vger.kernel.org
Cc: linux-stm32@st-md-mailman.stormreply.com
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-kernel@vger.kernel.org
Cc: Krzysztof Kozlowski <krzk@kernel.org>
Cc: devicetree@vger.kernel.org
Cc: linux-arm-msm@vger.kernel.org
---
 arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts | 19 ++++++++++++++++++-
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi  |  2 +-
 2 files changed, 19 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts b/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
index a000c75494f1c..f65263955229c 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
@@ -21,17 +21,34 @@ &framebuffer0 {
 	stride = <(1080 * 4)>;
 };
 
 &i2c2 {
 	clock-frequency = <1000000>;
 
 	status = "okay";
 
-	/* ST,FTS @ 49 */
+	touchscreen@49 {
+		compatible = "st,stmfts5";
+		reg = <0x49>;
+
+		pinctrl-0 = <&touchscreen_irq_n>, <&touchscreen_reset>;
+		pinctrl-names = "default";
+
+		interrupts-extended = <&tlmm 125 IRQ_TYPE_LEVEL_LOW>;
+
+		mode-switch-gpios = <&tlmm 136 GPIO_ACTIVE_HIGH>;
+		reset-gpios = <&tlmm 99 GPIO_ACTIVE_LOW>;
+
+		avdd-supply = <&vreg_l19a_3p3>;
+		vdd-supply = <&vreg_l14a_1p8>;
+
+		touchscreen-size-x = <1080>;
+		touchscreen-size-y = <2160>;
+	};
 };
 
 &mdss_dsi0 {
 	vdda-supply = <&vdda_mipi_dsi0_1p2>;
 
 	status = "okay";
 
 	panel@0 {
diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index 3c9656b88b696..7d90c0be485ff 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -525,17 +525,17 @@ firmware-pins {
 
 	touchscreen_reset: ts-reset-state {
 		pins = "gpio99";
 		function = "gpio";
 		drive-strength = <8>;
 		bias-pull-up;
 	};
 
-	touchscreen_pins: ts-pins-gpio-state {
+	touchscreen_irq_n: ts-irq-n-gpio-state {
 		pins = "gpio125";
 		function = "gpio";
 		drive-strength = <2>;
 		bias-disable;
 	};
 };
 
 &uart6 {

---
base-commit: 909ef7a9a30fa139e69e555e3606680f5cca7726
change-id: 20260214-stmfts5-b47311fbd732

Best regards,
--  
David Heidelberg <david@ixit.cz>

