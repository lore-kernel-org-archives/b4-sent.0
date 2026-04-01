From: David Heidelberg <david@ixit.cz>
Date: Thu, 02 Apr 2026 00:39:38 +0200
Subject: [PATCH v4 4/4] arm64: dts: qcom: sdm845-samsung-starqltechn:
 Convert fb to use memory-region
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260402-beryllium-fb-v4-4-46170004da28@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1183; i=david@ixit.cz;
 h=from:subject:message-id; bh=gN5kieASmpmvG+WEYJe1SGEYovf2d/d661pl9qIjP0k=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpzZ6pgC/nS88wI0yQMp0VyFhh2nm5c5335vdWy
 +6URQAjsLuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac2eqQAKCRBgAj/E00kg
 cm3LEAC7XOvnvorLfRnv0jq2UQj/F6jtDPzY1o+eTp0VjA6r1fk6hBAORqt+rS537AmBQPYZiAo
 cW8Kv7+1PdyIbw9afgepI4d9jKysnK6Tb9QCyOk0nLAHg5bAUWoHGsU4GSpOnWzViumdmMSvRIH
 YVeORaXyqYP0M1eIQK/QaIoKxMhRrzC0GNmKI8oo5+zW5op/0a9U4KxKdotKJJmPIVq9hBed8/R
 CN/H3MCcB7M0TSGrLwvebVrHkcRqng8N7g/kK30DSpbfWvc0y+zUCqwkeuCRv6GEZHtI025OPyy
 ymohd34JYHZNJRcUlLDm+JInkcY/bTFDvsMtuysIlKMQeYU3tYmwNgmYq5WMLsJssumfuofu6bF
 gqHUCRW0DU0ozlBXMQesYy2Y0ZSePmjGwriAIhQjvm3cc+O1bBkM58yge3nPznnCdjXjTKFToK1
 Dhg/E23OZ0kP6acfXlIX3qV3w7Q8B/uSiX6mq626Epz1IKqK2/hCLbFOJLREVRfayKO+2bBYqfC
 aBq0u8PeHuZl3gHSIas5py0jVfNs0qESO3Ai59xe29c9lv+0+f9BfKRpSI4hYgF4y+TFaTPu8LZ
 TFmmYUd+3pmsWWS+fHJ1bbhtZP/hbkY/h9SJ16QolkqsIBuCg+gc4SOeIzQvmXOlLDYq/jxCBz/
 xrV9t2z0lm/e71w==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead of manually specifying reg, reuse the memory region.

Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts | 7 ++++---
 1 file changed, 4 insertions(+), 3 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts b/arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts
index 77f5872de6f19..0d915ecb0444f 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts
@@ -43,9 +43,10 @@ chosen {
 		#address-cells = <2>;
 		#size-cells = <2>;
 		ranges;
-		framebuffer: framebuffer@9d400000 {
+
+		framebuffer {
 			compatible = "simple-framebuffer";
-			reg = <0 0x9d400000 0 (2960 * 1440 * 4)>;//2400000
+			memory-region = <&framebuffer_mem>;
 			width = <1440>;
 			height = <2960>;
 			stride = <(1440 * 4)>;
@@ -109,7 +110,7 @@ vreg_s4a_1p8: pm8998-smps4 {
 	};
 
 	reserved-memory {
-		memory@9d400000 {
+		framebuffer_mem: memory@9d400000 {
 			reg = <0x0 0x9d400000 0x0 0x02400000>;
 			no-map;
 		};

-- 
2.53.0

