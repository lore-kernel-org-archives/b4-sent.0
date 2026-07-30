From: Andy Chung <Andy.Chung@amd.com>
Date: Thu, 30 Jul 2026 17:07:57 +0800
Subject: [PATCH linux dev-6.18 2/4] dt-bindings: trivial-devices: Add
 Kandou KB9002
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260730-kb9002-backport-v1-2-41f472e52215@amd.com>
References: <20260730-kb9002-backport-v1-0-41f472e52215@amd.com>
In-Reply-To: <20260730-kb9002-backport-v1-0-41f472e52215@amd.com>
To: openbmc@lists.ozlabs.org, joel@jms.id.au, andrew@codeconstruct.com.au
Cc: Andy Chung <Andy.Chung@amd.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785402478; l=1261;
 i=Andy.Chung@amd.com; s=20260327; h=from:subject:message-id;
 bh=Ex6bkGPWNE1aR7VWIU8rbqLRd+CR1DA8kncq0v7nRrw=;
 b=A1K0WaveVTpNZBUNAV2pzrA164YbHISxbVgnjmxdeUozhUfSRJNXDxyRzHfWLCblLyCFFhzfP
 WvsVfIoYVC8BUHKKEEySFpWf+dCWKdxg6u0TADL84GDmnoBF4sjYsAL
X-Developer-Key: i=Andy.Chung@amd.com; a=ed25519;
 pk=X2gaHRnhU2q5hvMjkC6xmIcC03vKNvHY9CQRdsj9ecM=
X-Endpoint-Received: by B4 Relay for Andy.Chung@amd.com/20260327 with auth_id=696
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Kandou KB9002 is an 8-lane PCIe 5.0 retimer exposing an SMBus target
that reports an aggregated die temperature. It needs no device-specific
device tree properties beyond its address, so add it to trivial-devices.

Signed-off-by: Andy Chung <Andy.Chung@amd.com>
Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Link: https://lore.kernel.org/r/20260724-kb9002-upstream-v5-2-9523c3ffe83a@amd.com
Signed-off-by: Guenter Roeck <linux@roeck-us.net>
---
 Documentation/devicetree/bindings/trivial-devices.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/trivial-devices.yaml b/Documentation/devicetree/bindings/trivial-devices.yaml
index dd5077ab3a20..677c0088ddad 100644
--- a/Documentation/devicetree/bindings/trivial-devices.yaml
+++ b/Documentation/devicetree/bindings/trivial-devices.yaml
@@ -177,6 +177,8 @@ properties:
           - isil,isl69260
             # JEDEC JESD300 (SPD5118) Hub and Serial Presence Detect
           - jedec,spd5118
+            # Kandou KB9002 PCIe 5.0 retimer
+          - kandou,kb9002
             # Linear Technology LTC2488
           - lineartechnology,ltc2488
             # 5 Bit Programmable, Pulse-Width Modulator

-- 
2.34.1

