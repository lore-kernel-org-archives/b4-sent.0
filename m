From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH RFC 0/3] clk: support arbitrary clk_register() sequence
Date: Sat, 21 Jun 2025 18:54:17 +0800
Message-Id: <20250621-clk-reparent-v1-0-48a7f2f31c59@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFmPVmgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDMyND3eScbN2i1ILEotS8El0LyxRz0zSzRItUA0sloJaCotS0zAqwcdF
 KQW7OSrG1tQC96b0OYwAAAA==
To: Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750503258; l=1543;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=Kr1PMFMv+JN+0XmDqx/X45C5BEyo9RXyrT7a22SKlgE=;
 b=ZJ9Jd2KUh17Kt6cHU2G3Pc8ks2gIVIIUm10ruOh1X7mskFWALArzUdZUulDcnUBLXiTCbAxGY
 0dmzedxsuDhBE7j85wL8HLmkw/t1MwjgF6FwGRuA9azbxuXSOYBCBSK
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently U-Boot clk framework mandates the sequence of registering clks
to begin from root, and then its children. This is an addtional
requirement that doesn't exist in Linux kernel, which makes clk driver
porting more difficult.

Let's handle this entirely in clk framework and give driver the freedom
to register clocks in any order.

This is done by assigning the parent "lazily". It will cache the parent
name in the core clk struct and try to refresh it when clk consumers
call clk_get_parent(). It's transparent to clk consumers as long as they
only use APIs provided by clk framework.

I've ran `ut dm clk*` and verified these commits does not break any
existing testcases. Though no new testcase is added because I think
existing testcases already test the logic very well.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Yang Xiwen (3):
      drivers: core: device: set new parent when old parent is NULL
      clk: allow assigning parent lazily
      clk: sandbox: reverse the order to register clk i2c_root and i2c

 drivers/clk/clk-uclass.c      | 47 +++++++++++++++++++++++++++++++------------
 drivers/clk/clk.c             | 14 +++++++++++--
 drivers/clk/clk_sandbox_ccf.c |  6 +++---
 drivers/core/device.c         |  5 +++++
 include/clk.h                 |  2 ++
 5 files changed, 56 insertions(+), 18 deletions(-)
---
base-commit: 721eecd9cbf2cc59c5230abd37d02d4a02f75cc7
change-id: 20250621-clk-reparent-89d75f6a8e09

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

