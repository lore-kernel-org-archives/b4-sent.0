From: Michael Reeves <michael.reeves077@gmail.com>
Date: Sat, 21 Nov 2026 08:34:16 +0000
Subject: [PATCH 2/4] dt-bindings: mfd: apple,smc: Add t8122-smc compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-t8122-smc-dt-v1-2-898f3f5d6228@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795250077; l=946;
 i=michael.reeves077@gmail.com; s=20261107; h=from:subject:message-id;
 bh=tn5lVW1FjAYmZE60s+OKJciG68xs7HiP2AZnWSAa9v8=;
 b=6kSbfAXUY6Hx8zZUZFBAQvz8WcZ4q2RQ3ZdaVS8fU/1yMEP2+nQhCgjo7LEIvIovLZAWK4ETP
 ZkucVQe7/UuAhZKcrLPTm8hvQbpXqHfSupR5JZn7IEyJRMSlrgjusZK
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=ykwkLcuByJYb/cdLc2UuoYP03pIzwrscEZg30+4tJL8=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20261107 with auth_id=1442
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Janne Grunau <j@jannau.net>

Add the apple,t8122-smc compatible for the System Management Controller
on the Apple M3 (T8122) SoC, which is compatible with apple,t8103-smc.

Signed-off-by: Janne Grunau <j@jannau.net>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 Documentation/devicetree/bindings/mfd/apple,smc.yaml | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/mfd/apple,smc.yaml b/Documentation/devicetree/bindings/mfd/apple,smc.yaml
index 34ce048619f5..d5d30c053845 100644
--- a/Documentation/devicetree/bindings/mfd/apple,smc.yaml
+++ b/Documentation/devicetree/bindings/mfd/apple,smc.yaml
@@ -17,7 +17,9 @@ properties:
   compatible:
     oneOf:
       - items:
-          - const: apple,t6020-smc
+          - enum:
+              - apple,t6020-smc
+              - apple,t8122-smc
           - const: apple,t8103-smc
       - items:
           - enum:

-- 
2.56.0

