From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:20:06 +0000
Subject: [PATCH 1/4] dt-bindings: usb: generic-ehci: Allow describing the
 root hub ports
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-usb-port-pairing-v1-1-9307e29d2ed2@gmail.com>
References: <20261110-usb-port-pairing-v1-0-9307e29d2ed2@gmail.com>
In-Reply-To: <20261110-usb-port-pairing-v1-0-9307e29d2ed2@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Alan Stern <stern@rowland.harvard.edu>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295206; l=1701;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=XJm2p3cBaQH7CQW9BFwWeXyIaL1TnsEG5XYxo2DdPHY=;
 b=Z49FAgk/mtw577IjyyCSPTGHpreFuxeB4B4vjpWfaQWB5Atdm9uqD8p9EESPkon+PAAAw5EcB
 3em7S98g/2ED+rXTPW9X7btWvyF4foVvaC0EaT/g/Za/sHFcj8Ps3Rj
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The USB 2.0 lines and the SuperSpeed lanes of a USB 3 connector don't
always reach the same host controller. On the Rockchip RK3588, the
SuperSpeed-only USB 3.0 host 2 (xHCI) is paired on the board with one
of the separate USB 2.0 hosts (EHCI/OHCI). Only the device tree knows
which EHCI root hub port shares a connector with which SuperSpeed port.

The USB core already reads a hub's OF graph, with one graph port per
downstream port, and uses it for the port connect type. Allow the same
"ports" node on EHCI controllers, so that a root hub port can be linked
to its usb-connector node.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 Documentation/devicetree/bindings/usb/generic-ehci.yaml | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/Documentation/devicetree/bindings/usb/generic-ehci.yaml b/Documentation/devicetree/bindings/usb/generic-ehci.yaml
index 908b02d9175e..9dcba539d60d 100644
--- a/Documentation/devicetree/bindings/usb/generic-ehci.yaml
+++ b/Documentation/devicetree/bindings/usb/generic-ehci.yaml
@@ -160,6 +160,19 @@ properties:
       - host
       - otg
 
+  ports:
+    $ref: /schemas/graph.yaml#/properties/ports
+    description:
+      The root hub's downstream facing ports, linked to the connectors they
+      are wired to. Needed when a connector's SuperSpeed lanes go to a
+      different host controller, which then pairs with the root hub port
+      through the connector.
+
+    patternProperties:
+      "^port@[1-9a-f][0-9a-f]*$":
+        $ref: /schemas/graph.yaml#/properties/port
+        description: Root hub port, numbered from 1.
+
 required:
   - compatible
   - reg

-- 
2.55.0

