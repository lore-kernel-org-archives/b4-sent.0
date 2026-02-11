From: Amit Sunil Dhamne <amitsd@google.com>
Date: Wed, 11 Feb 2026 23:25:35 +0000
Subject: [PATCH 1/2] dt-bindings: connector: Add sink properties to comply
 with PD 3.1 spec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260211-skedb-v1-1-616340426cdc@google.com>
References: <20260211-skedb-v1-0-616340426cdc@google.com>
In-Reply-To: <20260211-skedb-v1-0-616340426cdc@google.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, Kyle Tso <kyletso@google.com>, 
 RD Babiera <rdbabiera@google.com>, Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770852352; l=4787;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=40ogrCcivnEF/evwbFDrjls1wMnY+vyXmAsgygJKhzE=;
 b=smnhzMHObSMHKVKd34C+12b8BOSyLH1WkwhnrzCDQ7JCFOMmY/TBOsuOB9RcAFdwYMAq8LUf1
 IOJavVJfL+oBGZWDor//g05X9ZjBggfDgGC4f/TVYEYFYdI/5RPb96Y
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add additional properties for ports supporting sink mode. The properties
define certain hardware and electrical properties such as sink load
step, sink load characteristics, sink compliance and charging adapter
Power Delivery Profile (PDP) for the connector. These properties need to
be defined for a Type-C port in compliance with the PD 3.1 spec.

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
---
 .../bindings/connector/usb-connector.yaml          | 34 ++++++++++++++++++++++
 .../devicetree/bindings/usb/maxim,max33359.yaml    |  4 +++
 include/dt-bindings/usb/pd.h                       | 18 ++++++++++++
 3 files changed, 56 insertions(+)

diff --git a/Documentation/devicetree/bindings/connector/usb-connector.yaml b/Documentation/devicetree/bindings/connector/usb-connector.yaml
index 11e40d225b9f..901986de3e2b 100644
--- a/Documentation/devicetree/bindings/connector/usb-connector.yaml
+++ b/Documentation/devicetree/bindings/connector/usb-connector.yaml
@@ -300,6 +300,40 @@ properties:
     $ref: /schemas/types.yaml#/definitions/uint8-array
     maxItems: 4
 
+  sink-load-step:
+    description: Indicates the preferred load step slew rate in mA/usec for
+      the port (in sink mode). This property is defined in "6.5.13.7" of
+      "USB Power Delivery Specification Revision 3.1 Version 1.8".
+    $ref: /schemas/types.yaml#/definitions/uint32
+    enum: [150, 500]
+    default: 150
+
+  sink-load-characteristics:
+    description: Indicates the port's (in sink mode) preferred load
+      characteristics. Users can leverage SINK_LOAD_CHAR() defined in
+      dt-bindings/usb/pd.h to populate this field. This property is defined in
+      "6.5.13.8" of "USB Power Delivery Specification Revision 3.1 Version 1.8".
+    $ref: /schemas/types.yaml#/definitions/uint16
+
+  sink-compliance:
+    description: Represents the types of sources the sink device has been tested
+      and certified with. This property is defined in "6.5.13.9" of
+      "USB Power Delivery Specification Revision 3.1 Version 1.8"
+      Bit 0 when set indicates it has been tested on LPS compliant source
+      Bit 1 when set indicates it has been tested on PS1 compliant source
+      Bit 2 when set indicates it has been tested on PS2 compliant source
+    $ref: /schemas/types.yaml#/definitions/uint8
+    maximum: 7
+
+  charging-adapter-pdp-milliwatt:
+    description: This corresponds to the Power Delivery Profile rating of the
+      charging adapter shipped or recommended for use with the connector port.
+      This property is a requirement to infer the USB PD property
+      "SPR Sink Operational PDP" given in "6.5.13.14" of
+      "USB Power Delivery Specification Revision 3.1 Version 1.8".
+    minimum: 0
+    maximum: 100000
+
 dependencies:
   sink-vdos-v1: [ sink-vdos ]
   sink-vdos: [ sink-vdos-v1 ]
diff --git a/Documentation/devicetree/bindings/usb/maxim,max33359.yaml b/Documentation/devicetree/bindings/usb/maxim,max33359.yaml
index 3de4dc40b791..46a3748c8be4 100644
--- a/Documentation/devicetree/bindings/usb/maxim,max33359.yaml
+++ b/Documentation/devicetree/bindings/usb/maxim,max33359.yaml
@@ -75,6 +75,10 @@ examples:
                                        PDO_FIXED(9000, 2000, 0)>;
                 sink-bc12-completion-time-ms = <500>;
                 pd-revision = /bits/ 8 <0x03 0x01 0x01 0x08>;
+                sink-load-step = <150>;
+                sink-load-characteristics = /bits/ 16 <SINK_LOAD_CHAR(0, 1, 1, 2)>;
+                sink-compliance = /bits/ 8 <(COMPLIANCE_LPS | COMPLIANCE_PS1)>;
+                charging-adapter-pdp-milliwatt = <18000>;
             };
         };
     };
diff --git a/include/dt-bindings/usb/pd.h b/include/dt-bindings/usb/pd.h
index e6526b138174..6cff2339bda3 100644
--- a/include/dt-bindings/usb/pd.h
+++ b/include/dt-bindings/usb/pd.h
@@ -465,4 +465,22 @@
 	 | ((vbm) & 0x3) << 15 | (curr) << 14 | ((vbi) & 0x3f) << 7	\
 	 | ((gi) & 0x3f) << 1 | (ct))
 
+/*
+ * Sink Load Characteristics
+ * -------------------------
+ *  <15>    :: Can tolerate vbus voltage droop
+ *  <11:14> :: Duty cycle in 5% increments when bits 4:0 are non-zero
+ *  <10:5>  :: Overload period in 20ms when bits 4:0 are non-zero
+ *  <4:0>   :: Percent overload in 10% increments. Values higher than 25 are
+ *             clipped to 250%
+ */
+#define SINK_LOAD_CHAR(vdroop, duty_cycle, period, percent_ol)		\
+	(((vdroop) & 0x1) << 15 | ((duty_cycle) & 0xf) << 11 |		\
+	 ((period) & 0x3f) << 5 | ((percent_ol) & 0x1f))
+
+/* Compliance */
+#define COMPLIANCE_LPS		(1 << 0)
+#define COMPLIANCE_PS1		(1 << 1)
+#define COMPLIANCE_PS2		(1 << 2)
+
 #endif /* __DT_POWER_DELIVERY_H */

-- 
2.53.0.239.g8d8fc8a987-goog

