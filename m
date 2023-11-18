From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH v2 0/4] clk: ccf: fix enable_count mismatch
Date: Sun, 19 Nov 2023 06:10:04 +0800
Message-Id: <20231111-enable_count-v2-0-20e3728600b5@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADw2WWUC/3WNwQ6CMBBEf4X0bM22iBFP/ochZlsWaYSuaQvRE
 P7dwt25vZlM3iIiBUdRXItFBJpddOwz6EMhbI/+SdK1mYUGXaocSR7NQA/Lk08S2wpAlfp8UZX
 IF4ORpAnobb+dRoyJwja8A3Xus3vuTebexcThu2tntbV/DLOSICuouxMA1rU1N57SwPw6Wh5Fs
 67rD9hGnM7DAAAA
To: Simon Glass <sjg@chromium.org>, Lukasz Majewski <lukma@denx.de>, 
 Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1700345405; l=1251;
 i=forbidden405@outlook.com; s=20230415; h=from:subject:message-id;
 bh=cIJV6B09g+7Xx319ac9aHiH8ENi3eVyuNM0Ph9jsENg=;
 b=QTRVdx+VB8iyOPawZnuOQ0CkwnJbwR98lmbst7ZNbdyFqfAixe74NULSP5AKanre/V63seBmw
 bIxdMuCnptNAX7dVCfVFCgNW2cyGUh1G66Ysnu8JEJw/6tR2b+28yi0
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
Changes in v2:
- add missing SoB in patch 1/4, no functional change
- Link to v1: https://lore.kernel.org/r/20231111-enable_count-v1-0-509f400a99cb@outlook.com

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

