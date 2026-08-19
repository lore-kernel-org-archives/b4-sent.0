From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Aug 2026 15:49:05 +0200
Subject: [PATCH v3] media: dt-bindings: dongwoon,dw9714: Fix example
 implying 1.8V
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260819-pp-pro-camera-v3-1-5b669a2ba899@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNwQ6CMBAFf4X07JpuQSie/A/jobRF1kRpWmxQw
 r9L8aAx8TjJm3kTC9aTDWyfTczbSIH62wL5JmO6U7ezBTILM8FFySVHcA6c70Grq/UKFBYGVVv
 IXBu2OM7blsa1dzy9Odybi9VDiqRFR2Ho/WM9jJh2/9oRgUPVFKbmlZRt3R5opGGrnyyVo/hys
 f51BSBogeVOGJNLaT7uPM8vVYfb3fYAAAA=
X-Change-ID: 20260801-pp-pro-camera-a14d1af483cd
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, 
 =?utf-8?q?Ond=C5=99ej_Jirman?= <megi@xff.cz>, 
 Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>, 
 linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1971; i=david@ixit.cz;
 h=from:subject:message-id; bh=wXaWf0FZiUfHyVgUjQSi9vHdfwd5hd8hKQ6POghja+U=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqhbRUmxsSfnnRYEDqMfknoHRKdh0SwjhRtZZlG
 BFwOmYHASaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaoW0VAAKCRBgAj/E00kg
 cts/D/9sg86dS3xB86qmIQ3O20aL5UHA9BJBD8xzmXRwFizV4CTmRbIQBWftFo7NQLhqAYXEMus
 OhTcLfXFJklcofBG3i1A2IO/YdQ78PqhuHT/TJpyuk8AzihU8lnmikjNxWkx90MJNJ1gTlA4SvG
 S32Lk/jGWOmbR8qoqzbfA4YuYQMCm5hZpZkauKxuh+WZGGKDzVAD8p94z2zBNJEkirE2Fesa13v
 1ag3owZYsJ3aZ5V7te6mIFMeu4cTBE1lS3W7ptlUT/JyyrPixr0oVvhmhBFAxCwP72dXhnDBpGD
 FGm+LFHfX4h5mnbDTYF4VBSGEjaW3gE1ET9Rma+YdI3svPL61EeOqu3PsDCKQzasRBpZ+m/OJES
 g7THZCzvAGUhZ7RDp589uyiYPFBsyIwsWAUn5lItc9Qa48RBQgHIQTRlAi3Z96PQcnyf3CFW2Ua
 lU1dI7J6451CnsiCwqeAkFntIvY1uRmPaKOChdJ3FrF7jXPwn9wg9ffs0T9tvkJyvmgd4iCxi6I
 JYL3lC7wRdMW+qJQGt2Cg4GTUkAdElgRyNzXprBqqpigupqmIBZjmYfJhydAyEgPsoC69wr1E6/
 5ogTQaGAJxSB3B9XEmxuQjueKSkmZCYjImutOC4lzapo3SvihNaoBslPSAeIMADor36yh5jfLfS
 /IcjlZY0OUkwcww==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The datasheet says VDD should be between 2.3 to 4.3V, usually around
2.8V. Correct to prevent confusion and extend description.

Fixes: 2a96b40f366a ("media: dt-bindings: dongwoon,dw9714: convert to dtschema")
Acked-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
The example implies incorrect voltage, fix it.
---
Changes in v3:
- Missed Rob A-b.
- Link to v2: https://patch.msgid.link/20260819-pp-pro-camera-v2-1-c21652dd388d@ixit.cz

Changes in v2:
- Dropped the devices fixes, needs HW owners to address issues or
  document state to be understandable.
- Link to v1: https://patch.msgid.link/20260801-pp-pro-camera-v1-0-7b4d90788f9f@ixit.cz
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

---
base-commit: 5453bc3279e9f8578ac3e534d476240e40c879e1
change-id: 20260801-pp-pro-camera-a14d1af483cd

Best regards,
--  
David Heidelberg <david@ixit.cz>

