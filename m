From: David Heidelberg <david@ixit.cz>
Date: Sat, 29 Mar 2025 13:09:47 +0100
Subject: [PATCH] dt-bindings: extcon: linux,extcon-usb-gpio: GPIO must be
 provided
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250329-yaml-extcon-usb-gpio-v1-1-190696e53a0b@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAArj52cC/x3MTQ5AMBBA4avIrE3CSP1dRSyKwSS00iJE3F1j+
 S3ee8CzE/ZQRw84PsWLNQFpHEE/azMxyhAMlJBKMqrw1uuCfO29NXj4DqdNLJJKuzxXRFQWENL
 N8SjXv23a9/0AbyawbmYAAAA=
X-Change-ID: 20250329-yaml-extcon-usb-gpio-251b66522287
To: MyungJoo Ham <myungjoo.ham@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Frank Li <Frank.Li@nxp.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1190; i=david@ixit.cz;
 h=from:subject:message-id; bh=6zOdWVK0FWYxP5yR1EYKpiCnbgePLoWpBtG1jaVzWSM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn5+MLjnkz7tOUu4/VzAucCUwghIvdwh9LekMe+
 UtW0Kkd83+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ+fjCwAKCRBgAj/E00kg
 cnO8D/9TwNZ/47r84coAbQMqSgvjIITfQcHU166ONygnNFJ7Ws5zhaC+J5TN+XM++EjcFgXKUMY
 qfKCKsN1C1gEqY51Ka0z3gLnc+Zo3uiBGqEiKr1DOxYOCT6ojRptwxRn7VMRfm3Xf3m9Z+r7Wpl
 cpVbia1MAC7jnvcSRDhxub8BqldDCFGoPQU5f+T7mgfhShHRQ63leuF2ybPrQG4tB+y2kYjM9ai
 /mByxRyNMq5OT4y0g+q0VHNSl6w6MEabqjcXY7exN+i1e9hOiwffK9YsChW7sdiFoKqjwu1arGx
 vIu2A9zXFFVOO6n5aKuDbrUtjnOlu1hkgrVGsN0OHoWsbUMDj/HdN6oriQ16wB1XAeMKxp3XbFb
 crH8nynAgsd5pP4lB6mqfJBSCdDW7zAaZN0JzUiz+KOt7o5H7SsnHRAEguAulwUPo51/z1vCwvJ
 bzdM4CWKUAW6CVa+tvuEQx7vOU/OeDTyknI50IrE5p4fn2DlgVcEuhP5k4l0dhkbOX3EDF9chkA
 lxV1SJXIAA7wlyUPZ6UbKM7OkY72Jgb+Cc8l8SoZX0qa31FJDKwf7por1WUufmdN+uuhGw5P/Q0
 5OKlS70l/SaUDnoAfU3o4WoLFmU5ScEw7KUu1kJvfNIyqbWktULNkTC0m4jxa6mUH4J61TIWCBO
 OvYxv1Mh2S4O02g==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Without providing either ID or VBUS GPIO the driver is not able to operate.
Original text binding says:
  "Either one of id-gpio or vbus-gpio must be present."

Fixes: 79a31ce03f41 ("dt-bindings: extcon: convert extcon-usb-gpio.txt to yaml format")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/extcon/linux,extcon-usb-gpio.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/extcon/linux,extcon-usb-gpio.yaml b/Documentation/devicetree/bindings/extcon/linux,extcon-usb-gpio.yaml
index 8856107bdd33b8654812ab9c97e85e23dc2ef75a..8f29d333602b95fe5ccd8464aa64e2d1f0c1c781 100644
--- a/Documentation/devicetree/bindings/extcon/linux,extcon-usb-gpio.yaml
+++ b/Documentation/devicetree/bindings/extcon/linux,extcon-usb-gpio.yaml
@@ -25,6 +25,12 @@ properties:
 required:
   - compatible
 
+anyOf:
+  - required:
+      - id-gpios
+  - required:
+      - vbus-gpios
+
 additionalProperties: false
 
 examples:

---
base-commit: e21edb1638e82460f126a6e49bcdd958d452929c
change-id: 20250329-yaml-extcon-usb-gpio-251b66522287

Best regards,
-- 
David Heidelberg <david@ixit.cz>

