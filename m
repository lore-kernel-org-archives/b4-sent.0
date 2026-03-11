From: David Heidelberg <david@ixit.cz>
Date: Thu, 12 Mar 2026 00:49:43 +0100
Subject: [PATCH] arm64: dts: qcom: Mark l1a regulator as powered during
 boot
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260312-beryllium-booton-v1-1-59c83ab91b78@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAJb/sWkC/x3MQQqAIBBA0avIrBN0goquEi20phowDa0oorsnL
 d/i/wcSRaYErXgg0smJg8/QhYBhMX4myWM2oMJKlRqlpXg7x8cqbQh78NKMFnVDQ03YQM62SBN
 f/7Lr3/cD7eMPfGIAAAA=
X-Change-ID: 20260312-beryllium-booton-adb218ec7e28
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Amit Pundir <amit.pundir@linaro.org>, 
 Joel Selvaraj <foss@joelselvaraj.com>
Cc: Konrad Dybcio <konradybcio@gmail.com>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1043; i=david@ixit.cz;
 h=from:subject:message-id; bh=y27EVFmPscBC6k41hKpMUbdL61VHoT6gjj25XcDc/Dk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpsf+YAnO9xEZ8lMwOKBWhFOPOQMvlih5EuNnnm
 53ySIoTkbCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCabH/mAAKCRBgAj/E00kg
 clj5D/9Lt5xAXXYmqCelEPyDL7bwezi4tQGOJuyKg5zLcPhtJSJ2d2+vG1nYRitj53r3Zsa5krr
 S+IN4u84oGPHaBL0uEhHoR4oiEoPlMAhYuI8dOKkhaB2FsCI4RPCMRiVRNjA7oKCv7pSfo1VBhG
 RTa9kYwt1h4qY2hUYjdFLqRp0oju1xEmMz0MpGczhGBwNmZLlhPk9GVzIKtiq6SFNk9yxvQF31i
 uhXRxQA8OouxWblxoC/Wi2Q22eVbEqmJRs6SzfOU7gk06Dy+lDRAVg1tgO+HPNGxbUkdaHPO8Kb
 qYFqIaLyXPTu6SCgJ6rn4P7Hr0K2+8ounT1XQbtRt/8HAHhcwSXZu2u2GRWQEPi05Ju8W6Y60wH
 clIjuBqb+3Z7JUPcn4f1jieDXCNjjGflXNb+7QqrQN9El++aaXWacyTW7cbogBWVx/ZSPKPxUIa
 Fr8bRusFFamAeKX/5eJqelodo1eppiwc/qMhwVUvcHGvxmmYHUGjR1VVopNm0On+C7B7N9Q5svT
 YNHnJj3dR0MqFXeZEiTJtDRf2wxJD/d6LWqFfRqGoGyNpQyYYk4DdPDB9Ol/Nl72ClRM9Eho1vy
 EY4QkN7uY9ERikgzFjy+JHKhdUxiWZ57yCZuHCqPIisKbasenuyYeoAp2l1MXE95Rw6PszkAbeF
 +e9FfCElhpFR8VA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This regulator provides for the display subsystem, thus must be on.

Fixes: 77809cf74a8c ("arm64: dts: qcom: Add support for Xiaomi Poco F1 (Beryllium)")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index 01b570d0880d6..1298485c42142 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -148,6 +148,7 @@ vreg_l1a_0p875: ldo1 {
 			regulator-min-microvolt = <880000>;
 			regulator-max-microvolt = <880000>;
 			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
+			regulator-boot-on;
 		};
 
 		vreg_l5a_0p8: ldo5 {

---
base-commit: f90aadf1c67c8b4969d1e5e6d4fd7227adb6e4d7
change-id: 20260312-beryllium-booton-adb218ec7e28

Best regards,
-- 
David Heidelberg <david@ixit.cz>

