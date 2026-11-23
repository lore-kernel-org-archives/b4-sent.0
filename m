From: Suyuan Wang <shyckless@gmail.com>
Subject: [PATCH v3 0/3] cpufreq: Fix leaks on probe error paths in three
 drivers
Date: Mon, 23 Nov 2026 05:40:42 +0000
Message-Id: <20261123-cpufreq-leaks-v3-0-1f1e3f4f5a7b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANrRA2sC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQyNj3eSC0rSi1ELdnNTE7GLd5KS0FFPDFBPjpFQLJaCegqLUtMwKsHn
 RsRB+cWlSVmpyCcgQpdpaAJratyFxAAAA
X-Change-ID: 20261123-cpufreq-leaks-cbfd51d43be8
To: viresh.kumar@linaro.org, krzk@kernel.org, peter.griffin@linaro.org, 
 rafael@kernel.org
Cc: linux-kernel@vger.kernel.org, zhongqiu.han@oss.qualcomm.com, 
 alim.akhtar@samsung.com, linux-pm@vger.kernel.org, 
 linux-samsung-soc@vger.kernel.org, linux-arm-kernel@lists.infradead.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795412443; l=1356;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=hCDTxIrRIBEJ8uzexGJBO/WMptBy/NJuSC/LPl/uuvI=;
 b=wTCgJpRhXo1QfJzkQpiNEKvF1DBjx7RADIcqO2hnQzXMu10hFoPvG/xJFlPQaU/cNielTXIYB
 HuvkjZehewGCGNLvItHDc8oV6YBZnWfhqbBlPn4xgw93pKkp/bc6wMm
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Three small fixes for resources that are not released when a cpufreq
driver fails to probe: the cpu clock in highbank, the three clocks in
kirkwood (also on unbind), and the regulators and register mappings in
s5pv210, and its reboot notifier, when cpufreq_register_driver() fails.

Found with a static analysis tool and checked by hand. Compile tested
on arm (W=1, multi_v5 for kirkwood); I don't have the hardware.

Changes in v3:
- Add Zhongqiu's Reviewed-by from v1 to 1/3 and 2/3 (Viresh).
  No other change.

Changes in v2:
- 3/3: fix the Fixes tags. The regulator and reboot notifier leaks come
  from e8b4c1986efb and fe7f1bcbff91, and e0e5b2b4f427 did not add a
  leak (Zhongqiu Han). No code change.
- 1/3, 2/3: unchanged.

v2: https://lore.kernel.org/all/20261123-cpufreq-leaks-v2-0-29277f2f0ddd@gmail.com/
v1: https://lore.kernel.org/all/20261122-cpufreq-leaks-v1-0-96fc17ff7339@gmail.com/
---
Suyuan Wang (3):
      cpufreq: highbank: Put cpu clock if clk notifier registration fails
      cpufreq: kirkwood: Put clocks on error and in remove
      cpufreq: s5pv210: Fix resource leaks on probe error paths

 drivers/cpufreq/highbank-cpufreq.c |  1 +
 drivers/cpufreq/kirkwood-cpufreq.c | 15 ++++++++++++---
 drivers/cpufreq/s5pv210-cpufreq.c  | 12 +++++++++---
 3 files changed, 22 insertions(+), 6 deletions(-)

