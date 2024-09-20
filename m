From: Chuan Liu <chuan.liu@amlogic.com>
Subject: [PATCH 0/6] clk: meson: Delete a meaningless spinlock from the
 MPLL
Date: Fri, 20 Sep 2024 16:16:10 +0800
Message-Id: <20240920-mpll_spinlock-v1-0-5249a9a7e2b7@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEov7WYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDS0ML3dyCnJz44oLMvJz85GxdkyTLJFPTZBOTtBRTJaCegqLUtMwKsHn
 RsbW1ACypo2ZfAAAA
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726820173; l=1441;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=RY6C6fgg/u2FQqsycCMOcuCyZ6IO+mQm4xQLZhTAfLU=;
 b=Bel3Jh1Lzlk031mBbSqUOf1Dk86SKnJakYDwJxNS3ho8IG5uNcg8mx+X7/EfDSiy6iKQyUMhu
 3KqlnI81BLTAVgJmOjGOvofYkUdDus+QNqhGaVI3qnas/eAXOOemQf7
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The existing locking mechanism of CCF can effectively avoid concurrent
register access. struct meson_clk_mpll_data has no meaning in defining
a spinlock repeatedly.

In addition, the register corresponding to MPLL does not share the same
register with other module drivers, so there is no concurrent access to
the register with other modules drivers.

Every driver file with mpll defines a spinlock with the same name (even
if defined as "static"), giving the illusion of repeated definitions?

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
Chuan Liu (6):
      clk: meson: mpll: Delete a meaningless spinlock from the MPLL
      clk: meson: axg: Delete the spinlock from the MPLL
      clk: meson: meson8b: Delete the spinlock from the MPLL
      clk: meson: gxbb: Delete the spinlock from the MPLL
      clk: meson: g12a: Delete the spinlock from the MPLL
      clk: meson: s4: Delete the spinlock from the MPLL

 drivers/clk/meson/axg.c      |  6 ------
 drivers/clk/meson/clk-mpll.c | 11 -----------
 drivers/clk/meson/clk-mpll.h |  1 -
 drivers/clk/meson/g12a.c     |  6 ------
 drivers/clk/meson/gxbb.c     |  6 ------
 drivers/clk/meson/meson8b.c  |  3 ---
 drivers/clk/meson/s4-pll.c   |  6 ------
 7 files changed, 39 deletions(-)
---
base-commit: 0ef513560b53d499c824b77220c537eafe1df90d
change-id: 20240918-mpll_spinlock-4b9b55c44fd5

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

