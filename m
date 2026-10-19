From: Aiden Isik <aidenisik@member.fsf.org>
Date: Mon, 19 Oct 2026 15:41:30 +0100
Subject: [PATCH 1/3] dt-bindings: pinctrl: samsung: Add compatible for
 Exynos5515
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-for-next-lucky7-pinctrl-v1-1-0f77e94c70bc@member.fsf.org>
References: <20261019-for-next-lucky7-pinctrl-v1-0-0f77e94c70bc@member.fsf.org>
In-Reply-To: <20261019-for-next-lucky7-pinctrl-v1-0-0f77e94c70bc@member.fsf.org>
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Sylwester Nawrocki <s.nawrocki@samsung.com>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, Linus Walleij <linusw@kernel.org>, 
 Rob Herring <robh@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Tomasz Figa <tomasz.figa@gmail.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aiden Isik <aidenisik@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=844;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=wcMJv5MC9TAqtq4PfS0HwwKmDAbPXKFvyCt4uDAd3gs=;
 b=owEBiQJ2/ZANAwAIAUknAbLEetfrAcsmYgBq1iwalT3DrmyIqPYLP3Z7S5COD3XtGVEIvxELp
 cCUWs70fYSJAk8EAAEIADkWIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCatYsGhsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQSScBssR61+u50hAAlqJrRNdYR/IhdgDR2Z4JKrlPojiSFZF
 r4kSl4JfDqKJeVBbydVc+TRfP3AiSN/jpBtieHLGjPMSuCE+2/r0zSa5LSetSGq72tBEo8fE0DR
 /4xc+peLKdp/oJjZxpbDS3Yoi0VUITPhjzy6zW6aGjfV4CtYYpCoN/TR6k2VK9fYAxkVKx4hqmV
 2Mrr4xla3sowMZ2zMsZasqg1leusJ8kLDcTuMKiSWiU8fRW7gGRiqYqNOrK5zsHZtRvK7j10IEE
 5P7c4sUjaTnV87ecrHA/JQLw/OAcvVdUKgjPGlXMzQbyU2PmV2m/dCu8LkupnMyuCOk8ObY3Far
 prfwgZytOvlxXX2SnfquLe2ydvj8N65Q0PJpWPNU27ns8KGTmfzEkv2gLt/VWkXamO/EtDJITal
 U8Pil1ONY0bdbgSlmPr0LcLWFZ6uUyihnS/dFAyzdnXUFNLnSt5QZNJdkzKP4FgZE0MmwBVkE3d
 bG1czf3R99cmTjopp/VScbDKxv/N41mUtZdJIV/YhqEvql3/CxRTO3Lrl5fDoshV41e99wHKpvW
 m2hF3agqVs3Zl0STBww2u5WbTlrx0t1BT5hpCt44YrQJei32adFTbsQCoyuEKm9uqGiMif5ye98
 H7qqtq1Ts774mlTeE7w7N0qOQ6PiSeryjdrDUPCQgQaQTzhTamFo=
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Exynos5515 pinctrl compatible string.

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
 Documentation/devicetree/bindings/pinctrl/samsung,pinctrl.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/samsung,pinctrl.yaml b/Documentation/devicetree/bindings/pinctrl/samsung,pinctrl.yaml
index 1feb6a6fc690..7e49ca7b560a 100644
--- a/Documentation/devicetree/bindings/pinctrl/samsung,pinctrl.yaml
+++ b/Documentation/devicetree/bindings/pinctrl/samsung,pinctrl.yaml
@@ -49,6 +49,7 @@ properties:
       - samsung,exynos5410-pinctrl
       - samsung,exynos5420-pinctrl
       - samsung,exynos5433-pinctrl
+      - samsung,exynos5515-pinctrl
       - samsung,exynos7-pinctrl
       - samsung,exynos7870-pinctrl
       - samsung,exynos7885-pinctrl

-- 
2.54.0

