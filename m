From: Aiden Isik <aidenisik@member.fsf.org>
Subject: [PATCH v2 0/3] Introduce Exynos5515 pinctrl support
Date: Tue, 20 Oct 2026 01:02:33 +0100
Message-Id: <20261020-for-next-lucky7-pinctrl-v2-0-b6b0e6065452@member.fsf.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJmv1moC/4WNQQ6CMBBFr0K6dkhpgIIr72FY2DqFKrZkWgiEc
 HcBD+DyJe+/v7KAZDGwa7IywskG690O4pIw3T1ci2CfOzPBRZnxrAbjCRzOEfpRvxcJg3U6Ug9
 lrkyRF1VVi4Lt64HQ2Pks35sfh1G9UMcjdxidDdHTcl5P2eH9f5ky4MCNlFjnWnKlbx/8KKTUB
 JN6almzbdsXLHp/CdUAAAA=
X-Change-ID: 20261019-for-next-lucky7-pinctrl-64bf54588925
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1902;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=4CKTR/UrVUHdBxRcjY6+8KRZbZVbDeBQa9eE5DqMIL8=;
 b=owEBiQJ2/ZANAwAIAUknAbLEetfrAcsmYgBq1q+awCvmX6gpGP3Hpt0PsTjwRibMBLQtV5I+X
 6YInT7kCyuJAk8EAAEIADkWIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCatavmhsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQSScBssR61+s4zg/9HwQhJWCdTXqJukDRuhk+vd39ps25aAe
 lk2AQDbmWdvAyE7WJtOe7mrbU9d5ZbtVYo4iFV7x3J+mrpt/bg++9sr/UucEUUGGafzK6QAjfPQ
 ra+iy+mn80OWXWd8iYA74M4m7aumGYYM+RTF0q62pJZiYupOpwnz7upoO9lMoQZhbjCbT6lg+fv
 0QcqwPPXbBE6aHscQC04uwnAql69PulTFvmEETT/WUeJze8xJQfnjIr2kpCmBY628RGwOlTjGdz
 Hh4ByZA/dI55gwlWEp/10Skg25Icr4K5qpwN2pxZxoQzLRBeXHd4evEP3Fv4ijDZM9nLZzMrYyQ
 OK9odh8Tv5xeUlIR8x0daJ1O/WvcopjglPchsZqKM1K0kCTNDLx6SAjBjnEaWXSo5ohQ1Gsqq58
 HkQAJD4UMSUHXTwovAXz/OuZEwSpykZP/20LBwKs7Vz2VLED03Iq+/qReNF1O0jzLQVDk6UsJGp
 AU9wd4jEgi3LowxpC4t9oYoXVH4jJfduQVy5tAUp5XumiQyMJXsgdzerAhGt8moU0dp0iwpQpAE
 1cAPTbGfBDAGR0yJygvfo5/mRPv1u7wqRknXmxbPWwJ78Tyjr5kSniR7aWis79VVjQQ9t4wwplO
 ePr6kJrxqT/hdsbHayArzsQnn6NWuP5F+h15OAu+wZ8BKCKzw6D4=
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi there,

This patchset introduces pinctrl support for the Exynos5515 SoC.

It is very similar to the other Exynos SoCs, therefore we reuse the driver
and for the most part the pinctrl bank macros. A couple
Exynos5515-specific macros are also added.

Kind regards,
- Aiden Isik

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
Changes in v2:
- Remove eint_gpio_init, suspend, and resume entries where they are wrong
- Link to v1: https://patch.msgid.link/20261019-for-next-lucky7-pinctrl-v1-0-0f77e94c70bc@member.fsf.org

To: Krzysztof Kozlowski <krzk@kernel.org>
To: Sylwester Nawrocki <s.nawrocki@samsung.com>
To: Peter Griffin <peter.griffin@linaro.org>
To: Alim Akhtar <alim.akhtar@samsung.com>
To: Linus Walleij <linusw@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Tomasz Figa <tomasz.figa@gmail.com>
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-samsung-soc@vger.kernel.org
Cc: linux-gpio@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Aiden Isik (3):
      dt-bindings: pinctrl: samsung: Add compatible for Exynos5515
      dt-bindings: pinctrl: samsung: add exynos5515-wakeup-eint compatible
      pinctrl: samsung: Add Exynos5515 pinctrl configuration

 .../pinctrl/samsung,pinctrl-wakeup-interrupt.yaml  |   1 +
 .../bindings/pinctrl/samsung,pinctrl.yaml          |   1 +
 drivers/pinctrl/samsung/pinctrl-exynos-arm64.c     | 119 +++++++++++++++++++++
 drivers/pinctrl/samsung/pinctrl-exynos.h           |  20 ++++
 drivers/pinctrl/samsung/pinctrl-samsung.c          |   2 +
 drivers/pinctrl/samsung/pinctrl-samsung.h          |   1 +
 6 files changed, 144 insertions(+)
---
base-commit: 993e1bec85faedf90c5d27480793084e54357c09
change-id: 20261019-for-next-lucky7-pinctrl-64bf54588925

Best regards,
--  
Aiden Isik <aidenisik@member.fsf.org>

