From: Aiden Isik <aidenisik@member.fsf.org>
Date: Tue, 18 Aug 2026 16:05:42 +0100
Subject: [PATCH v2 1/2] dt-bindings: hwinfo: samsung,exynos-chipid: Add
 Exynos5515 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260818-for-next-lucky7-chipid-v2-1-28ae49f5c349@member.fsf.org>
References: <20260818-for-next-lucky7-chipid-v2-0-28ae49f5c349@member.fsf.org>
In-Reply-To: <20260818-for-next-lucky7-chipid-v2-0-28ae49f5c349@member.fsf.org>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aiden Isik <aidenisik@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=950;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=HkPlddHKQwmqWY1ufNhu6MddjjvEqgdH7uQbcVq9NGo=;
 b=owEBbQKS/ZANAwAIAUknAbLEetfrAcsmYgBqhHUY7ydlaLNNK0/u9GgxtdHJziy1rKsqJDZ6e
 CEaOqscgRGJAjMEAAEIAB0WIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCaoR1GAAKCRBJJwGyxHrX
 6yh2EACcHTH6X8Oxhu2iTKt+S/NSJkPZbr05I7QQwLnen0SomU4mSTbVSPFObCQKD4/J/oEiJ90
 yGGFaYKEG/ZECSrOIEFSNj6tfA+JuDkxV3Xikbj0HEDnSCQ1cNlk9JZJ3HBO1h/z/NKBUcPeQnc
 FV8zxiZ/va3xUT0s68afQY9ecQMV2xwzotSM9qS9tUx7AVkJvS6MciB7KC0dvadeB9PjGw4VplX
 D5SwECOHsZIOsgtJyrCDMgSvTx48fLCZflE1i9dUYKushaZPvMdAU4OU+0Qqz0Vfs+2Qs744zNn
 NResE0AA6KkEGh9XUhM0AYCoDtQ4rCjNy7hNnpIkMfI3yuG2g3DTkaMNf2Wm4V/1o6hqQOK1m9o
 MV8glC88kJlEZaVEP4MXGlRs3MbidYNjYlVJuT7BgQ2YfEnhBU6Vajm15kM2XUiXy3uNzVdXCXE
 vb/21em44JXEb8yl8OCBk0wmq+LyaSgL20BCyLsFakPKU2OFvy3LMLEdbt9xfkCB1cGwEGfZJlg
 0A1C5J/g5Hp9Ca4du6sTNkL3JJZvNpb9x0bDJPh1ROc6yyoNL0h5B39Ulw7dTIMhpgj68ppJzIY
 Y5ACoFYzawEm6mC5DMMF3l7dwpacBMNpBehwfQarzj6DXXpzx9i++C7frjN6lVbR/TVH/1cFFTk
 pM8PYmwr7jDa2mw==
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add "samsung,exynos5515-chipid" compatible string to binding document,
which is fully compatible with "samsung,exynos850-chipid".

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
 Documentation/devicetree/bindings/hwinfo/samsung,exynos-chipid.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/hwinfo/samsung,exynos-chipid.yaml b/Documentation/devicetree/bindings/hwinfo/samsung,exynos-chipid.yaml
index b9cdfe52b62f..619faf33214b 100644
--- a/Documentation/devicetree/bindings/hwinfo/samsung,exynos-chipid.yaml
+++ b/Documentation/devicetree/bindings/hwinfo/samsung,exynos-chipid.yaml
@@ -25,6 +25,7 @@ properties:
       - items:
           - enum:
               - samsung,exynos2200-chipid
+              - samsung,exynos5515-chipid
               - samsung,exynos7885-chipid
               - samsung,exynos8895-chipid
               - samsung,exynos9610-chipid

-- 
2.54.0

