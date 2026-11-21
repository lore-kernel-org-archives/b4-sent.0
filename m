From: Suyuan Wang <shyckless@gmail.com>
Date: Sat, 21 Nov 2026 15:33:02 +0000
Subject: [PATCH 2/2] MIPS: rtlx: Call finish_wait() when rtlx_open() is
 interrupted
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-rtlx-v1-2-bc05d6763ec1@gmail.com>
References: <20261121-rtlx-v1-0-bc05d6763ec1@gmail.com>
In-Reply-To: <20261121-rtlx-v1-0-bc05d6763ec1@gmail.com>
To: tsbogend@alpha.franken.de
Cc: linux-mips@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795275180; l=1294;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=JgIEyO6aUO99OgeO8YLTPRZSiqUg8Z8PnNHmmpccaUs=;
 b=ZRE64yLtB4g7UK57d6Ub5C+FeZeabJw0hXAmX9dHszWGgo3mnRLduQpqWoTqe1juvQx8m2is9
 nYkLp04QW0YAkPrIUkZvboLSBquz/yjUF4FmCl8hMuXuazcU5snY/jt
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

While rtlx_open() waits for the SP program, it calls prepare_to_wait()
with a wait entry on its own stack. If a signal is pending, it leaves
the loop with:

	ret = -ERESTARTSYS;
	goto out_fail;

and skips finish_wait(). The stack wait entry stays on
channel_wqs[index].lx_queue after rtlx_open() returns, and the task is
still in TASK_INTERRUPTIBLE state. A later wake up of that queue then
walks a stale stack entry.

Call finish_wait() before leaving the loop on a signal.

Found with a static analysis tool and checked by hand.

Fixes: 9e3468202657 ("[MIPS] RTLX: Don't use volatile; it's fragile.")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
 arch/mips/kernel/rtlx.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/mips/kernel/rtlx.c b/arch/mips/kernel/rtlx.c
index a1da56163f19..d5ea99bde129 100644
--- a/arch/mips/kernel/rtlx.c
+++ b/arch/mips/kernel/rtlx.c
@@ -138,6 +138,8 @@ int rtlx_open(int index, int can_sleep)
 						schedule();
 						continue;
 					}
+					finish_wait(&channel_wqs[index].lx_queue,
+						    &wait);
 					ret = -ERESTARTSYS;
 					goto out_fail;
 				}

-- 
2.34.1

