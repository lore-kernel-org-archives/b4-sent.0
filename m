From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Mon, 06 Nov 2023 07:42:54 -0600
Subject: [PATCH 2/7] powerpc/rtas: Fix ppc_rtas_rmo_buf_show() kernel-doc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231106-rtas-trivial-v1-2-61847655c51f@linux.ibm.com>
References: <20231106-rtas-trivial-v1-0-61847655c51f@linux.ibm.com>
In-Reply-To: <20231106-rtas-trivial-v1-0-61847655c51f@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>
Cc: linuxppc-dev@lists.ozlabs.org, Nathan Lynch <nathanl@linux.ibm.com>, 
 kernel test robot <lkp@intel.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1699278208; l=1171;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=MnmHwrzxob67ZPsK4bqOYSxHsOYqB81Q1mDqbzsffXI=;
 b=TrJuivsNnPgJjWeb4xWtS9Ju9o52A1tJtNTIM1pQ0awSCMtmEVw+mvMXSlrFdj/YofFdrTfFZ
 SLBUBA8ZkiLBv4bABkSVHp/K7TtW9JIqpnvw+zK/cQ7hvb4tkqaXecM
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From a W=1 build:

>> arch/powerpc/kernel/rtas-proc.c:771: warning: Function parameter or member 'm' not described in
>> 'ppc_rtas_rmo_buf_show'
>> arch/powerpc/kernel/rtas-proc.c:771: warning: Function parameter or member 'v' not described in
>> 'ppc_rtas_rmo_buf_show'

Add the missing parameter descriptions.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
Reported-by: kernel test robot <lkp@intel.com>
Closes: https://lore.kernel.org/oe-kbuild-all/202309211645.1Lvwmbv4-lkp@intel.com/
---
 arch/powerpc/kernel/rtas-proc.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/powerpc/kernel/rtas-proc.c b/arch/powerpc/kernel/rtas-proc.c
index 9454b8395b6a..f38df72e64b8 100644
--- a/arch/powerpc/kernel/rtas-proc.c
+++ b/arch/powerpc/kernel/rtas-proc.c
@@ -752,6 +752,8 @@ static int ppc_rtas_tone_volume_show(struct seq_file *m, void *v)
 
 /**
  * ppc_rtas_rmo_buf_show() - Describe RTAS-addressable region for user space.
+ * @m: seq_file output target.
+ * @v: Unused.
  *
  * Base + size description of a range of RTAS-addressable memory set
  * aside for user space to use as work area(s) for certain RTAS

-- 
2.41.0

