From: David Heidelberg <david@ixit.cz>
Date: Tue, 17 Mar 2026 23:12:34 +0100
Subject: [PATCH v2 4/5] arm64: dts: qcom: sdm845-samsung-starqltechn:
 Convert fb to use memory-region
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260317-beryllium-fb-v2-4-36b69dfb760c@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1131; i=david@ixit.cz;
 h=from:subject:message-id; bh=RXjeRhCssdQxix5qN3wrJwt18xmt4cI0v6Yeeq6xdTU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpudHRSHDJ02hwchFc5TgZyWfN1S84TyU3efX4l
 7j/XQseUhOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCabnR0QAKCRBgAj/E00kg
 clwrD/9tMxt2PWbYewfbTmjK4AF9Te5tCgkNbjmBsitwGQ+B0Xuv/W6UOOajyrqRzeOC66SUguj
 kdKvjTLS4XR81REQz4vPRghjy7pEItawX6crNxMfkDtXPjAGhooVsN2nfn5batp7jHQAIRCV7VU
 0lPj3G+Fk4f0UhwpTfOV+HpGf2WUKyRXZxcGOTLwBi7Ok6MnIgx+6L+7GtzgRz2kNEr6FV9FgeN
 8ARxm9mVlIVxbc1VN3e6CjviuMPSzbznMLh08n0BulC65zOVLWkfVXmIWBX7uFhHlq3ikWUnxzI
 uTKC2mswabnGXMsqxTXtdnsLnkOJLmdxZq9i1Dmk4W5+2uyzFRyL69Xav97LmmaZWGKMnrX77N8
 yVg/BI8r+amaC7nw5g95eilG7B+hjzIMZDxwp+mPrTF1FmGEBkJIvZXhBtZ6UGm1nzlujYgi9Ez
 qq4Q/+9NbyCeas4eh8KzdLXPapX/nuIld3AinwkYXeh38n/DyzdafPNew/ky9c6LkSiMmcV41sh
 FMQp/RRWOAKHlANQw5DX8IW/lYfl4KdIkRJAata3+ythZHBSvj547FBz7tPdTA2v4hheZhJZ0G9
 GeJIZJnZKHEUJ3rnhgk0dKteYMbEbz2H4LyxjVxUnwp7PMEz3Z7GnUqhevGRLRh0zjf2j0RMU5X
 ajVZxGHqscExMBA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead of manually specifying reg, reuse the memory region.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts | 7 ++++---
 1 file changed, 4 insertions(+), 3 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts b/arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts
index 77f5872de6f19..e704497853407 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts
@@ -43,9 +43,10 @@ chosen {
 		#address-cells = <2>;
 		#size-cells = <2>;
 		ranges;
-		framebuffer: framebuffer@9d400000 {
+
+		framebuffer: framebuffer-0 {
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

