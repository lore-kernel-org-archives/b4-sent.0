From: Akshat Singh <automobilehacks@gmail.com>
Date: Sun, 15 Nov 2026 19:26:01 +0000
Subject: [PATCH 1/3] dt-bindings: interrupt-controller:
 econet,en751221-intc: Allow up to 6 parent interrupts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-en751221-intc-all-lines-v1-1-dc03a40f47f0@gmail.com>
References: <20261115-en751221-intc-all-lines-v1-0-dc03a40f47f0@gmail.com>
In-Reply-To: <20261115-en751221-intc-all-lines-v1-0-dc03a40f47f0@gmail.com>
To: Caleb James DeLisle <cjd@cjdns.fr>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thomas Bogendoerfer <tsbogend@alpha.franken.de>
Cc: linux-mips@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Akshat Singh <automobilehacks@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794770761; l=1607;
 i=automobilehacks@gmail.com; s=20261115; h=from:subject:message-id;
 bh=Q16SqUnJq9TZKzQktewafiPW/Xjzjt1HWd82Q/C9cGI=;
 b=0C9XBuX/ItvzSfYec1R10aS9mPoOqWbTmhE7Xy98VI55aKqu/mh7vLYTTy4wrifi4UWVaMqo6
 EZZyS3HKfq+CulMHDanTxAozywwwbuwR4Fbk6vp4jlZaxY+xlP4gQZ6
X-Developer-Key: i=automobilehacks@gmail.com; a=ed25519;
 pk=wYmYXn6wy/XN0edTCg6D7UtE9nYLei8mbfqydGGCdf4=
X-Endpoint-Received: by B4 Relay for automobilehacks@gmail.com/20261115 with auth_id=1535
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The controller is not connected to its parent through a single
interrupt line: it presents the number of the pending interrupt plus
one, in binary, on the CPU interrupt lines IP2-IP7. A CPU in VEIC mode
takes that number as the vector, but without VEIC each line is a
separate interrupt, and the controller has to be chained to all the
lines that can carry it.

Allow listing up to six parent interrupts, one per line.

Signed-off-by: Akshat Singh <automobilehacks@gmail.com>
---
 .../bindings/interrupt-controller/econet,en751221-intc.yaml      | 9 +++++++--
 1 file changed, 7 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/interrupt-controller/econet,en751221-intc.yaml b/Documentation/devicetree/bindings/interrupt-controller/econet,en751221-intc.yaml
index 44c09785e..098fdeaa3 100644
--- a/Documentation/devicetree/bindings/interrupt-controller/econet,en751221-intc.yaml
+++ b/Documentation/devicetree/bindings/interrupt-controller/econet,en751221-intc.yaml
@@ -34,8 +34,13 @@ properties:
   interrupt-controller: true
 
   interrupts:
-    maxItems: 1
-    description: Interrupt line connecting this controller to its parent.
+    minItems: 1
+    maxItems: 6
+    description:
+      CPU interrupt lines connecting this controller to its parent. The
+      controller presents the number of the pending interrupt plus one, in
+      binary, on the CPU interrupt lines IP2-IP7, so it can be connected to
+      up to six of them.
 
   econet,shadow-interrupts:
     $ref: /schemas/types.yaml#/definitions/uint32-matrix

-- 
2.43.0

