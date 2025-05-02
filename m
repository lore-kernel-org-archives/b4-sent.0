From: George Moussalem <george.moussalem@outlook.com>
Date: Fri, 02 May 2025 14:15:44 +0400
Subject: [PATCH 2/6] clk: qcom: ipq5018: mark XO clock as critical
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250502-ipq5018-cmn-pll-v1-2-27902c1c4071@outlook.com>
References: <20250502-ipq5018-cmn-pll-v1-0-27902c1c4071@outlook.com>
In-Reply-To: <20250502-ipq5018-cmn-pll-v1-0-27902c1c4071@outlook.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Luo Jie <quic_luoj@quicinc.com>, 
 Lee Jones <lee@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746180945; l=3162;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=+jh6lJyc6zNRZTZYzkpza07Sun/HT5/b9BNAnQimwiU=;
 b=pRaVkwsUBUL+Vijxsb0gQsC6GaOjOndCEKITU4vaW+wD1FdmnUVcS9A0SZidi/WY/LbgYjtIy
 Jw0hTxWTureDEK3ax3abe+U4AoXKWYDYbCc1iayuQUJw6Apl+lnZHVV
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The XO clock must not be disabled, so let's add the CLK_IS_CRITICAL
flag to avoid the kernel trying to disable the XO clock (when parenting
it under the CMN PLL reference clock), else the kernel will panic and
the following message will appear in the kernel logs:

[    0.916515] ------------[ cut here ]------------
[    0.918890] gcc_xo_clk_src status stuck at 'on'
[    0.918944] WARNING: CPU: 0 PID: 8 at drivers/clk/qcom/clk-branch.c:86 clk_branch_wait+0x114/0x124
[    0.927926] Modules linked in:
[    0.936945] CPU: 0 PID: 8 Comm: kworker/0:0 Not tainted 6.6.74 #0
[    0.939982] Hardware name: Linksys MX2000 (DT)
[    0.946151] Workqueue: pm pm_runtime_work
[    0.950489] pstate: 604000c5 (nZCv daIF +PAN -UAO -TCO -DIT -SSBS BTYPE=--)
[    0.954566] pc : clk_branch_wait+0x114/0x124
[    0.961335] lr : clk_branch_wait+0x114/0x124
[    0.965849] sp : ffffffc08181bb50
[    0.970101] x29: ffffffc08181bb50 x28: 0000000000000000 x27: 61c8864680b583eb
[    0.973317] x26: ffffff801fec2168 x25: ffffff800000abc0 x24: 0000000000000002
[    0.980437] x23: ffffffc0809f6fd8 x22: 0000000000000000 x21: ffffffc08044193c
[    0.985276] loop: module loaded
[    0.987554] x20: 0000000000000000 x19: ffffffc081749278 x18: 000000000000007c
[    0.987573] x17: 0000000091706274 x16: 000000001985c4f7 x15: ffffffc0816bbdf0
[    0.987587] x14: 0000000000000174 x13: 000000000000007c x12: 00000000ffffffea
[    0.987601] x11: 00000000ffffefff x10: ffffffc081713df0 x9 : ffffffc0816bbd98
[    0.987615] x8 : 0000000000017fe8 x7 : c0000000ffffefff x6 : 0000000000057fa8
[    1.026268] x5 : 0000000000000fff x4 : 0000000000000000 x3 : ffffffc08181b950
[    1.033385] x2 : ffffffc0816bbd30 x1 : ffffffc0816bbd30 x0 : 0000000000000023
[    1.040507] Call trace:
[    1.047618]  clk_branch_wait+0x114/0x124
[    1.049875]  clk_branch2_disable+0x2c/0x3c
[    1.054043]  clk_core_disable+0x60/0xac
[    1.057948]  clk_core_disable+0x68/0xac
[    1.061681]  clk_disable+0x30/0x4c
[    1.065499]  pm_clk_suspend+0xd4/0xfc
[    1.068971]  pm_generic_runtime_suspend+0x2c/0x44
[    1.072705]  __rpm_callback+0x40/0x1bc
[    1.077392]  rpm_callback+0x6c/0x78
[    1.081038]  rpm_suspend+0xf0/0x5c0
[    1.084423]  pm_runtime_work+0xf0/0xfc
[    1.087895]  process_one_work+0x17c/0x2f8
[    1.091716]  worker_thread+0x2e8/0x4d4
[    1.095795]  kthread+0xdc/0xe0
[    1.099440]  ret_from_fork+0x10/0x20
[    1.102480] ---[ end trace 0000000000000000 ]---

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/clk/qcom/gcc-ipq5018.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/clk/qcom/gcc-ipq5018.c b/drivers/clk/qcom/gcc-ipq5018.c
index 70f5dcb96700f55da1fb19fc893d22350a7e63bf..24eb4c40da63462077ee2e5714e838aa30ced2e3 100644
--- a/drivers/clk/qcom/gcc-ipq5018.c
+++ b/drivers/clk/qcom/gcc-ipq5018.c
@@ -1371,7 +1371,7 @@ static struct clk_branch gcc_xo_clk = {
 				&gcc_xo_clk_src.clkr.hw,
 			},
 			.num_parents = 1,
-			.flags = CLK_SET_RATE_PARENT,
+			.flags = CLK_SET_RATE_PARENT | CLK_IS_CRITICAL,
 			.ops = &clk_branch2_ops,
 		},
 	},

-- 
2.49.0

