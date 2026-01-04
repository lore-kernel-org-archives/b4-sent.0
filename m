From: Sven Peter <sven@kernel.org>
Date: Sun, 04 Jan 2026 22:18:31 +0100
Subject: [PATCH next] phy: apple: atc: Actually check return value of
 devm_apple_tunable_parse
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260104-atcphy-tunable-fix-v1-1-40bf00feaac0@kernel.org>
X-B4-Tracking: v=1; b=H4sIACbZWmkC/x2MQQqAIBAAvxJ7bkGlLPpKdLBcayEs1KKI/p50n
 IGZByIFpghd8UCgkyNvPoMsC5gW42dCtplBCaWFFBWaNO3LjenwZlwJHV9Yy6ZV2mpHzkIO90B
 Z/9MePF0Jhvf9AOlMAr1qAAAA
X-Change-ID: 20260104-atcphy-tunable-fix-517826d6fefd
To: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Vinod Koul <vkoul@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-phy@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Thomas Glanzmann <thomas@glanzmann.de>, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3484; i=sven@kernel.org;
 h=from:subject:message-id; bh=qmsbKPbX1+sTQZ0QzAzI0MrRK6GYbgNVPa9s4pvCfbc=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ2bUTe3pSZWHQk0WVMpvdHxZcLpp0gkxf/0n51f+idksd
 HDZnYBzHaUsDGJcDLJiiizb99ubPnn4RnDppkvvYeawMoEMYeDiFICJ9Bkw/A9fmLPN/tvt5H9J
 akkBktq9fi0KHhOUl5vJnPgdUZu3m4Xhr3zIV2XVuNWfHGUnT2Kc/bQkIPyQn+TJaSeeTXkXIel
 TygUA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Let's actually check the return value of devm_apple_tunable_parse
instead of trying to check IS_ERR on a pointer to the return value which
is always going to be valid. This prevent a oops when the tunables are
invalid or when they don't exist:

[   42.819119] ------------[ cut here ]------------
[   42.819121] WARNING: CPU: 6 PID: 88 at drivers/phy/apple/atc.c:2145 atcphy_mux_set+0xf60/0x1128 [phy_apple_atc]
[   42.819302] CPU: 6 UID: 0 PID: 88 Comm: kworker/6:1 Tainted: G S                  6.18+unreleased-asahi #1 PREEMPTLAZY  Debian 6.18.2-0-1~exp1
[   42.819311] Tainted: [S]=CPU_OUT_OF_SPEC
[   42.819314] Hardware name: Apple Mac mini (M1, 2020) (DT)
[   42.819316] Workqueue: events cd321x_update_work [tps6598x]
[   42.819332] pstate: 81400009 (Nzcv daif +PAN -UAO -TCO +DIT -SSBS BTYPE=--)
[   42.819338] pc : atcphy_mux_set+0xf60/0x1128 [phy_apple_atc]
[   42.819344] lr : atcphy_mux_set+0x30/0x1128 [phy_apple_atc]
[   42.819348] sp : ffffc000813c7c00
[   42.819350] x29: ffffc000813c7c00 x28: ffff800016babeb8 x27: ffff800016babc80
[   42.819357] x26: 0000000000000001 x25: 0000000000000001 x24: 0000000000000000
[   42.819364] x23: ffff800016babec0 x22: 00000000ffffffa1 x21: 0000000000000003
[   42.819371] x20: ffff80000c1b3680 x19: ffff80000dcdd080 x18: 0000000000000000
[   42.819376] x17: 0000000000000000 x16: ffffd42e6ede6e08 x15: 0000000000000000
[   42.819382] x14: ffffd42e707b6980 x13: 0000000000025c68 x12: 726f703d54524f50
[   42.819388] x11: 0000000000000040 x10: 0000000000000000 x9 : ffffd42e555ed9c0
[   42.819394] x8 : 0000000000000006 x7 : ffff80000a000dd8 x6 : 0000000000000002
[   42.819399] x5 : 0000000000000000 x4 : 0000000000000000 x3 : 0000000000000001
[   42.819404] x2 : 0000000000000005 x1 : 000000000000ff01 x0 : 0000000000000001
[   42.819410] Call trace:
[   42.819412]  atcphy_mux_set+0xf60/0x1128 [phy_apple_atc] (P)
[   42.819419]  typec_mux_set+0x74/0xd8 [typec]
[   42.819444]  cd321x_update_work+0x440/0x8a8 [tps6598x]
[   42.819453]  process_one_work+0x170/0x3e0
[   42.819466]  worker_thread+0x25c/0x390
[   42.819473]  kthread+0x148/0x240
[   42.819479]  ret_from_fork+0x10/0x20
[   42.819488] ---[ end trace 0000000000000000 ]---

Reported-by: Thomas Glanzmann <thomas@glanzmann.de>
Fixes: 8e98ca1e74db ("phy: apple: Add Apple Type-C PHY")
Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/phy/apple/atc.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/phy/apple/atc.c b/drivers/phy/apple/atc.c
index c8a58ee64b7aad3205df51cf16ae778471ad2c5d..716c1e70de38ca604803739fedaa543d91f7501b 100644
--- a/drivers/phy/apple/atc.c
+++ b/drivers/phy/apple/atc.c
@@ -2178,10 +2178,10 @@ static int atcphy_load_tunables(struct apple_atcphy *atcphy)
 	for (int i = 0; i < ARRAY_SIZE(tunables); i++) {
 		*tunables[i].tunable = devm_apple_tunable_parse(
 			atcphy->dev, atcphy->np, tunables[i].dt_name, tunables[i].res);
-		if (IS_ERR(tunables[i].tunable)) {
+		if (IS_ERR(*tunables[i].tunable)) {
 			dev_err(atcphy->dev, "Failed to read tunable %s: %ld\n",
-				tunables[i].dt_name, PTR_ERR(tunables[i].tunable));
-			return PTR_ERR(tunables[i].tunable);
+				tunables[i].dt_name, PTR_ERR(*tunables[i].tunable));
+			return PTR_ERR(*tunables[i].tunable);
 		}
 	}
 

---
base-commit: add66a6673bc4aacd0ef0f3c4a51271501770b17
change-id: 20260104-atcphy-tunable-fix-517826d6fefd

Best regards,
-- 
Sven Peter <sven@kernel.org>

