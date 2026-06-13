From: Enzo Adriano <enzo.adriano.code@gmail.com>
Date: Sat, 13 Jun 2026 05:42:13 -0400
Subject: [PATCH 1/4] dt-bindings: arm: sunxi: add Radxa Cubie A7S
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260613-a733-dts-v1-public-ready-v1-1-7787c94681db@gmail.com>
References: <20260613-a733-dts-v1-public-ready-v1-0-7787c94681db@gmail.com>
In-Reply-To: <20260613-a733-dts-v1-public-ready-v1-0-7787c94681db@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>, 
 Ulf Hansson <ulfh@kernel.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-mmc@vger.kernel.org, Enzo Adriano <enzo.adriano.code@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781343732; l=870;
 i=enzo.adriano.code@gmail.com; s=a733-cubie-a7s; h=from:subject:message-id;
 bh=i6WAYnG2+hwZK3Eb/pK94tZG5A16TibjSeWXfvrfG5Q=;
 b=5BARvAPMpbKPU18jBrRxIKm7WodlM6Gk6MSwlfRJ27A2ff7vIgRd1LEXPKA4Y2YrCF8MS/5C9
 EJzXnC/1/kBBJVnh2a/D4waItyqVfHitw2Wm55132Zfn98+LESXjRpj
X-Developer-Key: i=enzo.adriano.code@gmail.com; a=ed25519;
 pk=5S3Wmdqa4XfCdeZF/HfeYqnQF8GN9JGt3SE1cxqSX8E=
X-Endpoint-Received: by B4 Relay for enzo.adriano.code@gmail.com/a733-cubie-a7s with auth_id=820
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Radxa Cubie A7S board compatible for the Allwinner A733 SoC.

Signed-off-by: Enzo Adriano <enzo.adriano.code@gmail.com>
---
 Documentation/devicetree/bindings/arm/sunxi.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/sunxi.yaml b/Documentation/devicetree/bindings/arm/sunxi.yaml
index e6443c266fa1..9f603681c78e 100644
--- a/Documentation/devicetree/bindings/arm/sunxi.yaml
+++ b/Documentation/devicetree/bindings/arm/sunxi.yaml
@@ -850,6 +850,11 @@ properties:
           - const: radxa,cubie-a5e
           - const: allwinner,sun55i-a527
 
+      - description: Radxa Cubie A7S
+        items:
+          - const: radxa,cubie-a7s
+          - const: allwinner,sun60i-a733
+
       - description: Remix Mini PC
         items:
           - const: jide,remix-mini-pc

-- 
2.53.0

