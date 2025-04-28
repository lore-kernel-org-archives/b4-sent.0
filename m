From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Mon, 28 Apr 2025 12:44:29 +0200
Subject: [PATCH v2 2/4] dt-bindings: arm: amlogic: Add TCU Fernsehfee 3.0
 board
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250428-fernsehfee-v2-2-293b98a43a91@posteo.net>
References: <20250428-fernsehfee-v2-0-293b98a43a91@posteo.net>
In-Reply-To: <20250428-fernsehfee-v2-0-293b98a43a91@posteo.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>
Cc: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745837069; l=1095;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=MIe7PtmNs9I3jGf86k4FxS5W7n++ITrjeAkSDcGo2i4=;
 b=JQIGJmDcQaIKoCGqKGZeFqJOtEbcqdf1GapeFkjcfu3MQktin5wLvLjwWR6M3BJUvWsxUfYrp
 COTqXuWSsBPC51m1X21MQ2ud+DY74IGJKMBCehtdkHP3H9myv+fAtNY
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fernsehfee ("TV fairy") 3.0 is a set-top box with HDMI input and output
ports. It originally ran Android 4.4 and a Linux 3.10 kernel.

  https://fernsehfee.de/  (German)
  https://telefairy.com/  (English)

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Reviewed-by: Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 Documentation/devicetree/bindings/arm/amlogic.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/amlogic.yaml b/Documentation/devicetree/bindings/arm/amlogic.yaml
index 0647851ae1f55a27bfb148252532bcf15ca905bf..f6f045528da32cf4625b30da59262ca21da860e6 100644
--- a/Documentation/devicetree/bindings/arm/amlogic.yaml
+++ b/Documentation/devicetree/bindings/arm/amlogic.yaml
@@ -27,6 +27,7 @@ properties:
         items:
           - enum:
               - minix,neo-x8
+              - tcu,fernsehfee3
           - const: amlogic,meson8
 
       - description: Boards with the Amlogic Meson8m2 SoC

-- 
2.48.0.rc1.219.gb6b6757d772

