From: David Heidelberg <david@ixit.cz>
Date: Sun, 25 Oct 2026 23:28:13 +0100
Subject: [PATCH] arm64: dts: qcom: sdm845-google: Move panel pins into
 common
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261025-pixel-panel-pins-fix-v1-1-7cde6f7ca861@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWM0QoCIRBFf0XmuQGdKKJfiR5sd9wmwsRpF0H89
 7R9uXAunFNBOQsrXE2FzJuofGIHdzAwPX1cGGXuDGTp7CydMEnhNyYfx0pUDFKQOBAdw0wXstD
 VlLnf/+ztvrOujxdP39GC1n6ehVk9eAAAAA==
X-Change-ID: 20261025-pixel-panel-pins-fix-2ef223fd2820
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Selvaraj <foss@joelselvaraj.com>, 
 Casey Connolly <casey@connolly.tech>
Cc: Sumit Semwal <sumit.semwal@linaro.org>, Vinod Koul <vkoul@kernel.org>, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Petr Vorel <petr.vorel@gmail.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2816; i=david@ixit.cz;
 h=from:subject:message-id; bh=sZieprxE4e1RIG8z6t14P5reed770kk+50G6rXBQCqo=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq3oJ+en+4/21fx6ETZOMR/4ZxYH/0jNcVLy9fa
 XhiVr9xT02JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCat6CfgAKCRBgAj/E00kg
 cnu8EADJgEy9gtlVyB/MBlIDisr8uSn3q7V8RQbuFp0zlCmixuOczwSqLvqdcVHmJD48cWluUs5
 r1WRvjRyE5Hs9fPCc6yzRGzbAW0ALINPMhInIzRRikLkJTz8Tc4N/0xorCdc6zFfIB412Iv+FZR
 +LThREZvwGYo+EombXjyJNybm7CDCtXgWR8s3+u8UyQVY7Jb3r+p9dq3pq4WcCX8ars02wOHu7a
 Qxzmupa5ed/WXM3R1t/q/bAbhq1R+DQjat+ACWHO4pmQid3W5W52SXPlyHQaJdrx7d9TIFH92hA
 6IJnSCtGTyRks0jNrCLq+B7muymD1dN/Bfkyh0SMu6wQBKwAvZtarwNxeuQYr4kepyvWcVTmRZi
 8HrYsbt7swrPBDbpN4uV9UUmWZM6J2MKfTYAQYcIIVD+fRay4pJ2mMKZDbfP3rrFhoYnYSPKqtj
 AkeTVysMqInbeezc1Vq8wVYeAP8SvRG3MkPAWb7R5JDkZpcru5nFjYRCnVHZAwbbO0x2270ffh5
 WX3h5BuFNanyxkiWccaKlIy5YDx07TL6kyOSZLpfmGOdxeLhPArc4hZNgci0/tzbCtUCNU5ESg5
 fP11dU6xtEXVyzUSYNPgn9eGZDQWPjnhoPw7kVr3U16rRRiRfNmc0iUTo1bd39nDVDxAmy4Pfsk
 hZyasE5jYS9MZbQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Both devices share the pinctrl configuration.

Fixes: a678adbf2d22 ("arm64: dts: qcom: Add support for Pixel 3 and Pixel 3 XL")
Reviewed-by: Petr Vorel <petr.vorel@gmail.com>
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Retained R-b from previous series, added Fixes: tag.

https://lore.kernel.org/all/20260924-crosshatch-panel-v2-0-08d5c7bf72fc@ixit.cz

While it's not obvious from current DT, as we upstreaming Pixel 3 XL
bits, we already know this block was misplaced.

This will save us some unplesant rebase conflicts while we upstream the
rest of the panel for Pixel 3 XL and other bits.
---
 arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts | 18 ------------------
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi  | 16 ++++++++++++++++
 2 files changed, 16 insertions(+), 18 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts b/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
index fa89be500fb85..a000c75494f1c 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
@@ -61,29 +61,11 @@ &mdss_dsi0_out {
 };
 
 &mdss_dsi0_phy {
 	vdds-supply = <&vdda_mipi_dsi0_pll>;
 
 	status = "okay";
 };
 
-&tlmm {
-	panel_default: panel-default-state {
-		reset-pins {
-			pins = "gpio6";
-			function = "gpio";
-			drive-strength = <8>;
-			bias-disable;
-		};
-
-		te-pins {
-			pins = "gpio12";
-			function = "mdp_vsync";
-			drive-strength = <2>;
-			bias-pull-down;
-		};
-	};
-};
-
 &wifi {
 	qcom,calibration-variant = "Google_blueline";
 };
diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index f1379857e2742..d54cb47cdf95b 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -473,16 +473,32 @@ &qup_uart9_tx {
 	drive-strength = <2>;
 	bias-disable;
 };
 
 &tlmm {
 	gpio-reserved-ranges = < 0 4>, /* SPI (Intel MNH Pixel Visual Core) */
 			       <81 4>; /* SPI (most likely Fingerprint Cards FPC1075) */
 
+	panel_default: panel-default-state {
+		reset-pins {
+			pins = "gpio6";
+			function = "gpio";
+			drive-strength = <8>;
+			bias-disable;
+		};
+
+		te-pins {
+			pins = "gpio12";
+			function = "mdp_vsync";
+			drive-strength = <2>;
+			bias-pull-down;
+		};
+	};
+
 	nfc_default: nfc-default-state {
 		enable-pins {
 			pins = "gpio25";
 			function = "gpio";
 			drive-strength = <2>;
 			bias-pull-down;
 		};
 

---
base-commit: 20a33c6b6cbe7e4805dfb6cd68816937443aa148
change-id: 20261025-pixel-panel-pins-fix-2ef223fd2820

Best regards,
--  
David Heidelberg <david@ixit.cz>

