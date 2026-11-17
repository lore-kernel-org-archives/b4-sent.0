From: Roman Vivchar <rva333@protonmail.com>
Date: Tue, 17 Nov 2026 20:08:35 +0200
Subject: [PATCH v2 1/4] dt-bindings: iio: light: stk33xx: add power supply
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-6768-stk3337-v2-1-92f4c7be3bc6@protonmail.com>
References: <20261117-6768-stk3337-v2-0-92f4c7be3bc6@protonmail.com>
In-Reply-To: <20261117-6768-stk3337-v2-0-92f4c7be3bc6@protonmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794938915; l=793;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=diwcCURmKRJT1PWJdnMByDcutmnsbaDcpEkfCbV6CHw=;
 b=gMygiIVHrbmRjl+dx9CR4BESixsupRVRXvlKv6XXxt6feRRYQ5EMNd8bzXwvciT3kEqLx8C9C
 FSVJaduL9yTATnpy4+AyaXxZ/Kl76Ho8qRJ7+xN7d6iH89bJkaj3Tly
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On some boards, the chip shares a power rail with other components. If
that rail is turned off, the chip can't function.

Add vdd-supply property to document the chip power supply.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 Documentation/devicetree/bindings/iio/light/stk33xx.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/light/stk33xx.yaml b/Documentation/devicetree/bindings/iio/light/stk33xx.yaml
index f655a570aac7..114cf87eb54d 100644
--- a/Documentation/devicetree/bindings/iio/light/stk33xx.yaml
+++ b/Documentation/devicetree/bindings/iio/light/stk33xx.yaml
@@ -37,6 +37,8 @@ properties:
 
   proximity-near-level: true
 
+  vdd-supply: true
+
 required:
   - compatible
   - reg

-- 
2.56.1

