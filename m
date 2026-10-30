From: Aiden Isik <aidenisik@member.fsf.org>
Date: Fri, 30 Oct 2026 20:33:57 +0000
Subject: [PATCH v3 2/5] dt-bindings: soc: samsung: exynos-pmu: Add
 Exynos5515 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-for-next-lucky7-v3-2-81e02272ce69@member.fsf.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=956;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=u5w9oDBuV+q/JxmEewB9ecAjYkFIvHtUgbXKYE3snfg=;
 b=owEBiQJ2/ZANAwAIAUknAbLEetfrAcsmYgBq5P9BWj3cp07eny7nWeYelC5iwoGlylEEAbuTD
 jG3RYJC+xSJAk8EAAEIADkWIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCauT/QRsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQSScBssR61+tHVg/+M1rsIcz0uUNK/8caEG3ZIfganwEVCQ/
 ufqay8FMzfjgwt5TkdJoAwDFfyj7KpfPHGtW7hLE//0EAhIyWCkw/yYWqliLSUGNoJzRFODEG/M
 WkxRu4eSum8WFC02NxTmkw+0KcBsV5FiIe+WZKkPT6FVr5aNukxAAVMnwIK+P4IE7P3RoHUwXtY
 kIZE5FP0WSckxgoz/9l96VUVF8sesk/QVR/PyeTYq5wkjxLXjJwqzL8ZsECrft0ah5V3vcf41XJ
 MBo95k0+GigXF14NBr4xarZRfrSStoYa7WvwFzNgsJlKqS3YoUGnrAqAIq/eCGee7NNA9OKo9LZ
 J2ASn84vHf/RhwwDduRDu2HMApjdbIWp8j1zUErwzCVuzad9urxaczGNhatcw64h5n8WndkDEAF
 YJVopq6IP4Bh2ZJ4FCQsa3k5q0iX/Bf3KUc/IK4V5aB8uDeN6fho9zVXaBHwU6neFeN9Ift/fNm
 I6Ely7lNsz64JZchDj/NFyc09KSIMVQQSSLD9hGOQir4EYYH5neY3Nc/IqQ46BXQoz3VCHtr81G
 uJTnbbZ8/Ej8kkvRqY2IWr2MTkj1pOzOFE5bhIOC7VQN9fIp+y3l6Egf6pEn0LS67IuvZbBu1s7
 R0ziopYG9tWdYrQw7hGnknX/s7UzheDB9y9l/1+WceR5ooJMz7WI=
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

