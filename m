From: David Heidelberg <david@ixit.cz>
Date: Sat, 01 Aug 2026 02:35:20 +0200
Subject: [PATCH 1/4] media: dt-bindings: dongwoon,dw9714: Example shouldn't
 imply 1.8 V
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260801-pp-pro-camera-v1-1-7b4d90788f9f@ixit.cz>
References: <20260801-pp-pro-camera-v1-0-7b4d90788f9f@ixit.cz>
In-Reply-To: <20260801-pp-pro-camera-v1-0-7b4d90788f9f@ixit.cz>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Ondrej Jirman <megi@xff.cz>, 
 Olivier Benjamin <olivier.benjamin@bootlin.com>, 
 Manuel Traut <manut@mecka.net>, 
 Alexander Warnecke <awarnecke002@hotmail.com>, Frank Li <Frank.Li@nxp.com>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, 
 Martin Kepplinger <martin.kepplinger@puri.sm>, 
 Shawn Guo <shawnguo@kernel.org>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 phone-devel@vger.kernel.org, imx@lists.linux.dev, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1376; i=david@ixit.cz;
 h=from:subject:message-id; bh=sfBlyUIhGugdsRnaSHNhShuFZ0DGsHeOeRXQgKfVu9M=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqbT9RqSJZNqhResdsqnz0RhYvhHWQ77DYnIRl/
 Ps/2ru4VpSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCam0/UQAKCRBgAj/E00kg
 ckZpD/9/AsNbDL0qEmqEHmCublG5Nru0i0jH1IltGtLg1JiBS9qXYwT7VJsp1bHvCfebRKXTBMs
 Yz6hsPICqGmpcKwVqisMWQLLFvtc9oKJuPqHCfP0IsPB2TErPXDME7fR/uSu4V5wLvoclp9lJ/0
 leDx5sEc/BY4/RCCbR/gA/7fWXzrwstH1JAGz0jFRMpmLEfue5IW0SPSZE9TjtG670UxPQw4zXV
 FWlwR+rB6YjMBa2Mqv0jh/rogANRjSma258zkZ0M4AMMHxxp4kAeJcPqUIU9iadNiK+diiTIutd
 Ctul8mqc22FokHc4nUDpSSU6j0DMRFZmlFXdp/oki06idrCCofiYc+iHmKknX3o7ZLGZGidwome
 9lkjst6xJb5s90IUb7JzcB+gJ5t9G2+pUeCBh5l14626KLEEwm5SpGQFuEDunj5p1m97D2M1i6O
 Lvoeha998AcBR9o7pzOm93bwJrBFfDMY/o3H6nA9jZpDRHrd47+EjHBNVm5/1DHdkzEABELKVKo
 3WnHDWivnImwpnKqD6ZO7U/krf1/ak7C2/fu/My9wOJUVrt2MwU2aHhQ5FLyEVOiqYhVLJqSCQR
 kIG+KJ3flbfU97rmGk/iSqpg5Tm6shakMS9JR2SbHdnIDx+cVW8k76Inyr2p3h+w1jkl9c0cOXF
 0VAbWtXBsOQ7C0A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The datasheet says VDD should be between 2.3 to 4.3V, usually around
2.8V. Correct to prevent confusion and extend description.

Fixes: 2a96b40f366a ("media: dt-bindings: dongwoon,dw9714: convert to dtschema")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/media/i2c/dongwoon,dw9714.yaml | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/media/i2c/dongwoon,dw9714.yaml b/Documentation/devicetree/bindings/media/i2c/dongwoon,dw9714.yaml
index 66229a3dc05d6..7f5aa098351dc 100644
--- a/Documentation/devicetree/bindings/media/i2c/dongwoon,dw9714.yaml
+++ b/Documentation/devicetree/bindings/media/i2c/dongwoon,dw9714.yaml
@@ -20,28 +20,28 @@ properties:
   reg:
     maxItems: 1
 
   powerdown-gpios:
     description:
       XSD pin for shutdown (active low)
 
   vcc-supply:
-    description: VDD power supply
+    description: VDD power supply (2.3 to 4.3V)
 
 required:
   - compatible
   - reg
 
 additionalProperties: false
 
 examples:
   - |
     i2c {
         #address-cells = <1>;
         #size-cells = <0>;
 
         camera-lens@c {
             compatible = "dongwoon,dw9714";
             reg = <0x0c>;
-            vcc-supply = <&reg_csi_1v8>;
+            vcc-supply = <&reg_vcm_2v8>;
         };
     };

-- 
2.53.0

