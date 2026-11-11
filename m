From: yzddMr6 <yzddmr6@gmail.com>
Date: Wed, 11 Nov 2026 15:21:13 +0800
Subject: [PATCH] soc: qcom: llcc-qcom: Reserve ISLAND1 ways on SM8750
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-sm8750-llcc-island1-v1-1-64055702ca3f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAGgX9GoC/yWMTQ6CMBBGr0Jm7cTSqCVexbBoh6nUlEo6YEwId
 7fF5ft+3gbCObDAvdkg8ydIeKcC7akBGm16MoahMGilb63SHcrUmavCGIkwSLRpaFErfzHGk3f
 aQnnOmX34HtZH/2dZ3Ytpqaq6cFYYXbaJxhqtsyyZ7XQ+tLWEff8B3LN9qpwAAAA=
X-Change-ID: 20261028-sm8750-llcc-island1-20f477fcfb2a
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Abel Vesa <abelvesa@kernel.org>, 
 Melody Olvera <melody.olvera@oss.qualcomm.com>, 
 Ajay Kumar Nandam <ajay.nandam@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, yzddMr6 <yzddmr6@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794381693; l=5561;
 i=yzddmr6@gmail.com; s=20261028; h=from:subject:message-id;
 bh=u1722Y2/33+v6rnFwy/S7BVP2WhypCsiB/i4KfmJGt8=;
 b=D9elJKqXuPeYSa4NxF/CsBm3PukIBJzMoOEY/ZeyL8lGbrvpokMybh1i20zfMNynBl6f9Y0lv
 lT2t2biCAXsBfCi28O0IYw2uSN5egtABSKE0LkxmHgyu/xS+ThvVrMc
X-Developer-Key: i=yzddmr6@gmail.com; a=ed25519;
 pk=QLT2mwairk4R38oU379hkHynqjoLrlqd0Cl1ERUqIqY=
X-Endpoint-Received: by B4 Relay for yzddmr6@gmail.com/20261028 with auth_id=1489
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SM8750 table gives the island slice (LLCC_ISLAND1, SCID 12) its way
mask 0x7fffffff as bonus ways and reserves none. Bonus ways are only
allocated when no other slice has reserved them, while reserved ways
belong to the slice alone. The first posting of the SM8750 support [1]
had these ways reserved, as the downstream table shipped for this SoC
still has them (res_ways = 0x7fffffff, no bonus ways). They became bonus
ways when v2 converted the table to designated initializers, and v3,
which refreshed the table, kept them.

With this table, system suspend can reset the SoC once nothing votes
for the LPASS core. On a Xiaomi Pad 8 Pro with the LPASS_HW_MACRO_VOTE
and LPASS_HW_DCODEC_VOTE votes released, 16 suspend attempts (15 with
s2idle, one with PSCI system suspend) ended in a reset. The PMIC PON log
shows only PS_HOLD-triggered resets and no PMIC fault. Holding
LPASS_HW_MACRO_VOTE or LPASS_HW_LPR_VOTE across suspend let one s2idle
cycle each resume, but cxsd did not increase in either case.

The reset stayed hidden while the LPASS macro codecs took both votes at
probe and held them until removal, as they did before v7.3. Since v7.3
the codecs manage these votes through the PM clock framework and drop
them when they runtime suspend.

Reserve the ways again. With that, all six s2idle cycles that went to
sleep (48 to 60 s each, no LPASS vote held) resumed normally, with the
cxsd and ddr residencies in qcom_stats within 0.1 s of the time spent
asleep. The ADSP island counter increases at runtime with either
table. The mechanism behind the suspend reset is not yet understood.

The mismatch was found with the help of an AI coding assistant.

Fixes: 2c04e58e30ce ("soc: qcom: llcc-qcom: Add support for SM8750")
Link: https://lore.kernel.org/r/20250113-sm8750_llcc_master-v1-3-5389b92e2d7a@quicinc.com [1]
Cc: stable@vger.kernel.org
Signed-off-by: yzddMr6 <yzddmr6@gmail.com>
---
Tested on a Xiaomi Pad 8 Pro (SM8750) running v7.4-rc1 with out-of-tree
board support and the TX/VA patches of Ajay's "manage clocks in runtime
PM" series [2], which replace the PM clock handling with explicit clock
management and also force the macros into runtime suspend for system
sleep. For the comparison I set these two fields back to the current
values in a copy of the same kernel image; DT, initramfs and root file
system were the same. With the current values, the first s2idle attempt
ended in a reset, and the PMIC PON log again shows only
PS_HOLD-triggered resets. With this patch, three s2idle cycles (38, 46
and 59 s) resumed normally, with the cxsd and ddr residencies within
0.01 s of the time spent asleep.

The numbers in the changelog come from earlier runs on a v7.2-based
kernel with the v7.3 TX and VA macro runtime PM conversions backported
and the same patches of [2] on top. Not counted there on either side:
attempts that exited at once because of a debug setting (two before the
fix with CX collapse blocked, two after it with console_suspend=N).

All of these suspend tests were done with a USB cable connected.
Build-tested on the base commit below (arm64 defconfig, W=1); in the
object only these two fields of sm8750_data change.

v1 had {LLCC_ISLAND1, 12, 7936, 7, 1, 0, 0x7FFFFFFF, ...}, the same
values as the downstream sun_data, e.g. in the OnePlus 13 kernel
release [3]. The downstream driver writes res_ways to TRP_ATTR0_CFGn and
bonus_ways to TRP_ATTR1_CFGn, as _qcom_llcc_cfg_program_v6() does here.

The final table also differs from v1 and downstream elsewhere: v2
changed CVP from ovcap_en to vict_prio and the CAMRTRF priority from 3
to 1, and v3 set ovcap_prio where v1 and downstream set ovcap_en for
VIDDEC, CAMOFE, CAMRTIP, CAMSRTIP, CAMRTRF and CAMSRTRF. I can't test
those and left them alone.

Downstream moved the SM8550 island slices from bonus to reserved ways in
2023 ("as per design recommendation") [4]; upstream sm8550_data still
has the earlier bonus values. I have no SM8550 hardware to test that.

Kaanapali also uses bonus ways for ISLAND1, but that matches its
downstream table [5], so I left it alone.

I used an AI coding assistant for this work. It ran the suspend
experiments on the tablet, found the table mismatch and drafted this
patch and changelog. I have reviewed the change and the measurements.

[2] https://lore.kernel.org/r/20260928-xo-sd-runtimepm-v1-final-v1-0-e3ebade3aeb7@oss.qualcomm.com
[3] https://github.com/OnePlusOSS/android_kernel_oneplus_sm8750/blob/6028f47faddaa27700f8dd3a1d83906ea8f27170/drivers/soc/qcom/llcc-qcom.c#L479
[4] https://git.codelinaro.org/clo/la/kernel/msm-5.15/-/commit/adec35fd4cf84dca253eca06d9a4960f1eb85db0
[5] https://github.com/OnePlusOSS/android_kernel_oneplus_sm8850/blob/fc30e54174d254ff7f33622a9278e4435f6718d2/drivers/soc/qcom/llcc-qcom.c#L665
---
 drivers/soc/qcom/llcc-qcom.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/soc/qcom/llcc-qcom.c b/drivers/soc/qcom/llcc-qcom.c
index d7a42a8040a1..007593d1e951 100644
--- a/drivers/soc/qcom/llcc-qcom.c
+++ b/drivers/soc/qcom/llcc-qcom.c
@@ -3923,7 +3923,7 @@ static const struct llcc_slice_config sm8750_data[] = {
 		.max_cap = 7936,
 		.priority = 7,
 		.fixed_size = true,
-		.bonus_ways = 0x7fffffff,
+		.res_ways = 0x7fffffff,
 	}, {
 		.usecase_id = LLCC_DISP_WB,
 		.slice_id = 23,

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261028-sm8750-llcc-island1-20f477fcfb2a

Best regards,
--  
yzddMr6 <yzddmr6@gmail.com>

