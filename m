From: Suyuan Wang <shyckless@gmail.com>
Date: Mon, 23 Nov 2026 05:21:18 +0000
Subject: [PATCH v2 1/3] cpufreq: highbank: Put cpu clock if clk notifier
 registration fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-cpufreq-leaks-v2-1-29277f2f0ddd@gmail.com>
References: <20261123-cpufreq-leaks-v2-0-29277f2f0ddd@gmail.com>
In-Reply-To: <20261123-cpufreq-leaks-v2-0-29277f2f0ddd@gmail.com>
To: rafael@kernel.org, peter.griffin@linaro.org, viresh.kumar@linaro.org, 
 krzk@kernel.org
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-samsung-soc@vger.kernel.org, alim.akhtar@samsung.com, 
 linux-pm@vger.kernel.org, zhongqiu.han@oss.qualcomm.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795411278; l=1132;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=3C9gDTowDdRDGMzNw1WS33LAVCdBMhUpJeT844xhx+Y=;
 b=GL1vgLvcUui95YQY/CL0DXZRMnKDChxPyd/L4C2Yvsf76SYi/8CyeMT3UHOHVkLog2bCiTDHV
 Fb8fPqsU7q3BpI3JYmUD04S+5/ay2W+v30fhrlesLBQawZagAFWSK16
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

hb_cpufreq_driver_init() gets the cpu0 clock with clk_get() and then
registers a clk notifier on it. If clk_notifier_register() fails, the
function jumps to out_put_node and returns the error, but the clock
reference is never dropped.

Call clk_put() on that error path.

Found with a static analysis tool and checked by hand.

Fixes: 6754f556103b ("cpufreq / highbank: add support for highbank cpufreq")
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
 drivers/cpufreq/highbank-cpufreq.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/cpufreq/highbank-cpufreq.c b/drivers/cpufreq/highbank-cpufreq.c
index a45864701143..ccdaff4384d2 100644
--- a/drivers/cpufreq/highbank-cpufreq.c
+++ b/drivers/cpufreq/highbank-cpufreq.c
@@ -89,6 +89,7 @@ static int __init hb_cpufreq_driver_init(void)
 	ret = clk_notifier_register(cpu_clk, &hb_cpufreq_clk_nb);
 	if (ret) {
 		pr_err("failed to register clk notifier: %d\n", ret);
+		clk_put(cpu_clk);
 		goto out_put_node;
 	}
 

-- 
2.34.1

