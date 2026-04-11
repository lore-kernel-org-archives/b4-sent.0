From: David Heidelberg <david@ixit.cz>
Date: Sat, 11 Apr 2026 12:09:42 +0200
Subject: [PATCH 2/2] arm64: dts: qcom: sdm845-google: Enable PMI8998 camera
 flash LED
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260411-pixel3-camera-v1-2-2757606515b6@ixit.cz>
References: <20260411-pixel3-camera-v1-0-2757606515b6@ixit.cz>
In-Reply-To: <20260411-pixel3-camera-v1-0-2757606515b6@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>, 
 Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1068; i=david@ixit.cz;
 h=from:subject:message-id; bh=oHm5gtJSD89tJ1iKZHr8Xq3et+1+samike+C1B2jGmY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp2h3oq4IMTLAc/PJcUwxGj3JyjDtnXbhTJHmGQ
 iR0OqwcdPOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadod6AAKCRBgAj/E00kg
 cnI+D/0emBL5iXqIrTA1BWpgqCf2aZ38y4Goa5MEEibIwJAk48Iz09pfK1lpxOlIY/OHT0Nr5mL
 sLMCP40ZPb+HBk+IY81w78LSTJoYzKYiKiTF4gONsHVl1AZr18pj5i2qA9UhRG27Zchja6j9zOF
 uvhoak2wLVm6dHDGIBVnKi/IYa7i2MiQrbc8dtE+1hZqyObED6bccjF3Zzig/iIpt9eyVc0QyHY
 Uvye+Btk71UfIEim+JsbOVEd2dFuljRNa7jUR9rWb6qy8vNoAbzPPTy6Ow1Fds0AxCZJy8SLWlb
 39+c91uLyoG3y7J4ICQy/AgvOE1FwzokoZTvR1AU2OWBEDhOKwqSqyrhBEKwKRIdBf7XepCgMD7
 ZS1wSQ8PXW+7fb3p1/b1kYY+kYV/PYd8KDP0cE7X5DIpOwp35p8mWuYiclJKQJSh9MCuRawEY/E
 cwb+gYNEyp6FmhIIAFDKwfJ/a9ezPYVuxQkfFGbEXwD2ka6VGt+SYgTs4Q3GAASvyYh7RB86rMJ
 E46tdsnaeAZXCLF3hGjIGcZigVwjuS7WSY4Si3lfY+T3a1AMB0hUzdxPYreCSXZcRuGHZRoRzkp
 kFrGeDp1Bnh6+pEcqyTOvSL5A+PqPZeUdNtgUa2nJAm+FtiAqfgnM6+O/v5MYC2w2WTI4SDkSXt
 Olc9ItiTrrhTKBg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the PMI8998 flash LED block and describe the white flash LED
used for the rear camera.

Configure the LED in flash mode with hardware limits matching the
original device configuration, including maximum current and timeout.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index 084058a597c10..3aa164c34f43f 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -590,6 +590,19 @@ &pmi8998_charger {
 	status = "okay";
 };
 
+&pmi8998_flash {
+	status = "okay";
+
+	led-1 {
+		function = LED_FUNCTION_FLASH;
+		color = <LED_COLOR_ID_WHITE>;
+		led-sources = <2>;
+		led-max-microamp = <500000>;
+		flash-max-microamp = <750000>;
+		flash-max-timeout-us = <1280000>;
+	};
+};
+
 &qupv3_id_0 {
 	status = "okay";
 };

-- 
2.53.0

