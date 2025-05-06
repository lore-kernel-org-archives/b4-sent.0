From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 06 May 2025 12:09:17 -0500
Subject: [PATCH v2 1/2] dt-bindings: phy: tegra-xusb: Document
 role-switch-default-mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250506-xusb-peripheral-v2-1-bfbe00671389@gmail.com>
References: <20250506-xusb-peripheral-v2-0-bfbe00671389@gmail.com>
In-Reply-To: <20250506-xusb-peripheral-v2-0-bfbe00671389@gmail.com>
To: JC Kuo <jckuo@nvidia.com>, Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-phy@lists.infradead.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746551373; l=12515;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=bXDz9V7ijjOjEJDjbseeUMoc4cMqeqy8K+grZCx+HLw=;
 b=GK4I3KpBd+lxijxREOMj3v4HHSzQOPDNux/+SXpHMeMi8uzDS6uEDdGuyu5bXQw2ENsgPvtPL
 L19irEOUYKfDSAsiMpZ9XZxUubnrs+Hepayj3lgnO6WCO/Hi5ly24XI
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This property is used to default an otg port to host or peripheral.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 .../bindings/phy/nvidia,tegra124-xusb-padctl.yaml  | 33 ++++++++++++++++++++
 .../bindings/phy/nvidia,tegra186-xusb-padctl.yaml  | 27 ++++++++++++++++
 .../bindings/phy/nvidia,tegra194-xusb-padctl.yaml  | 36 ++++++++++++++++++++++
 .../bindings/phy/nvidia,tegra210-xusb-padctl.yaml  | 36 ++++++++++++++++++++++
 4 files changed, 132 insertions(+)

diff --git a/Documentation/devicetree/bindings/phy/nvidia,tegra124-xusb-padctl.yaml b/Documentation/devicetree/bindings/phy/nvidia,tegra124-xusb-padctl.yaml
index 33b41b6b2fd539450f9ce72db8bba204e9c08eba..f383f25d932071bb4e4c86cb9f87f51e6a59aaac 100644
--- a/Documentation/devicetree/bindings/phy/nvidia,tegra124-xusb-padctl.yaml
+++ b/Documentation/devicetree/bindings/phy/nvidia,tegra124-xusb-padctl.yaml
@@ -357,10 +357,21 @@ properties:
 
               See ../connector/usb-connector.yaml.
 
+          role-switch-default-mode:
+            description:
+              Indicates if usb-role-switch is enabled, the device default operation
+              mode of controller while usb role is USB_ROLE_NONE.
+            $ref: /schemas/types.yaml#/definitions/string
+            enum: [host, peripheral]
+            default: peripheral
+
           vbus-supply:
             description: A phandle to the regulator supplying the VBUS
               voltage.
 
+        dependencies:
+          role-switch-default-mode: [ usb-role-switch ]
+
       usb2-1:
         type: object
         additionalProperties: false
@@ -392,10 +403,21 @@ properties:
 
               See ../connector/usb-connector.yaml.
 
+          role-switch-default-mode:
+            description:
+              Indicates if usb-role-switch is enabled, the device default operation
+              mode of controller while usb role is USB_ROLE_NONE.
+            $ref: /schemas/types.yaml#/definitions/string
+            enum: [host, peripheral]
+            default: peripheral
+
           vbus-supply:
             description: A phandle to the regulator supplying the VBUS
               voltage.
 
+        dependencies:
+          role-switch-default-mode: [ usb-role-switch ]
+
       usb2-2:
         type: object
         additionalProperties: false
@@ -427,10 +449,21 @@ properties:
 
               See ../connector/usb-connector.yaml.
 
+          role-switch-default-mode:
+            description:
+              Indicates if usb-role-switch is enabled, the device default operation
+              mode of controller while usb role is USB_ROLE_NONE.
+            $ref: /schemas/types.yaml#/definitions/string
+            enum: [host, peripheral]
+            default: peripheral
+
           vbus-supply:
             description: A phandle to the regulator supplying the VBUS
               voltage.
 
+        dependencies:
+          role-switch-default-mode: [ usb-role-switch ]
+
       ulpi-0:
         type: object
         additionalProperties: false
diff --git a/Documentation/devicetree/bindings/phy/nvidia,tegra186-xusb-padctl.yaml b/Documentation/devicetree/bindings/phy/nvidia,tegra186-xusb-padctl.yaml
index 8b1d5a8529e38a1956a60e402c40ebec089ff2e9..f38ed6d339f125df136bcf0e954efb9f5b46466a 100644
--- a/Documentation/devicetree/bindings/phy/nvidia,tegra186-xusb-padctl.yaml
+++ b/Documentation/devicetree/bindings/phy/nvidia,tegra186-xusb-padctl.yaml
@@ -260,12 +260,21 @@ properties:
 
               See ../connector/usb-connector.yaml.
 
+          role-switch-default-mode:
+            description:
+              Indicates if usb-role-switch is enabled, the device default operation
+              mode of controller while usb role is USB_ROLE_NONE.
+            $ref: /schemas/types.yaml#/definitions/string
+            enum: [host, peripheral]
+            default: peripheral
+
           vbus-supply:
             description: A phandle to the regulator supplying the VBUS
               voltage.
 
         dependencies:
           usb-role-switch: [ connector ]
+          role-switch-default-mode: [ usb-role-switch ]
 
       usb2-1:
         type: object
@@ -298,12 +307,21 @@ properties:
 
               See ../connector/usb-connector.yaml.
 
+          role-switch-default-mode:
+            description:
+              Indicates if usb-role-switch is enabled, the device default operation
+              mode of controller while usb role is USB_ROLE_NONE.
+            $ref: /schemas/types.yaml#/definitions/string
+            enum: [host, peripheral]
+            default: peripheral
+
           vbus-supply:
             description: A phandle to the regulator supplying the VBUS
               voltage.
 
         dependencies:
           usb-role-switch: [ connector ]
+          role-switch-default-mode: [ usb-role-switch ]
 
       usb2-2:
         type: object
@@ -336,12 +354,21 @@ properties:
 
               See ../connector/usb-connector.yaml.
 
+          role-switch-default-mode:
+            description:
+              Indicates if usb-role-switch is enabled, the device default operation
+              mode of controller while usb role is USB_ROLE_NONE.
+            $ref: /schemas/types.yaml#/definitions/string
+            enum: [host, peripheral]
+            default: peripheral
+
           vbus-supply:
             description: A phandle to the regulator supplying the VBUS
               voltage.
 
         dependencies:
           usb-role-switch: [ connector ]
+          role-switch-default-mode: [ usb-role-switch ]
 
       hsic-0:
         type: object
diff --git a/Documentation/devicetree/bindings/phy/nvidia,tegra194-xusb-padctl.yaml b/Documentation/devicetree/bindings/phy/nvidia,tegra194-xusb-padctl.yaml
index 6e3398399628766e820ff2a5da0ee644dcdee956..8253ff3ac5e8cffba16ddca3fbbc0fa32b58384f 100644
--- a/Documentation/devicetree/bindings/phy/nvidia,tegra194-xusb-padctl.yaml
+++ b/Documentation/devicetree/bindings/phy/nvidia,tegra194-xusb-padctl.yaml
@@ -251,12 +251,21 @@ properties:
 
               See ../connector/usb-connector.yaml.
 
+          role-switch-default-mode:
+            description:
+              Indicates if usb-role-switch is enabled, the device default operation
+              mode of controller while usb role is USB_ROLE_NONE.
+            $ref: /schemas/types.yaml#/definitions/string
+            enum: [host, peripheral]
+            default: peripheral
+
           vbus-supply:
             description: A phandle to the regulator supplying the VBUS
               voltage.
 
         dependencies:
           usb-role-switch: [ connector ]
+          role-switch-default-mode: [ usb-role-switch ]
 
       usb2-1:
         type: object
@@ -289,12 +298,21 @@ properties:
 
               See ../connector/usb-connector.yaml.
 
+          role-switch-default-mode:
+            description:
+              Indicates if usb-role-switch is enabled, the device default operation
+              mode of controller while usb role is USB_ROLE_NONE.
+            $ref: /schemas/types.yaml#/definitions/string
+            enum: [host, peripheral]
+            default: peripheral
+
           vbus-supply:
             description: A phandle to the regulator supplying the VBUS
               voltage.
 
         dependencies:
           usb-role-switch: [ connector ]
+          role-switch-default-mode: [ usb-role-switch ]
 
       usb2-2:
         type: object
@@ -327,12 +345,21 @@ properties:
 
               See ../connector/usb-connector.yaml.
 
+          role-switch-default-mode:
+            description:
+              Indicates if usb-role-switch is enabled, the device default operation
+              mode of controller while usb role is USB_ROLE_NONE.
+            $ref: /schemas/types.yaml#/definitions/string
+            enum: [host, peripheral]
+            default: peripheral
+
           vbus-supply:
             description: A phandle to the regulator supplying the VBUS
               voltage.
 
         dependencies:
           usb-role-switch: [ connector ]
+          role-switch-default-mode: [ usb-role-switch ]
 
       usb2-3:
         type: object
@@ -365,12 +392,21 @@ properties:
 
               See ../connector/usb-connector.yaml.
 
+          role-switch-default-mode:
+            description:
+              Indicates if usb-role-switch is enabled, the device default operation
+              mode of controller while usb role is USB_ROLE_NONE.
+            $ref: /schemas/types.yaml#/definitions/string
+            enum: [host, peripheral]
+            default: peripheral
+
           vbus-supply:
             description: A phandle to the regulator supplying the VBUS
               voltage.
 
         dependencies:
           usb-role-switch: [ connector ]
+          role-switch-default-mode: [ usb-role-switch ]
 
       usb3-0:
         type: object
diff --git a/Documentation/devicetree/bindings/phy/nvidia,tegra210-xusb-padctl.yaml b/Documentation/devicetree/bindings/phy/nvidia,tegra210-xusb-padctl.yaml
index e9237c58ce45df7fa25cac861891b3fe76efe83d..c14bb947d306912fb732ff219511c6d6fda80f7c 100644
--- a/Documentation/devicetree/bindings/phy/nvidia,tegra210-xusb-padctl.yaml
+++ b/Documentation/devicetree/bindings/phy/nvidia,tegra210-xusb-padctl.yaml
@@ -379,12 +379,21 @@ properties:
 
               See ../connector/usb-connector.yaml.
 
+          role-switch-default-mode:
+            description:
+              Indicates if usb-role-switch is enabled, the device default operation
+              mode of controller while usb role is USB_ROLE_NONE.
+            $ref: /schemas/types.yaml#/definitions/string
+            enum: [host, peripheral]
+            default: peripheral
+
           vbus-supply:
             description: A phandle to the regulator supplying the VBUS
               voltage.
 
         dependencies:
           usb-role-switch: [ connector ]
+          role-switch-default-mode: [ usb-role-switch ]
 
       usb2-1:
         type: object
@@ -417,12 +426,21 @@ properties:
 
               See ../connector/usb-connector.yaml.
 
+          role-switch-default-mode:
+            description:
+              Indicates if usb-role-switch is enabled, the device default operation
+              mode of controller while usb role is USB_ROLE_NONE.
+            $ref: /schemas/types.yaml#/definitions/string
+            enum: [host, peripheral]
+            default: peripheral
+
           vbus-supply:
             description: A phandle to the regulator supplying the VBUS
               voltage.
 
         dependencies:
           usb-role-switch: [ connector ]
+          role-switch-default-mode: [ usb-role-switch ]
 
       usb2-2:
         type: object
@@ -455,12 +473,21 @@ properties:
 
               See ../connector/usb-connector.yaml.
 
+          role-switch-default-mode:
+            description:
+              Indicates if usb-role-switch is enabled, the device default operation
+              mode of controller while usb role is USB_ROLE_NONE.
+            $ref: /schemas/types.yaml#/definitions/string
+            enum: [host, peripheral]
+            default: peripheral
+
           vbus-supply:
             description: A phandle to the regulator supplying the VBUS
               voltage.
 
         dependencies:
           usb-role-switch: [ connector ]
+          role-switch-default-mode: [ usb-role-switch ]
 
       usb2-3:
         type: object
@@ -493,12 +520,21 @@ properties:
 
               See ../connector/usb-connector.yaml.
 
+          role-switch-default-mode:
+            description:
+              Indicates if usb-role-switch is enabled, the device default operation
+              mode of controller while usb role is USB_ROLE_NONE.
+            $ref: /schemas/types.yaml#/definitions/string
+            enum: [host, peripheral]
+            default: peripheral
+
           vbus-supply:
             description: A phandle to the regulator supplying the VBUS
               voltage.
 
         dependencies:
           usb-role-switch: [ connector ]
+          role-switch-default-mode: [ usb-role-switch ]
 
       hsic-0:
         type: object

-- 
2.48.1

