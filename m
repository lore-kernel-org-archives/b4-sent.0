From: Paul Sajna <sajattack@postmarketos.org>
Date: Thu, 12 Nov 2026 14:22:56 -0700
Subject: [PATCH v5 1/3] dt-bindings: leds: aw2013: Add awinic,aw2027
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-aw2013-aw20xx-rename-v5-1-b2c5e323a90a@postmarketos.org>
References: <20261112-aw2013-aw20xx-rename-v5-0-b2c5e323a90a@postmarketos.org>
In-Reply-To: <20261112-aw2013-aw20xx-rename-v5-0-b2c5e323a90a@postmarketos.org>
To: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Nikita Travkin <nikitos.tr@gmail.com>, 
 Alexey Min <alexeymin@minlexx.ru>, David Heidelberg <david@ixit.cz>, 
 Griffin Kroah-Hartman <griffin@kroah.com>
Cc: Nikita Travkin <nikita@trvn.ru>, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 Paul Sajna <sajattack@postmarketos.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794518585; l=1313;
 i=sajattack@postmarketos.org; s=20250413; h=from:subject:message-id;
 bh=w/6qEc2cwOI6T/xUHNJh3OifoyGO3FRpW1FATx28UoM=;
 b=+n/fssUtnahXhwLA+TPDYrveXzn8paom4T2+5PLDQVoY9xyEsemgj/xnn0qVXDlP7Xgx2FUhU
 zAlRVX5yur/DiRAHYwoRU8Lvh4alLFhycVIX0RftSO2fgXLOIvuU7j5
X-Developer-Key: i=sajattack@postmarketos.org; a=ed25519;
 pk=ZFE/UBqiz9Wr8b+zBL27opOjw5x5ket5JFqks/VQGeM=
X-Endpoint-Received: by B4 Relay for sajattack@postmarketos.org/20250413 with auth_id=1505
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The aw2027 is largely the same as the aw2013, with the
exception of the way the max current is written to registers.
This exception makes it different enough to not work without
driver modifications, but similar enough to fall under the
umbrella of the same driver.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Paul Sajna <sajattack@postmarketos.org>
---
 Documentation/devicetree/bindings/leds/leds-aw2013.yaml | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/leds/leds-aw2013.yaml b/Documentation/devicetree/bindings/leds/leds-aw2013.yaml
index 26238446f2bd..1ad165cfe34a 100644
--- a/Documentation/devicetree/bindings/leds/leds-aw2013.yaml
+++ b/Documentation/devicetree/bindings/leds/leds-aw2013.yaml
@@ -4,7 +4,7 @@
 $id: http://devicetree.org/schemas/leds/leds-aw2013.yaml#
 $schema: http://devicetree.org/meta-schemas/core.yaml#
 
-title: AWINIC AW2013 3-channel LED Driver
+title: AWINIC AW2013/AW2027 3-channel LED Driver
 
 maintainers:
   - Nikita Travkin <nikitos.tr@gmail.com>
@@ -15,7 +15,9 @@ description: |
 
 properties:
   compatible:
-    const: awinic,aw2013
+    enum:
+      - awinic,aw2013
+      - awinic,aw2027
 
   reg:
     maxItems: 1

-- 
2.56.0

