From: Igor Velkov <iav@iav.lv>
Date: Fri, 09 Oct 2026 20:45:36 +0000
Subject: [PATCH 1/2] dt-bindings: gpio: pca95xx: add onnn,pca9655 with
 nxp,pca9555 fallback
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-helios64-pca9655-v1-1-673ee4432650@iav.lv>
References: <20261009-helios64-pca9655-v1-0-673ee4432650@iav.lv>
In-Reply-To: <20261009-helios64-pca9655-v1-0-673ee4432650@iav.lv>
To: Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Rosen Penev <rosenp@gmail.com>, 
 Gregory Clement <gregory.clement@bootlin.com>, Andrew Lunn <andrew@lunn.ch>, 
 Sebastian Hesselbarth <sebastian.hesselbarth@gmail.com>, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1279; i=iav@iav.lv;
 h=from:subject:message-id; bh=hwPZSPeRdIPJzNMdM23subxRzNUtRq7wz0V1xH0yzjg=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFkng4q0mR+f+lNWWPY86ViKmaPPXsN/ryL4bzfHMdXL8
 bzzDr3dUcrCIMbFICumyDLhkMatjCVX//p7mD+AmcPKBDKEgYtTACby4CEjw3v3veEsqge9IxZu
 n6A/fd2/fzerWBRt2Z70hl/btj64cT8jQ6vZ+10TDlxxX3IrKax844VsZacev0C//51+7zjXJP1
 W4wQA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ON Semiconductor PCA9655E is a 16-bit I2C GPIO expander that the
pca953x driver handles as a PCA9555: both entries of its OF match
table carry OF_953X(16, PCA_INT), and onnn,pca9655 has been there since
commit 6d49b3a0f351 ("gpio: pca953x: Add support for the On Semi
pca9655"). Document it with nxp,pca9555 as the fallback, the form the
comments in armada-388-clearfog.dtsi and armada-388-helios4.dts ask
for. The I2C core tries OF matching first, so the fallback form
probes; tested on Helios64, the first user.

Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 Documentation/devicetree/bindings/gpio/gpio-pca95xx.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/gpio/gpio-pca95xx.yaml b/Documentation/devicetree/bindings/gpio/gpio-pca95xx.yaml
index 4631388a7d91..d671aaf83bb7 100644
--- a/Documentation/devicetree/bindings/gpio/gpio-pca95xx.yaml
+++ b/Documentation/devicetree/bindings/gpio/gpio-pca95xx.yaml
@@ -25,6 +25,9 @@ properties:
       - items:
           - const: kinetic,kts1622
           - const: ti,tcal6416
+      - items:
+          - const: onnn,pca9655
+          - const: nxp,pca9555
       - items:
           - enum:
               - exar,xra1202

-- 
2.43.0

