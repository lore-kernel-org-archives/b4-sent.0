From: =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>
Date: Wed, 24 Apr 2024 20:42:29 +0200
Subject: [PATCH v10 02/12] dt-bindings: pinctrl: pinctrl-single: add
 marvell,pxa1908-padconf compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240424-pxa1908-lkml-v10-2-36cdfb5841f9@skole.hr>
References: <20240424-pxa1908-lkml-v10-0-36cdfb5841f9@skole.hr>
In-Reply-To: <20240424-pxa1908-lkml-v10-0-36cdfb5841f9@skole.hr>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Linus Walleij <linus.walleij@linaro.org>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Tony Lindgren <tony@atomide.com>, 
 Haojian Zhuang <haojian.zhuang@linaro.org>, 
 =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>, 
 Lubomir Rintel <lkundrak@v3.sk>, Catalin Marinas <catalin.marinas@arm.com>, 
 Will Deacon <will@kernel.org>, Kees Cook <keescook@chromium.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>, Rob Herring <robh@kernel.org>
Cc: phone-devel@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 Karel Balej <balejk@matfyz.cz>, David Wronek <david@mainlining.org>, 
 linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=989;
 i=duje.mihanovic@skole.hr; h=from:subject:message-id;
 bh=KkKUaK2SeDyP20scuUXm7oVk+QfHUL3F87v8Iwvt8qk=;
 b=owEBbQKS/ZANAwAIAZoRnrBCLZbhAcsmYgBmKVKUl27/OG+PLk3ZXfgd+Slke19f6jnwssT/t
 Ej89zrVxnmJAjMEAAEIAB0WIQRT351NnD/hEPs2LXiaEZ6wQi2W4QUCZilSlAAKCRCaEZ6wQi2W
 4SowD/9Z1fBqrqZtXeWdIrjCtAVge6G3+6l00V8MVHqJpjOnSCPTo0EcDaXOrSMZZCwnjUwbWCB
 GNFzU1sFeYBEp2Tmk7RT+wAB+UAaJNA8AlkPSF15DJhezdiHfVMibW+BEil7/kzolcSbDB+Pm6A
 xOBtQ59I1r4XmyohtVaZFqs7qJVrDv6z9ZmwdZL0RmCB9BrjxTRkv3lO3BjFT9dVpphNsNfmLpf
 u/6U/LV4hV6D1swBbDqcOKscS29SJ2ISMgZL6ipRApB8Wbk3w8GsvMzjWszGQ6LfezGspxehlnm
 sF5j5u281gFYzB/LuKOp/Uzw/PCNmDUyt+258QCusRnb/dHbsN6cfzkctobk15383Tw2PggaXhj
 7gxaN3kxLc1Rg5Lf84/mQotyLApkzZH4eTId86jd+ApYSq22XPNUd4CmJ6Aev6Mwy1NTFV8wPZ2
 djYLmYFDLQ/FJm6+EraY1bEjt06Iy3b2yPV4SVHQrSZ1mIyPb0+BmcAUvuSXXi0EhD1rLuxJMHe
 jLSK+d8peMZMiQiG3mIEqvlBYyjfPY3acounggQo0FgQEWq2XfF2tlpxgCZ6Eh9TTRulxFHN3lP
 5tuZK0cb/UYhlcwkUerOevSEyW0BYqcrw4y/NFfKMoaXfD4l8+g/JzniMGs21McWMPACio0R39k
 x5KLyWuowS7cLvg==
X-Developer-Key: i=duje.mihanovic@skole.hr; a=openpgp;
 fpr=53DF9D4D9C3FE110FB362D789A119EB0422D96E1
X-Endpoint-Received: by B4 Relay for duje.mihanovic@skole.hr/default with auth_id=112
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the "marvell,pxa1908-padconf" compatible to allow migrating to a
separate pinctrl driver later.

Reviewed-by: Rob Herring <robh@kernel.org>
Acked-by: Linus Walleij <linus.walleij@linaro.org>
Signed-off-by: Duje Mihanović <duje.mihanovic@skole.hr>
---
 Documentation/devicetree/bindings/pinctrl/pinctrl-single.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/pinctrl-single.yaml b/Documentation/devicetree/bindings/pinctrl/pinctrl-single.yaml
index c11495524dd2..1ce24ad8bc73 100644
--- a/Documentation/devicetree/bindings/pinctrl/pinctrl-single.yaml
+++ b/Documentation/devicetree/bindings/pinctrl/pinctrl-single.yaml
@@ -33,6 +33,10 @@ properties:
               - ti,omap5-padconf
               - ti,j7200-padconf
           - const: pinctrl-single
+      - items:
+          - enum:
+              - marvell,pxa1908-padconf
+          - const: pinconf-single
 
   reg:
     maxItems: 1

-- 
2.44.0

