From: Colin Huang <u8813345@gmail.com>
Date: Fri, 08 May 2026 17:44:28 +0800
Subject: [PATCH v5 1/3] dt-bindings: trivial-devices: Add Delta E50SN12051
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260508-add-e50sn12051-v5-1-abebdcc29665@gmail.com>
References: <20260508-add-e50sn12051-v5-0-abebdcc29665@gmail.com>
In-Reply-To: <20260508-add-e50sn12051-v5-0-abebdcc29665@gmail.com>
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kevin Chang <kevin.chang2@amd.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Colin Huang <colin.huang2@amd.com>, Colin Huang <u8813345@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778233493; l=932;
 i=u8813345@gmail.com; s=20260202; h=from:subject:message-id;
 bh=BgW8zMkOvHttDiEUcHy6hcle9cw258caoKT/SxPSyTQ=;
 b=iRPEGRysd4om3K5MrlI4SC9yjHp6mCWLURk8RNI1PDDNDFy6QUtA4FEWe5K6otfEDC6rJ7FTW
 9jK7hKlWhosDYzK2xar7/VlDksyRC/v3zN4r5BGTCJRDhuLWO2F6oaZ
X-Developer-Key: i=u8813345@gmail.com; a=ed25519;
 pk=Zlg0WqpCw4qbswOqamTBTXIchwR/3SnYZpy7rjaGMdQ=
X-Endpoint-Received: by B4 Relay for u8813345@gmail.com/20260202 with auth_id=761
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add 600W Non-isolated 1/8th Brick DC/DC Power Modules, E50SN12051.

Signed-off-by: Colin Huang <u8813345@gmail.com>
---
 Documentation/devicetree/bindings/trivial-devices.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/trivial-devices.yaml b/Documentation/devicetree/bindings/trivial-devices.yaml
index 23fd4513933a..0f10368a1386 100644
--- a/Documentation/devicetree/bindings/trivial-devices.yaml
+++ b/Documentation/devicetree/bindings/trivial-devices.yaml
@@ -100,6 +100,8 @@ properties:
             # Delta Electronics DPS920AB 920W 54V Power Supply
           - delta,dps920ab
             # 1/4 Brick DC/DC Regulated Power Module
+          - delta,e50sn12051
+            # 600W Non-isolated 1/8th Brick DC/DC Power Modules
           - delta,q54sj108a2
             # 1300W 1/4 Brick DC/DC Regulated Power Module
           - delta,q54sn120a1

-- 
2.34.1

