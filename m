From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Subject: [PATCH 0/4] clk: meson: g12a: fix a few clock definition errors
Date: Thu, 22 Oct 2026 23:52:38 +0200
Message-Id: <20261022-fix-g12a-clk-v1-0-e2bd8f3f1afa@aliel.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKaF2moC/x2MQQqAIBAAvxJ7bqFd0ENfiQ5qqy2FhUIE0d+Tj
 sMw80CVolJh7B4ocmnVIzegvoOwupwEdWkMPLClgRmj3piIHYZ9Q4resCcTorPQkrNI8/9umt/
 3A4rwOaZeAAAA
X-Change-ID: 20261022-fix-g12a-clk-1fb52b15cfa6
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jian Hu <jian.hu@amlogic.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1230;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=kv186d9Cog+H5dWdzKf8ASTTBRJiUw79UW7YCNc2//0=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ9at1g0fNi+Rc9qleitm8/LAgJbJb64ef8cW2GcvknOKZ
 /fEWwmzO0pZGMS4GGTFFFn651qeeHf56Jmve9RTYOawMoEMYeDiFICJhAszMsz1K2F8yr0t446h
 x9GHfwyWR+xf4H37+sWODWyJ9z9KnyplZOgUU0n/x2kvfKPZ+nnanfNNDBYVebaTKoJCPe6GX4h
 ZzQUA
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

While reviewing the G12A clock controller, I noticed two unrelated
mistakes in the clock definitions:

 - fclk_div2p5 uses mult = 1 instead of 2, so it runs at fclk / 5
   instead of fclk / 2.5.
 - CLKID_VID_PLL and CLKID_VID_PLL_DIV are swapped in the hw_onecell_data
   tables.

The first one is a single fix. The second one is split per SoC (g12a,
g12b, sm1) since each table was introduced by a different commit so
I provide different Fixes: tag.

I do not see any consumer today, so nobody should be affected.
I don't think there is any values in backporting them btw.

Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
Ronald Claveau (4):
      clk: meson: g12a: fix fclk_div2p5 multiplier
      clk: meson: g12a: fix swapped VID_PLL and VID_PLL_DIV clock ids
      clk: meson: g12a: fix swapped VID_PLL and VID_PLL_DIV clock ids for g12b
      clk: meson: g12a: fix swapped VID_PLL and VID_PLL_DIV clock ids for sm1

 drivers/clk/meson/g12a.c | 14 +++++++-------
 1 file changed, 7 insertions(+), 7 deletions(-)
---
base-commit: d419d682257d813f6cb7a28e42b35d0edf4ad038
change-id: 20261022-fix-g12a-clk-1fb52b15cfa6

Best regards,
--  
Ronald Claveau <linux-kernel-dev@aliel.fr>

