From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Date: Mon, 11 May 2026 01:32:11 +0700
Subject: [PATCH v2 3/3] dt-bindings: usb: fix properties type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-bm92t-v2-3-2145e4f4386b@gmail.com>
References: <20260511-bm92t-v2-0-2145e4f4386b@gmail.com>
In-Reply-To: <20260511-bm92t-v2-0-2145e4f4386b@gmail.com>
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, CTCaer <ctcaer@gmail.com>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778437929; l=1431;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=f6S7QyZFwXdvy107/0JuOsiYe2d8g5NArKl85IO4QKI=;
 b=O/UffyUVHLFM26VSXF5Zp+aE56RyfVdIa/jgYJcrbUqlGu++fkJ0xLl/UxnwKzK1bQIGhIPYe
 V129Ye44sBvCh/ygmhB+DZ6bA7tclX+LNEgVwRuT/wef1GVqPXdlR3V
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rohm,pd-5v-current-limit-ma, rohm,pd-9v-current-limit-ma,
rohm,pd-12v-current-limit-ma, rohm,pd-15v-current-limit-ma
where missing type, add appropriate uint32 type

Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
---
 Documentation/devicetree/bindings/usb/rohm,bm92t.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/usb/rohm,bm92t.yaml b/Documentation/devicetree/bindings/usb/rohm,bm92t.yaml
index 007f70a8f5bb..6ee6ddcdca7a 100644
--- a/Documentation/devicetree/bindings/usb/rohm,bm92t.yaml
+++ b/Documentation/devicetree/bindings/usb/rohm,bm92t.yaml
@@ -71,15 +71,19 @@ properties:
       Disable the lower power limit applied when a dock is detected.
 
   rohm,pd-5v-current-limit-ma:
+    $ref: /schemas/types.yaml#/definitions/uint32
     description: Charging current limit in mA when 5V PD contract is active.
 
   rohm,pd-9v-current-limit-ma:
+    $ref: /schemas/types.yaml#/definitions/uint32
     description: Charging current limit in mA when 9V PD contract is active.
 
   rohm,pd-12v-current-limit-ma:
+    $ref: /schemas/types.yaml#/definitions/uint32
     description: Charging current limit in mA when 12V PD contract is active.
 
   rohm,pd-15v-current-limit-ma:
+    $ref: /schemas/types.yaml#/definitions/uint32
     description: Charging current limit in mA when 15V PD contract is active.
 
   port:

-- 
2.54.0

