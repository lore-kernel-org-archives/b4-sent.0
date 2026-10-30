From: Aiden Isik <aidenisik@member.fsf.org>
Date: Fri, 30 Oct 2026 20:33:58 +0000
Subject: [PATCH v3 3/5] dt-bindings: arm: samsung: Add lucky7 board binding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-for-next-lucky7-v3-3-81e02272ce69@member.fsf.org>
References: <20261030-for-next-lucky7-v3-0-81e02272ce69@member.fsf.org>
In-Reply-To: <20261030-for-next-lucky7-v3-0-81e02272ce69@member.fsf.org>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aiden Isik <aidenisik@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1084;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=7JvUn6Gsqc0cxhWub/oalXTSGokInna58PtxHScXffE=;
 b=owEBiQJ2/ZANAwAIAUknAbLEetfrAcsmYgBq5P9BHMKBNh4IQyDh63QQ1k4O5B7iuUyB1RWst
 LQX8wp+4zqJAk8EAAEIADkWIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCauT/QRsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQSScBssR61+t2URAAyZpdL0VPHA7tNOV/jR4IN13ZZjCE5rk
 U+2fOx7l6sFhM+bm/CXkpLAdlxnq8DYJBBMY+c9v4RDYvRAWfNwSdhBnj1vhiP82NEDomFkwN1U
 1QrAQ0FCSps9MWrONQ9aLkVkvA8KmXqXLQI+kzdmHtA/KQUHB/JgKPYEwdw33Tr3CIy90MPrGmD
 3K2cDQ3cVdtAXUtUIEUH3ZQwD2kPxtV298RhVAdpbId+CLw1fYETEdHz+/3WVLZQtcbjgfwH9P7
 QJvmZ5mEMmAzwGUXBstlTWT/Ma+n6A3wDiXEEUvQ0LwCzMDqg7GxrDdSkWjiyWQwYFZTQc/Y5WG
 GJYkI2XAdnxItD8uX0PAaFvJZi/D6R6vs6CLr0m6NG8QE0Cpb5hKjizpH3oquemGwOfPmNdch8i
 1pVV2nCidNIZppWMmYSucV48h7VmdGBfKdtzZNlwFZfh+O5TNoAMh+N7t6qo/ctF6QDhJNYkhv/
 o7e4J9s9sgFZi2LEujp/Ibr8CdeefOtzJPam5pr2UDo0WAJutthUbiiAC78VoiIVWOzZcIlVJJ8
 Kq0PRTrAVnlO4jDuqL3EW4szSyo7fwo8Z+MFBk7ijS6E8FTknoWkrHSbwXIi8CVi9dClc5oVxDW
 Y7n6uAqG74JaOAafywKRTbnVVo3O3Ocscc137xcAFTJPerl7C3mI=
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree binding for the Samsung Galaxy Watch FE (SM-R861/SM-R866)
board, based on the Exynos5515 SoC.

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
 Documentation/devicetree/bindings/arm/samsung/samsung-boards.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/samsung/samsung-boards.yaml b/Documentation/devicetree/bindings/arm/samsung/samsung-boards.yaml
index db19a686f490..c80fac4fad7a 100644
--- a/Documentation/devicetree/bindings/arm/samsung/samsung-boards.yaml
+++ b/Documentation/devicetree/bindings/arm/samsung/samsung-boards.yaml
@@ -157,6 +157,12 @@ properties:
           - const: samsung,exynos5420
           - const: samsung,exynos5
 
+      - description: Exynos5515 based boards
+        items:
+          - enum:
+              - samsung,lucky7                  # Samsung Galaxy Watch FE (SM-R861/SM-R866)
+          - const: samsung,exynos5515
+
       - description: Google Peach Pit Boards (Rev 6+)
         items:
           - const: google,pit-rev16

-- 
2.54.0

