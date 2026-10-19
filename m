From: Aiden Isik <aidenisik@member.fsf.org>
Date: Mon, 19 Oct 2026 15:41:31 +0100
Subject: [PATCH 2/3] dt-bindings: pinctrl: samsung: add
 exynos5515-wakeup-eint compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-for-next-lucky7-pinctrl-v1-2-0f77e94c70bc@member.fsf.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1047;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=q5YBELZSChcm5N+9fv9roR9m2IQnUyRk2ttRDDQKDEc=;
 b=owEBiQJ2/ZANAwAIAUknAbLEetfrAcsmYgBq1iwajzFWg0aVeVqU+vV1FOodxeEllVHtW/OFH
 4mNd2Jlj++JAk8EAAEIADkWIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCatYsGhsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQSScBssR61+uaEBAAskBR84nnZ+fZUkuAU68wmG506UQBr2n
 3L2REb/7wvEQwpeyxuVH0eTvrWlytBIRzRVLQdTnRqIP0GpD5epet53OLL1NOLM/c5fvS5Hkclx
 /2FjEVtmtVAPZaLWpwEQUmnMob2SVxMKr01Pu8xo2onFrHKT6TrkwH5cd8rQpBbGX+1XTddx20o
 7UxfziSl6+rebTl3o6sq/rWBYHH2WVZ3M2M41MS5S2tuRTq15AQpAPMGzcbR4gfBYh314jmQX7f
 9L+LAxhCTJKISzUQGHJBsHBmQ0caaaqXClGffewEmxSM74EFZB3ogtLOpR5Gvk6yeaODnF0wfZx
 3kFJYZhWpmNHxSSVwZ3X0Fb20v6RQ99k5SCLtsQvrQVRafgIG3ApT4bCgxTR2WAqQxBhYXoaNi6
 bbZ2sBH8kbMHGk/1GkJw4Hi54jwU/DSaW+eDTPMqZoy+y2rvai2S+oxf4P8suKQeg3npJ34fKg/
 O3hsqEr6G8oyoop7bpRMt+P8/1cORxpjfORzqCXBZ+PuQ42sz3b/UDB1jmmP3+W4f9yEgBN05+K
 JZ/lR/Qsjhxxoe0LhVT1r6o8HZoW63uMYgh+WcMc98PWfZmtdLcy7nVuVYgkhh+F07TJ+HLH9oN
 ZBqCDnyvCvkle9iaxgOjDhkr6KQxpyeETjzSpQE5G+hfHxnQmxkE=
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the pinctrl wakeup compatible for the Exynos5515 SoC. It is
register-compatible with Exynos850, so document it as such.

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
 .../devicetree/bindings/pinctrl/samsung,pinctrl-wakeup-interrupt.yaml    | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/samsung,pinctrl-wakeup-interrupt.yaml b/Documentation/devicetree/bindings/pinctrl/samsung,pinctrl-wakeup-interrupt.yaml
index 802911e23aff..d5200b04a1dd 100644
--- a/Documentation/devicetree/bindings/pinctrl/samsung,pinctrl-wakeup-interrupt.yaml
+++ b/Documentation/devicetree/bindings/pinctrl/samsung,pinctrl-wakeup-interrupt.yaml
@@ -49,6 +49,7 @@ properties:
           - enum:
               - google,gs101-wakeup-eint
               - samsung,exynos2200-wakeup-eint
+              - samsung,exynos5515-wakeup-eint
               - samsung,exynos9610-wakeup-eint
               - samsung,exynos9810-wakeup-eint
               - samsung,exynos990-wakeup-eint

-- 
2.54.0

