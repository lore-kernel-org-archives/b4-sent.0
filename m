From: Alexandre Messier <alex@me.ssier.org>
Date: Mon, 06 Apr 2026 01:16:58 -0400
Subject: [PATCH v2 2/4] ARM: dts: qcom: msm8974pro-htc-m8: add NFC support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260406-m8-dts-additions-v2-2-c4c4bd50af48@me.ssier.org>
References: <20260406-m8-dts-additions-v2-0-c4c4bd50af48@me.ssier.org>
In-Reply-To: <20260406-m8-dts-additions-v2-0-c4c4bd50af48@me.ssier.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Luca Weiss <luca@lucaweiss.eu>, linux-arm-kernel@lists.infradead.org, 
 linux-arm-msm@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 phone-devel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Alexandre Messier <alex@me.ssier.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775452618; l=1054;
 i=alex@me.ssier.org; s=20240603; h=from:subject:message-id;
 bh=JU0TS6dILZCLSZHyXLFTL6ZYC0tHdKQqnoQppdUf1kQ=;
 b=BwfaQTGnDfue3ZWWdpP2EfasX/7LitrEQGjtuzkKlETFgafs5q6Xw6Y/vx7zos53mjvYL/zT9
 N0o5zj3Y7PQAF4pAL5x5Qr6K1Nhnyh18M1duHV63gO/aetiyzSOFXKV
X-Developer-Key: i=alex@me.ssier.org; a=ed25519;
 pk=JjRqVfLd2XLHX2QTylKoROw346/1LOyZJX0q6cfnrKw=
X-Endpoint-Received: by B4 Relay for alex@me.ssier.org/20240603 with auth_id=168
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the NFC chip used in the HTC One M8 to its device tree.

The downstream vendor kernel used an I2C frequency of 384 kHz
for this bus. Use the same value as the vendor.

Signed-off-by: Alexandre Messier <alex@me.ssier.org>
---
 arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts b/arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts
index 37df271dbdeb..f24882dbeef3 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts
@@ -65,6 +65,22 @@ vreg_vph_pwr: vreg-vph-pwr {
 	};
 };
 
+&blsp1_i2c3 {
+	clock-frequency = <384000>;
+
+	status = "okay";
+
+	nfc@28 {
+		compatible = "nxp,pn544-i2c";
+		reg = <0x28>;
+
+		interrupts-extended = <&tlmm 144 IRQ_TYPE_LEVEL_HIGH>;
+
+		enable-gpios = <&tlmm 2 GPIO_ACTIVE_LOW>;
+		firmware-gpios = <&tlmm 3 GPIO_ACTIVE_HIGH>;
+	};
+};
+
 &pm8941_lpg {
 	qcom,power-source = <1>;
 

-- 
2.53.0

