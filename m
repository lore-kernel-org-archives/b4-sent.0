From: David Heidelberg <david@ixit.cz>
Date: Wed, 01 Apr 2026 22:40:17 +0200
Subject: [PATCH v3 4/4] arm64: dts: qcom: sdm845-samsung-starqltechn:
 Convert fb to use memory-region
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260401-beryllium-fb-v3-4-ec7d443402ab@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1183; i=david@ixit.cz;
 h=from:subject:message-id; bh=gN5kieASmpmvG+WEYJe1SGEYovf2d/d661pl9qIjP0k=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpzYKvNtolsKMdRe+ofmju3FGMEBlacb1FH7vwM
 xjeBQhho+uJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac2CrwAKCRBgAj/E00kg
 cqlZD/0VYN3MA1hQxNm+8ykNZljgC0t3axnfW3nBo1S8PCRI00XJ+lHXosoTdoD2Z6Hr86PQG8g
 YFwX5q3rozOQPa2KQUKcH35VdCjgAzbJaKD6rMK9mmz4dG6ECFoNv/UmQCbxS7TWOE4OqDAnEfA
 Tc117RAc8SKOIsaZywO7r3+agXQzbAAincNHaok27ft9uSLO3z97PuFG4JAIEvnjNna62vJUEZ0
 tTZTV8ogbhl/MY9MMn/J1JnwhpAGVKu4Kwp4vgN/SrzVP2R0MdPxICcHfc5Sj6VCWfd4NegGEPH
 +aJpgIeobsRrKRLqc2lCpg4TTK9dxESJIWpRHiC5cq1FQBvKf+g5MNwyjYX7+0jBHWNg1FrFmG+
 dZmyPsZofjvtICKpghaNFKZwuAQv9NjHdEfEY/o7knuAXHNfvol6lbp4721pJ0V9B3FGVa4Y9VC
 f+fJV3MA3SMNZ3CHvSggQKdo0bVJl/wAQQW6l+R/IBk8KAnISJWNN5mPR7OzngbTnmxbWeTTs0/
 ZvpqJ0Dr8nEBeJQjswwK1TUn40DPdn1OndmzjrKFy2tqJynDb1fyULAvUYWKw8GBnw3Du5Vc6K2
 u/V5codYBkzjqkHeBo6h8JBzOE51ajrJuyG9XuiJNwCL3tE+JoAkZQBUy3RQCKy6mWydMbhozwk
 8ySES7h75YJ8ECQ==
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

