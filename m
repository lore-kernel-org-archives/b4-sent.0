From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Date: Thu, 23 Jul 2026 18:27:09 +0700
Subject: [PATCH 2/4] dt-bindings: input: edt-ft5x06 - add
 no-regmap-bulk-read property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-b4-ft5426-v1-2-d4b4e32be042@gmail.com>
References: <20260723-b4-ft5426-v1-0-d4b4e32be042@gmail.com>
In-Reply-To: <20260723-b4-ft5426-v1-0-d4b4e32be042@gmail.com>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Henrik Rydberg <rydberg@bitmath.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Alexandre Hamamdjian <azkali.limited@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784806028; l=1274;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=Y6plFHAdYOrN+v0JnPDtGVQB09ZIhxaAyZp05Rxn6xo=;
 b=AnFiHS16i0k014X7gtwrdF8LI0B2V9NUk/mHSujJOLMYi7m1cJkwgsUyo80cOMKx8UUiRXHlO
 Ize2/S5daARBtx4frDkwkgciyZdjEGpqSt3k7N+jRkMZ8plRr0v9Nk+
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document an optional boolean property for boards whose i2c controller
cannot reliably sustain the multi-byte block read of a full touch frame.
When set, the driver reads the frame one register at a time instead of in
a single bulk transfer.

Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
---
 .../devicetree/bindings/input/touchscreen/edt-ft5x06.yaml         | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml b/Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml
index 68b2f1601654..0d8310a290ea 100644
--- a/Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml
+++ b/Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml
@@ -111,6 +111,14 @@ properties:
 
   interrupt-controller: true
 
+  no-regmap-bulk-read:
+    type: boolean
+    description:
+      Set this when the i2c controller the touch controller is attached to
+      cannot reliably sustain the multi-byte block read of a full touch
+      frame and aborts long transfers. The driver then reads the touch
+      frame one register at a time instead of in a single bulk transfer.
+
 unevaluatedProperties: false
 
 required:

-- 
2.55.0

