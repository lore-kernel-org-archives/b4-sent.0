From: Vincent Jardin <vjardin@free.fr>
Date: Thu, 30 Jul 2026 17:44:00 +0200
Subject: [PATCH v7 2/4] dt-bindings: hwmon: pmbus: add MPS MPQ8646
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260730-mpq8646_v0-v7-2-e7c7ad768d5d@free.fr>
References: <20260730-mpq8646_v0-v7-0-e7c7ad768d5d@free.fr>
In-Reply-To: <20260730-mpq8646_v0-v7-0-e7c7ad768d5d@free.fr>
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Charles Hsu <ythsu0511@gmail.com>
Cc: Markus Elfring <Markus.Elfring@web.de>, linux-hwmon@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-doc@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785426244; l=1162;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=a+CG730JpK5wjHqaq0LPgcAJ+BdTq/WBHRpNWo3nNgc=;
 b=F9eBJPPQYOAn4J0eH/jsZSLORdY9h58TCERiIR/DzpQEvXw9v15wJKQTYFxWBpyJ0942F1q9D
 KM17Ssfxr5zDLmCAoBRm2ky4pDMkT3mHBRNI2eDJ7mwQYHGS+jTfwRE
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MPS MPQ8646 PMBus step-down converter uses the same
mps,vout-fb-divider-ratio-permille property with the same constraints
(maximum 2047, default 706) as the mps,mpq8785, so add its compatible
to the existing schema.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8785.yaml | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8785.yaml b/Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8785.yaml
index 90970a0433e9..d7a32fb3b7af 100644
--- a/Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8785.yaml
+++ b/Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8785.yaml
@@ -18,6 +18,7 @@ properties:
       - mps,mpm3695
       - mps,mpm3695-25
       - mps,mpm82504
+      - mps,mpq8646
       - mps,mpq8785
 
   reg:
@@ -52,7 +53,9 @@ allOf:
   - if:
       properties:
         compatible:
-          const: mps,mpq8785
+          enum:
+            - mps,mpq8646
+            - mps,mpq8785
     then:
       properties:
         mps,vout-fb-divider-ratio-permille:

-- 
2.43.0

