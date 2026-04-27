From: David Heidelberg <david@ixit.cz>
Date: Mon, 27 Apr 2026 08:44:41 +0200
Subject: [PATCH 1/2] arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable
 ath10k host-cap skip quirk
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260427-b4-skip-host-cam-qmi-req-fixup-v1-1-4398e94bde70@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1228; i=david@ixit.cz;
 h=from:subject:message-id; bh=dFwEYxu73po0zSxmgpnWbzbIH8GvmNwIvYtD/YgGI/s=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp7wXaXnpqapDXe5HVMTJrySileF6HrOdyYP/5o
 KV2DGaVeXWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCae8F2gAKCRBgAj/E00kg
 cmw5D/9aj4P+fIpDTGUVrEo30lq4teNJUvVkZVRT1UJT/zv8OFeJWE0JLFJpSB58u03IDsl4u5d
 HqJSqlhvCkzrz8OfAj0WhzNw5O/xt4W0XPkp2V2rJqFwZZRLYf/aes7HXlJYNj9KD5OeoIpZp3+
 AigPqwEYi62Tc97fUH7fqB0D8AfAhPrKDpK4HdO4zsRasN4j7LpIE1+DNvFbGNJplu/qF8RSHZF
 /ZWLJvUHQBA1Mjv74FfdT0sQPgeLD8+qwNihFgtrJHJeoC/uNvJ0QWdvXkzGE2MdU6pZx1rknpE
 tmKvmd9X/X7lSiKWFx9lPwH1MyjKUfquOWxGUlQiAFgWIOI96GGw3e4KWV8/GIF4qO6d/JAHN3q
 y7u7LDEQeuHZf8jmpunlGelHrKSaslLIUre4tYPj5l+hdryomzn8G/PqoPHfF/wibvpi1ahPVLF
 sxxjzq9azVosLSct8wmyWYDuv1hqrk8lmK8DnHR3SLKNE1p0qIlLMmZpaZjgIYlibHESadFaTu3
 W9/S9QhJjR6ocW/kIsySuTpQuI614BXc9gaMyLjHWqeuyw1EFOmLWWOV6FRF34P/5hevkuDuvtV
 09MkX31XERflyl2HSXRIuF8/C1RcCLVf7lKa7Qf8ZLF0nexyw4hK561L4E8zEijiscLXQPAt+v2
 3QLyv1Ou9xv57Tw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Amit Pundir <amit.pundir@linaro.org>

The Wi-Fi firmware used on Xiaomi Poco F1 (beryllium) phone doesn't
support the host-capability QMI request, so add a quirk to skip it on
this device.

Fixes: 77809cf74a8c ("arm64: dts: qcom: Add support for Xiaomi Poco F1 (Beryllium)")
Cc: <stable@vger.kernel.org> # 7.1.x
Signed-off-by: Amit Pundir <amit.pundir@linaro.org>
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index 1298485c42142..950bbcc3bf91f 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -656,10 +656,11 @@ &wifi {
 
 	vdd-0.8-cx-mx-supply = <&vreg_l5a_0p8>;
 	vdd-1.8-xo-supply = <&vreg_l7a_1p8>;
 	vdd-1.3-rfa-supply = <&vreg_l17a_1p3>;
 	vdd-3.3-ch0-supply = <&vreg_l25a_3p3>;
 	vdd-3.3-ch1-supply = <&vreg_l23a_3p3>;
 
 	qcom,calibration-variant = "xiaomi_beryllium";
+	qcom,snoc-host-cap-skip-quirk;
 };
 

-- 
2.53.0

