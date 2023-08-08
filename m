From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH 0/5] clk: A few bugfixes/enhancements for CCF
Date: Wed, 09 Aug 2023 00:37:40 +0800
Message-Id: <20230809-clk-fix-v1-0-808dbae54e5e@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFRv0mQC/x3NQQqDMBCF4avIrDuQKJLoVaSLGEcdbKPMlCKId
 ze6/HkfvAOUhEmhLQ4Q+rPymnLYVwFxDmki5CE3lKasjDcO42fBkXe0jnxTj67x1kHWfVDCXkK
 K8+2/QX8k97AJZf9cdO/zvACsD0ubcgAAAA==
To: Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1691512665; l=867;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=HRI1qmWbSnnmrsMMWS7kDsrErXlHhOstH6hcX+XwmEQ=;
 b=KNGs2dHV3AFnhL218imdK1SWCB6CJ4ikwGxpE9oWL1qaU3+wUsgb3JijA/b676i9T7Bju2jj9
 ea1pCVWA4ncAdNzUPew75dwjAZzI92ZXsvcgRZj9lbow4Jy92oxLLJ0
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

They are found during my development for HiSilicon clock driver. Details
are in commit logs.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Yang Xiwen (5):
      clk: export clk_register_mux_table()
      clk: call log_debug() instead to avoid console log printing
      clk: also handle ENOENT in *_optional functions
      clk: promote clk_dev_ops to linux/clk-provider.h
      clk: ccf: call clock provided ops directly for endisable()

 drivers/clk/clk-uclass.c     |  5 -----
 drivers/clk/clk.c            | 16 +++++++++++++---
 include/clk.h                |  8 +++++---
 include/linux/clk-provider.h | 11 +++++++++++
 4 files changed, 29 insertions(+), 11 deletions(-)
---
base-commit: 580eb31199be8a822e62f20965854a242f895d03
change-id: 20230807-clk-fix-17e895f79817

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

