From: Joel Selvaraj <foss@joelselvaraj.com>
Date: Tue, 21 Oct 2025 01:20:49 -0500
Subject: [PATCH v2] arm64: dts: qcom: sdm845-shift-axolotl: fix touchscreen
 properties
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251021-shift-axolotl-fix-touchscreen-dts-v2-1-e94727f0aa7e@joelselvaraj.com>
X-B4-Tracking: v=1; b=H4sIAEAm92gC/5WNQQ7CIBBFr9KwdgzQWq0r72G6IDAVGiyGQVLTc
 HexN3D5fn7e2xhhdEjs2mwsYnbkwlJBHhqmrVoeCM5UZpLLEx/EAGTdlECtwYfkYXIrpPDWlnR
 EXMAkAjUpee60bFuDrHpeEettb9zHytZRCvGzJ7P4rf/YswABPUfZK9Mhby+3OaAn9FlFNR91e
 LKxlPIFtwQ4J9kAAAA=
X-Change-ID: 20250919-shift-axolotl-fix-touchscreen-dts-afa274c233de
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joel Selvaraj <foss@joelselvaraj.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761027667; l=2603;
 i=foss@joelselvaraj.com; s=20250919; h=from:subject:message-id;
 bh=U0sTpFpcrFN55z2alpABRqP+EG7oJWABVi8Wsg5kAeU=;
 b=uNkxTO4CLk55xQaPOMprWB4EgvcEz8dLQcg3oddM5f0Abu3ebTofFDa/+dwsxgZ2hm8z8vfna
 kK/SV5o0VXMCF1nQckuwBHJTdgr8+GM2GqSrBGOgaogjHVDpFpMq5n+
X-Developer-Key: i=foss@joelselvaraj.com; a=ed25519;
 pk=BBMos4ph15apUFh2AkG9rLZIrBWl5LD4egPOhEv63X0=
X-Endpoint-Received: by B4 Relay for foss@joelselvaraj.com/20250919 with auth_id=529
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The touchscreen properties previously upstreamed was based on downstream
touchscreen driver. We ended up adapting upstream edt_ft5x06 driver to
support the touchscreen controller used in this device. Update the
touchscreen properties to match with the upstream edt_ft5x06
driver.

Also, the touchscreen controller used in this device is ft5452 and not
fts8719. Fix the compatible string accordingly.

The wakeup-source property was removed as it prevents the touchscreen's
regulators and irq from being disabled when the device is suspended and
could lead to unexpected battery drain. Once low power mode and
tap-to-wake functionality is properly implemented and tested to be
working, we can add it back, if needed.

Signed-off-by: Joel Selvaraj <foss@joelselvaraj.com>
---
Changes in v2:
- Split the commit message into multiple paragraphs. (Konrad Dybcio)
- Add explanation for removing the wakeup-source property. (Konrad Dybcio)
- Link to v1: https://lore.kernel.org/r/20250919-shift-axolotl-fix-touchscreen-dts-v1-1-60e26ad4e038@joelselvaraj.com
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 17 ++++++++---------
 1 file changed, 8 insertions(+), 9 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index 89260fce6513937224f76a94e1833a5a8d59faa4..d4062844234e33b0d501bcb7d0b6d5386c822937 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -434,20 +434,19 @@ &i2c5 {
 	status = "okay";
 
 	touchscreen@38 {
-		compatible = "focaltech,fts8719";
+		compatible = "focaltech,ft5452";
 		reg = <0x38>;
-		wakeup-source;
-		interrupt-parent = <&tlmm>;
-		interrupts = <125 IRQ_TYPE_EDGE_FALLING>;
-		vdd-supply = <&vreg_l28a_3p0>;
-		vcc-i2c-supply = <&vreg_l14a_1p88>;
 
-		pinctrl-names = "default", "suspend";
+		interrupts-extended = <&tlmm 125 IRQ_TYPE_EDGE_FALLING>;
+		reset-gpios = <&tlmm 99 GPIO_ACTIVE_LOW>;
+
+		vcc-supply = <&vreg_l28a_3p0>;
+		iovcc-supply = <&vreg_l14a_1p88>;
+
 		pinctrl-0 = <&ts_int_active &ts_reset_active>;
 		pinctrl-1 = <&ts_int_suspend &ts_reset_suspend>;
+		pinctrl-names = "default", "suspend";
 
-		reset-gpio = <&tlmm 99 GPIO_ACTIVE_HIGH>;
-		irq-gpio = <&tlmm 125 GPIO_TRANSITORY>;
 		touchscreen-size-x = <1080>;
 		touchscreen-size-y = <2160>;
 	};

---
base-commit: fe45352cd106ae41b5ad3f0066c2e54dbb2dfd70
change-id: 20250919-shift-axolotl-fix-touchscreen-dts-afa274c233de

Best regards,
-- 
Joel Selvaraj <foss@joelselvaraj.com>

