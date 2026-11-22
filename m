From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Mon, 23 Nov 2026 00:50:18 +0530
Subject: [PATCH v2] dt-bindings: usb: snps,dwc3-common: Document
 usb-psy-name
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-vantage-dwc3-v2-1-2e741a834411@yahoo.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNwQ7CIBBEf6XZs5guRJp48j9MD3S7tZhYDCDaN
 Py7UM8e32TmzQaBveUA52YDz8kG65YC8tAAzWa5sbBjYZCt1IioRTJLNCUe36QEE5GcUKpREZT
 J0/NkP7vu2v84vIY7U6yO2phtiM6v+1/C2vujTihQaDMMJ6Nk103tZTWzc0dyD+hzzl+j2yrnu
 gAAAA==
X-Change-ID: 20261116-vantage-dwc3-eccc2f123d3c
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Felipe Balbi <balbi@kernel.org>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795375217; l=2646;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=UVWhSLAPePZ8e1Iapxx51B9VAvYDZtSIXNZrGl1F++A=;
 b=LjXwV7r79U8KqLx/vldf3Mc/6A/BgjP6EzZ6jS8G5dTdt4sOEiNqEnmS/Ui+hP5aYL2bg3XyZ
 05OKvisLHdHBFh5IqFbzVln+XVooaG1+C1lpR4/ExGWW6ZwD7/OIikM
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The dwc3 driver reads usb-psy-name since commit 6f0764b5adea ("usb: dwc3:
add a power supply for current control") to tell a power supply the
current the USB host grants, but the property was never documented.

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
Changes in v2:
- Drop the Assisted-by trailers and the LLM notes from the commit
  messages, the LLM use is stated in this cover letter.
- Move usb-psy-name after phy-names, it split the phys/phy-names pair
  (Sashiko).
- Sashiko also asked whether a power supply name belongs in the binding
  rather than a phandle. The property is not new: dwc3 has read it since
  commit 6f0764b5adea ("usb: dwc3: add a power supply for current
  control") and this only documents it. A phandle based description
  would need a new dwc3 interface; I am happy to do that instead if it
  is preferred. Its other point, that qcom_battmgr cannot take the
  limit, no longer holds since commit be5e7367bceb ("power: supply:
  qcom_battmgr: Allow setting the USB input current limit").
- Link to v1: https://patch.msgid.link/20261116-vantage-dwc3-v1-1-6abb5a3277f0@yahoo.com
---
 Documentation/devicetree/bindings/usb/snps,dwc3-common.yaml | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/Documentation/devicetree/bindings/usb/snps,dwc3-common.yaml b/Documentation/devicetree/bindings/usb/snps,dwc3-common.yaml
index 6c0b8b653824..41e8537b34d5 100644
--- a/Documentation/devicetree/bindings/usb/snps,dwc3-common.yaml
+++ b/Documentation/devicetree/bindings/usb/snps,dwc3-common.yaml
@@ -51,6 +51,13 @@ properties:
       - items:
           pattern: "^usb(2-([0-9]|1[0-4])|3-[0-3])$"
 
+  usb-psy-name:
+    $ref: /schemas/types.yaml#/definitions/string
+    description:
+      Name of the power supply that is told the current the USB host
+      grants to the device (e.g. after enumeration), so the charger can
+      draw it.
+
   snps,usb2-lpm-disable:
     description: Indicate if we don't want to enable USB2 HW LPM for host
       mode.

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261116-vantage-dwc3-eccc2f123d3c

Best regards,
--  
Venkat Yadlapati <venkat.yadlapati@yahoo.com>

