From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Aug 2026 15:46:54 +0200
Subject: [PATCH v2] media: dt-bindings: dongwoon,dw9714: Fix example
 implying 1.8V
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260819-pp-pro-camera-v2-1-c21652dd388d@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ6CMBBFr0Jm7ZgWiRRX3sOwKO1UxkRoWiQo4
 e62uHb5kvffXyFSYIpwKVYINHPkcUhQHgowvR7uhGwTQynKs1BCovfow4hGPylo1LKyUrtKnYy
 FtPGBHC9779b+OL66B5kpR7LRc5zG8N4PZ5m9f+1ZosC6q2wjaqVc46688HQ0H2i3bfsCrLFtn
 LoAAAA=
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1798; i=david@ixit.cz;
 h=from:subject:message-id; bh=WEz/pz57pQGwTSB/NZ0X/QE1xaXHsRApbxIBxFTqjKk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqhbPQMqzPiKbvO2zm5Y25Q1FChZvbD4ycOMRlw
 qreCnstAv2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaoWz0AAKCRBgAj/E00kg
 cph7EADFujxDmvz4QUJ/nDfMlv+cHBpuMmsb3VBF0efv/N5Tj3rbzfRnVtu1y9h0iztGRpf7dIt
 MMnY9s6dLeTqG2H7dKN601hn6ZQkHsYTnXutP8cJR6FoED2GSczi3cSDTt/kCNi5+71dTdktqGb
 IwzlRcZxGoXid2bNtWvI3rnhLJZoQX03ntlkRgPndYL/R1gqf0PG37VLfMLiiw2qmy+4gt+Os5W
 xU/hxWjng309iYlTNMU9emVVe97I/WpzBDAWjOMifN1WbjAnFnSg2IhfryhQpggzXPR3NJMFxr0
 MCFGNc4zpPZjzKLPtVDTAYzOd1pxJc6Jms1BJ70oNPlI5ma3MITPI/Wpb8OFOHzb4j7Wriszj0e
 2QkZ1ibo7YTTqD08nhR7cWar460VUFIs8DGiWf9wtE4mFSgVObGoan60TAm3bO4r5Bn5HpzXtIk
 eJAE9zzzrxwOny8mgdUZYx0iHrn2LdckM8E0pbkNso3BrIL1shh0xc/fbHL3jWTeAoSFkePyIeF
 MG/glKm26c2NLMD7AxHG2HZUE5PbjbDSSVZxia+uHDCdxHxvCtzNY+GzAem5MuFQm1zedYHADID
 KOpLOjhw9YX9ozE9NyhBPVvQuEt6d7y2SNRTRX3rJGulYHzm8rcnBN2lq7tKXh3bCbQQTgAzLuX
 eOXKIeFIFCKYqsA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The datasheet says VDD should be between 2.3 to 4.3V, usually around
2.8V. Correct to prevent confusion and extend description.

Fixes: 2a96b40f366a ("media: dt-bindings: dongwoon,dw9714: convert to dtschema")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
The example implies incorrect voltage, fix it.
---
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

