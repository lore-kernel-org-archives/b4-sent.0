From: Han Gao <gaohan@iscas.ac.cn>
Subject: [PATCH 0/2] clk: eswin: Fix the EIC7700 PLL post-divider
Date: Wed, 25 Nov 2026 02:41:01 +0800
Message-Id: <20261125-eic7700-cpu-pll-postdiv-v1-0-b1ccd6339a20@iscas.ac.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD3aBWsC/x3MQQqAIBBA0avErBtwpLK6SrQIHWsgSrQiiO6et
 HyL/x9IHIUT9MUDkS9Jsm8ZVBZgl2mbGcVlg1a6IdI1slhjlEIbTgzrimFPh5MLdeXIdq0nRwp
 yHSJ7uf/zML7vB/69D9dpAAAA
X-Change-ID: 20261125-eic7700-cpu-pll-postdiv-24d1c98f1d10
To: Yifeng Huang <huangyifeng@eswincomputing.com>, 
 Xuyang Dong <dongxuyang@eswincomputing.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>
Cc: Brian Masney <bmasney@redhat.com>, Han Gao <rabenda.cn@gmail.com>, 
 linux-clk@vger.kernel.org, Han Gao <gaohan@iscas.ac.cn>, 
 Jingkun Zheng <zhengjingkun@iscas.ac.cn>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795545672; l=779;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=t8ZcuweeJNISZuSMsr0ma3NCNW561sd+NOoXsw+v1Sw=;
 b=diPFeDuIDZU9YkcSf71xBpGfVxkppziXUTRXOyWVSnCDGZBgMMD8UO+z+vwdcNbgWt6VaM99J
 wHJwV6tWvgoD+cBPF+PEWiT4ohrFB2XO2+Qh2aTudnS3jJHkYOaQpMj
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

clk_pll_set_rate() sets a post-divider the rate math doesn't know
about, so the P550 CPU ran at half speed. Patch 1 fixes that, patch 2
makes recalc_rate use the full formula from the TRM.

Tested on a HiFive Premier P550: all CPU operating points, and setting
and reading back the audio PLL rate.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
Han Gao (2):
      clk: eswin: Fix the EIC7700 PLL post-divider
      clk: eswin: Use REFDIV and the post-dividers in the EIC7700 PLL rate

 drivers/clk/eswin/clk.c | 26 ++++++++++++++++++--------
 1 file changed, 18 insertions(+), 8 deletions(-)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261125-eic7700-cpu-pll-postdiv-24d1c98f1d10

Best regards,
-- 
Han Gao <gaohan@iscas.ac.cn>

