From: =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>
Date: Tue, 18 Jun 2024 14:08:13 +0200
Subject: [PATCH RESEND v10 02/12] dt-bindings: pinctrl: pinctrl-single: add
 marvell,pxa1908-padconf compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240618-pxa1908-lkml-v10-2-754e5ece9078@skole.hr>
References: <20240618-pxa1908-lkml-v10-0-754e5ece9078@skole.hr>
In-Reply-To: <20240618-pxa1908-lkml-v10-0-754e5ece9078@skole.hr>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Linus Walleij <linus.walleij@linaro.org>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Tony Lindgren <tony@atomide.com>, 
 Haojian Zhuang <haojian.zhuang@linaro.org>, 
 =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>, 
 Lubomir Rintel <lkundrak@v3.sk>, Catalin Marinas <catalin.marinas@arm.com>, 
 Will Deacon <will@kernel.org>, Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>, Rob Herring <robh@kernel.org>, 
 Kees Cook <kees@kernel.org>
Cc: phone-devel@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 Karel Balej <balejk@matfyz.cz>, David Wronek <david@mainlining.org>, 
 linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=989;
 i=duje.mihanovic@skole.hr; h=from:subject:message-id;
 bh=DHVN0JCnU9cjk5HoT2nuCXlkwB4DvFUsqraG05pTwEY=;
 b=owEBbQKS/ZANAwAIAZoRnrBCLZbhAcsmYgBmcXjRcSJnF85BqFVepG9EMDyQ5R/kh868wHfKL
 rhGHfjfhkaJAjMEAAEIAB0WIQRT351NnD/hEPs2LXiaEZ6wQi2W4QUCZnF40QAKCRCaEZ6wQi2W
 4Sl0D/4qdztHij0UjE7SDl6Kq+zjmKmNa83246ceGFzwDddPrJOEd0yGeHsvv4VSpx+37aY7/2K
 Xqm1+uyGlWevlP8GNiHJFoioql8g5V4j6JRdlZLoqkIieII6w5XDF3qtYTaGqmRjDKx119eOTJ/
 8s0qZsLsynK2QXqTVuCrs5K1E54Ql+48Zi7tZpdkfb8HFq9rRy4aFgtGXuERCLkl/GJd6+GuI/n
 IcpuM318ymNQn+6UtNyvYlPRHsupRJhgX2pnR1PoYug+iTRdKGpNyTS60LNsUOmdT2SEItAqyOz
 8zA+yfh2M8dePSh06d4nxmSJ0BRbPoUaGnqmnrlDhTAiYYz6FE6GD6XZow6QKb6OZ520Kn6/zII
 dj7ZxyHY16huTFTHVSh9IAxDE6G6gPPY+pfjXQJ4xS4NSAAnNibqPOZHHeMmPkoYJCY2ZtguxcT
 yJf8WdOQPjjWO3IISkRTVLVrO6bYDrnntoa+6VHualswq7B3VKX/V+X9EOXjh1IEtgut/q4cfST
 NeRqaSWXbuT6Ij6RjqxYm/pgxpyzViNonXR8pM/rHWz1I8CXx25TnleixG0/ep29Z+or5UuRvw8
 mdGdGS9bivAdKm38D/N9AFqe6xJEuVauIpnMJPC4EJWP+Lj4LjDqUEQAKPYbi+hf50qmoCgpZLf
 m19cb16EaTUb7pA==
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
2.45.2

