From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Mon, 16 Nov 2026 01:50:35 +0530
Subject: [PATCH] dt-bindings: usb: snps,dwc3-common: Document usb-psy-name
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-vantage-dwc3-v1-1-6abb5a3277f0@yahoo.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMOwqAMBBF0a3I1AacBCzciljEyahjESXxB5K9G
 7U8D969IXIQjtAUNwQ+JMriM7AsgCbrR1biskFXukbEWh3WbzbP7iSjmIj0gNo4Q5Ava+BBri/
 Xdr/j3s9M29uAlB7/7r8rcAAAAA==
X-Change-ID: 20261116-vantage-dwc3-eccc2f123d3c
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Felipe Balbi <balbi@kernel.org>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794774034; l=1726;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=J0DuQqzHD83Tdoof2dhWur/dO95GQ6Otkr6u2afsZJs=;
 b=EW5L7/7wwp0Wa1rB+7mM5/7XBOUyZYFVvDwHdd2giW9vuobWkyuG9WmQCARjAtIcWheeu7Aeh
 guDmXGWHGcbBd+cYJ83HvhY5CLmDq6rTmqKZF1SoZhUAkPS9/3idKs2
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The dwc3 driver reads usb-psy-name since commit 6f0764b5adea ("usb: dwc3:
add a power supply for current control") to tell a power supply the
current the USB host grants, but the property was never documented.

An LLM was used to help write this commit message.

Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
The dwc3 driver has read usb-psy-name for a long time, but the property
was never documented. The Motorola Signature uses it to tell the
qcom_battmgr USB power supply the current the host grants.

Checked with dt_binding_check and with dtbs_check on the Motorola
Signature devicetree, which sets the property.

I used an LLM (Claude) to help write this patch and its commit message.
I reviewed it.
---
 Documentation/devicetree/bindings/usb/snps,dwc3-common.yaml | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/Documentation/devicetree/bindings/usb/snps,dwc3-common.yaml b/Documentation/devicetree/bindings/usb/snps,dwc3-common.yaml
index 6c0b8b653824..5d46db402f93 100644
--- a/Documentation/devicetree/bindings/usb/snps,dwc3-common.yaml
+++ b/Documentation/devicetree/bindings/usb/snps,dwc3-common.yaml
@@ -42,6 +42,13 @@ properties:
     minItems: 1
     maxItems: 19
 
+  usb-psy-name:
+    $ref: /schemas/types.yaml#/definitions/string
+    description:
+      Name of the power supply that is told the current the USB host
+      grants to the device (e.g. after enumeration), so the charger can
+      draw it.
+
   phy-names:
     minItems: 1
     maxItems: 19

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261116-vantage-dwc3-eccc2f123d3c

Best regards,
--  
Venkat Yadlapati <venkat.yadlapati@yahoo.com>

