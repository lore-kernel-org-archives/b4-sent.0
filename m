From: Jia Wang <wangjia@ultrarisc.com>
Date: Mon, 16 Mar 2026 14:33:22 +0800
Subject: [PATCH v2 1/2] dt-bindings: serial: update bindings of ultrarisc
 dp1000 uart
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260316-ultrarisc-serial-v2-1-6ab3e7fa891c@ultrarisc.com>
References: <20260316-ultrarisc-serial-v2-0-6ab3e7fa891c@ultrarisc.com>
In-Reply-To: <20260316-ultrarisc-serial-v2-0-6ab3e7fa891c@ultrarisc.com>
To: =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 linux-riscv@lists.infradead.org, devicetree@vger.kernel.org, 
 Jia Wang <wangjia@ultrarisc.com>, Yao Zi <me@ziyao.cc>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773642814; l=830;
 i=wangjia@ultrarisc.com; s=20260309; h=from:subject:message-id;
 bh=jeAzNqfdfA35qeisKPZc2pOi87g/Zrhmu+g6GMmMbgw=;
 b=21UIh673o/8ZBIrk9WQvOzWy5rDlgKN+9PWKeDlBEnyynB2e84xnm6/RpcozinoFCvkcsVQKl
 VXF0KQqFk1UCubU68eRC6OJ3+3QNQB9HA2mZJ6rPWp0HVUcrV9B82ml
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=XvYkrelqJIIzobY7j+nIg8rsfv5kzaOzuc1UPhd087U=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260309 with auth_id=682
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add DP1000 UART compatible information

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
Reviewed-by: Yao Zi <me@ziyao.cc>
---
 Documentation/devicetree/bindings/serial/snps-dw-apb-uart.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/serial/snps-dw-apb-uart.yaml b/Documentation/devicetree/bindings/serial/snps-dw-apb-uart.yaml
index 6efe43089a74..0040ed28e35b 100644
--- a/Documentation/devicetree/bindings/serial/snps-dw-apb-uart.yaml
+++ b/Documentation/devicetree/bindings/serial/snps-dw-apb-uart.yaml
@@ -78,6 +78,8 @@ properties:
               - starfive,jh7100-uart
               - starfive,jh7110-uart
           - const: snps,dw-apb-uart
+      - items:
+          - const: ultrarisc,dp1000-uart
       - const: snps,dw-apb-uart
 
   reg:

-- 
2.34.1

