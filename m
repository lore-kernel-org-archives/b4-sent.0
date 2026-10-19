From: Aiden Isik <aidenisik@member.fsf.org>
Date: Mon, 19 Oct 2026 11:23:48 +0100
Subject: [PATCH v2 2/5] dt-bindings: soc: samsung: exynos-pmu: Add
 Exynos5515 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-for-next-lucky7-v2-2-c4ecab4b1c4c@member.fsf.org>
References: <20261019-for-next-lucky7-v2-0-c4ecab4b1c4c@member.fsf.org>
In-Reply-To: <20261019-for-next-lucky7-v2-0-c4ecab4b1c4c@member.fsf.org>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aiden Isik <aidenisik@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=956;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=u5w9oDBuV+q/JxmEewB9ecAjYkFIvHtUgbXKYE3snfg=;
 b=owEBiQJ2/ZANAwAIAUknAbLEetfrAcsmYgBq1e+7qKwtn/AtJxY1XoSwej2KfOWWVj/ql3ZhS
 0epIVrGOwWJAk8EAAEIADkWIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCatXvuxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQSScBssR61+uhdhAAs6wYyfqFQE8Kf9EhnMzIlElTCyjVbxs
 5gvWepRuxfRjVHx2o+HU5iNRveaO69wHCxgZ53q90nV4VMEfqTYSU5pS/B4cpLXfs7fztUFX//Q
 6kVUG1cl6zNj6Aw5OePRWrYntLSvxj94rUqR0Flu8J46ZxVtVcY6rMxm53ahzFuDDh0l+FLVvhs
 E5ISks01UnNZ+Ac6NleHOiZ3/XpEXUC5+PwDUPDJh/gdUShy46hsF4y4eX1535sUC1+XVjwLyRs
 HPkHFeQtl6zkX35y94ILJNpD7bK45VfQEWkh4foTbKSdxfeQW79QcO/RrHa3XAhna+BX/LWDeqw
 m3IQEaHA+6OrVoOTyzI1K4X9gKMXetHt9A6pKsixv3r1aFzYt1ZnXZMPhLUUOUoeBEj3MmzAdc9
 iMD6kvXRha3T6nQhrR0iqYWWillS8UKJYK2zy25nsPsTubQ+Xxoa7nZDaq40DyjM87W/LynDRKk
 wlMhQRt15CVQ9HEEwmWHXxKhAaWr9oqX4IpnYg4drWKXEtgjpHWpIpucmgsBnwu12oxre59mXN2
 UL4pJaKMKneosaaeisppdjsvKyg26JTZO7q4Mpfq+VB8rSLaYj4FrNdRIb0GXrJi7BwBmbJ17Ln
 Vwn9JrgbG7tT+zQLs8RXhxFitAx8dRy6em6UUPwcxbg+NgjhLdbs=
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add exynos5515-pmu compatible to the device tree bindings documentation.
Use the samsung,exynos7-pmu compatible, as it works the same for Exynos7
and Exynos5515.

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
 Documentation/devicetree/bindings/soc/samsung/exynos-pmu.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/soc/samsung/exynos-pmu.yaml b/Documentation/devicetree/bindings/soc/samsung/exynos-pmu.yaml
index 5bd39876e3b3..1a0d9de79696 100644
--- a/Documentation/devicetree/bindings/soc/samsung/exynos-pmu.yaml
+++ b/Documentation/devicetree/bindings/soc/samsung/exynos-pmu.yaml
@@ -33,6 +33,7 @@ properties:
           - enum:
               - axis,artpec9-pmu
               - samsung,exynos2200-pmu
+              - samsung,exynos5515-pmu
               - samsung,exynos7870-pmu
               - samsung,exynos7885-pmu
               - samsung,exynos8890-pmu

-- 
2.54.0

