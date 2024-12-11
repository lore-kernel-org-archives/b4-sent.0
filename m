From: Amit Sunil Dhamne <amitsd@google.com>
Date: Tue, 10 Dec 2024 19:07:07 -0800
Subject: [PATCH v2 1/3] dt-bindings: connector: Add pd-revision property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241210-get_rev_upstream-v2-1-d0094e52d48f@google.com>
References: <20241210-get_rev_upstream-v2-0-d0094e52d48f@google.com>
In-Reply-To: <20241210-get_rev_upstream-v2-0-d0094e52d48f@google.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>
Cc: Kyle Tso <kyletso@google.com>, RD Babiera <rdbabiera@google.com>, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733886444; l=1976;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=B8pzC6JyPb6d6J2y5c3NtirTYdP4wbp3vA4FOkKh+8Y=;
 b=x6OZql4uZejwU/PoFmWILQjDk19x2cbxV0bPjxctWOr7XEGzX1u12+ILPURCy5+sFV7jj7vCv
 vnhoNyv95QGBZ0GGeB4+xHtcFQ0X6Qer+HaGrjl9y1qJDjVRGE2qCbM
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add pd-revision property definition, to specify the maximum Power
Delivery Revision and Version supported by the connector.

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
---
 Documentation/devicetree/bindings/connector/usb-connector.yaml | 7 +++++++
 Documentation/devicetree/bindings/usb/maxim,max33359.yaml      | 1 +
 2 files changed, 8 insertions(+)

diff --git a/Documentation/devicetree/bindings/connector/usb-connector.yaml b/Documentation/devicetree/bindings/connector/usb-connector.yaml
index 67700440e23b5b7ca0db2c395c8a455bcf650864..11e40d225b9f3a0d0aeea7bf764f1c00a719d615 100644
--- a/Documentation/devicetree/bindings/connector/usb-connector.yaml
+++ b/Documentation/devicetree/bindings/connector/usb-connector.yaml
@@ -293,6 +293,13 @@ properties:
       PD negotiation till BC1.2 detection completes.
     default: 0
 
+  pd-revision:
+    description: Specifies the maximum USB PD revision and version supported by
+      the connector. This property is specified in the following order;
+      <revision_major, revision_minor, version_major, version_minor>.
+    $ref: /schemas/types.yaml#/definitions/uint8-array
+    maxItems: 4
+
 dependencies:
   sink-vdos-v1: [ sink-vdos ]
   sink-vdos: [ sink-vdos-v1 ]
diff --git a/Documentation/devicetree/bindings/usb/maxim,max33359.yaml b/Documentation/devicetree/bindings/usb/maxim,max33359.yaml
index 20b62228371bdedf2fe92767ffe443bec87babc5..350d39fbf2dcd4d99db07cb8f099467e6fc653ee 100644
--- a/Documentation/devicetree/bindings/usb/maxim,max33359.yaml
+++ b/Documentation/devicetree/bindings/usb/maxim,max33359.yaml
@@ -70,6 +70,7 @@ examples:
                                        PDO_FIXED_DUAL_ROLE)
                                        PDO_FIXED(9000, 2000, 0)>;
                 sink-bc12-completion-time-ms = <500>;
+                pd-revision = /bits/ 8 <0x03 0x01 0x01 0x08>;
             };
         };
     };

-- 
2.47.0.338.g60cca15819-goog

