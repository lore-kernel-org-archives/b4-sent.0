From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Wed, 22 Jan 2025 07:41:56 +0100
Subject: [PATCH] arm64: dts: qcom: sc8280xp-blackrock: switch to uefi rtc
 offset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250122-jg-blackrock-rtc-v1-1-3b05cd85bdfa@oldschoolsolutions.biz>
X-B4-Tracking: v=1; b=H4sIADOTkGcC/x3M3QpAQBBA4VfRXJva3fzEq8iFHYNBaFZS8u42l
 9/FOQ8EVuEAdfKA8iVB9i3CpgnQ1G0jo/TR4IzLjXUG5xH92tGiOy2oJ6HPKlty4YmrDGJ2KA9
 y/8umfd8PgwYjlWIAAAA=
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Johan Hovold <johan@kernel.org>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1737528116; l=1921;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=4fIfQMa3HqpPjSmfIw1qUNksE48aZP+ZpYp1h1ftNbI=;
 b=5uy6wYE1C3rG3cAXw5pTu1FPBjpNikCW0xrJ5P6YbdxkwJh8AxZZy2TMeo9WLBW8OOfSYOgCn
 +AFQlqZvYe5AOARybBO1c+h/mfAwyx0Ud0ZF6xd2g1H2D0x9aaEMnYf
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On many Qualcomm platforms the PMIC RTC control and time registers are
read-only so that the RTC time can not be updated. Instead an offset
needs be stored in some machine-specific non-volatile memory, which a
driver can take into account.

Switch to using the Qualcomm specific UEFI variable that is used by the
UEFI firmware (and Windows) to store the RTC offset.

This specifically means that the RTC time will be synchronised between
the UEFI firmware setup (or UEFI shell), Windows and Linux.

Note however that Windows stores the RTC time in local time by default,
while Linux typically uses UTC (i.e. as on X86).

Based on a patch by Johan Hovold. [1]

Link: https://lore.kernel.org/all/20250120144152.11949-7-johan+linaro@kernel.org/ # [1]
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
This is a patch to switch the Windows Dev Kit 2023 over to
using the UEFI offset.
---
 arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts | 11 +----------
 1 file changed, 1 insertion(+), 10 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts
index fa9d941050522..aaea2fa3c6c0a 100644
--- a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts
+++ b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts
@@ -762,20 +762,11 @@ &pmk8280_pon_resin {
 };
 
 &pmk8280_rtc {
-	nvmem-cells = <&rtc_offset>;
-	nvmem-cell-names = "offset";
+	qcom,uefi-rtc-info;
 
 	status = "okay";
 };
 
-&pmk8280_sdam_6 {
-	status = "okay";
-
-	rtc_offset: rtc-offset@bc {
-		reg = <0xbc 0x4>;
-	};
-};
-
 &pmk8280_vadc {
 	channel@144 {
 		reg = <PM8350_ADC7_AMUX_THM1_100K_PU(1)>;

---
base-commit: 232f121837ad8b1c21cc80f2c8842a4090c5a2a0
change-id: 20250120-jg-blackrock-rtc-b4917e6bce94

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

