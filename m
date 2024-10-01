From: =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>
Date: Tue, 01 Oct 2024 16:37:33 +0200
Subject: [PATCH v13 03/12] pinctrl: single: add marvell,pxa1908-padconf
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241001-pxa1908-lkml-v13-3-6b9a7f64f9ae@skole.hr>
References: <20241001-pxa1908-lkml-v13-0-6b9a7f64f9ae@skole.hr>
In-Reply-To: <20241001-pxa1908-lkml-v13-0-6b9a7f64f9ae@skole.hr>
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
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=994;
 i=duje.mihanovic@skole.hr; s=20240706; h=from:subject:message-id;
 bh=wmllmkXuy52PZE0mmFVA4U83iFJjDnJw2/MynI3ODOQ=;
 b=owGbwMvMwCW21nBykGv/WmbG02pJDGl/OCfdMvizNOeYzcdZO07nZccd2P37ePn5bY/elAY3b
 PoixDr1f0cpC4MYF4OsmCJL7n/Ha7yfRbZuz15mADOHlQlkCAMXpwBM5GoyI8OC/67Hc+yU+Gb+
 mOx1s9bd9oDZZMeyZcFCZ9b3swQZdqgw/C+eMP9D4sFmqYj3HlflK172Heaf8XNZzILY9Yfqw4W
 4jNgA
X-Developer-Key: i=duje.mihanovic@skole.hr; a=openpgp;
 fpr=6DFF41D60DF314B5B76BA630AD319352458FAD03
X-Endpoint-Received: by B4 Relay for duje.mihanovic@skole.hr/20240706 with auth_id=191
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the "marvell,pxa1908-padconf" compatible to allow migrating to a
separate pinctrl driver later.

Acked-by: Linus Walleij <linus.walleij@linaro.org>
Signed-off-by: Duje Mihanović <duje.mihanovic@skole.hr>
---
 drivers/pinctrl/pinctrl-single.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/pinctrl/pinctrl-single.c b/drivers/pinctrl/pinctrl-single.c
index 2ec599e383e4b2d463725b8baf4bb8bbcdc4c9f1..09fe7e6233f00d83de385c3a0f449bc4a709681f 100644
--- a/drivers/pinctrl/pinctrl-single.c
+++ b/drivers/pinctrl/pinctrl-single.c
@@ -1966,6 +1966,7 @@ static const struct pcs_soc_data pinconf_single = {
 };
 
 static const struct of_device_id pcs_of_match[] = {
+	{ .compatible = "marvell,pxa1908-padconf", .data = &pinconf_single },
 	{ .compatible = "ti,am437-padconf", .data = &pinctrl_single_am437x },
 	{ .compatible = "ti,am654-padconf", .data = &pinctrl_single_am654 },
 	{ .compatible = "ti,dra7-padconf", .data = &pinctrl_single_dra7 },

-- 
2.46.2

