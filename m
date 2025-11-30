From: David Heidelberg <david@ixit.cz>
Date: Sun, 30 Nov 2025 01:08:19 +0100
Subject: [PATCH] arm64: dts: qcom: sdm845-oneplus: labibb is not used on
 OnePlus 6/6T
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251130-oneplus-labibb-v1-1-bb3653e43120@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAPKKK2kC/x2MQQqAIBAAvxJ7TlDDDn0lOri51YKoKEUg/j2JO
 c1hpkKhzFRgGSpkerhwDF3UOMB+2XCSYNcdtNRGqUmKGCj5uwhvkRGFNOjc3NGooEcp08HvP1y
 31j4EN6vBYAAAAA==
X-Change-ID: 20251130-oneplus-labibb-05bdd6d6d2b1
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1552; i=david@ixit.cz;
 h=from:subject:message-id; bh=yhGffhFUntOUCTMWNhgszqUC32ou/2+cER0uMXyFzY0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpK4r0rHKaYmKTRdO95a/fUctPZC2iZP8xj5/jy
 oTgMJxYLYqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaSuK9AAKCRBgAj/E00kg
 co+lD/4qrLRtW3r/YdjJ/A08QcH8fVokvjJ3shcfOyzgXlyXdIqhEDpYgPaaeVw+BNk6i7Qvl+x
 sKpVv/hV3MAEPsiB6R3wabQJPHBqImSCrs+i9IS3xMv7icrTfMMOnltvZQRc2qexmHirMx9eetM
 M+7XBqE7xsj46wiiyXISCB4riUGk3l38PX9yMGJeh2i8GxljWTPzUKgJ7ArjYx5TqrH/7AM5tWM
 BugHLf4b6YGv/LCmQq3HqBRbah3qxoAo01yKRPrZudgkhFkTCFatLrJkcGpCFcu9H8q42c1rlbx
 /xTHVwD/mAkfaGK3Xr3I3u/D2/fvJKFG6iMz59KBb5XFduvqzGfdGecnhlMt8DAAdDrCOLtfNct
 yFNnDM8k0WvNdpxHXg8gHVQ5ALrWoTT+TdU24mcIoYQp/1EO/00yZPYLbOl5eip9ZKQHDXqf1j4
 wpCUbhGbRmitVRWfk6l6LPX/5Adw4Daflj4MsaFUS0GkzgiUrmX/spD0GeF0Fr8o64Twei+xVhJ
 U9zwvGXjfitYHN0EidZP6J4EDUXgiDF6S4UQICiK9hzM1ezB7qViKm1RVqMHKFe+pkt2eufXUuD
 0U06xuCt0v4sWMO8bPxpUjwHn+Ali4ClUgNEEO8QGHNtoXLv8mAET2c1IL8THKExB/Uw6h/xmZj
 48uUe6d0lYTAlGQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The lab and ibb regulators aren't used here. Disable them.

Removes following warnings:
qcom-lab-ibb-regulator c440000.spmi:pmic@3:labibb: Failed to create device link (0x180) with supplier c440000.spmi for /soc@0/spmi@c440000/pmic@3/labibb/lab
qcom-lab-ibb-regulator c440000.spmi:pmic@3:labibb: Failed to create device link (0x180) with supplier c440000.spmi for /soc@0/spmi@c440000/pmic@3/labibb/ibb

Fixes: 288ef8a42612 ("arm64: dts: sdm845: add oneplus6/6t devices")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
I assume this is right approach, as OLEDs on both devices are driven by
different regulators.

Question is, if should be labibb nodes enabled by default?
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index db6dd04c51bb5..78a835bdfe3b4 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -419,6 +419,10 @@ rmi4_f12: rmi4-f12@12 {
 	};
 };
 
+&ibb {
+	status = "disabled";
+};
+
 &ipa {
 	qcom,gsi-loader = "self";
 	memory-region = <&ipa_fw_mem>;
@@ -426,6 +430,10 @@ &ipa {
 	status = "okay";
 };
 
+&lab {
+	status = "disabled";
+};
+
 &mdss {
 	status = "okay";
 };

---
base-commit: 7d31f578f3230f3b7b33b0930b08f9afd8429817
change-id: 20251130-oneplus-labibb-05bdd6d6d2b1

Best regards,
-- 
David Heidelberg <david@ixit.cz>

