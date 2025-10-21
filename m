From: David Heidelberg <david@ixit.cz>
Date: Tue, 21 Oct 2025 13:53:06 +0200
Subject: [PATCH v4 6/7] arm64: dts: qcom: sdm845-oneplus: Describe TE gpio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251021-s6e3fc2x01-v4-6-5e3ee21c688a@ixit.cz>
References: <20251021-s6e3fc2x01-v4-0-5e3ee21c688a@ixit.cz>
In-Reply-To: <20251021-s6e3fc2x01-v4-0-5e3ee21c688a@ixit.cz>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=744; i=david@ixit.cz;
 h=from:subject:message-id; bh=4HlzjaWbltHovpW/x3csoBFsnc7NUcuYDQwYcmmZFrE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo93Qh8qZOMkmBNVijDAoQ1Q6Qg+1c4buWwc5AM
 M+Vqm/GnOyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaPd0IQAKCRBgAj/E00kg
 csZBEADPO5B99OhdousRGVcs4eB/tkJL/81Gj2Pkrn/gy4BEIOCxqjmp7yzWxY2llWqtL162T0g
 oivf2adFLgpVuf3UtS/1I1ZMw0adJlQVjqW7JaHZ1BzD4H8mLPF6kjsUyPBXHOw+hW5mP7ByrnV
 gHHxxdtz6e4UXHPwSJmyU51n+iC4qUXwBtUIeZeWv/WsWdj9yygPP8H8X2ggoZgiuE5h/M+nFsF
 4J9BrY55qDvyBfEcSqEWHmelIZBX8JCc5nhcwBs/4irG7CXBA0tATdknjuTxLEExmku/3wqF81g
 TJ+eZBMJm+7sFc2NOHWG2163anq/CGjx7m98TYBZvSsk1CG2YR4k9Cwt2NsF/ujMC5oj8Jv9nn7
 6GyELU5ywbiJCmjKz8Osdkzj/k50EcBbdZokkC+BccO4+pNe20dMQpBuKj/39GGb/Ig22DR4vFQ
 SpIrucuM+IwgCRzu3yi29u1kDizmq9By76CEganh8/W50c8sZLlu225iPbvDDDbfELP+GdvuT2i
 9BgFpwIVMqbIUjJpqP36Z4uBdbjcd2sNwAbYNzcPajPg5gkCGv2PPClDh/269/WRT1XtOUhK8hn
 s9FYq9ndlkuQzja5FCiUBAP3wh5ID4OYziN/Yho442G+wn45dnjWOcuHBSbRDul7UvC8U0SULRf
 2I2pd1VyCZ4asOg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe panel Tearing Effect (TE) GPIO line.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index a8e87507d667b..8ccf93dec557a 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -460,6 +460,7 @@ display_panel: panel@0 {
 		vci-supply = <&panel_vci_3v3>;
 		poc-supply = <&panel_vddi_poc_1p8>;
 
+		te-gpios = <&tlmm 10 GPIO_ACTIVE_HIGH>;
 		reset-gpios = <&tlmm 6 GPIO_ACTIVE_LOW>;
 
 		pinctrl-0 = <&panel_default>;

-- 
2.51.0

