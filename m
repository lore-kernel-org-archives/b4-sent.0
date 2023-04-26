From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH v3 0/2] clk: fix corner case of
 clk_mux_determine_rate_flags()
Date: Thu, 27 Apr 2023 03:34:15 +0800
Message-Id: <20230421-clk-v3-0-9ff79e7e7fed@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALd8SWQC/22OSw7CMAwFr4KyxihxSpFYcQ/EonEdGvUTlJQIV
 PXuJN1VYjn2e2MvInJwHMX1sIjAyUXnpwz6eBDUNdOTwbWZBUrUskIFNPRQV1SbmlFRa0ROmiY
 ymNBM1JXs2MSZQ1m8Alv32fT3R+bOxdmH73YtqTLdi5MCBcacpbZokay++fc8eN+fyI+iGBL+a
 SFIuOSfiBBV1ap9a13XH1Tv8/znAAAA
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1682537658; l=901;
 i=forbidden405@outlook.com; s=20230415; h=from:subject:message-id;
 bh=maf6/BWfgU2ncGnj6zGDd1S57xHd7EW9VanLw4HM0lQ=;
 b=SIb8BOsguv8fnRlfotQhfHQXWXc+E+Db4OKYO/BHbSNJaXC/Dr9OX7sk8NwFAZYgTBvkng8C1
 CXt5kM/XsQxDfudX6xYcK+gn2tcJp9Vm/aWQRoX+4aAaAY3z+Prp10V
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=hfdpPU3AXR+t7fdv58tXCD4UzRNq+fop2TMJezFlAhM=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230415 with auth_id=44
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Changes in v3:
- Add many unittest functions for mux determine_rate
- Add more checks for ULONG_MAX
- Link to v2: https://lore.kernel.org/r/20230421-clk-v2-0-74c6cc2214d1@outlook.com

Changes in v2:
- Add a unit test to clk_test.c
- Link to v1: https://lore.kernel.org/r/20230421-clk-v1-1-bb503f2f2cf3@outlook.com

---
Yang Xiwen (2):
      clk: use ULONG_MAX as the initial value for the iteration in clk_mux_determine_rate_flags()
      clk: tests: Add missing test cases for mux determine_rate

 drivers/clk/clk.c      |  13 ++++-
 drivers/clk/clk_test.c | 131 ++++++++++++++++++++++++++++++++++++++++++++++++-
 2 files changed, 141 insertions(+), 3 deletions(-)
---
base-commit: 76f598ba7d8e2bfb4855b5298caedd5af0c374a8
change-id: 20230421-clk-64c6b6e21cdb

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

