From: Amit Sunil Dhamne <amitsd@google.com>
Date: Sat, 10 Oct 2026 01:37:37 +0000
Subject: [PATCH v2 1/2] dt-bindings: connector: Add time property for
 tSenderResponse
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-tcpm-sender-response-time-v2-1-67ea364a21d7@google.com>
References: <20261010-tcpm-sender-response-time-v2-0-67ea364a21d7@google.com>
In-Reply-To: <20261010-tcpm-sender-response-time-v2-0-67ea364a21d7@google.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, RD Babiera <rdbabiera@google.com>, 
 Kyle Tso <kyletso@google.com>, Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791596277; l=3123;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=FL1PG6Q8jNcDKHxKV05v81lJ0z959GjQmYchXFifxbA=;
 b=JkSV9DUT2Ao6dhQnVTsmooSFEYzmlk6TZ05+S26KNp+VchDzCNfPsdjek40eTiHK3srSNHl9F
 PGIrFhfMlfbAgzyJGL2IgEAFvzL4LtyctvnRNvYMMftOKbF5rlZBdZy
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the sender-response-time-ms property to allow platforms to specify
the tSenderResponse timer value, i.e. the max time a port waits for the
port partner to respond to a message that requires a response.

As per the PD specifications, the tSenderResponse values are:

+--------+----------+----------+
| Spec   | Min (ms) | Max (ms) |
+--------+----------+----------+
| PD 2.0 | 24       | 30       |
| PD 3.2 | 27       | 33       |
+--------+----------+----------+

Set the minimum value to 24 ms (the lowest minimum across the PD
specifications). Both the default and maximum values are intentionally
relaxed to 60 ms to maintain interoperability with slower port partners,
while allowing platforms to configure stricter spec-compliant timeouts.

Also update the max33359 example to showcase the new property.

Assisted-by: LLM
Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
Reviewed-by: Badhri Jagan Sridharan <badhri@google.com>
---
 .../devicetree/bindings/connector/usb-connector.yaml         | 12 ++++++++++++
 Documentation/devicetree/bindings/usb/maxim,max33359.yaml    |  1 +
 2 files changed, 13 insertions(+)

diff --git a/Documentation/devicetree/bindings/connector/usb-connector.yaml b/Documentation/devicetree/bindings/connector/usb-connector.yaml
index 8ca0292490a2c..272181e375694 100644
--- a/Documentation/devicetree/bindings/connector/usb-connector.yaml
+++ b/Documentation/devicetree/bindings/connector/usb-connector.yaml
@@ -283,6 +283,18 @@ properties:
     maximum: 200
     default: 200
 
+  sender-response-time-ms:
+    description: Represents the max time in ms that a Type-C port waits for
+      the port partner to respond to a message that requires a response. This
+      timer starts when the port's PHY layer receives the last bit of the
+      GoodCRC EOP corresponding to the message requiring a response. This timer
+      stops when the last bit of the EOP of the expected response message is
+      received by the PHY layer. A timeout leads to a soft or hard reset by the
+      port.
+    minimum: 24
+    maximum: 60
+    default: 60
+
   sink-bc12-completion-time-ms:
     description: Represents the max time in ms that a port in sink role takes
       to complete Battery Charger (BC1.2) Detection. BC1.2 detection is a
diff --git a/Documentation/devicetree/bindings/usb/maxim,max33359.yaml b/Documentation/devicetree/bindings/usb/maxim,max33359.yaml
index 003c0b7130688..61d8fc6607032 100644
--- a/Documentation/devicetree/bindings/usb/maxim,max33359.yaml
+++ b/Documentation/devicetree/bindings/usb/maxim,max33359.yaml
@@ -78,6 +78,7 @@ examples:
                                        PDO_FIXED_DUAL_ROLE)
                                        PDO_FIXED(9000, 2000, 0)>;
                 sink-bc12-completion-time-ms = <500>;
+                sender-response-time-ms = <29>;
                 pd-revision = /bits/ 8 <0x03 0x01 0x01 0x08>;
                 sink-load-step = <150>;
                 sink-load-characteristics = /bits/ 16 <SINK_LOAD_CHAR(0, 1, 1, 2)>;

-- 
2.56.0.385.gd3acb90ef8-goog

