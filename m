From: David Heidelberg <david@ixit.cz>
Date: Thu, 02 Apr 2026 11:54:07 +0200
Subject: [PATCH v3 2/3] arm64: dts: qcom: sdm845-shift-axolotl: Set higher
 touchscreen i2c clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260402-axolotl-misc-p1-v3-2-8934e9db6831@ixit.cz>
References: <20260402-axolotl-misc-p1-v3-0-8934e9db6831@ixit.cz>
In-Reply-To: <20260402-axolotl-misc-p1-v3-0-8934e9db6831@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dylan Van Assche <me@dylanvanassche.be>
Cc: linux-arm-msm@vger.kernel.org, Petr Hodina <phodina@protonmail.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Alexander Martinz <amartinz@shiftphones.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=838; i=david@ixit.cz;
 h=from:subject:message-id; bh=9p+K/F4jbKx5IwsqTA3jbf55J7M/QFSo8brdWdbijrI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpzjy/9xJHnhjNT6Qk2yPhnOGmFdNSYXM8WMu+4
 AjEBa0p2eqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac48vwAKCRBgAj/E00kg
 csNFD/9YMHUrBa9PsOyayLViCNbx138tHBJuuRTyMd6t/fwcAphniB0+7EWjeqiGNgz35AaLREZ
 VmU1rHJstEP8yz/bb0G0AIC4TlAW1FQH6XhPbn2m0Pj2gafflIsJYKoo4nqjteTgK9IYdQQpLTK
 BA1VJY0ginDt8VcXABSryfjlTYbrzYaTjrwDbxofBriKvGppo4mUk1MFb3YNkLLUmO8mROAC0GH
 ZlPW7wfBY6KhAynqcjkXWP8nWiAHFUC3jbYRK4qT31J8nLdSaeZpgo4Q2hiHCASwn1Cit4X3q6N
 m/xkHbCj5m4tf+a2xnWnF1YPghd26BnHvv7KQjCiumkyVcUemYirRd74To4ocnXTJipRwZ5nO+I
 JkCKkpqy2Q2FzPWTGllyG2elsXPfZMh18BUo+RRxQqO0qXpQe8hvErYaQZpCRhAlPFGxFxqbOai
 l4YMrhs2EYZjzETNW8e711a7j0yi1V4lrUr23fOcnTxpv99DRnUrT04UgS7nV+B3W+24wI2NF9a
 6uzEOoLLPVc0fzcOBRCij8jWk4Szy2j096Lcyvsu6T1jPhqsbGmtu506YbhzLTUeSJ14XFBHTBL
 6f5TBkvZGs0Pkcqe0m5VmW8iX1JkWzyqD/6V1SyRHe0Csti5AUatIp7crFUv8ukxp7o0ggsuwmO
 qHcTh23gzCAWGXA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

Sets a higher rate than the default for good responsiveness of
touchscreen.

Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index b05f04a621e5b..f26079398e07b 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -432,6 +432,8 @@ &gpu_zap_shader {
 };
 
 &i2c5 {
+	clock-frequency = <400000>;
+
 	status = "okay";
 
 	touchscreen@38 {

-- 
2.53.0

