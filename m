From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Tue, 13 Oct 2026 09:06:02 +0300
Subject: [PATCH v6 01/10] dt-bindings: vendor-prefixes: Add Securifi
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-b4-cs75xx-v6-1-37e8f3969b7c@gmail.com>
References: <20261013-b4-cs75xx-v6-0-37e8f3969b7c@gmail.com>
In-Reply-To: <20261013-b4-cs75xx-v6-0-37e8f3969b7c@gmail.com>
To: Arnd Bergmann <arnd@arndb.de>, Linus Walleij <linusw@kernel.org>, 
 Krzysztof Kozlowski <krzk@kernel.org>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Russell King <linux@armlinux.org.uk>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Drew Fustini <fustini@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 Jason Li <jason.li@cortina-access.com>, 
 Conor Dooley <conor.dooley@microchip.com>, 
 Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791871561; l=944;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=xgnzc7i7xTN4fotWpFnT0TA7w9z1wGvQ4nKXVlJT/zc=;
 b=yzkRYUQWI3fEO2TwyaICuILvVq8N3ONMeSHu6dBuJX+kA+9MeuYijqS+J99OE3f8CQOnliPb/
 A7UA9OmAWrRBN7i9sNF/C/3ccenoPVLXvfCjf2zQISIRZ4bfDVgmPjF
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Securifi Ltd. makes the Almond series of touchscreen Wi-Fi routers.
Add a vendor prefix for it.

Reviewed-by: Linus Walleij <linusw@kernel.org>
Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index 5ddeae3a6..71e6f82a7 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -1497,6 +1497,8 @@ patternProperties:
     description: SDMC Technology Co., Ltd
   "^seagate,.*":
     description: Seagate Technology PLC
+  "^securifi,.*":
+    description: Securifi Ltd.
   "^seeed,.*":
     description: Seeed Technology Co., Ltd
   "^seirobotics,.*":

-- 
2.53.0

