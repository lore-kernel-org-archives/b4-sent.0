From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Subject: [PATCH v2 0/3] clk: meson: g12a: fix a few clock definition errors
Date: Fri, 23 Oct 2026 14:53:50 +0200
Message-Id: <20261023-fix-g12a-clk-v2-0-0b0b9b86d437@aliel.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAN5Y22oC/3WMQQ6CQAxFr0K6tmZaAzGuvIdhMUALjQTMDJloy
 Nzdkb3L93/e2yFKMIlwq3YIkizauhTgUwX95JdR0IbCwI4bcsyo9saR2GM/P5G0q7mjulffQFF
 eQcp/5B5t4cnitobPUU/0W/+EEqFD4W646kXJq7/72WQ+a4A25/wFfY3+bKcAAAA=
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1213;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=YTsDBLMNkEFFewGfzypfNHgAfzd07DIYOGxGlQ1uYps=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ9btSFn1d0cXbz6SYcGbvXD+7roPc84mBahK/JP7qPLvt
 KCAhIh8RykLgxgXg6yYIkv/XMsT7y4fPfN1j3oKzBxWJpAhDFycAjCRL96MDFtmRFtvVblYxbak
 7K268h+ljRHzfosxe57f9y+T5fkBKy9Ghhe+KUdbFq4LPNE0S4Sn/fqNjXeTmX+e/Za7+ej5BH/
 zFH4A
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

While reviewing the G12A clock controller, I noticed mistakes in
the clock definitions:

 - CLKID_VID_PLL and CLKID_VID_PLL_DIV are swapped in the hw_onecell_data
   tables.

The fix is split per SoC (g12a, g12b, sm1) since each table was
introduced by a different commit so I provide different Fixes: tag.

I do not see any consumer today, so nobody should be affected.
I don't think there is any values in backporting them btw.

Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
Changes in v2:
- Drop the first patch as it would introduce a bug due to misreading..
- Link to v1: https://patch.msgid.link/20261022-fix-g12a-clk-v1-0-e2bd8f3f1afa@aliel.fr

---
Ronald Claveau (3):
      clk: meson: g12a: fix swapped VID_PLL and VID_PLL_DIV clock ids
      clk: meson: g12a: fix swapped VID_PLL and VID_PLL_DIV clock ids for g12b
      clk: meson: g12a: fix swapped VID_PLL and VID_PLL_DIV clock ids for sm1

 drivers/clk/meson/g12a.c | 12 ++++++------
 1 file changed, 6 insertions(+), 6 deletions(-)
---
base-commit: d419d682257d813f6cb7a28e42b35d0edf4ad038
change-id: 20261022-fix-g12a-clk-1fb52b15cfa6

Best regards,
--  
Ronald Claveau <linux-kernel-dev@aliel.fr>

