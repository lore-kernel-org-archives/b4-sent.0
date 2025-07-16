From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Wed, 16 Jul 2025 19:25:10 +0800
Subject: [PATCH v3 1/9] dt-bindings: mips: loongson: Add LS1B-DEMO and
 CQ-T300B
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250716-loongson1-arch-v3-1-d160974d696b@gmail.com>
References: <20250716-loongson1-arch-v3-0-d160974d696b@gmail.com>
In-Reply-To: <20250716-loongson1-arch-v3-0-d160974d696b@gmail.com>
To: Thomas Bogendoerfer <tsbogend@alpha.franken.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Keguang Zhang <keguang.zhang@gmail.com>
Cc: linux-mips@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752665136; l=1139;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=BeFER/OTjUaBJU4oGgkzvKA9dNM7aAK4NJf5Ys8zrbg=;
 b=6NcprzyhHtqouLOk+dmcRREh3edSDZAcjjBl2aMyHDjb9/mrxGkh8j+6ktAKFqM1XO8mV5tnh
 4pXNBMzYFGsBf/Wq3+LlQy+c7NVgPC1kxfbjklAk69d3hGjDc51WCPM
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document two Loongson-1 boards:
 - loongson,ls1b-demo: a board based on Loongson-1B
 - loongson,cq-t300b: a board based on Loongson-1C

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
 Documentation/devicetree/bindings/mips/loongson/devices.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/mips/loongson/devices.yaml b/Documentation/devicetree/bindings/mips/loongson/devices.yaml
index 099e40e1482d..ca66bc49c2d6 100644
--- a/Documentation/devicetree/bindings/mips/loongson/devices.yaml
+++ b/Documentation/devicetree/bindings/mips/loongson/devices.yaml
@@ -40,6 +40,7 @@ properties:
       - description: LS1B based boards
         items:
           - enum:
+              - loongson,ls1b-demo
               - loongson,lsgz-1b-dev
           - const: loongson,ls1b
 
@@ -47,6 +48,7 @@ properties:
         items:
           - enum:
               - loongmasses,smartloong-1c
+              - loongson,cq-t300b
           - const: loongson,ls1c
 
 additionalProperties: true

-- 
2.43.0

