From: Amit Sunil Dhamne <amitsd@google.com>
Date: Wed, 12 Mar 2025 16:42:01 -0700
Subject: [PATCH 1/5] dt-bindings: connector: add fixed-batteries property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250312-batt_ops-v1-1-88e0bb3129fd@google.com>
References: <20250312-batt_ops-v1-0-88e0bb3129fd@google.com>
In-Reply-To: <20250312-batt_ops-v1-0-88e0bb3129fd@google.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Sebastian Reichel <sre@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <len.brown@intel.com>, 
 Pavel Machek <pavel@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, linux-pm@vger.kernel.org, 
 RD Babiera <rdbabiera@google.com>, Kyle Tso <kyletso@google.com>, 
 Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741822998; l=2148;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=lqB7hbM4siiws9pIh8thUf/I8+c5fiz+QxbzSuLaKTI=;
 b=hsUx8+UVc88upFK9cm+h8BLvCbfLdOUWzajlTp2MMm6mhFBleKWb8+HpA/plfvmMQYjbZ68zu
 p4UeoLFlbZaDKPMCwtoPQDgTMN7r+riaPZLxj73hm2hWzkwoq23N1HT
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a new "fixed-batteries" DT property to connector class. This
property is populated with nodes associated with battery type power
supplies powering the USB PD connector. This is needed by the Type-C
Port Manager (TCPM) to query psy properties which are used to feed
Battery_Status & Battery_Capacity AMS.

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
---
 Documentation/devicetree/bindings/connector/usb-connector.yaml | 8 ++++++++
 Documentation/devicetree/bindings/usb/maxim,max33359.yaml      | 1 +
 2 files changed, 9 insertions(+)

diff --git a/Documentation/devicetree/bindings/connector/usb-connector.yaml b/Documentation/devicetree/bindings/connector/usb-connector.yaml
index 11e40d225b9f3a0d0aeea7bf764f1c00a719d615..5e15bc060f5a2cfce842f83de738f1e8bae3ce2d 100644
--- a/Documentation/devicetree/bindings/connector/usb-connector.yaml
+++ b/Documentation/devicetree/bindings/connector/usb-connector.yaml
@@ -300,6 +300,14 @@ properties:
     $ref: /schemas/types.yaml#/definitions/uint8-array
     maxItems: 4
 
+  fixed-batteries:
+    description: Contains references to nodes associated with battery type power
+      supplies powering the USB PD device. These batteries are fixed type and
+      not hot swappable.
+    minItems: 1
+    maxItems: 4
+    $ref: /schemas/types.yaml#/definitions/phandle-array
+
 dependencies:
   sink-vdos-v1: [ sink-vdos ]
   sink-vdos: [ sink-vdos-v1 ]
diff --git a/Documentation/devicetree/bindings/usb/maxim,max33359.yaml b/Documentation/devicetree/bindings/usb/maxim,max33359.yaml
index 3de4dc40b79192b60443421b557bd2fb18683bf7..66c99f0131f074f1c08e31d7481f555647e3b2f8 100644
--- a/Documentation/devicetree/bindings/usb/maxim,max33359.yaml
+++ b/Documentation/devicetree/bindings/usb/maxim,max33359.yaml
@@ -75,6 +75,7 @@ examples:
                                        PDO_FIXED(9000, 2000, 0)>;
                 sink-bc12-completion-time-ms = <500>;
                 pd-revision = /bits/ 8 <0x03 0x01 0x01 0x08>;
+                fixed-batteries = <&batt1 &batt2>;
             };
         };
     };

-- 
2.49.0.rc0.332.g42c0ae87b1-goog

