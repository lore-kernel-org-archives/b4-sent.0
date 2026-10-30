From: Aiden Isik <aidenisik@member.fsf.org>
Date: Fri, 30 Oct 2026 20:33:56 +0000
Subject: [PATCH v3 1/5] dt-bindings: soc: samsung: exynos-sysreg: Add
 compatibles for Exynos5515
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-for-next-lucky7-v3-1-81e02272ce69@member.fsf.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1491;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=QtI7rR1JE5JZ0IsGeNkyOHtQG1QoQSmhMzQKfhBONkY=;
 b=owEBiQJ2/ZANAwAIAUknAbLEetfrAcsmYgBq5P9BRwnhwKnh1lcLA8zegpISzuoxVtpp5hFSk
 J2zaklXBzqJAk8EAAEIADkWIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCauT/QRsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQSScBssR61+sUcw/+KAI+HUyt1z+19ZMIG5gRCEjE44sucKH
 KNHTSOx64D+bNnnirR/IWS6DGiL4OCtHgBLgaaYoTu2rcjjPkARscI3n1BFNH3qknQNcNVLPagG
 JEdMikMNvIjTYc0+RKLMTV4hOAKGxNdk5ycDH5P/d0aWZNi4LZzS9DeC/ID+KJg5TyYWBhZv1hM
 mzi+Jq65JmDFFAcZ0hKi+hS7gJHMgzP9ewAwwRQor464RYTR66m/eGMbXCSKNJc+HgY+ErFpXH/
 lTk3aD6t4CdFYYN+SxUKbtbJqZydCMmEZVWBAoFn7VfD7loooEx6BknS65WU0cT1HeeD8J/J//e
 bRgPFtQm0bQgKesqdoccbIxtlW+Kl9w0tuR1tXn/BxCpL6dZ+QH9gGbK0eSMxx/1atIHAQAPL14
 HheUfUJM5JsInrfZyVBtGqDXlF1IPkJv+Y6912ZctsOSkCejwHcJ72MSe+Wc7nO5kZivxgc02Et
 86RTXf9QUjRMUWwQQ3cb9QXpxVGsiOJ9nLE9cvXU0CgGaAhGhTdseWBH78WC9vVhk6MUbHTm2va
 S289sjykEYRGVGW6Qxkcle8PBMO6/LulZ6ijDXmCpedKRWsfu7JPYBhDD4N/1EMvqpVAEN/WNEf
 iD+X7Wg83J2zPnp5nq5rKGNiCrr4sTqk6Qo6OQaCioJNT+st9uk0=
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Exynos5515 compatibles for the following sysreg controllers:
- top
- peri
- fsys

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
 .../devicetree/bindings/soc/samsung/samsung,exynos-sysreg.yaml       | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/soc/samsung/samsung,exynos-sysreg.yaml b/Documentation/devicetree/bindings/soc/samsung/samsung,exynos-sysreg.yaml
index fcdb9ffd2644..9e698d065820 100644
--- a/Documentation/devicetree/bindings/soc/samsung/samsung,exynos-sysreg.yaml
+++ b/Documentation/devicetree/bindings/soc/samsung/samsung,exynos-sysreg.yaml
@@ -29,6 +29,9 @@ properties:
               - samsung,exynos3-sysreg
               - samsung,exynos4-sysreg
               - samsung,exynos5-sysreg
+              - samsung,exynos5515-fsys-sysreg
+              - samsung,exynos5515-peri-sysreg
+              - samsung,exynos5515-top-sysreg
               - samsung,exynos7870-cam0-sysreg
               - samsung,exynos7870-disp-sysreg
               - samsung,exynos8895-fsys0-sysreg
@@ -100,6 +103,8 @@ allOf:
               - google,gs101-misc-sysreg
               - google,gs101-peric0-sysreg
               - google,gs101-peric1-sysreg
+              - samsung,exynos5515-fsys-sysreg
+              - samsung,exynos5515-peri-sysreg
               - samsung,exynos850-cmgp-sysreg
               - samsung,exynos850-peri-sysreg
               - samsung,exynos850-sysreg

-- 
2.54.0

