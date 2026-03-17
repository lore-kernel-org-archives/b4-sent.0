From: David Heidelberg <david@ixit.cz>
Date: Tue, 17 Mar 2026 23:12:32 +0100
Subject: [PATCH v2 2/5] arm64: dts: qcom: sdm845-oneplus: Drop address from
 framebuffer node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260317-beryllium-fb-v2-2-36b69dfb760c@ixit.cz>
References: <20260317-beryllium-fb-v2-0-36b69dfb760c@ixit.cz>
In-Reply-To: <20260317-beryllium-fb-v2-0-36b69dfb760c@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Heidelberg <david@ixit.cz>, 
 Sam Day <me@samcday.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=857; i=david@ixit.cz;
 h=from:subject:message-id; bh=KVG+oAo4IX+FcwkDj3OQjurvcb14N3Vls6N/xvndJuU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpudHQjlabPKJ1x8fxqZ/sZSs8UqV4aoymK2u93
 U7q6IL5v12JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCabnR0AAKCRBgAj/E00kg
 cn6fD/9NJ9RJT1D+qtD3fv1V0M5bqR0HnLU5hcs5cyFND1uIk8RGu3Vsj2ujZpcdlgVfdg0+wdx
 8NqE2InzM68848IRGbMxd4Z1AhNg7x/1hmOmAKFyW3OnKP67DOs1cbiHatUD3HMx1DrU+Mw7UMi
 YsVeBzNfrcJp4RUmpotJ6ewe9jk/osyAHPO64tE3sYpB1tarD91TFtsmjdHoKDJENUmc0n8UVBI
 pG4XJNgrHWg+8es1gfuT30jwhf10z4k5yBerutPIRcaRtIpsfS+Q9hcSv9Oi0xHXTLycO/erpBH
 adtH/X2EBhzmWw5TYFr1fcogTDoB24auqzLZ08fcNEITdZ4lMaRdxQmSP9i86rAM+feF/snYEna
 M+Bfm6v+Je/4GSUf1xregFwyon8H3wL647FrjEceWwu04bRIzKanKLLFuEeW95wY9wQrX/nTkh4
 G46OnCXhYoGfp8r9M9dy8PufldzpuGUM3Kx+Fng0s4l0MA0yaUyXaHI3wUJyw4SD9a8RHo3t9ZZ
 KvaGiLOCnGwKMnPLsPOhqkwVsWdbPVKDtSOwzVcIL+icYfGe4uoWEM6oGGbhdE3Wd+vAkthb6yg
 +tErEqC/X0/hLinD0qXsj9naacxz0uZkS1cg0WeL0C1TxHSrS/972o1q6lpBi1fULEcaTwwUaqc
 AT56VqMMiz8+hvQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This node has no 'reg' property, so it shouldn't have a unit address
(after '@') either

Fixes: b0d5c96e860c ("arm64: dts: qcom: sdm845-oneplus: Add framebuffer")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index 5b121ea5520f5..f5fd213d4a1fd 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -37,7 +37,7 @@ chosen {
 
 		stdout-path = "serial0:115200n8";
 
-		framebuffer: framebuffer@9d400000 {
+		framebuffer: framebuffer-0 {
 			compatible = "simple-framebuffer";
 			memory-region = <&cont_splash_mem>;
 

-- 
2.53.0

