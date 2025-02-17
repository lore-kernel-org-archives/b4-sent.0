From: =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
Date: Mon, 17 Feb 2025 14:07:52 +0100
Subject: [PATCH 2/2] dt-bindings: gpio: Add support for PCF8574T.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250217-gpio-pcf8574t-v1-2-137e140df5fc@gmail.com>
References: <20250217-gpio-pcf8574t-v1-0-137e140df5fc@gmail.com>
In-Reply-To: <20250217-gpio-pcf8574t-v1-0-137e140df5fc@gmail.com>
To: Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Laurent Pinchart <laurent.pinchart+renesas@ideasonboard.com>
Cc: linux-gpio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739797690; l=668;
 i=gomba007@gmail.com; s=20230706; h=from:subject:message-id;
 bh=B6J4izNH3fp6JISZ2syXUSUwyTFFQEArfTvkcwoUcp4=;
 b=yLBLbSdGcT6u1xG8ikX06I9UIbLWAP3E3AI1PGayeGeSFpL5P9PNIvj/yFxJSFXOVzE7nyU/d
 4Ls+m2twM8GAr6xHtu7zw43GjKDEDNiTOWiXl1ULWXqvRSQzEMZVvxA
X-Developer-Key: i=gomba007@gmail.com; a=ed25519;
 pk=iY9MjPCbud82ULS2PQJIq3QwjKyP/Sg730I6T2M8Y5U=
X-Endpoint-Received: by B4 Relay for gomba007@gmail.com/20230706 with auth_id=60
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the necessary documentation for PCF8574T.

Signed-off-by: Tóth János <gomba007@gmail.com>
---
 Documentation/devicetree/bindings/gpio/nxp,pcf8575.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/gpio/nxp,pcf8575.yaml b/Documentation/devicetree/bindings/gpio/nxp,pcf8575.yaml
index 3718103e966a..cbe4cf96e942 100644
--- a/Documentation/devicetree/bindings/gpio/nxp,pcf8575.yaml
+++ b/Documentation/devicetree/bindings/gpio/nxp,pcf8575.yaml
@@ -34,6 +34,7 @@ properties:
       - nxp,pca9675
       - nxp,pcf8574
       - nxp,pcf8574a
+      - nxp,pcf8574t
       - nxp,pcf8575
 
   reg:

-- 
2.34.1

