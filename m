From: David Heidelberg <david@ixit.cz>
Date: Mon, 24 Nov 2025 22:53:41 +0100
Subject: [PATCH RFC 8/8] arm64: dts: qcom: sdm670-google-sargo: Enable fuel
 gauge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251124-pmi8998_fuel_gauge-v1-8-dd3791f61478@ixit.cz>
References: <20251124-pmi8998_fuel_gauge-v1-0-dd3791f61478@ixit.cz>
In-Reply-To: <20251124-pmi8998_fuel_gauge-v1-0-dd3791f61478@ixit.cz>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Casey Connolly <casey@connolly.tech>, Joel Selvaraj <foss@joelselvaraj.com>, 
 Yassine Oudjana <y.oudjana@protonmail.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Alexander Martinz <amartinz@shiftphones.com>, 
 =?utf-8?q?Barnab=C3=A1s_Cz=C3=A9m=C3=A1n?= <barnabas.czeman@mainlining.org>, 
 Richard Acayan <mailingradian@gmail.com>, 
 Alexey Minnekhanov <alexeymin@postmarketos.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=813; i=david@ixit.cz;
 h=from:subject:message-id; bh=SyGBCL9VTEPA+aAWTUKzUH7OLMbCTKZV+KFoRbFN9oM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpJNPgenmWLfuDKhq15mBg6v1tJzJPi9mONOtDK
 +nbgiB4RcSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaSTT4AAKCRBgAj/E00kg
 ct3+D/9FOzgDdTeSSuMnpUerlqxXHRc7EteoshYCabmOBQfZkQfTUgC+p7Nnbujn8EyVH35kHb2
 04thXEH3bbZXwDcQ37886myN5Mtm7HRNkGg2/FzE3FYSClXrJoIo+9XdzSWRFTqh7jgLHGYW7bW
 IKK/9Qq3KPlvhlmiYyhegZSxWdKzhbxFMBprU2gcomvExFvuT9mFU4A8UjddL9SxgXLlmXhn1vC
 7Mbvfvd7eBwQ3/n/T4jqKkb7mw5V5ZX3KaSade6jOq3tjcv9pVH/Ui8Ds8BenYgsOYKYPbyIGvT
 K4W6HBLQfUd3Y2CBEPSGB7wUZW58vhoRNjDUz26iBZ8ofu/gdimjAjo84FQtLpq89gvQpot+2do
 nJkFJVFN4uDf6Oh4/AaEk3bysrf2gZ0QaeGAMyL0yasVutQO2bELurmwmfVVBGvPVi1Ri0CpYF9
 dqxm8E8uvzWkxcRFsi9OymhD9I+WIUN5tdCFlvyihsMMlOSGpOyJoEVJ6kgfCmYBNbmPiWfPyHS
 xDH5NX8mvn0rQcchS2DL04az9PEzKLSgvyHVl/+StqKya6kPzZGnlsJteKA63dlWzhDCgg/hr2f
 ej8jQ1LL8+E+bTikNcpcJfR1nUt1P8VPgayWzBhDG2UHB7465QB9YCfpV2U8+zTqpCxJer7NCAF
 BVXLpg4Ve72CGEw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Richard Acayan <mailingradian@gmail.com>

The PM660 fuel gauge determines the battery charge. Enable it for full
battery support.

Signed-off-by: Richard Acayan <mailingradian@gmail.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm670-google-sargo.dts | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm670-google-sargo.dts b/arch/arm64/boot/dts/qcom/sdm670-google-sargo.dts
index ed55646ca419d..a8e0e85c42cd2 100644
--- a/arch/arm64/boot/dts/qcom/sdm670-google-sargo.dts
+++ b/arch/arm64/boot/dts/qcom/sdm670-google-sargo.dts
@@ -490,6 +490,13 @@ &pm660_charger {
 	status = "okay";
 };
 
+&pm660_fg {
+	monitored-battery = <&battery>;
+	power-supplies = <&pm660_charger>;
+
+	status = "okay";
+};
+
 &pm660_rradc {
 	status = "okay";
 };

-- 
2.51.0

