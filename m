From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH 0/2] clk: fix a bug in CCF which results in a clock being
 enabled twice.
Date: Mon, 24 Jul 2023 05:16:53 +0800
Message-Id: <20230724-clk_fix-v1-0-283f5b427070@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMWYvWQC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI2MDcyMT3eSc7Pi0zApdwyRzIzPTFDMz40QLJaDqgqJUoDDYpOjY2loAXn9
 EX1kAAAA=
To: Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1690147024; l=1082;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=jM3H69U/XUQ0Lsn8g5o066UYOJN1VbwLr9q+jBTeJac=;
 b=t5Xo/bOFJo0VuTAU3eNqQlW3N9cdDz0n5ABIuk4bknFcLYByVu0TUnmCHGhhdDSv21TxyZRwp
 WkqoTmPY/FRDGWxQyZdT4my1nTbvvxenzm7hmLHQzoBd7LDXPjFVlT8
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, ccf_clk_endisable() calls clk_enable() / clk_disable()
directly depending on the request. However, this function is also
referenced in clk->ops, which is also called in clk_enable() /
clk_disable().

This caused a recursion and made the clock enabled twice if clk_enable()
is invoked. So we have to call clk_disable() twice to disable the clock.
It can be easily reproduced with few extra lines of debug code.

Fix that by calling clk->ops->enable/disable directly in
ccf_clk_endisable() rather than using the framework functions.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Yang Xiwen (2):
      clk: move clk_get_ops() to a common header
      clk: ccf: invoke ops provided by clk directly

 drivers/clk/clk-uclass.c |  5 -----
 drivers/clk/clk.c        | 10 ++++++++--
 include/clk.h            | 17 +++++++++++++++++
 3 files changed, 25 insertions(+), 7 deletions(-)
---
base-commit: 580eb31199be8a822e62f20965854a242f895d03
change-id: 20230724-clk_fix-1b7265d663a8

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

