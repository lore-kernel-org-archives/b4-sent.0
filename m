From: Suyuan Wang <shyckless@gmail.com>
Subject: [PATCH 0/3] cpufreq: Fix leaks on probe error paths in three
 drivers
Date: Sun, 22 Nov 2026 11:55:25 +0000
Message-Id: <20261122-cpufreq-leaks-v1-0-96fc17ff7339@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAC3YAmsC/yXMQQ6CMBBG4auQWdukHQILr2JYlPJXRghCRwwJ4
 e4WXH6L93ZSJIHSvdgp4Ssq7ynD3QoKvZ+eMNJlE1uunWM2YV5jwmJG+EGN7VBFy62tfEm5mRO
 ibNfv0fyta/tC+JwTOo4fI8lzFXEAAAA=
X-Change-ID: 20261122-cpufreq-leaks-0de5f02b05a3
To: rafael@kernel.org, viresh.kumar@linaro.org, krzk@kernel.org, 
 peter.griffin@linaro.org
Cc: linux-samsung-soc@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-pm@vger.kernel.org, alim.akhtar@samsung.com, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795348526; l=860;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=oIQfnl7M3LakYVj9eUuZPGGQrd8JJ9WvL2rZCs+mAW4=;
 b=Dw3HZ/Htimtqz09/4oos98ULzG9c99ofSXnu/hME1AhOvccUerU9jFEpxi3CIn2JVWTA75bqT
 +EypHFn1RYfDIPBzP27XmefoIKFhYx2jgt98BPARvGWAB54nuCsZXfq
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

---
Suyuan Wang (3):
      cpufreq: highbank: Put cpu clock if clk notifier registration fails
      cpufreq: kirkwood: Put clocks on error and in remove
      cpufreq: s5pv210: Fix resource leaks on probe error paths

 drivers/cpufreq/highbank-cpufreq.c |  1 +
 drivers/cpufreq/kirkwood-cpufreq.c | 15 ++++++++++++---
 drivers/cpufreq/s5pv210-cpufreq.c  | 12 +++++++++---
 3 files changed, 22 insertions(+), 6 deletions(-)

