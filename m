From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Mon, 17 Mar 2025 15:16:55 +0800
Subject: [PATCH 4/7] dt-bindings: serial: amlogic,meson-uart: Add
 compatible string for S6/S7/S7D
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250317-s6-s7-basic-v1-4-d653384e41f3@amlogic.com>
References: <20250317-s6-s7-basic-v1-0-d653384e41f3@amlogic.com>
In-Reply-To: <20250317-s6-s7-basic-v1-0-d653384e41f3@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-serial@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742195812; l=995;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=8tWndSz2wgG4AKPpBkmzvXgp+1cbCi/8NB7D0Mgsh2s=;
 b=oGCmPQDQlNKAJdrYHGunPq9vAAqeWtaF/57Ac1nzwBMiRecNx7K5knkP/r7VuG6g1CavemmhE
 s6r9Mv9O4g6CvZVdRwyi7GI4Y+Y8Th7g2vtT8rIXbQA5R59TNBzWjGM
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Amlogic S6/S7/7D SoCs uses the same UART controller as S4 SoCs and G12A.
There is no need for an extra compatible line in the driver, but
add S6/S7/S7D compatible line for documentation.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 Documentation/devicetree/bindings/serial/amlogic,meson-uart.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/serial/amlogic,meson-uart.yaml b/Documentation/devicetree/bindings/serial/amlogic,meson-uart.yaml
index 0565fb7649c5..d8ad1bb6172d 100644
--- a/Documentation/devicetree/bindings/serial/amlogic,meson-uart.yaml
+++ b/Documentation/devicetree/bindings/serial/amlogic,meson-uart.yaml
@@ -56,6 +56,9 @@ properties:
         items:
           - enum:
               - amlogic,a4-uart
+              - amlogic,s6-uart
+              - amlogic,s7-uart
+              - amlogic,s7d-uart
               - amlogic,t7-uart
           - const: amlogic,meson-s4-uart
 

-- 
2.37.1

