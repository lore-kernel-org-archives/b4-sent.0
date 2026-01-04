From: Sven Peter <sven@kernel.org>
Date: Sun, 04 Jan 2026 22:56:39 +0100
Subject: [PATCH next v2] phy: apple: atc: Actually check return value of
 devm_apple_tunable_parse
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260104-atcphy-tunable-fix-v2-1-84e5c2a57aaa@kernel.org>
X-B4-Tracking: v=1; b=H4sIABbiWmkC/32NQQ6DIBBFr2Jm3WkGYmnTVe/RuEAdhNSAAWo0x
 ruXcIAu//v57x+QODpO8GwOiLy65IIvQV4aGKz2E6MbSwZJUpGgFnUeFrtj/nrdz4zGbXgT94d
 UozJsRijDJXLBVfoGz1uGrlDrUg5xr0+rqN0/6SpQYEu9ITKs9UCvD0fP8zXECbrzPH+Amfemu
 wAAAA==
X-Change-ID: 20260104-atcphy-tunable-fix-517826d6fefd
To: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Vinod Koul <vkoul@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-phy@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Thomas Glanzmann <thomas@glanzmann.de>, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4402; i=sven@kernel.org;
 h=from:subject:message-id; bh=uWGulKN2lHSRnMj0osTbo7QLy+1zIg8tXJwHMSqsZzg=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ2bUIyk5+WNWvS27v5hr3lnM1HHkoOXx0mnvGdj+9MhKz
 660z7/RUcrCIMbFICumyLJ9v73pk4dvBJduuvQeZg4rE8gQBi5OAZjIzUpGho0bnNeLCO589vd9
 98d7uf3bg+/kZP7OEd13u+Qnc/almIuMDMuyP97byOQ7ieFR0xzHCYz3MrX3WJ1c+EMxtyDndcT
 ZmwwA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Let's actually check the return value of devm_apple_tunable_parse
instead of trying to check IS_ERR on a pointer to the return value which
is always going to be valid. This prevent a oops when the tunables are
invalid or when they don't exist:

[   57.664567] Unable to handle kernel paging request at virtual address fffffffffffffffe
[   57.664584] Mem abort info:
[   57.664589]   ESR = 0x0000000096000007
[   57.664595]   EC = 0x25: DABT (current EL), IL = 32 bits
[   57.664602]   SET = 0, FnV = 0
[   57.664607]   EA = 0, S1PTW = 0
[   57.664611]   FSC = 0x07: level 3 translation fault
[   57.664617] Data abort info:
[   57.664621]   ISV = 0, ISS = 0x00000007, ISS2 = 0x00000000
[   57.664626]   CM = 0, WnR = 0, TnD = 0, TagAccess = 0
[   57.664631]   GCS = 0, Overlay = 0, DirtyBit = 0, Xs = 0
[   57.664640] swapper pgtable: 16k pages, 47-bit VAs, pgdp=0000000b4391c000
[   57.664647] [fffffffffffffffe] pgd=0000000000000000, p4d=0000000000000000, pud=0000000b44188403, pmd=0000000b4418c403, pte=0000000000000000
[   57.664670] Internal error: Oops: 0000000096000007 [#1]  SMP
[   57.665047] CPU: 1 UID: 0 PID: 23 Comm: kworker/1:0 Tainted: G S                  6.18.2+ #2 PREEMPTLAZY
[   57.665061] Tainted: [S]=CPU_OUT_OF_SPEC
[   57.665066] Hardware name: Apple Mac mini (M1, 2020) (DT)
[   57.665072] Workqueue: events cd321x_update_work [tps6598x]
[   57.665100] pstate: 61400009 (nZCv daif +PAN -UAO -TCO +DIT -SSBS BTYPE=--)
[   57.665111] pc : apple_tunable_apply+0x8/0x80 [apple_tunable]
[   57.665121] lr : atcphy_mux_set+0x3e0/0x1138 [phy_apple_atc]
[   57.665133] sp : ffffc000802a7c00
[   57.665138] x29: ffffc000802a7c00 x28: 0000000000000003 x27: ffff800016c84080
[   57.665151] x26: 0000000000000002 x25: ffff800016c84090 x24: ffff800016c8408f
[   57.665163] x23: 0000000000020004 x22: 0000000000000001 x21: 0000000000000006
[   57.665175] x20: ffff80000d6da9b0 x19: ffff80000d6da880 x18: 0000000000000002
[   57.665188] x17: 0000000000000000 x16: ffffe22de59e0e38 x15: 0000000000000002
[   57.665199] x14: ffffe22de76ecff8 x13: 0000000000000001 x12: ffff9dd5f90bc000
[   57.665211] x11: 00000000000000c0 x10: 048abc15ceba0919 x9 : ffffe22dbc5fde10
[   57.665223] x8 : ffff80000175e0d8 x7 : 0000000000000004 x6 : 0000000000000000
[   57.665234] x5 : 0000000000000001 x4 : 0000000d6d132db7 x3 : 00000000000155db
[   57.665246] x2 : 0000000000000000 x1 : fffffffffffffffe x0 : ffffc00082b80000
[   57.665258] Call trace:
[   57.665265]  apple_tunable_apply+0x8/0x80 [apple_tunable] (P)
[   57.665276]  typec_mux_set+0x74/0xe0 [typec]
[   57.665315]  cd321x_update_work+0x440/0x8c0 [tps6598x]
[   57.665332]  process_one_work+0x178/0x3d0
[   57.665346]  worker_thread+0x260/0x390
[   57.665354]  kthread+0x150/0x250
[   57.665369]  ret_from_fork+0x10/0x20
[   57.665386] Code: e69a0ae8 ffffe22d aa1e03e9 d503201f (f9400022)
[   57.665394] ---[ end trace 0000000000000000 ]---

Reported-by: Thomas Glanzmann <thomas@glanzmann.de>
Fixes: 8e98ca1e74db ("phy: apple: Add Apple Type-C PHY")
Signed-off-by: Sven Peter <sven@kernel.org>
---
Changes in v2:
- Copy/paste error: Copied a WARN instead of the kernel oops this patch fixes
- Link to v1: https://patch.msgid.link/20260104-atcphy-tunable-fix-v1-1-40bf00feaac0@kernel.org
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

