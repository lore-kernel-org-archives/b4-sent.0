From: PavithraUdayakumar-adi <pavithra.u@analog.com>
Date: Mon, 17 Feb 2025 18:17:16 +0530
Subject: [PATCH RESEND v5 1/2] dt-bindings: rtc: max31335: Add max31331
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250217-add_support_max31331_fix_8-v1-1-16ebcfc02336@analog.com>
References: <20250217-add_support_max31331_fix_8-v1-0-16ebcfc02336@analog.com>
In-Reply-To: <20250217-add_support_max31331_fix_8-v1-0-16ebcfc02336@analog.com>
To: Antoniu Miclaus <antoniu.miclaus@analog.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>, 
 =?utf-8?q?Nuno_S=C3=A1?= <noname.nuno@gmail.com>
Cc: linux-rtc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 Christophe JAILLET <christophe.jaillet@wanadoo.fr>, 
 PavithraUdayakumar-adi <pavithra.u@analog.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739796453; l=833;
 i=pavithra.u@analog.com; s=20241220; h=from:subject:message-id;
 bh=kBVh5Woapx+65ZvZaO0BE5t/r0tL7uQbUpMT/sCj/bA=;
 b=bn/FRRqulS/I7fnK6tfOK5I8k5G5Nz8tQ4WHbP0daq3P158iZYjVmiSidcFKWd62zrc/7Pdm4
 +KnrZXiGFI/AWc+75q9Ip+5ta+W+hvg65P6hJ5V4k9i3p5/pRD40//O
X-Developer-Key: i=pavithra.u@analog.com; a=ed25519;
 pk=RIhZrdpg71GEnmwm1eNn95TYUMDJOKVsFd37Fv8xf1U=
X-Endpoint-Received: by B4 Relay for pavithra.u@analog.com/20241220 with auth_id=303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Added DT compatible string for MAX31331.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
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

