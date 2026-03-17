From: David Heidelberg <david@ixit.cz>
Date: Tue, 17 Mar 2026 23:12:33 +0100
Subject: [PATCH v2 3/5] arm64: dts: qcom: sdm845-shift-axolotl: Convert fb
 to use memory-region
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260317-beryllium-fb-v2-3-36b69dfb760c@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1114; i=david@ixit.cz;
 h=from:subject:message-id; bh=+J1GiE3/gu+Ex4529cyTBsEBCOk3gC0OobsfViZGQVA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpudHR+/5GlKmBFroZ+rrEc7ox3nBpoo4sRrRck
 mtBmnTSuPiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCabnR0QAKCRBgAj/E00kg
 chhnEACDhIYCHFrtbVidzFiokgVEvko7c1vNLICH17a+Ctjjf1CZsVQilUcOxcUDmABnOyNxm8/
 01zQthhInphazePhHYzMTiYwy/9iyUwRddnMShd4pf4qsjA59TNOxxnIgPDCe92QPzFnoi0VK8G
 utgm1Oj/uc1biV4JMFP/UEqKjb8NMZkHEtrtNwW3bLHLm2vfGX6zZ0noeKd4Uc4Dhx56I4kTtGJ
 BEQPqLIXyevNkJx/tvaIcovzm6a8ZQCVLPiJOBZymwt+tUM+l0sSeDgHZd9Z3YiDwgQSa/J7ZtC
 CyMmVMSH2USPmAeJxPwOJLF4I6PNMfG15D38wmawpzNss6YXQnIicgxAktkSP+Nuf6H0KHsa/8N
 wGiqrVdj0kfTAqSlEIqNlvCdxcJr6LWgsSY3JMaA1RL7CZjL5rn/Y5XlS3B/rKKGOCogZj7VNs1
 +/S4DyoQR5UrpuXO2NuDK/r/bI8NhtrIrssfcuo6pK3urqblE8hSPXA9CP1SB3r7S414ZTah6zq
 ufxa6Y7AUwuwkEP8R1EcUYt1XKMPwz3L2AK4LCWa4V300m0s/hdF+II+w17VMxMHuial0RF485r
 s0/QF/XwcdAOFL1tmRFlwsoFNesv+sZCFzhUYknemVdQ2RJyzZL7IZbcQ6ZzZzkwZF+9bFgM3Fa
 0T6j/5SvZHUa4gQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead of manually specifying reg, reuse the memory region.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index 51b041f91d3e2..27a0facd174c8 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -36,9 +36,9 @@ chosen {
 		stdout-path = "serial0";
 
 		/* Use framebuffer setup by the bootloader. */
-		framebuffer0: framebuffer@9d400000 {
+		framebuffer0: framebuffer-0 {
 			compatible = "simple-framebuffer";
-			reg = <0x0 0x9d400000 0x0 (1080 * 2160 * 4)>;
+			memory-region = <&framebuffer_mem>;
 			width = <1080>;
 			height = <2160>;
 			stride = <(1080 * 4)>;
@@ -62,7 +62,7 @@ key-vol-up {
 	};
 
 	reserved-memory {
-		framebuffer@9d400000 {
+		framebuffer_mem: framebuffer@9d400000 {
 			reg = <0x0 0x9d400000 0x0 (1080 * 2160 * 4)>;
 			no-map;
 		};

-- 
2.53.0

