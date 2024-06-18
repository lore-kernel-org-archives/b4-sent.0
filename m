From: =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>
Date: Tue, 18 Jun 2024 14:08:14 +0200
Subject: [PATCH RESEND v10 03/12] pinctrl: single: add
 marvell,pxa1908-padconf compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240618-pxa1908-lkml-v10-3-754e5ece9078@skole.hr>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=938;
 i=duje.mihanovic@skole.hr; h=from:subject:message-id;
 bh=/nR1o+WfwzLszgn+C3p6mt8A5/wqrmlXux49ejE20Hw=;
 b=owEBbQKS/ZANAwAIAZoRnrBCLZbhAcsmYgBmcXjRRS8WFa96wH4cU8qz9ZyqeNrJk9sCMc07P
 rFUy7i9tuKJAjMEAAEIAB0WIQRT351NnD/hEPs2LXiaEZ6wQi2W4QUCZnF40QAKCRCaEZ6wQi2W
 4bmRD/9TZSmiKm1CkLE4xNVYuYwXwZpQIzFIg+m7ibFPr5pFBKqmSxx/vDUuB8epNzwL1wHrY/T
 iBOF3SXpRdxxoj+wUy1m7u2iH4dva83/DLAjQnBh0tAfRlZlLjLI9e6piAeYAImmm2fBwFjWQgx
 ZLI/is000ca8lT/KgvYYoRn5D1uh7dQmSoRt996ElhYSe3lJrc45jqw+Cj8Ni2z+aRYZeHmuSnq
 VJzzr6yQDkut7xDjsNmgOKHe8YQT3FC6+LSBgUeK2kpZGAe0sxOYaE/6IK/h3ivN+lXQ7ilJQ1r
 n16uHVYUKzEHKNsHVg0LvHgchTVxMlQyqHuJip4RJddmK07fhjDCfgDsyXOzzKF43htvnEU4/ai
 VqIW3kd5GN1427ud8IZgxetc6xsdXXbQphtrrOKwyr6Ed/1KEkx2dYP9xbzmoCj5ZtirPCpg1Ih
 3nnEjiXtN1ckxr/WzbfA9OoUnme4yQtLmQs/n33ckwri53mkm6VvKwO4nxaipOEYIpINMTUyBv3
 VvD4tAvB8dqWfl4U1nUGLy+Fgt+bHewiMPu5s9rTqE13olg4aPWKotOz68cXPPnzuSt0hOIxT60
 KNceFpj1VnlQP5vRCZVP5VrKx/z0/pjH8cocMpb8S1eCiZez9VeIjkH4wHVo3Kci7ApgVx51EwE
 vCtLkTBcSsWUAJw==
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
2.45.2

