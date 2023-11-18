From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH 0/4] clk: ccf: fix enable_count mismatch
Date: Sun, 19 Nov 2023 06:07:03 +0800
Message-Id: <20231111-enable_count-v1-0-509f400a99cb@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIc1WWUC/x2N0QqDMAxFf0XyvEJbcch+ZYyR1kwDWxyJiiD+u
 9X7drgczgZGymTwqDZQWth4lALhVkEeUHpy3BWG6GMdyhwJpi+98zjL5LBrvA91vLehgaIkNHJ
 JUfJwSj+0ifQ8/kofXq/O87XvB/6pXzR3AAAA
To: Simon Glass <sjg@chromium.org>, Lukasz Majewski <lukma@denx.de>, 
 Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1700345230; l=1081;
 i=forbidden405@outlook.com; s=20230415; h=from:subject:message-id;
 bh=iin3xZ+JkOyUu2uZ/IzDEpsRulY2m4chnRnvE6WUc7U=;
 b=8ryuv1of+5Hm3lL9kTURlFffDw9OLZ2OBUjQsi5xfstYl3e1rooMJtEgQ9XlMW5YSF+3/T4mI
 O082B7aE3KHAh48+WkaIkQiVlnMKbuTCwU0MweDjNDqei0OELCP1bnI
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=hfdpPU3AXR+t7fdv58tXCD4UzRNq+fop2TMJezFlAhM=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230415 with auth_id=44
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As described in [1], enable_count is incremented by 2 when
ccf_clk_enable() is called. This series of patch fixed this issue and
added a testcase for that.

[1]: https://lore.kernel.org/all/SEZPR06MB695927A6DEEEF8489A06897396A7A@SEZPR06MB6959.apcprd06.prod.outlook.com/

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Yang Xiwen (4):
      clk: clk_sandbox_ccf: assign ccf_clk_ops to .ops of the driver
      clk: get correct ops for clk_enable() and clk_disable()
      clk: clk_sandbox: get devm clock i2c_root
      test: dm: clk_ccf: get "i2c_root" clock from &clk_ccf

 arch/sandbox/dts/test.dts      |  6 ++++--
 arch/sandbox/include/asm/clk.h |  1 +
 drivers/clk/clk-uclass.c       |  2 ++
 drivers/clk/clk_sandbox_ccf.c  |  1 +
 drivers/clk/clk_sandbox_test.c |  5 +++++
 test/dm/clk_ccf.c              | 14 +++++++++++---
 6 files changed, 24 insertions(+), 5 deletions(-)
---
base-commit: 3b913c148249a2b9d12ff25517ec311646e83bee
change-id: 20231111-enable_count-ad5001326815

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

