From: Colin Huang <u8813345@gmail.com>
Date: Tue, 19 May 2026 15:45:57 +0800
Subject: [PATCH linux dev-6.18 1/2] dt-bindings: trivial-devices: Add Delta
 Q54SN120A1 and Q54SW120A7
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260519-dev-6-18-add-delta-q54sn120a1-q54sw120a7-v1-1-9b5eb2c0752e@gmail.com>
References: <20260519-dev-6-18-add-delta-q54sn120a1-q54sw120a7-v1-0-9b5eb2c0752e@gmail.com>
In-Reply-To: <20260519-dev-6-18-add-delta-q54sn120a1-q54sw120a7-v1-0-9b5eb2c0752e@gmail.com>
To: openbmc@lists.ozlabs.org, joel@jms.id.au, andrew@codeconstruct.com.au
Cc: Colin Huang <colin.huang2@amd.com>, Colin Huang <u8813345@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779176769; l=1256;
 i=u8813345@gmail.com; s=20260202; h=from:subject:message-id;
 bh=K+IyVbY0YDaHf1Nno10Bh+6JniXhDUqanHMSQJiaYRo=;
 b=vc1fmn8JejcUhHd0AQo8cBYRp5H05esZop/A0ZMMMFVfm5dq3Qc/9ESB2ZNKRVbeiBeYHmW5X
 1ZwvKyL5h9lDFfVre2fKPilJYqDjWXf9VYhTjPHrqJRshwRzovkkwqw
X-Developer-Key: i=u8813345@gmail.com; a=ed25519;
 pk=Zlg0WqpCw4qbswOqamTBTXIchwR/3SnYZpy7rjaGMdQ=
X-Endpoint-Received: by B4 Relay for u8813345@gmail.com/20260202 with auth_id=761
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add two additional Delta 1/4-brick DC/DC power modules,
Q54SN120A1 and Q54SW120A7, to the trivial-devices list.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Colin Huang <u8813345@gmail.com>
Link: https://lore.kernel.org/r/20260316-add-q54sn120a1-q54q54sw120a7-v2-1-60e6182cc4a7@gmail.com
Signed-off-by: Guenter Roeck <linux@roeck-us.net>
---
 Documentation/devicetree/bindings/trivial-devices.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/trivial-devices.yaml b/Documentation/devicetree/bindings/trivial-devices.yaml
index b20a57677224..dd5077ab3a20 100644
--- a/Documentation/devicetree/bindings/trivial-devices.yaml
+++ b/Documentation/devicetree/bindings/trivial-devices.yaml
@@ -91,6 +91,10 @@ properties:
           - delta,e50sn12051
             # 1/4 Brick DC/DC Regulated Power Module
           - delta,q54sj108a2
+            # 1300W 1/4 Brick DC/DC Regulated Power Module
+          - delta,q54sn120a1
+            # 2000W 1/4 Brick DC/DC Regulated Power Module
+          - delta,q54sw120a7
             # Devantech SRF02 ultrasonic ranger in I2C mode
           - devantech,srf02
             # Devantech SRF08 ultrasonic ranger

-- 
2.34.1

