From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Mon, 17 Mar 2025 15:16:52 +0800
Subject: [PATCH 1/7] dt-bindings: arm: amlogic: add S6 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250317-s6-s7-basic-v1-1-d653384e41f3@amlogic.com>
References: <20250317-s6-s7-basic-v1-0-d653384e41f3@amlogic.com>
In-Reply-To: <20250317-s6-s7-basic-v1-0-d653384e41f3@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-serial@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742195812; l=998;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=Wj7jFeJyWB1as0Aiyf81qr7pjy4df2QQR553NSdpnoU=;
 b=JrHEbgLFxYtq3HcI4cNA/1nztKjg13wf2WuB6PsRL0fk2ileEs2wg9KNTq6LoaPhb3MiMp7CJ
 x1cG10+F0TNCw7hdt91ntyn6yuWBsfRYag3hwNUMrQm+sTsuAr0zfcn
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the new S6 SoC/board device tree bindings.

Amlogic S6 is an advanced application processor designed for
hybrid OTT/IP Set Top Box and high-end media box applications.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 Documentation/devicetree/bindings/arm/amlogic.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/amlogic.yaml b/Documentation/devicetree/bindings/arm/amlogic.yaml
index 0647851ae1f5..67423c838719 100644
--- a/Documentation/devicetree/bindings/arm/amlogic.yaml
+++ b/Documentation/devicetree/bindings/arm/amlogic.yaml
@@ -237,6 +237,12 @@ properties:
               - amlogic,aq222
           - const: amlogic,s4
 
+      - description: Boards with the Amlogic S6 S905X5 SoC
+        items:
+          - enum:
+              - amlogic,bl209
+          - const: amlogic,s6
+
       - description: Boards with the Amlogic T7 A311D2 SoC
         items:
           - enum:

-- 
2.37.1

