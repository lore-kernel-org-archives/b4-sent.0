From: Long Zhao <longzhao@ambarella.com>
Date: Thu, 13 Aug 2026 18:35:12 +0800
Subject: [PATCH v3 1/2] dt-bindings: serial: snps-dw-apb-uart: add
 ambarella,cv75-uart
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-cv75-v3-c-v3-1-9352b3fd6026@ambarella.com>
References: <20260813-cv75-v3-c-v3-0-9352b3fd6026@ambarella.com>
In-Reply-To: <20260813-cv75-v3-c-v3-0-9352b3fd6026@ambarella.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 devicetree@vger.kernel.org, Long Zhao <longzhao@ambarella.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786617317; l=853;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=gkrEC2gJHozNyHLXYCYlviD2HquMAPSKys0NOMPGcf8=;
 b=AZcisJRhZUGKxnenk9hSf4dSjj4a9SPEam+Td5pDcvpq+1Om3XhHg36QrKL/dGVmgseF98WwH
 VI+dhge8ehnAEKWLHXFS4cGPLWlv46rEcKGM23fdMrycc2qIVnI3m9e
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Ambarella CV75 compatible string to the Synopsys DW APB UART
binding.

Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
 Documentation/devicetree/bindings/serial/snps-dw-apb-uart.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/serial/snps-dw-apb-uart.yaml b/Documentation/devicetree/bindings/serial/snps-dw-apb-uart.yaml
index 49f51b002879..cec5c679f1a9 100644
--- a/Documentation/devicetree/bindings/serial/snps-dw-apb-uart.yaml
+++ b/Documentation/devicetree/bindings/serial/snps-dw-apb-uart.yaml
@@ -51,6 +51,7 @@ properties:
           - const: renesas,rzn1-uart
       - items:
           - enum:
+              - ambarella,cv75-uart
               - anlogic,dr1v90-uart
               - brcm,bcm11351-dw-apb-uart
               - brcm,bcm21664-dw-apb-uart

-- 
2.34.1

