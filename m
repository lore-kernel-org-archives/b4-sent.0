From: Christoph Winklhofer <cj.winklhofer@gmail.com>
Date: Fri, 05 Jan 2024 09:26:43 +0100
Subject: [PATCH v3 2/3] dt-bindings: serial: allow onewire as child node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240105-w1-uart-v3-2-8687093b2e76@gmail.com>
References: <20240105-w1-uart-v3-0-8687093b2e76@gmail.com>
In-Reply-To: <20240105-w1-uart-v3-0-8687093b2e76@gmail.com>
To: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 Rob Herring <robh+dt@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Christoph Winklhofer <cj.winklhofer@gmail.com>, 
 Rob Herring <robh@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-serial@vger.kernel.org, linux-doc@vger.kernel.org
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1704443222; l=827;
 i=cj.winklhofer@gmail.com; s=20240104; h=from:subject:message-id;
 bh=BPcWb7esDB40/mUZFKo7VPDltCBO7/vmdkKQuHI4X3c=;
 b=ay2ffRxDQFeORRmb/dFUU1+2tmYdubWI25/2dywCsok6JsxpAOUY/+GGh2vft0EDpfYIOh9CZ
 BrLamM8Za7rBjBIbMVgBG0MBgYYvd6Pdyqxpvz1QltICXRCtXrP9SU1
X-Developer-Key: i=cj.winklhofer@gmail.com; a=ed25519;
 pk=lgjGjOt7hFKJT9UXhgUyrdthxvZ7DJ5F1U/7d9qdAsk=
X-Endpoint-Received: by B4 Relay for cj.winklhofer@gmail.com/20240104 with auth_id=111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The UART 1-Wire bus utilizes the Serial Device Bus to create the 1-wire
timing patterns.

Signed-off-by: Christoph Winklhofer <cj.winklhofer@gmail.com>
---
 Documentation/devicetree/bindings/serial/serial.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/serial/serial.yaml b/Documentation/devicetree/bindings/serial/serial.yaml
index 65804ca274ae..ffc9198ae214 100644
--- a/Documentation/devicetree/bindings/serial/serial.yaml
+++ b/Documentation/devicetree/bindings/serial/serial.yaml
@@ -88,7 +88,7 @@ properties:
       TX FIFO threshold configuration (in bytes).
 
 patternProperties:
-  "^(bluetooth|bluetooth-gnss|gnss|gps|mcu)$":
+  "^(bluetooth|bluetooth-gnss|gnss|gps|mcu|onewire)$":
     if:
       type: object
     then:

-- 
2.43.0

