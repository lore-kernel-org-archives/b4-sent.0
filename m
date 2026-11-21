From: Suyuan Wang <shyckless@gmail.com>
Date: Sat, 21 Nov 2026 15:33:01 +0000
Subject: [PATCH 1/2] MIPS: rtlx: Drop in_open count when rtlx_init() fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-rtlx-v1-1-bc05d6763ec1@gmail.com>
References: <20261121-rtlx-v1-0-bc05d6763ec1@gmail.com>
In-Reply-To: <20261121-rtlx-v1-0-bc05d6763ec1@gmail.com>
To: tsbogend@alpha.franken.de
Cc: linux-mips@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795275180; l=1420;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=JD5qVzM6zgwsX4UmflbQor0ANyVYFEbJd9+2DIbxRVI=;
 b=5iR043Wt841g+UCP9SkKElIUd+CdajHIjhDXwDwTTnr8ZiXXasn0jhKEqwAzHjTMhgy440oYR
 KNRNolo1zd9Cz5oQRO4p3S2ZVHoVunO1VtIK28ozVuaAptDCAmRQay6
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

rtlx_open() raises channel_wqs[index].in_open at the start and drops it
again at out_fail, on both the success and the error paths. When
rtlx_init() fails, for example because the SP program has no valid RTLX
id, the code jumps to out_ret instead and skips the decrement.

After that, every later open of the channel sees in_open > 1 and fails
with -EBUSY, even after a correct SP program is loaded.

Jump to out_fail so the count is dropped, and remove the now unused
out_ret label.

Found with a static analysis tool and checked by hand.

Fixes: c4c4018b04f9 ("[MIPS] RTLX, VPE: Make open actually atomic.")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
 arch/mips/kernel/rtlx.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/arch/mips/kernel/rtlx.c b/arch/mips/kernel/rtlx.c
index 18c509c59f33..a1da56163f19 100644
--- a/arch/mips/kernel/rtlx.c
+++ b/arch/mips/kernel/rtlx.c
@@ -159,7 +159,7 @@ int rtlx_open(int index, int can_sleep)
 
 		ret = rtlx_init(*p);
 		if (ret < 0)
-			goto out_ret;
+			goto out_fail;
 	}
 
 	chan = &rtlx->channel[index];
@@ -175,7 +175,6 @@ int rtlx_open(int index, int can_sleep)
 	atomic_dec(&channel_wqs[index].in_open);
 	smp_mb();
 
-out_ret:
 	return ret;
 }
 

-- 
2.34.1

