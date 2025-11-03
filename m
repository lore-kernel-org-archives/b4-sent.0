From: David Heidelberg <david@ixit.cz>
Date: Mon, 03 Nov 2025 12:45:53 +0100
Subject: [PATCH v6 4/4] arm64: dts: qcom: sdm845-oneplus: Describe TE gpio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251103-s6e3fc2x01-v6-4-d4eb4abaefa4@ixit.cz>
References: <20251103-s6e3fc2x01-v6-0-d4eb4abaefa4@ixit.cz>
In-Reply-To: <20251103-s6e3fc2x01-v6-0-d4eb4abaefa4@ixit.cz>
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
 h=from:subject:message-id; bh=QDFx8txawxUA4NQVuvt5zOeKxx/QkLilb2g7UEm0IH0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpCJXuEzEiUcskISWH6ZZ4EhzYICTEATVcbv9Mu
 m1e+qHI4xaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaQiV7gAKCRBgAj/E00kg
 cj0jD/98YZnd6jOSxFHP/wV2DBx01s/B68H3a8riT2SeM/CG3+1MqkXzjIGumzwIjI296JN0D3n
 X4Dfxl+JTY5JOglHv59/9YqbNfiQyyzxAqfK9n+jfWFi0mv9GRpfgHqSKoQ0TTUiMUPZtntDyc1
 L+BobYGnNTM00oY5RhMo/y5eAJP6/glAlGonw7M8ligK2FWrRfJWEM9HDYVBYyLjWHTt7eymBSO
 nBW5dVrZgc0Bj6JdqkF5oqF4IWzDVQ9STD5Bq0krpQSSJPC8RdMm+fK8TFKA/QAIfQGDFr3Waf/
 uogDcwdMkR6lQ36LhW9puguJOHyLwdaawhf/LjegKxKCMW2SZ2Jd+aynqYPcjVabSxhpcubCtBE
 sAkFhWZ1TlwH77pOORx+416iMXWnT7CCU+La+CUPOWqV2FKalp+0nzgDsiHCXR1wSe+wNaEPYbW
 GLomUrkg961mJgDp6SZc1dxyBAcz9LBL45Hk/+GOv40yzGHX4+8Y/47iSi12/l0oC7ROh/d0Vrm
 rSQj+QfXjEL0nAmZ0YJKBe/Ngq9q6F4Lfz4mRGb1yp6ybCAWNyM4PKE2pOLIsvqsWEBVXe8yE/g
 OJ84f+AyQIIgmlH+ywGj2P+gKN/G3nUF4lr5ja8mK1/fqcJpvqYCz7G25N2dUMrudSFQaMfK7ck
 QGyY/BofAZDIBUQ==
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
index f00dbc0fff3d4..db6dd04c51bb5 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -447,6 +447,7 @@ display_panel: panel@0 {
 		vci-supply = <&panel_vci_3v3>;
 		poc-supply = <&panel_vddi_poc_1p8>;
 
+		te-gpios = <&tlmm 10 GPIO_ACTIVE_HIGH>;
 		reset-gpios = <&tlmm 6 GPIO_ACTIVE_LOW>;
 
 		pinctrl-0 = <&panel_default>;

-- 
2.51.0

