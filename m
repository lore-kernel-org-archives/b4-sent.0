From: Shigeaki Asai <y-asai.0816@docomonet.jp>
Subject: [PATCH RFC 0/2] clk: samsung: exynos5: fix sub-CMU power domain
 attach
Date: Mon, 23 Nov 2026 23:18:22 +0900
Message-Id: <20261123-exynos5-subcmu-defer-v1-0-43aef47d4f2b@docomonet.jp>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAC5LBGsC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQyNj3dSKyrz8YlPd4tKk5NxS3ZTUtNQiXfOUROM0CxMLi2SzFCWg1oK
 i1LTMCrCx0UpBbs5KsRBBoKas1OQSkIFKtbUA2Mmnmn0AAAA=
X-Change-ID: 20261123-exynos5-subcmu-defer-7da3f8488c6d
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Sylwester Nawrocki <s.nawrocki@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Marek Szyprowski <m.szyprowski@samsung.com>
Cc: linux-samsung-soc@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Shigeaki Asai <y-asai.0816@docomonet.jp>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795443504; l=2873;
 i=y-asai.0816@docomonet.jp; s=20261004; h=from:subject:message-id;
 bh=4fZjdy8kIZ+rBxv7aI3zGOWNd3D+cxfIlXqC2oK3nDA=;
 b=HnVIZ4Tampt3/AOjtHc5tpxc+IWZgY08VU6KnqF08rIqiTeEJ6rz4aW+mQCiM0dsnMBxTxwS1
 e4NEMZ8T+leBElW7vK9J+Yl0JUnTk069tm9KfAOLR7wcvhMhc/Vdgqt
X-Developer-Key: i=y-asai.0816@docomonet.jp; a=ed25519;
 pk=jkd95ViSn8i/X3oPMHYG1A8mae8IOwOKGE64kzLqC5c=
X-Endpoint-Received: by B4 Relay for y-asai.0816@docomonet.jp/20261004 with auth_id=1110
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit c09a3e6c97f0 ("soc: samsung: pm_domains: Convert to regular
platform driver"), the exynos-pd platform driver registers the power
domains too late for exynos5-subcmu, so the sub-CMUs are not attached to
them and their clock setup is not restored. On ODROID-XU4 this drops the
GPU performance badly (about 3.5 fps in the Kodi menu, with repeated
panfrost "gpu sched timeout").

This series fixes it as follows:
- Make the exynos5-clock probe wait until the power domains are
  registered, so the sub-CMUs are attached to them.
- Also make audss wait for pll_in. As a side effect of making the
  sub-CMUs wait, audss would otherwise probe before pll_in exists and
  generate audio from the 24 MHz pll_ref, which causes audio stuttering.

However, this relies on deferred probe, which conflicts with the move 
towards platform_driver_probe(), and the sub-CMU clock data is
__initconst, so the deferred probe has to finish before init memory is
freed. So I would like to discuss the preferred way to fix it.

This may also explain the oopses seen in the RFC series "clk: samsung:
Use platform_driver_probe() to avoid __refdata". Krzysztof saw them
when converting exynos5-subcmu, and Stephen pointed out that
platform_driver_probe() is incompatible with deferred probe. The
sub-CMUs have to wait for their power domains, so exynos5-subcmu
probably cannot use platform_driver_probe() as long as exynos-pd is a
regular platform driver.
https://lore.kernel.org/all/20250305-clk-samsung-ref-init-data-v1-0-a4e03a019306@linaro.org/

Testing:
- Tested on ODROID-XU4 with a Linux 7.3 based LibreELEC kernel:
  every power domain now has an exynos5-subcmu device attached in
  pm_genpd_summary, the Kodi menu went from about 3.5 fps to 25-30 fps,
  "gpu sched timeout" went from 17 to 0, and there is no audio
  stuttering.
- On next/clk, only build-tested (exynos_defconfig, W=1) and checked
  with checkpatch. I have not booted next/clk on the hardware.
- These patches are already carried in LibreELEC.

I investigated the root cause and wrote these patches and the commit
messages with the help of Claude (claude-opus-5-5). I reviewed the
changes and tested them on the hardware as described above.

Thanks,
Shigeaki

Signed-off-by: Shigeaki Asai <y-asai.0816@docomonet.jp>
---
Shigeaki Asai (2):
      clk: samsung: exynos-audss: defer probe until pll_in is available
      clk: samsung: exynos5-subcmu: defer probe until power domains are registered

 drivers/clk/samsung/clk-exynos-audss.c   |  3 ++
 drivers/clk/samsung/clk-exynos5-subcmu.c | 85 ++++++++++++++++++++++----------
 2 files changed, 61 insertions(+), 27 deletions(-)
---
base-commit: 783214e3268f71296cb6f62669b0daced0ac249d
change-id: 20261123-exynos5-subcmu-defer-7da3f8488c6d

Best regards,
--  
Shigeaki Asai <y-asai.0816@docomonet.jp>

