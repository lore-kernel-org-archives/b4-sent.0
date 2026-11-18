From: Cunhao Lu <1579567540@qq.com>
Date: Wed, 18 Nov 2026 17:03:46 +0800
Subject: [PATCH v2] pmdomain: rockchip: Roll back power-on when leaving
 idle fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-fix-rockchip-pmdomain-power-on-rollback-v2-1-3e4e93a19996@qq.com>
X-B4-Tracking: v=1; b=H4sIAPFp/WoC/5WOSxKCMBBEr0Jl7VgMH38r72GxCGGQEUhCgqhFc
 XcDnsDlq3ndPbPw5Ji8uESzcDSxZ6MDJLtIqEbqOwFXgUUSJwfEGKHmNzijWtWwBdtXppeswZo
 XOTA6nLqulKoFhUjBz6hGFKHNOgrRbelW/Ng/ywepca1fjYb9aNxne2XC1ft/dUJAyM8yy4+nl
 NKUrsOwV6YXxbIsXz5+zsTtAAAA
X-Change-ID: 20261101-fix-rockchip-pmdomain-power-on-rollback-c11e1014ef11
To: Ulf Hansson <ulfh@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Peter Geis <pgwipeout@gmail.com>
Cc: linux-pm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Cunhao Lu <1579567540@qq.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794992626; l=4100;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=iNwwI4s6GSLy+qcCrFrOUdp0m3/C5bTABfIfePwVyzQ=;
 b=H63KA2kbZQ2Udd1ZDZZGo9Hi68SF/NWCbC3+XwmNAXq8T/k3dsQ+VxVWUvmFLqYBBiUmgoEex
 xw75v/1FNqUD4mT0epcOH217F8bJF6A2hMLTH1oMBT5JU4Fy1okbdl4
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When NIU idle exit fails after PMU power-on, clocks and the regulator
reference are released while the domain remains powered. genpd treats
it as off and may power off its parents.

Request idle again and, if successful, use the low-level power-off path
before releasing resources. This preserves saved QoS and notifies
firmware while retaining the original error.

If rollback fails, resources are still released and genpd may power off
the parents.

Fixes: 6b2690df3f03 ("pmdomain: rockchip: fix rockchip_pd_power error handling")
Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
This pre-existing idle-exit failure case was reported by Sashiko AI
during the RK3572 mainlining work:
https://sashiko.dev/#/patchset/20261022-add-board-ok3572-c-v1-0-0b0fd85a31ee@qq.com?part=10

If leaving NIU idle fails after PMU power-on, the domain remains powered
while genpd treats it as off. The error path releases the clocks and
regulator reference, and genpd may power off the parent domains.

This patch requests idle again and, if successful, powers the domain
off before releasing those resources. It preserves the saved QoS state
and original error, and uses the low-level path to notify firmware.

Validation:

- All 48 host simulations passed, covering power cycles, idle-exit and
  rollback failures, QoS preservation and error propagation. No sanitizer
  findings.

- Hardware testing on OK3572-C: 20 patched and 50 unpatched NVM1 power
  cycles passed. Request-write injection caused native idle-exit polling
  timeouts. The fix powered the domain off in 3/3 cases; the original
  driver left it ON. QoS and the original error were preserved, and
  retries succeeded after removing the injection.

Persistent rollback idle and power-off timeouts were also tested:
resources were still released with the domain ON and genpd OFF. These
failure paths remain unresolved, and genpd may still power off the parents.

AI assistance:

- Codex / DeepSeek V4.1 Flash were used for:
  - Reviewing and adjusting code style to follow community conventions
  - Automating tests
  - Collecting data
---
Changes in v2:
- Rebase onto the next branch of Ulf Hansson's linux-pm.git tree.
- Link to v1:
  https://patch.msgid.link/20261101-fix-rockchip-pmdomain-power-on-rollback-v1-1-59a45783e33e@qq.com
---
 drivers/pmdomain/rockchip/pm-domains.c | 27 ++++++++++++++++++++++++++-
 1 file changed, 26 insertions(+), 1 deletion(-)

diff --git a/drivers/pmdomain/rockchip/pm-domains.c b/drivers/pmdomain/rockchip/pm-domains.c
index 6abef60a5b4c..2c021784316a 100644
--- a/drivers/pmdomain/rockchip/pm-domains.c
+++ b/drivers/pmdomain/rockchip/pm-domains.c
@@ -648,6 +648,29 @@ static int rockchip_do_pmu_set_power_domain(struct rockchip_pm_domain *pd,
 	return 0;
 }
 
+/*
+ * The caller holds the PMU lock and transition resources. Use the low-level
+ * power-off path to avoid overwriting the saved QoS state.
+ */
+static void rockchip_pd_power_on_rollback(struct rockchip_pm_domain *pd)
+{
+	int ret;
+
+	ret = rockchip_pmu_set_idle_request(pd, true);
+	if (ret < 0) {
+		dev_err(pd->pmu->dev,
+			"failed to idle domain '%s' on rollback: %d\n",
+			pd->genpd.name, ret);
+		return;
+	}
+
+	ret = rockchip_do_pmu_set_power_domain(pd, false);
+	if (ret < 0)
+		dev_err(pd->pmu->dev,
+			"failed to power off domain '%s' on rollback: %d\n",
+			pd->genpd.name, ret);
+}
+
 static int rockchip_pd_power(struct rockchip_pm_domain *pd, bool power_on)
 {
 	struct rockchip_pmu *pmu = pd->pmu;
@@ -682,8 +705,10 @@ static int rockchip_pd_power(struct rockchip_pm_domain *pd, bool power_on)
 	if (power_on) {
 		/* if powering up, leave idle mode */
 		ret = rockchip_pmu_set_idle_request(pd, false);
-		if (ret < 0)
+		if (ret < 0) {
+			rockchip_pd_power_on_rollback(pd);
 			goto out;
+		}
 
 		rockchip_pmu_restore_qos(pd);
 	}

---
base-commit: 6f5c8ec9302c5ad8904dbdfe8cf2a538ff835572
change-id: 20261101-fix-rockchip-pmdomain-power-on-rollback-c11e1014ef11

Best regards,
--  
Cunhao Lu <1579567540@qq.com>

