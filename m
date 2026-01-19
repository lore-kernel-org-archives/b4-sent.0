From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Date: Mon, 19 Jan 2026 07:06:22 +0000
Subject: [PATCH v3 1/3] spi: dt-bindings: xilinx: make interrupts optional
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260119-spi-xilinx-v3-1-4566c33bac0d@nexthop.ai>
References: <20260119-spi-xilinx-v3-0-4566c33bac0d@nexthop.ai>
In-Reply-To: <20260119-spi-xilinx-v3-0-4566c33bac0d@nexthop.ai>
To: Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Michal Simek <michal.simek@amd.com>
Cc: linux-spi@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768806393; l=837;
 i=abdurrahman@nexthop.ai; s=20260119; h=from:subject:message-id;
 bh=Rbmi4yji+D6yvwIqXdPoR0dJO1NzfG8jvbb3qwJR8Ss=;
 b=JQle1H+it+z7PYjip62TbpkcvzOoAbHLCXfpWxiR0e3EWzfcdXFENf+yN80RvCghBvCtGnzxy
 TNfS8lYEYh6BSevl/AA3QWQj6Fdsc6TRsq6Fcygb9T9ypG0L823enW0
X-Developer-Key: i=abdurrahman@nexthop.ai; a=ed25519;
 pk=S+ysnf+NwMcBdHBlyKIUEAtaFGSIhQwcJcgcXhq0osg=
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/20260119 with auth_id=608
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Both the hardware and driver already support polling mode. By removing
the mandatory IRQ requirement during probe, the driver can now fall
back to polling when an interrupt is unavailable, ensuring
compatibility with a wider range of systems.

Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
 Documentation/devicetree/bindings/spi/spi-xilinx.yaml | 1 -
 1 file changed, 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/spi/spi-xilinx.yaml b/Documentation/devicetree/bindings/spi/spi-xilinx.yaml
index 4beb3af0416d..24e62530d432 100644
--- a/Documentation/devicetree/bindings/spi/spi-xilinx.yaml
+++ b/Documentation/devicetree/bindings/spi/spi-xilinx.yaml
@@ -38,7 +38,6 @@ properties:
 required:
   - compatible
   - reg
-  - interrupts
 
 unevaluatedProperties: false
 

-- 
2.52.0

