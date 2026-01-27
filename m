From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Date: Tue, 27 Jan 2026 21:03:55 +0000
Subject: [PATCH v6 1/7] dt-bindings: i2c: xiic: make clocks optional
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260127-i2c-xiic-v6-1-e82e2f6f657c@nexthop.ai>
References: <20260127-i2c-xiic-v6-0-e82e2f6f657c@nexthop.ai>
In-Reply-To: <20260127-i2c-xiic-v6-0-e82e2f6f657c@nexthop.ai>
To: Michal Simek <michal.simek@amd.com>, Andi Shyti <andi.shyti@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, info@mocean-labs.com
Cc: Andy Shevchenko <andriy.shevchenko@intel.com>, 
 linux-arm-kernel@lists.infradead.org, linux-i2c@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769547843; l=759;
 i=abdurrahman@nexthop.ai; s=20260119; h=from:subject:message-id;
 bh=Jp8L32rGkddXyWP1kCRtOWV6Txgpa0+B9TbjL9V4o78=;
 b=u1JsuQG6Ngsrd05YJZA+2pdIjEIfAGdmj2WXnu48Z6ITIo+Hh2iL+m05kDLxkG7cwOBA1vGBk
 I6GaIzZE4xDDKR18UK7oEOuDBzvE3o8QBxTX0ojRs1UnNdigFm7Llq4
X-Developer-Key: i=abdurrahman@nexthop.ai; a=ed25519;
 pk=S+ysnf+NwMcBdHBlyKIUEAtaFGSIhQwcJcgcXhq0osg=
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/20260119 with auth_id=608
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The xiic driver is designed to operate without explicit clock configuration
when clocks are not specified in the firmware.

Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
 Documentation/devicetree/bindings/i2c/xlnx,xps-iic-2.00.a.yaml | 1 -
 1 file changed, 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/i2c/xlnx,xps-iic-2.00.a.yaml b/Documentation/devicetree/bindings/i2c/xlnx,xps-iic-2.00.a.yaml
index 658ae92fa86d..cc500130f41f 100644
--- a/Documentation/devicetree/bindings/i2c/xlnx,xps-iic-2.00.a.yaml
+++ b/Documentation/devicetree/bindings/i2c/xlnx,xps-iic-2.00.a.yaml
@@ -43,7 +43,6 @@ required:
   - compatible
   - reg
   - interrupts
-  - clocks
 
 unevaluatedProperties: false
 

-- 
2.52.0

