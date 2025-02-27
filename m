From: Maud Spierings <maudspierings@gocontroll.com>
Date: Thu, 27 Feb 2025 13:57:52 +0100
Subject: [PATCH 2/3] dt-bindings: hwmon: ntc-thermistor: fix typo regarding
 the deprecation of the ntc, compatibles
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250227-ntc_thermistor_fixes-v1-2-70fa73200b52@gocontroll.com>
References: <20250227-ntc_thermistor_fixes-v1-0-70fa73200b52@gocontroll.com>
In-Reply-To: <20250227-ntc_thermistor_fixes-v1-0-70fa73200b52@gocontroll.com>
To: Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Joseph McNally <jmcna06@gmail.com>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740661074; l=992;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=go8V0aZ/npOUYtcmaYuylqPFZ1dFM88LliPYDxQ4huM=;
 b=KL/bHOiQgKzvK+suFA2uzR6LNggkAGjIjfkm+a3DKhoW5sUgA/IEnZwnHpWGh4zVfJ3BGi7r5
 eHE5T4ug+OTCqo7oWlzCZbB2Ptvh3FmSSYzelyx6ygAklpkDjoV9rWz
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the comment stating that the "ntp," compatible strings are deprecated
which should be "ntc,"

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 Documentation/devicetree/bindings/hwmon/ntc-thermistor.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/hwmon/ntc-thermistor.yaml b/Documentation/devicetree/bindings/hwmon/ntc-thermistor.yaml
index 3d0146e20d3e10747c3049911b9419e9ccdab83d..b8e500e6cd9f861fbbabd79a14d882341dbb387c 100644
--- a/Documentation/devicetree/bindings/hwmon/ntc-thermistor.yaml
+++ b/Documentation/devicetree/bindings/hwmon/ntc-thermistor.yaml
@@ -76,7 +76,7 @@ properties:
       - const: murata,ncp03wf104
       - const: murata,ncp15xh103
       - const: samsung,1404-001221
-      # Deprecated "ntp," compatible strings
+      # Deprecated "ntc," compatible strings
       - const: ntc,ncp15wb473
         deprecated: true
       - const: ntc,ncp18wb473

-- 
2.48.1

