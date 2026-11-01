From: Cunhao Lu <1579567540@qq.com>
Date: Sun, 01 Nov 2026 22:18:51 +0800
Subject: [PATCH] pmdomain: rockchip: Roll back power-on when leaving idle
 fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-fix-rockchip-pmdomain-power-on-rollback-v1-1-59a45783e33e@qq.com>
X-B4-Tracking: v=1; b=H4sIAEpK52oC/yWNwQ6CQAxEf4X0bBNKDAd/xXhYSpEK7G66oiaEf
 7fo8WVm3mxQxFQKXKoNTF5aNEUHOlXAY4h3Qe2doamblqgmHPSDlnjiUTPmpU9L0Ig5vcUwRY/
 muQs8IROJ988yEIHbsolPf0/X25/L2j2En4ce9v0LSn4eh4sAAAA=
X-Change-ID: 20261101-fix-rockchip-pmdomain-power-on-rollback-c11e1014ef11
To: Ulf Hansson <ulfh@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Peter Geis <pgwipeout@gmail.com>
Cc: linux-pm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Cunhao Lu <1579567540@qq.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793542731; l=3895;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=n1GcdQjuTTwBnd/fyanWdo3GZ489PQSz5kGsPzwhT6c=;
 b=WxN7YfRzAeNe1ZbUpfFSZuvt9IaBjnFYOkoxDM/kiTSJpQsS8rYk6w2T9ZihIRiBvYWzq/PIR
 G6G1ODclGVOCL94vn9bNZUbkOUdldTj8Ov1ct0Cd54Y0Hq6VYpix9zm
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
 drivers/pmdomain/rockchip/pm-domains.c | 27 ++++++++++++++++++++++++++-
 1 file changed, 26 insertions(+), 1 deletion(-)

diff --git a/drivers/pmdomain/rockchip/pm-domains.c b/drivers/pmdomain/rockchip/pm-domains.c
index db3879846db6..170f140601d0 100644
--- a/drivers/pmdomain/rockchip/pm-domains.c
+++ b/drivers/pmdomain/rockchip/pm-domains.c
@@ -644,6 +644,29 @@ static int rockchip_do_pmu_set_power_domain(struct rockchip_pm_domain *pd,
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
@@ -678,8 +701,10 @@ static int rockchip_pd_power(struct rockchip_pm_domain *pd, bool power_on)
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
base-commit: d89e1d186ec9271bf78e62771779e9fc03bf0fc3
change-id: 20261101-fix-rockchip-pmdomain-power-on-rollback-c11e1014ef11

Best regards,
--  
Cunhao Lu <1579567540@qq.com>

