From: David Heidelberg <david@ixit.cz>
Date: Thu, 02 Apr 2026 00:39:36 +0200
Subject: [PATCH v4 2/4] arm64: dts: qcom: sdm845-oneplus: Drop address from
 framebuffer node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260402-beryllium-fb-v4-2-46170004da28@ixit.cz>
References: <20260402-beryllium-fb-v4-0-46170004da28@ixit.cz>
In-Reply-To: <20260402-beryllium-fb-v4-0-46170004da28@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Heidelberg <david@ixit.cz>, 
 Sam Day <me@samcday.com>, Dzmitry Sankouski <dsankouski@gmail.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=922; i=david@ixit.cz;
 h=from:subject:message-id; bh=3F91mVa3Gd9x1DELoQbgKGtwlkPBJMsvIBMfbezJet0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpzZ6pkMueddY1VCqQOnTwZYt2gdA8bwJiqAX8/
 VNfaRaeavaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac2eqQAKCRBgAj/E00kg
 cn5SEACYRsmEJ22J0d5fuuiv0HOMjRr0ZYbQ/KrFShXlFCwI8Z05EpiksguwmZQuoorn/wvWSVk
 zC7qYcqnxfd58LKnF09zxLZ2pRwW6sqy/iETjZ0wjGXkEyTgfDWZwan89qAVQSu0yF200pilkJp
 2IHdUGLByI2ryOWww1Z4rUzxza27q8LBzA7XQ7nudK2WJFNiXN1WPlfQSKLuu5DMwYIuhdGc8I9
 FxwSp7BQ2fKF65V+MJKKYtBG8I9FXkcfI539O3VPXtMPNqbCjTBMbYcLrI7btG13BQF3X39iSfc
 f9wft6IdI3ltiGFCJVffABBq6oUfmInHfVtX8pXJEj/LpYWS8p8hB7GVpM3yGlvla7UzoNDxgMQ
 hcrq66GtSn+afIrMucV7t1t25e6q5MyJYaHi4IunEAKTCtVI+Ew6UUspwEsDs0XQylug0JQLV7X
 BYIYxHwJmcuiYp9Z2vF7QczKFPzG3TS7y0iPWs8ISbm1EAZlRgpEF02awhxd1/hga/qGvvejx6f
 zdV9NQAxLA/UdQR8wbbGtnR/N2FhrIn8UmdOc5opblXIfqw3s+Qj0sC98yLbgYSJUfxKRZbG8rH
 rGtn8fBV+GNolVle+Xv4lzFBtiNdLxm5jEhz0OHcXrCxW1Xtx8wU3iDKk7yafihUcBlMgyO+sQ+
 yx7FXMCurpqfYxQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This node has no 'reg' property, so it shouldn't have a unit address
(after '@') either

Fixes: b0d5c96e860c ("arm64: dts: qcom: sdm845-oneplus: Add framebuffer")
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index 6b7378cf4d493..b0b9baf01ec29 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -72,7 +72,7 @@ chosen {
 
 		stdout-path = "serial0:115200n8";
 
-		framebuffer: framebuffer@9d400000 {
+		framebuffer: framebuffer {
 			compatible = "simple-framebuffer";
 			memory-region = <&cont_splash_mem>;
 

-- 
2.53.0

