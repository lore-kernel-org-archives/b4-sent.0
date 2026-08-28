From: Matt Eaton <linux@divinehawk.com>
Date: Fri, 28 Aug 2026 14:37:55 +0200
Subject: [PATCH 1/2] dt-bindings: usb: xhci: add xhci-no-soft-retry-quirk
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260828-xhci-no-soft-retry-v1-1-b9c264b56601@divinehawk.com>
References: <20260828-xhci-no-soft-retry-v1-0-b9c264b56601@divinehawk.com>
In-Reply-To: <20260828-xhci-no-soft-retry-v1-0-b9c264b56601@divinehawk.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Mathias Nyman <mathias.nyman@intel.com>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Matt Eaton <linux@divinehawk.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787920681; l=1049;
 i=linux@divinehawk.com; s=20260828; h=from:subject:message-id;
 bh=QfcjNB9WKVLLNE8Ksp+rel4ttvk1LueifZBC6xUC6/I=;
 b=7bkqOqUwaiqf0pG/quRnR30HZug1ImL+eIStoZTr1pcQwXeyvUthSfBuffaR840E25OSzpsnw
 aOM0yODmwLMDMVNflgrbnu9rjZYg34P5NU0Mv+NHuGC4grY6nzAXgo9
X-Developer-Key: i=linux@divinehawk.com; a=ed25519;
 pk=UG4KnKXGwxjTNdirUPh/nySblET4aRxWYWSMTQwzlMw=
X-Endpoint-Received: by B4 Relay for linux@divinehawk.com/20260828 with auth_id=982
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the xhci-no-soft-retry-quirk property, added in the
following patch.

snps,dwc3-common.yaml refs usb-xhci.yaml for every dr_mode other than
peripheral, so a host-mode dwc3 node inherits it and dt_binding_check
accepts it there.

Signed-off-by: Matt Eaton <linux@divinehawk.com>
---
 Documentation/devicetree/bindings/usb/usb-xhci.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/usb/usb-xhci.yaml b/Documentation/devicetree/bindings/usb/usb-xhci.yaml
index 4238ae896ef6..5d67a41658f7 100644
--- a/Documentation/devicetree/bindings/usb/usb-xhci.yaml
+++ b/Documentation/devicetree/bindings/usb/usb-xhci.yaml
@@ -25,6 +25,10 @@ properties:
     description: Set if the controller has broken port disable mechanism
     type: boolean
 
+  xhci-no-soft-retry-quirk:
+    description: Set if the controller cannot perform xHCI Soft Retry correctly
+    type: boolean
+
   imod-interval-ns:
     description: Interrupt moderation interval
     default: 5000

-- 
2.43.0

