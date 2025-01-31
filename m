From: PavithraUdayakumar-adi <pavithra.u@analog.com>
Date: Fri, 31 Jan 2025 17:22:14 +0530
Subject: [PATCH v5 1/2] dt-bindings: rtc: max31335: Add max31331 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250131-add_support_max31331_fix_7-v1-1-d29d5de3d562@analog.com>
References: <20250131-add_support_max31331_fix_7-v1-0-d29d5de3d562@analog.com>
In-Reply-To: <20250131-add_support_max31331_fix_7-v1-0-d29d5de3d562@analog.com>
To: Antoniu Miclaus <antoniu.miclaus@analog.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>, 
 =?utf-8?q?Nuno_S=C3=A1?= <noname.nuno@gmail.com>
Cc: linux-rtc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 PavithraUdayakumar-adi <pavithra.u@analog.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1738324342; l=769;
 i=pavithra.u@analog.com; s=20241220; h=from:subject:message-id;
 bh=T6sFNCObCLNQPeHE4syE+HNTP2Xkdn/NWtfgIUWPH80=;
 b=tvyLKpDMR7Ry1tRadhdVzjfbed9BL6/7UN0VA71853w3LPJwphhpiQxpe9varxG6YwEOFg5yS
 AVS+iZyw0TxBVyWQQiKEQgvGQLjVQEc4/F1JakMBfehr7sxV8MenbM0
X-Developer-Key: i=pavithra.u@analog.com; a=ed25519;
 pk=RIhZrdpg71GEnmwm1eNn95TYUMDJOKVsFd37Fv8xf1U=
X-Endpoint-Received: by B4 Relay for pavithra.u@analog.com/20241220 with auth_id=303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Added DT compatible string for MAX31331.

Signed-off-by: PavithraUdayakumar-adi <pavithra.u@analog.com>
---
 Documentation/devicetree/bindings/rtc/adi,max31335.yaml | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/rtc/adi,max31335.yaml b/Documentation/devicetree/bindings/rtc/adi,max31335.yaml
index 0125cf6727cc3d9eb3e0253299904ee363ec40ca..bce7558d0d8789127dcf6050a78a166c753887ba 100644
--- a/Documentation/devicetree/bindings/rtc/adi,max31335.yaml
+++ b/Documentation/devicetree/bindings/rtc/adi,max31335.yaml
@@ -18,7 +18,9 @@ allOf:
 
 properties:
   compatible:
-    const: adi,max31335
+    enum:
+      - adi,max31331
+      - adi,max31335
 
   reg:
     maxItems: 1

-- 
2.25.1

