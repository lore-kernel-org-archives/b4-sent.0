From: Aiden Isik <aidenisik@member.fsf.org>
Date: Tue, 20 Oct 2026 01:02:36 +0100
Subject: [PATCH v2 3/3] pinctrl: samsung: Add Exynos5515 pinctrl
 configuration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-for-next-lucky7-pinctrl-v2-3-b6b0e6065452@member.fsf.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=8848;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=WpGruSkDQ5IsRlg36hYMM7lL165QL22fCdhSe6pa0fI=;
 b=owEBiQJ2/ZANAwAIAUknAbLEetfrAcsmYgBq1q+bjOFJbWOXCtr6XjDBVxo6/5QoGIFN4yZSQ
 cWXVSVZKeWJAk8EAAEIADkWIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCatavmxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQSScBssR61+ukeg//TMIg4hn0gY8svHMqv6Duyi5jfPRl5IJ
 vrzBEC98/oXKRp+Xu5+4Yg87UduiJBRSEauJM25U7XZUYfLjMxmXxZZTmbxja35+ceXWqHkm0m0
 Z1cyqmR2/WspWa4LO3JJFwQX9frzOK6JMd4uItIMzVqQz35PEAu0ZikclA77ZBOWD/6v8Fk50Hf
 ROi+9pSispcKnEDlFpkPUS0u1208xyGmb+3bZhlZ4qDwAkif2ljEdEHO9JKHWC+3vPboSD7QgZQ
 LuSV4kgp7YXLiod0fi7D/YhuN7oDiX12r0hYoUoIJtz5f5/bVPlcNv7KRt0gJiKS7s+XdpACE5O
 eGQahBGehoLwSD2SsAK7+03/bYFBXTsYSVg978O/HmGZ59wimezU74noAD2a19CxCDsuET/wzZM
 kdJuMG6PMG/0ev8gHmi5L4GDzXlhHj7nxGYoknAdHekt9AV4FHZHhMc9Xz3LLPPrbjhTxVGRtBQ
 e/KlxQeLPzhVB2HrewuJdLLivBmRvPM3qeg7nz5cm871esJU2MudidrqexNm9Qgx3Ae+/XvVxKi
 ogVeFscL7s1WPGcOdoH0fV2htMjb1BHKwAt/hv8vk+QZBSr5OtzF4TjknaKPvKvt1nlKj0VYsWP
 Bf9fSTKcizv4RzU2Yoftpv9mX+M+5oR6cJ5Bxrxynuz/WzyyMHD8=
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the pinctrl configuration for the Exynos5515 SoC. Reuse the pinctrl
macros from Exynos850 and GS101, and add a few Exynos5515-specific macros.

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
 drivers/pinctrl/samsung/pinctrl-exynos-arm64.c | 119 +++++++++++++++++++++++++
 drivers/pinctrl/samsung/pinctrl-exynos.h       |  20 +++++
 drivers/pinctrl/samsung/pinctrl-samsung.c      |   2 +
 drivers/pinctrl/samsung/pinctrl-samsung.h      |   1 +
 4 files changed, 142 insertions(+)

diff --git a/drivers/pinctrl/samsung/pinctrl-exynos-arm64.c b/drivers/pinctrl/samsung/pinctrl-exynos-arm64.c
index 1aa977d2a1f8..3983979631c9 100644
--- a/drivers/pinctrl/samsung/pinctrl-exynos-arm64.c
+++ b/drivers/pinctrl/samsung/pinctrl-exynos-arm64.c
@@ -488,6 +488,125 @@ const struct samsung_pinctrl_of_match_data exynos5433_of_data __initconst = {
 	.num_ctrl	= ARRAY_SIZE(exynos5433_pin_ctrl),
 };
 
+/* pin banks of exynos5515 pin-controller 0 (ALIVE) */
+static const struct samsung_pin_bank_data exynos5515_pin_banks0[] __initconst = {
+	GS101_PIN_BANK_EINTW(8, 0x000, "gpa0", 0x00, 0x00),
+	GS101_PIN_BANK_EINTW(7, 0x020, "gpa1", 0x04, 0x08),
+	EXYNOS850_PIN_BANK_EINTN(6, 0x040, "gpq0"),
+	EXYNOS850_PIN_BANK_EINTN(6, 0x060, "etc0"),
+};
+
+/* pin banks of exynos5515 pin-controller 1 (CMGP) */
+static const struct samsung_pin_bank_data exynos5515_pin_banks1[] __initconst = {
+	GS101_PIN_BANK_EINTW(1, 0x000, "gpm0", 0x00, 0x00),
+	GS101_PIN_BANK_EINTW(1, 0x020, "gpm1", 0x04, 0x04),
+	GS101_PIN_BANK_EINTW(1, 0x040, "gpm2", 0x08, 0x08),
+	GS101_PIN_BANK_EINTW(1, 0x060, "gpm3", 0x0c, 0x0c),
+	GS101_PIN_BANK_EINTW(1, 0x080, "gpm4", 0x10, 0x10),
+	GS101_PIN_BANK_EINTW(1, 0x0a0, "gpm5", 0x14, 0x14),
+	GS101_PIN_BANK_EINTW(1, 0x0c0, "gpm6", 0x18, 0x18),
+	GS101_PIN_BANK_EINTW(1, 0x0e0, "gpm7", 0x1c, 0x1c),
+	GS101_PIN_BANK_EINTW(1, 0x100, "gpm8", 0x20, 0x20),
+	GS101_PIN_BANK_EINTW(1, 0x120, "gpm9", 0x24, 0x24),
+	GS101_PIN_BANK_EINTW(1, 0x140, "gpm10", 0x28, 0x28),
+	GS101_PIN_BANK_EINTW(1, 0x160, "gpm11", 0x2c, 0x2c),
+	GS101_PIN_BANK_EINTW(1, 0x180, "gpm12", 0x30, 0x30),
+	GS101_PIN_BANK_EINTW(1, 0x1a0, "gpm13", 0x34, 0x34),
+	GS101_PIN_BANK_EINTW(1, 0x1c0, "gpm14", 0x38, 0x38),
+	GS101_PIN_BANK_EINTW(1, 0x1e0, "gpm15", 0x3c, 0x3c),
+	GS101_PIN_BANK_EINTW(1, 0x200, "gpm16", 0x40, 0x40),
+	GS101_PIN_BANK_EINTW(1, 0x220, "gpm17", 0x44, 0x44),
+	GS101_PIN_BANK_EINTW(1, 0x240, "gpm18", 0x48, 0x48),
+	GS101_PIN_BANK_EINTW(1, 0x260, "gpm19", 0x4c, 0x4c),
+	EXYNOS5515_PIN_BANK_EINTG(1, 0x280, "gpm20", 0x50, 0x50),
+	EXYNOS5515_PIN_BANK_EINTG(1, 0x2a0, "gpm21", 0x54, 0x54),
+	GS101_PIN_BANK_EINTW(1, 0x2c0, "gpm22", 0x58, 0x58),
+	GS101_PIN_BANK_EINTW(1, 0x2e0, "gpm23", 0x5c, 0x5c),
+	GS101_PIN_BANK_EINTW(1, 0x300, "gpm24", 0x60, 0x60),
+	GS101_PIN_BANK_EINTW(1, 0x320, "gpm25", 0x64, 0x64),
+	GS101_PIN_BANK_EINTW(1, 0x340, "gpm26", 0x68, 0x68),
+};
+
+/* pin banks of exynos5515 pin-controller 2 (DISP) */
+static const struct samsung_pin_bank_data exynos5515_pin_banks2[] __initconst = {
+	EXYNOS5515_PIN_BANK_EINTN(5, 0x000, "gpb0"),
+	EXYNOS5515_PIN_BANK_EINTN(4, 0x020, "gpb1"),
+};
+
+/* pin banks of exynos5515 pin-controller 3 (FSYS) */
+static const struct samsung_pin_bank_data exynos5515_pin_banks3[] __initconst = {
+	EXYNOS5515_PIN_BANK_EINTN(4, 0x000, "gpf0"),
+	EXYNOS5515_PIN_BANK_EINTN(8, 0x020, "gpf1"),
+	EXYNOS5515_PIN_BANK_EINTN(6, 0x040, "gpf2"),
+};
+
+/* pin banks of exynos5515 pin-controller 4 (PERI) */
+static const struct samsung_pin_bank_data exynos5515_pin_banks4[] __initconst = {
+	GS101_PIN_BANK_EINTG(2, 0x000, "gpp0", 0x00, 0x00),
+	GS101_PIN_BANK_EINTG(2, 0x020, "gpp1", 0x04, 0x04),
+	GS101_PIN_BANK_EINTG(2, 0x040, "gpp2", 0x08, 0x08),
+	GS101_PIN_BANK_EINTG(3, 0x060, "gpp3", 0x0c, 0x0c),
+	GS101_PIN_BANK_EINTG(4, 0x080, "gpp4", 0x10, 0x10),
+	GS101_PIN_BANK_EINTG(4, 0x0A0, "gpc0", 0x14, 0x14),
+	GS101_PIN_BANK_EINTG(2, 0x0C0, "gpc1", 0x18, 0x18),
+	GS101_PIN_BANK_EINTG(2, 0x0E0, "gpg0", 0x1c, 0x1c),
+	GS101_PIN_BANK_EINTG(2, 0x100, "gpg1", 0x20, 0x20),
+	GS101_PIN_BANK_EINTG(2, 0x120, "gpg2", 0x24, 0x24),
+	GS101_PIN_BANK_EINTG(2, 0x140, "gpg3", 0x28, 0x28),
+	GS101_PIN_BANK_EINTG(2, 0x160, "gpg4", 0x2c, 0x2c),
+	GS101_PIN_BANK_EINTG(2, 0x180, "gpg5", 0x30, 0x30),
+	GS101_PIN_BANK_EINTG(2, 0x1A0, "gpg6", 0x34, 0x34),
+	GS101_PIN_BANK_EINTG(2, 0x1C0, "gpg7", 0x38, 0x38),
+};
+
+/* pin banks of exynos5515 pin-controller 5 (VTS) */
+static const struct samsung_pin_bank_data exynos5515_pin_banks5[] __initconst = {
+	EXYNOS5515_PIN_BANK_EINTN(2, 0x000, "gpv0"),
+};
+
+static const struct samsung_pin_ctrl exynos5515_pin_ctrl[] __initconst = {
+	{
+		/* pin-controller instance 0 ALIVE data */
+		.pin_banks	= exynos5515_pin_banks0,
+		.nr_banks	= ARRAY_SIZE(exynos5515_pin_banks0),
+		.eint_wkup_init	= exynos_eint_wkup_init,
+		.suspend	= gs101_pinctrl_suspend,
+		.resume		= gs101_pinctrl_resume,
+	}, {
+		/* pin-controller instance 1 CMGP data */
+		.pin_banks	= exynos5515_pin_banks1,
+		.nr_banks	= ARRAY_SIZE(exynos5515_pin_banks1),
+		.eint_gpio_init	= exynos_eint_gpio_init,
+		.eint_wkup_init	= exynos_eint_wkup_init,
+		.suspend	= gs101_pinctrl_suspend,
+		.resume		= gs101_pinctrl_resume,
+	}, {
+		/* pin-controller instance 2 DISP data */
+		.pin_banks	= exynos5515_pin_banks2,
+		.nr_banks	= ARRAY_SIZE(exynos5515_pin_banks2),
+	}, {
+		/* pin-controller instance 3 FSYS data */
+		.pin_banks	= exynos5515_pin_banks3,
+		.nr_banks	= ARRAY_SIZE(exynos5515_pin_banks3),
+	}, {
+		/* pin-controller instance 4 PERI data */
+		.pin_banks	= exynos5515_pin_banks4,
+		.nr_banks	= ARRAY_SIZE(exynos5515_pin_banks4),
+		.eint_gpio_init	= exynos_eint_gpio_init,
+		.suspend	= gs101_pinctrl_suspend,
+		.resume		= gs101_pinctrl_resume,
+	}, {
+		/* pin-controller instance 5 VTS data */
+		.pin_banks	= exynos5515_pin_banks5,
+		.nr_banks	= ARRAY_SIZE(exynos5515_pin_banks5),
+	},
+};
+
+const struct samsung_pinctrl_of_match_data exynos5515_of_data __initconst = {
+	.ctrl		= exynos5515_pin_ctrl,
+	.num_ctrl	= ARRAY_SIZE(exynos5515_pin_ctrl),
+};
+
 /* pin banks of exynos7 pin-controller - ALIVE */
 static const struct samsung_pin_bank_data exynos7_pin_banks0[] __initconst = {
 	/* Must start with EINTG banks, ordered by EINT group number. */
diff --git a/drivers/pinctrl/samsung/pinctrl-exynos.h b/drivers/pinctrl/samsung/pinctrl-exynos.h
index c9c38f8988dd..92bf8f0f1eb0 100644
--- a/drivers/pinctrl/samsung/pinctrl-exynos.h
+++ b/drivers/pinctrl/samsung/pinctrl-exynos.h
@@ -132,6 +132,26 @@
 		.pctl_res_idx   = pctl_idx,			\
 	}							\
 
+#define EXYNOS5515_PIN_BANK_EINTN(pins, reg, id)		\
+	{							\
+		.type		= &exynos850_bank_type_off,	\
+		.pctl_offset	= reg,				\
+		.nr_pins	= pins,				\
+		.eint_type	= EINT_TYPE_NONE,		\
+		.name		= id				\
+	}
+
+#define EXYNOS5515_PIN_BANK_EINTG(pins, reg, id, offs, fltcon_offs)	\
+	{								\
+		.type			= &exynos850_bank_type_alive,	\
+		.pctl_offset		= reg,				\
+		.nr_pins		= pins,				\
+		.eint_type		= EINT_TYPE_GPIO,		\
+		.eint_offset		= offs,				\
+		.eint_fltcon_offset	= fltcon_offs,			\
+		.name			= id				\
+	}
+
 #define EXYNOS7870_PIN_BANK_EINTN(pins, reg, id)		\
 	{							\
 		.type		= &exynos7870_bank_type_alive,	\
diff --git a/drivers/pinctrl/samsung/pinctrl-samsung.c b/drivers/pinctrl/samsung/pinctrl-samsung.c
index 5ecc9ed4c44d..f6b392a84cee 100644
--- a/drivers/pinctrl/samsung/pinctrl-samsung.c
+++ b/drivers/pinctrl/samsung/pinctrl-samsung.c
@@ -1492,6 +1492,8 @@ static const struct of_device_id samsung_pinctrl_dt_match[] = {
 		.data = &exynos2200_of_data },
 	{ .compatible = "samsung,exynos5433-pinctrl",
 		.data = &exynos5433_of_data },
+	{ .compatible = "samsung,exynos5515-pinctrl",
+		.data = &exynos5515_of_data},
 	{ .compatible = "samsung,exynos7-pinctrl",
 		.data = &exynos7_of_data },
 	{ .compatible = "samsung,exynos7870-pinctrl",
diff --git a/drivers/pinctrl/samsung/pinctrl-samsung.h b/drivers/pinctrl/samsung/pinctrl-samsung.h
index bb02fb49b2af..7c60375d5924 100644
--- a/drivers/pinctrl/samsung/pinctrl-samsung.h
+++ b/drivers/pinctrl/samsung/pinctrl-samsung.h
@@ -392,6 +392,7 @@ extern const struct samsung_pinctrl_of_match_data exynos5260_of_data;
 extern const struct samsung_pinctrl_of_match_data exynos5410_of_data;
 extern const struct samsung_pinctrl_of_match_data exynos5420_of_data;
 extern const struct samsung_pinctrl_of_match_data exynos5433_of_data;
+extern const struct samsung_pinctrl_of_match_data exynos5515_of_data;
 extern const struct samsung_pinctrl_of_match_data exynos7_of_data;
 extern const struct samsung_pinctrl_of_match_data exynos7870_of_data;
 extern const struct samsung_pinctrl_of_match_data exynos7885_of_data;

-- 
2.54.0

