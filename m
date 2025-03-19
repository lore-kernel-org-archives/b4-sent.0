From: Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>
Date: Tue, 18 Mar 2025 22:17:02 -0500
Subject: [PATCH] arm64: dts: qcom: x1e80100-dell-xps13-9345: Disable PM8010
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250318-xps13-no-pm8010-v1-1-c46236d96428@oss.qualcomm.com>
X-B4-Tracking: v=1; b=H4sIAC032mcC/x3MQQqAIBBA0avErBtwFEG6SrSIGmsWqSiEIN49a
 fkW/zconIULLFODzK8UiWGA5gmOew8Xo5zDoJW2ypDDmgoZDBHT4xQpNE5rstY7TwZGlTJ7qf9
 x3Xr/AGJHGdJhAAAA
X-Change-ID: 20250318-xps13-no-pm8010-3822155f8f13
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Aleksandrs Vinarskis <alex.vinarskis@gmail.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742354222; l=1197;
 i=bjorn.andersson@oss.qualcomm.com; s=20250318; h=from:subject:message-id;
 bh=omuUPA+qxmlSNoxLRc5BBaWQ5fn2KKc3XDYkxP1Te+0=;
 b=GMNIY9LC1Le/BwTXdv0ZcMEdOMWI93U25EXAHRSfxusH4YPd7lZH33Brot0eckETV1MO5obb0
 BXvVNBFNbNgAzv478yj1khKqpANpN2RuEDsaTK1HjY+vvnsu7/B2nRp
X-Developer-Key: i=bjorn.andersson@oss.qualcomm.com; a=ed25519;
 pk=rD3O9C9Erg+mUPBRBNw91AGaIaDVqquHZbnn6N6xh6s=
X-Endpoint-Received: by B4 Relay for bjorn.andersson@oss.qualcomm.com/20250318 with auth_id=362
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Qualcomm X Elite reference design uses the PM8010 PMIC for camera
use cases, but the Dell XPS13 doesn't. Disable this PMIC to avoid the
error in the kernel log caused by an attempt to access it during boot.

Fixes: f5b788d0e8cd ("arm64: dts: qcom: Add support for X1-based Dell XPS 13 9345")
Signed-off-by: Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/x1e80100-dell-xps13-9345.dts | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/x1e80100-dell-xps13-9345.dts b/arch/arm64/boot/dts/qcom/x1e80100-dell-xps13-9345.dts
index 967f6dba0878b51a985fd7c9570b8c4e71afe57d..684441bc3eb39ab2e8fd7dbb641a8ea75309901c 100644
--- a/arch/arm64/boot/dts/qcom/x1e80100-dell-xps13-9345.dts
+++ b/arch/arm64/boot/dts/qcom/x1e80100-dell-xps13-9345.dts
@@ -867,6 +867,10 @@ &pcie6a_phy {
 	status = "okay";
 };
 
+&pm8010 {
+	status = "disabled";
+};
+
 &pm8550_gpios {
 	rtmr0_default: rtmr0-reset-n-active-state {
 		pins = "gpio10";

---
base-commit: c4d4884b67802c41fd67399747165d65c770621a
change-id: 20250318-xps13-no-pm8010-3822155f8f13

Best regards,
-- 
Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>

