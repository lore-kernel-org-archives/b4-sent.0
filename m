From: Janne Grunau <j@jannau.net>
Date: Wed, 13 Aug 2025 11:53:36 +0200
Subject: [PATCH 4/5] dt-bindings: arm: apple: Add t8112 j415 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250813-apple-dt-sync-6-17-v1-4-209f15d10aa0@jannau.net>
References: <20250813-apple-dt-sync-6-17-v1-0-209f15d10aa0@jannau.net>
In-Reply-To: <20250813-apple-dt-sync-6-17-v1-0-209f15d10aa0@jannau.net>
To: Sven Peter <sven@kernel.org>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Mark Kettenis <kettenis@openbsd.org>, 
 Hector Martin <marcan@marcan.st>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1139; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=ED8ImSi3bhM4BQ6UPMffQZiVekSQkM/K2v2LMg5RCM4=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhow5CWueyDyPnp71I75zK0s8092b1S9MzW/du7XgH2c94
 x57F8/3HaUsDGJcDLJiiixJ2i87GFbXKMbUPgiDmcPKBDKEgYtTACYydzcjQ/99CyeGynWTK+Wl
 GwzOmS98cexHd2BnQZ0mY/jRxaqHTzAyPJgS7hbf/qiF48KP9F7xzZFCv5mFplxZ9D4m+fETtuC
 FXAA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds the "apple,j415" (MacBook Air (15-inch, M2, 2023) to the
apple,t8112 platform.

Signed-off-by: Janne Grunau <j@jannau.net>
---
 Documentation/devicetree/bindings/arm/apple.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/apple.yaml b/Documentation/devicetree/bindings/arm/apple.yaml
index da60e9de1cfbd0151e973c3aafba6d0880fc21aa..3b90b5df60507b245de387de104a4e64f234139a 100644
--- a/Documentation/devicetree/bindings/arm/apple.yaml
+++ b/Documentation/devicetree/bindings/arm/apple.yaml
@@ -93,6 +93,7 @@ description: |
 
   - MacBook Air (M2, 2022)
   - MacBook Pro (13-inch, M2, 2022)
+  - MacBook Pro (15-inch, M2, 2023)
   - Mac mini (M2, 2023)
 
   And devices based on the "M1 Pro", "M1 Max" and "M1 Ultra" SoCs:
@@ -279,6 +280,7 @@ properties:
         items:
           - enum:
               - apple,j413 # MacBook Air (M2, 2022)
+              - apple,j415 # MacBook Air (M2, 2023)
               - apple,j473 # Mac mini (M2, 2023)
               - apple,j493 # MacBook Pro (13-inch, M2, 2022)
           - const: apple,t8112

-- 
2.50.1

