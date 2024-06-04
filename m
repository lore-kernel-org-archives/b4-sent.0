From: Arthur Becker <arthur.becker@sentec.com>
Date: Tue, 04 Jun 2024 10:01:49 +0200
Subject: [PATCH v4 2/2] dt-bindings: iio: light: add VEML6040 RGBW-LS
 bindings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240604-veml6040-v4-2-5a4d59597874@sentec.com>
References: <20240604-veml6040-v4-0-5a4d59597874@sentec.com>
In-Reply-To: <20240604-veml6040-v4-0-5a4d59597874@sentec.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Javier Carrasco <javier.carrasco.cruz@gmail.com>
Cc: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, Arthur Becker <arthur.becker@sentec.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717488152; l=1386;
 i=arthur.becker@sentec.com; s=20240521; h=from:subject:message-id;
 bh=9rThcOFRJ7S93FIcWQdT1WZcQC1aM2qApoy4vlBF7hQ=;
 b=PKV/u4sIgobPlvHwj85thig13uPd1GBIwDqppFBW6emJDJc/6HgwmfVpHTjRCSIN70jmssdFs
 7kIUXj6e76ZC6AoGcZwQnzr7TZKHt99qjBf/7cr0h3VFSVrPiuGxdPA
X-Developer-Key: i=arthur.becker@sentec.com; a=ed25519;
 pk=1GLsDBF6GZKt9oNFsvdnAB6sHyKKrSISlwM3AyWbx/k=
X-Endpoint-Received: by B4 Relay for arthur.becker@sentec.com/20240521 with auth_id=163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Device tree bindings for the vishay VEML6040 RGBW light sensor iio
driver

Signed-off-by: Arthur Becker <arthur.becker@sentec.com>
---
V1 -> V3: Addressed review comments (v1 of the dt-bindings was sent
along with v2 of the driver but not in a set)
V3 -> V4: Combined dt-binding with veml6075 as they are basically the
same
---
 Documentation/devicetree/bindings/iio/light/vishay,veml6075.yaml | 9 +++++++--
 1 file changed, 7 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/iio/light/vishay,veml6075.yaml b/Documentation/devicetree/bindings/iio/light/vishay,veml6075.yaml
index 91c318746bf3..ecf2339e02f6 100644
--- a/Documentation/devicetree/bindings/iio/light/vishay,veml6075.yaml
+++ b/Documentation/devicetree/bindings/iio/light/vishay,veml6075.yaml
@@ -4,14 +4,19 @@
 $id: http://devicetree.org/schemas/iio/light/vishay,veml6075.yaml#
 $schema: http://devicetree.org/meta-schemas/core.yaml#
 
-title: Vishay VEML6075 UVA and UVB sensor
+title: Vishay VEML6075 UVA/B and VEML6040 RGBW sensors
 
 maintainers:
   - Javier Carrasco <javier.carrasco.cruz@gmail.com>
 
+description:
+  VEML6040 datasheet at https://www.vishay.com/docs/84276/veml6040.pdf
+
 properties:
   compatible:
-    const: vishay,veml6075
+    enum:
+      - vishay,veml6040
+      - vishay,veml6075
 
   reg:
     maxItems: 1

-- 
2.34.1

