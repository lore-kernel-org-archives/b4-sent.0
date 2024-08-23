From: =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>
Date: Fri, 23 Aug 2024 22:54:37 +0200
Subject: [PATCH v12 02/12] dt-bindings: pinctrl: pinctrl-single: add
 marvell,pxa1908-padconf compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240823-pxa1908-lkml-v12-2-cc3ada51beb0@skole.hr>
References: <20240823-pxa1908-lkml-v12-0-cc3ada51beb0@skole.hr>
In-Reply-To: <20240823-pxa1908-lkml-v12-0-cc3ada51beb0@skole.hr>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Linus Walleij <linus.walleij@linaro.org>, 
 Rob Herring <robh+dt@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Tony Lindgren <tony@atomide.com>, 
 Haojian Zhuang <haojian.zhuang@linaro.org>, 
 =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>, 
 Lubomir Rintel <lkundrak@v3.sk>, Catalin Marinas <catalin.marinas@arm.com>, 
 Will Deacon <will@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: phone-devel@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 Karel Balej <balejk@matfyz.cz>, David Wronek <david@mainlining.org>, 
 linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=989;
 i=duje.mihanovic@skole.hr; s=20240706; h=from:subject:message-id;
 bh=jSu/auev6NXw8rqoRVgMNJdUTPhlK55ZwDiRgbxNxJE=;
 b=owGbwMvMwCW21nBykGv/WmbG02pJDGknvmtETLGoaaip5PW9o/+ncSHTSucDN1qt7GSk7q/YX
 LBTJdymo5SFQYyLQVZMkSX3v+M13s8iW7dnLzOAmcPKBDKEgYtTACZSt5WR4fd2lh/ieY/bUpep
 dJS2SaVtU7ykbMuhUWH46anb0k2N2xn+ynZNWKn/T6dC8Yzj5YCJEa6ysdGq2gpyIkwKAeVz9i1
 nAgA=
X-Developer-Key: i=duje.mihanovic@skole.hr; a=openpgp;
 fpr=6DFF41D60DF314B5B76BA630AD319352458FAD03
X-Endpoint-Received: by B4 Relay for duje.mihanovic@skole.hr/20240706 with auth_id=191
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
index e02595316c9f..f83dbf32ad18 100644
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
2.46.0

