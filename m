From: David Heidelberg <david@ixit.cz>
Date: Thu, 23 Oct 2025 22:24:30 +0200
Subject: [PATCH v5 6/6] arm64: dts: qcom: sdm845-oneplus: Describe TE gpio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251023-s6e3fc2x01-v5-6-8f8852e67417@ixit.cz>
References: <20251023-s6e3fc2x01-v5-0-8f8852e67417@ixit.cz>
In-Reply-To: <20251023-s6e3fc2x01-v5-0-8f8852e67417@ixit.cz>
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
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo+o77mEd+eCRJ0hMbE6TLpH3mPs3ZCMwueE40f
 l4JJPO31juJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaPqO+wAKCRBgAj/E00kg
 cgCgD/9QMZOxyeIUcHQWTF3qvT1tVGuppo9og4JggfMhj+5QBC9QaegU057y7GnqHJJYy195ooU
 53E6w8YEBibHE7esvbksxh5OG41c5y/99JCIA7sgQwq8IRxYsxhf8VkXdrknNM9vClauqJRPx7x
 78RqQWGGCHoW9qSfNiLoKMpzhgT+mDgXVsYQkhaZZYOAIsLsWZPDToyya32axsy7tQ12ploiRC6
 m1cXzqhSDA3EqIyRVdzC5e9GmN4zU2cmAQfYh/jTCo6tbN7QO8fxxOZQYP8uZclZxf1GAyF+E5J
 GtgYHB2T4VnfUho+skT9EtF5dOHvOT0x5AdXoy56+CoMsDa/5cG2T43Ie9t4vCVQJTW2mZLOsGb
 JzlPu45/i2Wnr5RxoC5hbaRy2fm3fJ+fNyF0x+sMxXoYzuiWcCtES4W5ti3rVJHxHomxjc7ArHl
 PD8DcEmSvzFDOh4UdzTfIwYLlXlQwUgVRZ2gJMa62P71zM+CtXyKYkXcuXVy+tsyDH/h4OYslHl
 CEom9zQn2kb+2HDzXDn09sxcT0oBQWiCMnZwjbs2qY9hdwttVrghViDtIoDXTdgz0DEH1s4uyGd
 YMzsbvCjh0DWRQiS8OiWlwbUNkNTFg83tDCpLFjXCgcFI3NjhR2Wg2jOo8FcsAEradCbkv38AL4
 WWvX1wSH1KsbVOA==
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

