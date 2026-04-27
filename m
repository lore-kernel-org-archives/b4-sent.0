From: David Heidelberg <david@ixit.cz>
Date: Mon, 27 Apr 2026 08:44:42 +0200
Subject: [PATCH 2/2] arm64: dts: qcom: sdm845-lg: Enable
 qcom,snoc-host-cap-skip-quirk
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260427-b4-skip-host-cam-qmi-req-fixup-v1-2-4398e94bde70@ixit.cz>
References: <20260427-b4-skip-host-cam-qmi-req-fixup-v1-0-4398e94bde70@ixit.cz>
In-Reply-To: <20260427-b4-skip-host-cam-qmi-req-fixup-v1-0-4398e94bde70@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Amit Pundir <amit.pundir@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Paul Sajna <sajattack@postmarketos.org>
Cc: Konrad Dybcio <konradybcio@gmail.com>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 David Heidelberg <david@ixit.cz>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1150; i=david@ixit.cz;
 h=from:subject:message-id; bh=rjReFmShlnTaM2lZx/85DqjUqhkr2W2r+NrmMgLxkjg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp7wXaphRDQGvH4XoK/VOPxmZ+p4W1VgL/Papcr
 7665zCi8+WJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCae8F2gAKCRBgAj/E00kg
 cpTQD/439i8fIE09B6ex6xtz9if7DkBu8PuwBU2Taq7vE95PPMAYRaAxfb2HHnj9Exj1hQxiKg6
 Zkr5TgcSzT1jLsXLy/OWrkQt+Tc1m3JY6DTyZaCn0fHJhwx684MhKV1kVXUb0oz+OXyoYpOHUFT
 jfHpb0UlTi7yMh0S8fFLwWNBg7d/TB/bNznOZcM+n0PU6sW1pxzpo7o2hbakWsH0Fxmi1QLRcV3
 7nT8y/dy/AM7zrzwNtF+EbWM+C71JOL/7thBCjL70snDCRa+MefTjQVThQXfj54t06ZaeuzXA5O
 M/o3kFNYam3hu63t09cagRi35TJZCZgSV+rSCWUwkpevQKjkMcv848t2P9ECb5XMGLnMwqyqAVn
 KbaVgFwB9bXNYgbcrDkO6Te1AvVRwYaD+HBcJqArBmHdFjIkTO/smAbWY3iQ1DHKG+G3H7Bc3E+
 sgTCLwZQ0GpijqeE1oacU8tswlZIYrajT8QiwlTBbKAyk/p9vEH8kaFt2AXiaJIV35GeeVjJIhm
 sdVXtgjnGlWQHAZjMQViJz52rGYd3rdvcIm0JubgTknhSQupMhCgp5uI+s3A3w0M7vdZ4fRAMLB
 yZOyI6VHul6bpKaxJ4K2CKUiVZS5DdTTlyTba+XZFItCvOg8qRoIJj/2Hy0TkRC3EICWVHDL1PT
 wWt8eMFw4yleEjQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Paul Sajna <sajattack@postmarketos.org>

The WCN3990 firmware for judyln does not respond to the request for
host capabilities. Add the devicetree quirk to skip this request.

Fixes: eb8fa3208526 ("arm64: dts: qcom: sdm845-lg: Add wifi nodes")
Cc: <stable@vger.kernel.org> # 7.1.x
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Reviewed-by: David Heidelberg <david@ixit.cz>
Signed-off-by: Paul Sajna <sajattack@postmarketos.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi
index 71d070619ad73..2d02d77d35ea7 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi
@@ -675,10 +675,12 @@ &venus {
 
 &wifi {
 	vdd-0.8-cx-mx-supply = <&vreg_l5a_0p8>;
 	vdd-1.8-xo-supply = <&vreg_l7a_1p8>;
 	vdd-1.3-rfa-supply = <&vreg_l17a_1p3>;
 	vdd-3.3-ch0-supply = <&vreg_l25a_3p3>;
 	vdd-3.3-ch1-supply = <&vreg_l23a_3p3>;
 
+	qcom,snoc-host-cap-skip-quirk;
+
 	status = "okay";
 };

-- 
2.53.0

