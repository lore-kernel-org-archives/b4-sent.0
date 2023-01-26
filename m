From: Niall Leonard <nl250060@ncr.com>
Date: Thu, 26 Jan 2023 10:17:22 +0000
Subject: [PATCH 1/3] gpio: dt-bindings: add new property to wd,mbl-gpio
 bindings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230126-gpio-mmio-fix-v1-1-8a20ce0e8275@ncr.com>
References: <20230126-gpio-mmio-fix-v1-0-8a20ce0e8275@ncr.com>
In-Reply-To: <20230126-gpio-mmio-fix-v1-0-8a20ce0e8275@ncr.com>
To: Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Niall Leonard <nl250060@ncr.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=709; i=nl250060@ncr.com;
 h=from:subject:message-id; bh=TZqj8LOqd2ElAWFa5TLfeyGZqTZ8bzLHl7An5WBxTgA=;
 b=owEBbQKS/ZANAwAKAVGiIrYFD2P/AcsmYgBj0lNa8K940tPfSmc2r9nNjxeacsEcqV+EBYR7dCIh
 eoyWvsuJAjMEAAEKAB0WIQSha1EPjh6hUqdtwZNRoiK2BQ9j/wUCY9JTWgAKCRBRoiK2BQ9j/3RpD/
 4jj77vSlXxpbuPYKFdn0vEZhfXOLPaXlCCs+CkYcU39mGs9v4OjplKJUVPuuCVERaCmKgdhPtS1D9X
 wexpEBPbTOiuECj2lFIWp6Cv9C3jYDNCaBCsRIZ2mZ70FJiHXJgoSeZ7QK6NJD+ygLtbPGNKjVh9dV
 N4kkmiBnaSEuTjXHJ+cfMapEnVNmElK20rRcoxJp+Hldqw+bDCYUrGatqrCxCWwD22XkWSCIl4pmLp
 bwVZvgxTpuvBeC2gE63lwTBNH18cOAYgZ0Bl4kZRmLbEbiYFWEaWI5+tnU1aPd2dn52rnuKZtcVihJ
 P3adT7IxtLs+cDFZC/sIL76sYewxV8T6dwJ7fgo2EslzvAksfvo0cHTA+ZzuZRyXgiH7gDH9UozTLs
 Ql7nmtvS97ojMeM6lrEY4FUU6V0qGHyPvFbuzSGJeK/YzMM+Qv5LywW0gWeZLkLBpRulik2xhtkAfc
 U/7st71QO4Lp6PU+Mewz1a2XlZHpTBxnT4q7z2c4BCXbROfy4wCOspiWzy5NmMU5YGIZHaZmUtIJkY
 iCD4NQnRTXvaCgMuscLbRgADLRexTfRekrSnazsftSYN/fiQZOSWLpnqYYzPYiD7BHRQansuPMq6A4
 4UZCrn2KSFMw0awdyMxc81ntXCmZkmp3lVo9h83HdO8JWZyvfHcxL1R0Madw==
X-Developer-Key: i=nl250060@ncr.com; a=openpgp;
 fpr=A16B510F8E1EA152A76DC19351A222B6050F63FF
X-Endpoint-Received: by B4 Submission Endpoint for nl250060@ncr.com/default with auth_id=26
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Added optional "no-input" property

Signed-off-by: Niall Leonard <nl250060@ncr.com>
---
 Documentation/devicetree/bindings/gpio/wd,mbl-gpio.txt | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/gpio/wd,mbl-gpio.txt b/Documentation/devicetree/bindings/gpio/wd,mbl-gpio.txt
index 038c3a6a1f4d..9405f9dad522 100644
--- a/Documentation/devicetree/bindings/gpio/wd,mbl-gpio.txt
+++ b/Documentation/devicetree/bindings/gpio/wd,mbl-gpio.txt
@@ -18,6 +18,7 @@ Required properties:
 
 Optional properties:
 	- no-output: GPIOs are read-only.
+	- no-input: GPIOs are write-only. Read is via a shadow register.
 
 Examples:
 	gpio0: gpio0@e0000000 {

-- 
2.34.1

