From: Aiden Isik <aidenisik@member.fsf.org>
Date: Tue, 20 Oct 2026 01:02:35 +0100
Subject: [PATCH v2 2/3] dt-bindings: pinctrl: samsung: add
 exynos5515-wakeup-eint compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-for-next-lucky7-pinctrl-v2-2-b6b0e6065452@member.fsf.org>
References: <20261020-for-next-lucky7-pinctrl-v2-0-b6b0e6065452@member.fsf.org>
In-Reply-To: <20261020-for-next-lucky7-pinctrl-v2-0-b6b0e6065452@member.fsf.org>
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
 b=owEBiQJ2/ZANAwAIAUknAbLEetfrAcsmYgBq1q+byZGGHKqgzyYI/+ZhaVzdL/qMgghhguFuD
 yZsqKnXyiqJAk8EAAEIADkWIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCatavmxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQSScBssR61+tUiA/+LViUdNF3XYv0m1g86BaXq2JgvWOxiEE
 pyXBgh52h/KHHOhBTx7xF+3Pd5mEeT9NWIZUDmw659ZUZEwTXAGWsFKbKrXWuTgshl+6fB2kC6D
 tLxjn7k4mKrmVgaXbvo30ZfPz9MDU2zPE2n9ukRLfCOvyRaNqBI8YYQlz1ZKddUR7sEaigV3sRO
 I2VcIqeGTpcAmo+8Y1985B/rldNJFSmBsSxT7ph48VUfYIlFLZQro46GL3Wo9YHfLCpG0BASLSE
 fHzA+3kb+UMo78VWD6hL+PiZU8yS5z43qLamKQoWzF4P9ujqCgANYo54yMHC1QVIO+MR9lNUDcK
 CCoXL5u884oA+CFaYj43zEBdb4mzybj+JELRp2r4Hjf2Q42VJx12hGj7AdW8kzPECCGdEapxQfy
 7O79rCij5MXQRoh0uNQ3dZ3gdbQGgkpGIQvNqdtYqBbWS1jvz1c1AbebSXKJ6FlO70fDhi1j1OQ
 b+i19lBwcalbLY0H+7B5lZbaM9Erf109T1CnYzNPIoN3+vULiL96e985RYnHmJgMoQ7FwOLAILq
 LFRFQpm5emx7tT7hKiRAN1SCPHZWrV/NQBE5YKafrd6Nhib5DahFboeyArxsecizy67c+91Ar1T
 L5xvDQsjocOvfhdZTqzqMlmESq9PrXLk3A/ryw2REAEzwQBL1aBc=
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

