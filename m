From: =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>
Date: Wed, 24 Apr 2024 20:42:30 +0200
Subject: [PATCH v10 03/12] pinctrl: single: add marvell,pxa1908-padconf
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240424-pxa1908-lkml-v10-3-36cdfb5841f9@skole.hr>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=938;
 i=duje.mihanovic@skole.hr; h=from:subject:message-id;
 bh=9Fh0rtfqOUxLvMXy/ZdHE5t311Pfv0e+glL7VyPYAcw=;
 b=owEBbQKS/ZANAwAIAZoRnrBCLZbhAcsmYgBmKVKUuQkICKDgKUkYwrMmJLozzbWPsslKjmU7+
 tHQpLftmBqJAjMEAAEIAB0WIQRT351NnD/hEPs2LXiaEZ6wQi2W4QUCZilSlAAKCRCaEZ6wQi2W
 4brMD/9p/aVMBKQWkLSOSYJEGOJVXyQxkUMgSo0y6GQo1A9Rn/6uvPbzV9mEi9261XyKZLxpku2
 ie88dKpir2K5bFKzZfQxFPt2LGc+MvsTch6HIM+KbkFLjGuyBMkxazGdKBCpdr1fe0QwjZy243W
 Tk7VZ9FEJF+Hhi2qHNkeOyUtrKMjwd7HgXdrT/ONpIRKVtlf8clBJ9jRVFSM8mijXV6/rkfTYFC
 nnUd8z4sJcKOQdecakaxunH1Fe4BbAXSu8z2d6/zHB5/3yaPwffoQR7x+l+Qusu8PsvXpvNRuuy
 FB54O4ccAx6peyddh/vDCjLIaBQMpw3e1rfIcWvExwZvSV45if/0iodRrU3FrAeq0xsMyZImels
 N1Ri0ntdHBugRTIdiwEJlGC81gAIqIQMfGVSxz0l/4XMiBViccNZ+/tM2KQc1dAqxkYRqFDu3zo
 8h2Pbw4uoRncG3zsFy6xNOaTck7lXlIL2yWFTQcrKCFi1fDkCrDEwRBaUi0w5Fi1pDzvuEVGtqs
 MhyIuFYecmqBqMl5DvRpg3kwy4qDjeKykM9zux+uFxyTSpseTcMRxgcr/s8xx+pWQ1hSMpdXhWn
 E8dwU2axOEfAVGmmoo9Yf/LJwYI5SC4O360rXNActmBdtS1dS1ayU5Z6M/X4zRHP5jjVYuLjBKe
 ITTloEI4QuDp9TA==
X-Developer-Key: i=duje.mihanovic@skole.hr; a=openpgp;
 fpr=53DF9D4D9C3FE110FB362D789A119EB0422D96E1
X-Endpoint-Received: by B4 Relay for duje.mihanovic@skole.hr/default with auth_id=112
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the "marvell,pxa1908-padconf" compatible to allow migrating to a
separate pinctrl driver later.

Acked-by: Linus Walleij <linus.walleij@linaro.org>
Signed-off-by: Duje Mihanović <duje.mihanovic@skole.hr>
---
 drivers/pinctrl/pinctrl-single.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/pinctrl/pinctrl-single.c b/drivers/pinctrl/pinctrl-single.c
index 19cc0db771a5..c15bf3cbabd7 100644
--- a/drivers/pinctrl/pinctrl-single.c
+++ b/drivers/pinctrl/pinctrl-single.c
@@ -1967,6 +1967,7 @@ static const struct pcs_soc_data pinconf_single = {
 };
 
 static const struct of_device_id pcs_of_match[] = {
+	{ .compatible = "marvell,pxa1908-padconf", .data = &pinconf_single },
 	{ .compatible = "ti,am437-padconf", .data = &pinctrl_single_am437x },
 	{ .compatible = "ti,am654-padconf", .data = &pinctrl_single_am654 },
 	{ .compatible = "ti,dra7-padconf", .data = &pinctrl_single_dra7 },

-- 
2.44.0

