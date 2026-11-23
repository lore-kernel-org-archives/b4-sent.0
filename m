From: Suyuan Wang <shyckless@gmail.com>
Subject: [PATCH v2 0/3] cpufreq: Fix leaks on probe error paths in three
 drivers
Date: Mon, 23 Nov 2026 05:21:17 +0000
Message-Id: <20261123-cpufreq-leaks-v2-0-29277f2f0ddd@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAE3NA2sC/yXMTQqDMBBA4avIrA3EUSp4ldJFfiZ2tFjNmFIQ7
 27U5bd4bwOhyCTQFRtE+rHwd8rAsgD3NlNPin02oMZHVWGt3JxCpEV9yIyidBO0QV+31lvIzRw
 p8P/6PV+3JdmB3HpOYN8PSKQpOnEAAAA=
X-Change-ID: 20261123-cpufreq-leaks-04f0a2d37bdb
To: rafael@kernel.org, peter.griffin@linaro.org, viresh.kumar@linaro.org, 
 krzk@kernel.org
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-samsung-soc@vger.kernel.org, alim.akhtar@samsung.com, 
 linux-pm@vger.kernel.org, zhongqiu.han@oss.qualcomm.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795411278; l=1170;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=QDauegO8UPnaZeDUw3mfjrBEpQxLHmQyKSmsmNN2bfA=;
 b=ayTGpoX9eQGy3FWHBI19LxiV6yguDuVCy4e+367rDqPox/Zu/ZVmMZIe+SWSYsSL1Vo7ZYiPC
 rR+YhWt8xFDBKed1TcCneLr4uVNNkNRPFUXgu7CCojH6+Bc/dNDs1L1
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

Changes in v2:
- 3/3: fix the Fixes tags. The regulator and reboot notifier leaks come
  from e8b4c1986efb and fe7f1bcbff91, and e0e5b2b4f427 did not add a
  leak (Zhongqiu Han). No code change.
- 1/3, 2/3: unchanged.

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

