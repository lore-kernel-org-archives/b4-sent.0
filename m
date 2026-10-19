From: Aiden Isik <aidenisik@member.fsf.org>
Subject: [PATCH 0/3] Introduce Exynos5515 pinctrl support
Date: Mon, 19 Oct 2026 15:41:29 +0100
Message-Id: <20261019-for-next-lucky7-pinctrl-v1-0-0f77e94c70bc@member.fsf.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABks1moC/yXMQQqDMBBA0avIrB0wwVj1KuKixkk7VaJMYrGId
 29sl2/x/wGBhClAmx0g9ObAi09QeQb2efcPQh6TQRe6UoVq0C2CnvaI82anzw1X9jbKjFU5OFO
 aum60gVSvQo7337nr/w7b8CIbrx2c5xcZmt0LewAAAA==
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1181;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=6kpynfd1XwdzrYVYTdeaXZTq3IwSFC6OGWqTXpdz3k8=;
 b=owEBiQJ2/ZANAwAIAUknAbLEetfrAcsmYgBq1iwavoG8bk1Ptimk9zQV0SQe2ytajaJBH/G2P
 ibOACjdA/uJAk8EAAEIADkWIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCatYsGhsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQSScBssR61+th1w//Ro7tCNpouTquWY0eo4khNMPeKlmjBWX
 djR4Lt+9Dn8nepSQFtyeoVeBJ0kAjaLVllt11cXsPGXGBrJx0UAGorrlLiAKv1bkNtE0gJqQch4
 StnVw/3eGkjKyWKJy+LW3UgaRwV8xJdVt27559IR/mlPYzZRfE6BElnM5fEyrGIrTECGHstNsL7
 Cs2PVzUqdtDuhFdLvLICJcXLV6CHXMd3JC67yb4POh28LXxs5cfhFe13ILHTh4NKVg7Kh71kZe5
 I4Wzqm6u0RzgEEZjcv0w9vSoPVLbp6st05ywdTW1XtLNHpUSNwF3EEScUV3eLjipEN7dY5GwM7x
 LEiAV4aLFX2r7s2oSfOrpO0cwztGE4c56tCs+pXmbzFkRsHMb3dztSY9flHd3K++3KMwUy8ypl6
 3jEzMLyygJJqxSIA1r88GUyXccavN98fW3rsz9XZnZxLF6jmamsOula2mc3vxcm8BxHLaS6xzXc
 P7y4utUQYbsgJ7VpfVEQiMgJxTeK9UmC0mUd6lHpSKppGd3XZpqDrbcoJSQwHyiJv1jgW9CFgwq
 u4KwJsl8Mh9KdQHrfPFQQJFH7txOKN7QLqpGy1UGf5FKRAR5NchpyWl4Rr37qE0GJu4veBTwBUY
 MRV+CZxH5BDYCYZFSV8RzXiKoUKEXQ8TrcMgPeegQhJ8BQIkQaFM=
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
Aiden Isik (3):
      dt-bindings: pinctrl: samsung: Add compatible for Exynos5515
      dt-bindings: pinctrl: samsung: add exynos5515-wakeup-eint compatible
      pinctrl: samsung: Add Exynos5515 pinctrl configuration

 .../pinctrl/samsung,pinctrl-wakeup-interrupt.yaml  |   1 +
 .../bindings/pinctrl/samsung,pinctrl.yaml          |   1 +
 drivers/pinctrl/samsung/pinctrl-exynos-arm64.c     | 123 +++++++++++++++++++++
 drivers/pinctrl/samsung/pinctrl-exynos.h           |  20 ++++
 drivers/pinctrl/samsung/pinctrl-samsung.c          |   2 +
 drivers/pinctrl/samsung/pinctrl-samsung.h          |   1 +
 6 files changed, 148 insertions(+)
---
base-commit: 993e1bec85faedf90c5d27480793084e54357c09
change-id: 20261019-for-next-lucky7-pinctrl-64bf54588925

Best regards,
--  
Aiden Isik <aidenisik@member.fsf.org>

