From: Suyuan Wang <shyckless@gmail.com>
Subject: [PATCH 0/2] MIPS: rtlx: Fix two error paths in rtlx_open()
Date: Sat, 21 Nov 2026 15:33:00 +0000
Message-Id: <20261121-rtlx-v1-0-bc05d6763ec1@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKy5AWsC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQyND3aKSnArdZCODxLQUS2MjMxMzJaDSgqLUtMwKsDHRsRB+cWlSVmp
 yCUivUm0tALaT/YZoAAAA
X-Change-ID: 20261121-rtlx-c20afd932646
To: tsbogend@alpha.franken.de
Cc: linux-mips@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795275180; l=610;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=gp+9Dc0zHizgJ22P/f77EmMig+HbauItSUwqcGIjs4U=;
 b=GGINSRPN+mZuBMoU53CX9Fq9yNb4S116+enwuhSEKpuryV+vY0YqeruzQmljk4tRXNmCMKhra
 4y7scOPTFvHDymskfAch+vU6dqPT+rdMKBG/xe/23azWlfOSY09cJEC
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two error paths in rtlx_open() leave state behind: a failed
rtlx_init() skips the in_open decrement, so the channel stays busy for
good, and a signal while waiting for the SP program leaves the stack
wait entry on the queue.

Found with a static analysis tool and checked by hand. Compile tested
on mips (maltaaprp_defconfig, W=1); I don't have the hardware.

---
Suyuan Wang (2):
      MIPS: rtlx: Drop in_open count when rtlx_init() fails
      MIPS: rtlx: Call finish_wait() when rtlx_open() is interrupted

 arch/mips/kernel/rtlx.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

