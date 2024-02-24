From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH RFC 0/2] clk: hisilicon: add support for PLL
Date: Sun, 25 Feb 2024 00:56:08 +0800
Message-Id: <20240225-pll-v1-0-fad6511479c6@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKgf2mUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDIyNT3YKcHF0jM1NjM3PzZNNUwxQloMqCotS0zAqwKdFKQW7OSrG1tQD
 OUuxAWgAAAA==
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: David Yang <mmyangfl@gmail.com>, 
 Igor Opaniuk <igor.opaniuk@foundries.io>, 
 Jorge Ramirez-Ortiz Gmail <jorge.ramirez.ortiz@gmail.com>, 
 linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708793775; l=863;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=qtrP800EKdOTmakNAoNosODy8gqESCOm/APUkVSRbhY=;
 b=VWJx7sn+15PK7vXf+ej8Tpz2unugzwQue+YKYT03SMOkuuerrVwyZG8WJLBnAciOPt5OL6Gl5
 AU9RANsVZYJASYwKbIKwjuzsTBxnyTqY1qcsYQ9BTMbKnxBS6NeIyjA
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

HiSilicon PLLs are used by various SoCs to provide variable clocks for
various system on the SoC.

Hi3559 has implemented their own PLL driver. Also fix name duplication
because of that.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Yang Xiwen (2):
      clk: hisilicon: rename hi3519 PLL registration function
      clk: hisilicon: add support for PLL

 drivers/clk/hisilicon/Makefile      |   2 +-
 drivers/clk/hisilicon/clk-hi3559a.c |   4 +-
 drivers/clk/hisilicon/clk-pll.c     | 171 ++++++++++++++++++++++++++++++++++++
 drivers/clk/hisilicon/clk.c         |  24 +++++
 drivers/clk/hisilicon/clk.h         |  12 +++
 5 files changed, 210 insertions(+), 3 deletions(-)
---
base-commit: 8d3dea210042f54b952b481838c1e7dfc4ec751d
change-id: 20240225-pll-2653677c5e1d

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

