From: Maud Spierings <maud_spierings@hotmail.com>
Date: Sat, 01 Nov 2025 13:54:16 +0100
Subject: [PATCH 5/6] arm64: dts: qcom: x1e80100-vivobook-s15: add charge
 limit nvmem
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251101-asus_usbc_dp-v1-5-9fd4eb9935e8@hotmail.com>
References: <20251101-asus_usbc_dp-v1-0-9fd4eb9935e8@hotmail.com>
In-Reply-To: <20251101-asus_usbc_dp-v1-0-9fd4eb9935e8@hotmail.com>
To: Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762001681; l=986;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=aBmU+MBpzJDOfvhbJRvLf5MrSRONaR0yduU16nAFvRY=;
 b=fNTrArf6yUIrnwZEDY1VbngDIfndS5BkP8O+OFYSIg4GuDntgl3xwROZuWW00awAUwOEY8HAu
 e0qY+2A/MF6DoKaD6aIslS6bhjQme8d/DkFxgXlD7opk0UOL9Ks+bys
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add nvmem cells for getting charge control thresholds if they have
been set previously.

Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
 arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts b/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts
index ad648fcd414a..7dd0d7999fe5 100644
--- a/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts
+++ b/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts
@@ -82,6 +82,12 @@ pmic-glink {
 			     "qcom,pmic-glink";
 		orientation-gpios = <&tlmm 121 GPIO_ACTIVE_HIGH>,
 				    <&tlmm 123 GPIO_ACTIVE_HIGH>;
+		nvmem-cells = <&charge_limit_en>,
+			      <&charge_limit_end>,
+			      <&charge_limit_delta>;
+		nvmem-cell-names = "charge_limit_en",
+				   "charge_limit_end",
+				   "charge_limit_delta";
 		#address-cells = <1>;
 		#size-cells = <0>;
 

-- 
2.51.1

