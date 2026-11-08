From: Nizat Mikayilli <nacht@dxdmail.cc>
Date: Sun, 08 Nov 2026 09:33:55 +0100
Subject: [PATCH 3/5] dt-bindings: input: samsung,s6sy761: Add ST FTS1BA90A
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-b4-s6sy761-fts1ba90a-v1-3-999b3cfaf82d@dxdmail.cc>
References: <20261108-b4-s6sy761-fts1ba90a-v1-0-999b3cfaf82d@dxdmail.cc>
In-Reply-To: <20261108-b4-s6sy761-fts1ba90a-v1-0-999b3cfaf82d@dxdmail.cc>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Henrik Rydberg <rydberg@bitmath.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andi Shyti <andi.shyti@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Nizat Mikayilli <nacht@dxdmail.cc>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794126835; l=1350;
 i=nacht@dxdmail.cc; s=20261004; h=from:subject:message-id;
 bh=Flhr418PQSRALX306tCmpNhdbdYHNpQZPYQ/lvdWiZk=;
 b=449RXd/PIhn0/o9lzW3zF9HBXchOZUIIIoH6vVPIsTM6PIDM/KlRN/4uCLczLKWpD4d7Q8kwQ
 h/s71c2adWGASBV+ss9hX4h4ahY24Z6BU3COhqciYyzp3lSxKeBsNAQ
X-Developer-Key: i=nacht@dxdmail.cc; a=ed25519;
 pk=Kay3P3pOJq5klUD+0/I8QX8JGOh0CeQXEwRVv7CMm4k=
X-Endpoint-Received: by B4 Relay for nacht@dxdmail.cc/20261004 with auth_id=1111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ST FTS1BA90A in the Samsung Galaxy Tab S9 Wi-Fi runs firmware that
speaks the S6SY761 protocol rather than the ones of st,stmfts and
st,stmfts5, and it has the same supplies as the S6SY761. Its event size
and some commands differ, so there is no fallback compatible.

Signed-off-by: Nizat Mikayilli <nacht@dxdmail.cc>
---
 .../devicetree/bindings/input/touchscreen/samsung,s6sy761.yaml      | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/input/touchscreen/samsung,s6sy761.yaml b/Documentation/devicetree/bindings/input/touchscreen/samsung,s6sy761.yaml
index 1ffd17af3c53..92d071852d71 100644
--- a/Documentation/devicetree/bindings/input/touchscreen/samsung,s6sy761.yaml
+++ b/Documentation/devicetree/bindings/input/touchscreen/samsung,s6sy761.yaml
@@ -4,7 +4,7 @@
 $id: http://devicetree.org/schemas/input/touchscreen/samsung,s6sy761.yaml#
 $schema: http://devicetree.org/meta-schemas/core.yaml#
 
-title: Samsung S6SY761 touchscreen controller
+title: Samsung S6SY761 and ST FTS1BA90A touchscreen controllers
 
 maintainers:
   - Andi Shyti <andi.shyti@kernel.org>
@@ -14,7 +14,9 @@ allOf:
 
 properties:
   compatible:
-    const: samsung,s6sy761
+    enum:
+      - samsung,s6sy761
+      - st,fts1ba90a
 
   reg:
     maxItems: 1

-- 
2.56.0

