From: Michael Reeves <michael.reeves077@gmail.com>
Date: Sat, 21 Nov 2026 08:34:15 +0000
Subject: [PATCH 1/4] dt-bindings: spmi: apple,spmi: Add t8122-spmi
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-t8122-smc-dt-v1-1-898f3f5d6228@gmail.com>
References: <20261121-t8122-smc-dt-v1-0-898f3f5d6228@gmail.com>
In-Reply-To: <20261121-t8122-smc-dt-v1-0-898f3f5d6228@gmail.com>
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Stephen Boyd <sboyd@kernel.org>, 
 Abel Vesa <abelvesa@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sasha Finkelstein <k@chaosmail.tech>, 
 Lee Jones <lee@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 mfd@lists.linux.dev, Michael Reeves <michael.reeves077@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795250077; l=905;
 i=michael.reeves077@gmail.com; s=20261107; h=from:subject:message-id;
 bh=sdZqNboDueIqd/3+ZQB+YhZSKVMgBeFIQ/ArGmXfVBM=;
 b=O4/enfcuMGARRASodcI6u0D0M9IR6lwZh6J7hjydbof0yWVKLg1sIcj5RoEkM0m7hcFjsXH2l
 nsOrw2docFPB2VQB24U1WC4Ac2eJywciqkbpGeAdELfEzPNeH05s0gs
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=ykwkLcuByJYb/cdLc2UuoYP03pIzwrscEZg30+4tJL8=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20261107 with auth_id=1442
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sasha Finkelstein <k@chaosmail.tech>

Add the apple,t8122-spmi compatible for the SPMI controller on the Apple
M3 (T8122) SoC, which is compatible with apple,t8103-spmi.

Signed-off-by: Sasha Finkelstein <k@chaosmail.tech>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 Documentation/devicetree/bindings/spmi/apple,spmi.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/spmi/apple,spmi.yaml b/Documentation/devicetree/bindings/spmi/apple,spmi.yaml
index 3e5b14bc8c31..f7920dd3a59b 100644
--- a/Documentation/devicetree/bindings/spmi/apple,spmi.yaml
+++ b/Documentation/devicetree/bindings/spmi/apple,spmi.yaml
@@ -22,6 +22,7 @@ properties:
               - apple,t6020-spmi
               - apple,t8012-spmi
               - apple,t8015-spmi
+              - apple,t8122-spmi
           - const: apple,t8103-spmi
       - items:
           - enum:

-- 
2.56.0

