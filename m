From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH v2 0/2] clk: fix mux determine rate logic
Date: Wed, 06 Mar 2024 00:22:22 +0800
Message-Id: <20240306-mux-v2-0-92a5fa461fd2@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL5G52UC/1WMQQ6CMBBFr0JmbU2nFBVX3sOwoLTIRGFMCw2G9
 O5Wdi7fz39vg+A8uQDXYgPvIgXiKYM6FNAN7fRwgmxmUFJpqbAS47KKkzUXU55RV7WE/Hx719O
 6V+5N5oHCzP6zRyP+1n8/okDhjFG9aUu0ur7xMr+Yn8eOR2hSSl8hlQuRmAAAAA==
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: Maxime Ripard <mripard@kernel.org>, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1709655743; l=920;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=r7/IWaIhvfgMc2GIzTjgzs1RDsbeUNsRCGkfSkbm0Oc=;
 b=X7LxREwss3jp2LQPdavfWvW4OWeg4WPSZwTYjzwflVjrADoP+Wd1HKqPWR/bIpucKjskTeOIH
 Ko4GNR26KgbDxYNNyDWNu2ZWo7nBNn36oAGYyp35qELQW08PlRG6NpO
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is actually a v2 of [1]. It's tested in a mmc host driver.

[1]: https://lore.kernel.org/linux-clk/20230421-clk-v3-1-9ff79e7e7fed@outlook.com/

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Changes in v2:
- cover letter: remove statements about unittest
- add fix for clk_test.c
- s/privide/provide
- Cc Maxime
All suggested by Stephan Boyd
- Link to v1: https://lore.kernel.org/r/20240215-mux-v1-1-ebb2fba31d49@outlook.com

---
Yang Xiwen (2):
      clk: set initial best mux parent to current parent when determining rate
      clk: test: use __clk_mux_determine_rate() and remove FIXME

 drivers/clk/clk.c      |  4 ++--
 drivers/clk/clk_test.c | 18 +-----------------
 2 files changed, 3 insertions(+), 19 deletions(-)
---
base-commit: 90d35da658da8cff0d4ecbb5113f5fac9d00eb72
change-id: 20240215-mux-6db8b3714590

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

