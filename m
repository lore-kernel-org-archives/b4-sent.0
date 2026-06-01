From: Petr Hodina <petr.hodina@protonmail.com>
Subject: [PATCH 0/2] Add gpio configuration support for Qualcomm Snapdragon
 platform
Date: Mon, 01 Jun 2026 13:52:34 +0200
Message-Id: <20260601-qcom-gpio-v1-0-e24bcdb35da0@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIJyHWoC/yXM3wpAMBSA8VdZ59pqFvPnVeSCOTiKzYaUvLvh8
 ldf3wUeHaGHkl3g8CBPZgmIIwZ6bJYBOXXBIIVUQomYr9rMfLBkeJFjnjatlCrJIPTWYU/n96r
 q335vJ9TbO4D7fgC9coBLbQAAAA==
X-Change-ID: 20260601-qcom-gpio-98e85ab22647
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Rui Miguel Silva <rui.silva@linaro.org>, phone-devel@vger.kernel.org, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780314756; l=757;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=LC1KEiCh5cgS0hAeF9Hre6xCEkCl5eQod5RNmlL42C0=;
 b=GFU5sZU4RsOg0hvvaDb1hts/0dp1shvPTEM5/i9o6RVwFVP2eFSX8nTTtgWdyIxWmR/2GOcXr
 xOjizHsZ/JVBo7q3sMlUKS90D++x8HFfkHvmoV1nI627+TeU/nuo8Ax
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds the gpio configuration as input along with
pull-up/down/disable and drive strength for output.

Remove the reconfiguration from the set_direction.

This enables on mainline Linux phones to use volume-up in menu.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Petr Hodina (2):
      gpio: qcom_pmic_gpio: implement standard pinconf parameters
      gpio: qcom_pmic_gpio: don't reset pull on direction change

 drivers/gpio/qcom_pmic_gpio.c | 41 ++++++++++++++++++++++++++++++++---------
 1 file changed, 32 insertions(+), 9 deletions(-)
---
base-commit: 1f89ddd61cd8c27a3dc1fc7edbeccb55d424eb72
change-id: 20260601-qcom-gpio-98e85ab22647

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

