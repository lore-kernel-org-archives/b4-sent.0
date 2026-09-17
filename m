From: Andy Chung <Andy.Chung@amd.com>
Date: Thu, 17 Sep 2026 17:49:22 +0800
Subject: [PATCH linux dev-6.18 v2 2/4] dt-bindings: trivial-devices: Add
 Kandou KB9002
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260917-kb9002-backport-v2-2-71d46021f051@amd.com>
References: <20260917-kb9002-backport-v2-0-71d46021f051@amd.com>
In-Reply-To: <20260917-kb9002-backport-v2-0-71d46021f051@amd.com>
To: openbmc@lists.ozlabs.org, andrew@codeconstruct.com.au, 
 tan.siewert@9elements.com
Cc: joel@jms.id.au
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789638570; l=1379;
 i=Andy.Chung@amd.com; s=20260327; h=from:subject:message-id;
 bh=5mwrbcfnWsAfbYe3ByQPrSR2y9UiG5SCnrvvrZ3Sw3Y=;
 b=ccO/IApfr1plxiYi0cVdGNRjzNr9/PFlrxsDv/DznJy9myi6FCE+pIWrgyhlQIKF+6pauQJtn
 mSOriw/s6cAAVmOnqeRuwbnC4rKcLTdls+/MzCgep4UnzsuvptrgPqD
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
(cherry picked from commit 495e5dead2cce443c43f55c09d5f5e42392d3dbc)
Signed-off-by: Andy Chung <Andy.Chung@amd.com>
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

