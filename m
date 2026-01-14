From: David Heidelberg <david@ixit.cz>
Date: Wed, 14 Jan 2026 11:08:45 +0100
Subject: [PATCH v3] arm64: dts: qcom: sdm845: Introduce camera master clock
 pinctrl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260114-sdm845-mclk-v3-1-c9351deaf4f2@ixit.cz>
X-B4-Tracking: v=1; b=H4sIACxrZ2kC/23MQQ7CIBCF4as0rMUwU5DiynsYFxXQTrStgYZUm
 95d2o2auHwv+f6JRR/IR7YvJhZ8okh9l0e5KZht6u7qObm8GQpUgFDy6NpKKt7a+40LCResjUJ
 fAsviEfyFxrV2POXdUBz68FzjCZb3fycBFxyMPlsjtZN2d6CRhq19saWS8FvqX4lZaoGVRScMS
 PWR8zy/AbBSpOzeAAAA
X-Change-ID: 20251213-sdm845-mclk-041f2a952e31
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3175; i=david@ixit.cz;
 h=from:subject:message-id; bh=VjhjaqM3XS+2n8GQ/x6ApyiqxtWTj+IRWhXyXFadzb0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpZ2s4qUlnsUVwtA6W65uL1mnojYILhVNWEt82U
 g/yf/DzcLGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaWdrOAAKCRBgAj/E00kg
 cs7+D/9ML+U8eqXXOOZTcHPNgeiBo/mhZ0Z3jrLg/n2w6HWaR6tRiVitKZRAg+utC4b6Y02ad1U
 DXACGzZP6l1BIypVgyNPSxSMLMLoRycoDSF7O15SsqDnTroiv4KgYJGol1DsANCobEn9bKKGvBm
 0ch5BK5JN5k5hcQzMWkYggLs2Lm0dWrEd24V/EQGm6zbnsM5pq6bhp9bzzwk0rviyTX8I13AEpe
 XuzV8JoVN/wSMOnyu1uvfG578OT9zQTpApIPRQl4sj+EVFYiyhH4YHc9RF7/FwM3WxWdCU/J0kS
 A7MkMM9RO2KSduFDSB65Q9DVu0mXuz7kFf46S6sPzLfGCDwJCN1yfA1BqqxjqyGUwo0eXheAogw
 ePh78bIqgRBB9xblTehQYoYg9JYTADE1sqg+VzrRbX/BLSGiblS2QzyO1X+LTB5OGzNKaj29kOC
 bGDUY3fz0/C+JskQ0A3y3k2Vpo+EtFEi6GqvxIyhlEPA6PyU7DpIYUALzFPVxTVy/MACvFcS77b
 hADQVAB5xl4W95+QrU9yZTmMm1V6oTKq+6bdUSYZ2rJikN/FkxBapu2qutVEfxFZmJDbEyarQLZ
 thyraLsVcjGW5binxvRxcixhfeHhsx1kq8UYS4z7E6MvxlqV6D8LBxPyMt8yzaS3gbqM5i+Xf5D
 4X1ATcbIHiWqd3Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Put clock pins configuration for camera master clock into the dtsi.

Reviewed-by: Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Inspired by Richard's patch set for SDM670, I noticed that SDM845
follows the same pattern. This change prepares for enabling
additional cameras.

These pinctrl settings have been verified against the downstream
SDM845 kernel.

Since most of these are not yet used in mainline, testing was done
on sdm845-next using OnePlus 6 cameras with downstream drivers.

Thank you
David
---
Changes in v3:
- Dropped 2nd patch
  ("arm64: dts: qcom: sdm845-db845c: Use pad fn instead of defining own")
  as there is no documentation or people who can answer questions for
  now, so we can move forward with the main camera work.
- Link to v2: https://lore.kernel.org/r/20251217-sdm845-mclk-v2-0-7028c2d09145@ixit.cz

Changes in v2:
- Added mclk3. (Vladimir)
- Reword commit messages.
- Corrected commit msg name. (Konrad)
- Link to v1: https://lore.kernel.org/r/20251213-sdm845-mclk-v1-0-197bc947d4c6@ixit.cz
---
 arch/arm64/boot/dts/qcom/sdm845.dtsi | 56 ++++++++++++++++++++++++++++++++++++
 1 file changed, 56 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845.dtsi b/arch/arm64/boot/dts/qcom/sdm845.dtsi
index bf2f9c04adba7..c0f21a745fb0c 100644
--- a/arch/arm64/boot/dts/qcom/sdm845.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845.dtsi
@@ -2805,6 +2805,62 @@ tlmm: pinctrl@3400000 {
 			gpio-ranges = <&tlmm 0 0 151>;
 			wakeup-parent = <&pdc_intc>;
 
+			cam_mclk0_default: cam-mclk0-default-state {
+				pins = "gpio13";
+				function = "cam_mclk";
+				drive-strength = <2>;
+				bias-disable;
+			};
+
+			cam_mclk0_sleep: cam-mclk0-sleep-state {
+				pins = "gpio13";
+				function = "cam_mclk";
+				drive-strength = <2>;
+				bias-pull-down;
+			};
+
+			cam_mclk1_default: cam-mclk1-default-state {
+				pins = "gpio14";
+				function = "cam_mclk";
+				drive-strength = <2>;
+				bias-disable;
+			};
+
+			cam_mclk1_sleep: cam-mclk1-sleep-state {
+				pins = "gpio14";
+				function = "cam_mclk";
+				drive-strength = <2>;
+				bias-pull-down;
+			};
+
+			cam_mclk2_default: cam-mclk2-default-state {
+				pins = "gpio15";
+				function = "cam_mclk";
+				drive-strength = <2>;
+				bias-disable;
+			};
+
+			cam_mclk2_sleep: cam-mclk2-sleep-state {
+				pins = "gpio15";
+				function = "cam_mclk";
+				drive-strength = <2>;
+				bias-pull-down;
+			};
+
+			cam_mclk3_default: cam-mclk3-default-state {
+				pins = "gpio16";
+				function = "cam_mclk";
+				drive-strength = <2>;
+				bias-disable;
+			};
+
+			cam_mclk3_sleep: cam-mclk3-sleep-state {
+				pins = "gpio16";
+				function = "cam_mclk";
+				drive-strength = <2>;
+				bias-pull-down;
+			};
+
 			cci0_default: cci0-default-state {
 				/* SDA, SCL */
 				pins = "gpio17", "gpio18";

---
base-commit: 0f853ca2a798ead9d24d39cad99b0966815c582a
change-id: 20251213-sdm845-mclk-041f2a952e31

Best regards,
-- 
David Heidelberg <david@ixit.cz>

