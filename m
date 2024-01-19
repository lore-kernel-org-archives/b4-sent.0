From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH RFC 0/2] clk: add HiSilicon CLK framework
Date: Fri, 19 Jan 2024 21:32:03 +0800
Message-Id: <20240119-b4-hisi-clk-v1-0-0694a8a52283@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANN5qmUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDQ0NL3SQT3QygKt3knGxdCwsDc9MkE7NkY1NLJaCOgqLUtMwKsGnRSkF
 uzkqxtbUAFBaX4GIAAAA=
To: Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705671123; l=957;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=2DDQplc8tNctMkxLFzzAYfpzqf6Xoeofir9bEV9nppI=;
 b=bMggRQ5W2F+KvIPxCzKg1qU2ypKhiW9e0ud+pTgSrBNxQqTikrILGOS+y3Xo6ZZVwqYVPCkSv
 8ZqXgf9kPRjB4kRrz/HtEL+vn/eapVZ38ZNgzpMravdmM6l6NwKS3R2
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The first supported chip is Hi3798MV200.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Yang Xiwen (2):
      clk: ccf: Export clk_register_mux_table() in linux/clk-provider.h
      clk: add clock framework for HiSilicon SoCs

 drivers/clk/Kconfig                     |   7 ++
 drivers/clk/Makefile                    |   1 +
 drivers/clk/hisilicon/Kconfig           |  14 +++
 drivers/clk/hisilicon/Makefile          |   8 ++
 drivers/clk/hisilicon/clk-hi3798mv200.c | 213 ++++++++++++++++++++++++++++++++
 drivers/clk/hisilicon/clk.c             | 102 +++++++++++++++
 drivers/clk/hisilicon/clk.h             |  55 +++++++++
 include/dt-bindings/clock/histb-clock.h |   4 +
 include/linux/clk-provider.h            |   6 +
 9 files changed, 410 insertions(+)
---
base-commit: f7cca7ccc5117eaafcc2bde91ad1bed6fee7cfc3
change-id: 20240119-b4-hisi-clk-88075b46c359

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

