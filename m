From: David Heidelberg <david@ixit.cz>
Date: Thu, 25 Sep 2025 11:12:51 +0200
Subject: [PATCH 5/8] arm64: dts: qcom: sdm845-oneplus: Correct panel reset
 gpio polarity
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250925-s6e3fc2x01-v1-5-9293016768f7@ixit.cz>
References: <20250925-s6e3fc2x01-v1-0-9293016768f7@ixit.cz>
In-Reply-To: <20250925-s6e3fc2x01-v1-0-9293016768f7@ixit.cz>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jessica.zhang@oss.qualcomm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=995; i=david@ixit.cz;
 h=from:subject:message-id; bh=Mx+pkd2/AobEUeDku67R/7xYkAIay2Af2+Zb8hbtf9w=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo1QeR0uPmmIGKjO2LdfReaBRqvbkanfhCyQCCP
 S0Tgv5YyMGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaNUHkQAKCRBgAj/E00kg
 cuG3D/9klNUUR62Vi0zv8Cduyq9ByQYN5uEdD8bw9MyRDRkbAkbTk7KVrGiXtoyBYd1DxdYlhOu
 Y6cCYooM0H9vtclG0W0AD/khhzOgdWIvCmEI0ImNG9Ismfb7tLxb5QvmLAytbGsKC4LGUit/xzU
 QwSNhLjnOaFX+NA7Rv8RThIrP/rRW0+Qq7xa14bGWo2a9D8y2lqcp5eoeg3i3grm99MuXv07UFx
 Uef2mzl+/+TAVkm8NG1acC/MHmhQLygjntueAm6e3mbfZ5A2uQaYEo6N5O7UVKjogxOrkNcrG83
 sTI3xOuTOzz1eDs6Tlomw3qxI+wF8vTfOBn9KuzkxEcbFr3i2aR8vY5TN/6B9H7QRduxej2fi84
 p11oNmovPJzKkn9+eo+tjHwY2S1su7IJqzQeOdgQaoanXAo60YuncHxxtqkG6mVwAgzq/J7XKzU
 3k/qLe3ZUc1dSQSH7B+QHNgM6N7vZEoqJUlO54PxJuwsjscp37lBITCXwqZbEc0loBpdNSIdjrE
 mGJAylPknP2DYMgEfDHm4K+3WY5cPF6BTL7J/89KGUd83uvaZp0255ZJ+O0UmToD/IQcS6gAHIU
 FMo4xZdN+SENhckp7vvt6j68eHoLsU2GRb49Zo92OTDM6TRB1JooLCL3pvOksi0IUwmN7+5M9FG
 axt/aQmt25HlKkg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reset GPIO should be active in high state as usually the board doesn't
invert the polarity.

Fixes: 288ef8a42612 ("arm64: dts: sdm845: add oneplus6/6t devices")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index aff5e80c1eba43e830991c2afd53b6322893cd27..7f968f90a83b869395bedd5de510ba96de3c4e94 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -456,7 +456,7 @@ display_panel: panel@0 {
 		vci-supply = <&panel_vci_3v3>;
 		poc-supply = <&panel_vddi_poc_1p8>;
 
-		reset-gpios = <&tlmm 6 GPIO_ACTIVE_LOW>;
+		reset-gpios = <&tlmm 6 GPIO_ACTIVE_HIGH>;
 
 		pinctrl-names = "default";
 		pinctrl-0 = <&panel_reset_pins &panel_te_pin &panel_esd_pin>;

-- 
2.51.0

