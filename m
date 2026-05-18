From: Colin Huang <u8813345@gmail.com>
Date: Mon, 18 May 2026 16:10:17 +0800
Subject: [PATCH linux dev-6.6 1/3] dt-bindings: trivial-devices: Add Delta
 E50SN12051
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260518-dev-6-6-e50sn12051-driver-v1-1-8025fb61706e@gmail.com>
References: <20260518-dev-6-6-e50sn12051-driver-v1-0-8025fb61706e@gmail.com>
In-Reply-To: <20260518-dev-6-6-e50sn12051-driver-v1-0-8025fb61706e@gmail.com>
To: openbmc@lists.ozlabs.org, joel@jms.id.au, andrew@codeconstruct.com.au
Cc: Colin Huang <colin.huang2@amd.com>, Colin Huang <u8813345@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779091827; l=1160;
 i=u8813345@gmail.com; s=20260202; h=from:subject:message-id;
 bh=dL4vhMXFrasZpErKAdl5LN0MNubz6LqrPWme1lMtYIU=;
 b=jXFsGX1dQxjMUg/0kNFL7PvNHnVuxqIHLiymT/swrl7FJh7NyrMgFgcwWMTxJHN4V5iPnGgMl
 k8SWsUIzTnRCcE0aDllQtCANugkBvVnl9QCKy5P7t0BvdhQ4V6c9oAr
X-Developer-Key: i=u8813345@gmail.com; a=ed25519;
 pk=Zlg0WqpCw4qbswOqamTBTXIchwR/3SnYZpy7rjaGMdQ=
X-Endpoint-Received: by B4 Relay for u8813345@gmail.com/20260202 with auth_id=761
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add 600W Non-isolated 1/8th Brick DC/DC Power Modules, E50SN12051.

Signed-off-by: Colin Huang <u8813345@gmail.com>
Acked-by: Conor Dooley <conor.dooley@microchip.com>
Link: https://lore.kernel.org/r/20260508-add-e50sn12051-v5-1-abebdcc29665@gmail.com
[groeck: Swapped comment and definition]
Signed-off-by: Guenter Roeck <linux@roeck-us.net>
---
 Documentation/devicetree/bindings/trivial-devices.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/trivial-devices.yaml b/Documentation/devicetree/bindings/trivial-devices.yaml
index 4f291690420f..266e3c316c9c 100644
--- a/Documentation/devicetree/bindings/trivial-devices.yaml
+++ b/Documentation/devicetree/bindings/trivial-devices.yaml
@@ -91,6 +91,8 @@ properties:
           - delta,dps650ab
             # Delta Electronics DPS920AB 920W 54V Power Supply
           - delta,dps920ab
+            # 600W Non-isolated 1/8th Brick DC/DC Power Modules
+          - delta,e50sn12051
             # 1/4 Brick DC/DC Regulated Power Module
           - delta,q54sj108a2
             # Devantech SRF02 ultrasonic ranger in I2C mode

-- 
2.34.1

