From: David Heidelberg <david@ixit.cz>
Date: Wed, 01 Apr 2026 22:40:15 +0200
Subject: [PATCH v3 2/4] arm64: dts: qcom: sdm845-oneplus: Drop address from
 framebuffer node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260401-beryllium-fb-v3-2-ec7d443402ab@ixit.cz>
References: <20260401-beryllium-fb-v3-0-ec7d443402ab@ixit.cz>
In-Reply-To: <20260401-beryllium-fb-v3-0-ec7d443402ab@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=909; i=david@ixit.cz;
 h=from:subject:message-id; bh=WpNRtN9KzfW/WJ6Lnvj3M30Ah3OBdedD1ihXX8o//rY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpzYKuSCC6LZ70kvSXAg4upE79cW3vXQixDTeb3
 scUrRZBgiyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac2CrgAKCRBgAj/E00kg
 coLiD/9UMphhTgj7BGZNyxfMKhDjjXFrLIsFmw9p1/UxbPbEqmw8tZtHya8irhlOos/krRoWexS
 oGURF8JGpTujRx2W65cwnAEAxcCFRIenmEniqS8VWX2q/a/7jnsW0mhqlvuFOcJ/LlkaOyOqIli
 8g++dioBLaWUCdaoJJ20aXWAsUVrN5naNv/E3UOeVW77eKhYUTaoQvmAi/u3+WxD0MjELwTv1gq
 p5PeYHC0wiu3g2K9DJCgeP9kL5MRWOb0vHMzzqvLnWvos6q+THa18bPwlDffVm1XFx88bZ1WOCB
 NUPLYXYiw54qTPVwHFf7nyhB78op+lpwkW8HDPSH3gFZ72XP7Q+0lIEorKZsW2wkjxhWAS5hiUH
 fNKz7/DKnFSZfO6tYrSlq/bic2vRj17dAvQ9WSziq3WkvpDwhe927uy2TtAXCbcHgS7TlxudmYU
 ZnnK6TFUKs7ME9yX4P/RApPOWBG89sxUY7rP2BVn7jLxQ5Ts4q9gH8Uh/s6trwUS2+ggH6fJNok
 CubrqtV2OzZeCuNQyBsARRnok2W1tcezM4R5czO4hlt9acMkZe0Q/jF23bGXbZ4bmdWRH74/+1p
 Rkd1RZTutpQ64YmVLfkd9CJIG8DtIqDSjHc7B0ratYAz5JPy9ZtPjjFe41BFSoFn3b/XSCFgdTq
 yJuCWWeDUkmu3cA==
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
index 6b7378cf4d493..05b8d656b5fc4 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -72,7 +72,7 @@ chosen {
 
 		stdout-path = "serial0:115200n8";
 
-		framebuffer: framebuffer@9d400000 {
+		framebuffer {
 			compatible = "simple-framebuffer";
 			memory-region = <&cont_splash_mem>;
 

-- 
2.53.0

