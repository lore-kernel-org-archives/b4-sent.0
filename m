From: Nathan Lynch <nathanl@linux.ibm.com>
Subject: [PATCH 0/8] RTAS changes for 6.4
Date: Mon, 06 Mar 2023 15:33:39 -0600
Message-Id: <20230220-rtas-queue-for-6-4-v1-0-010e4416f13f@linux.ibm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADNcBmQC/x2NQQrCQAwAv1JyNrAbFwW/Ih6yNbWBstXEFaH07
 waPMzDMBi6m4nAZNjD5qOvaAvJhgHHm9hDUezBQomMiSmhvdnx16YLTanjCgpSLVKqcSzpDhJV
 dsBq3cY609WUJ+TSZ9Ps/XW/7/gO26XfIeQAAAA==
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>
Cc: linuxppc-dev@lists.ozlabs.org, Tyrel Datwyler <tyreld@linux.ibm.com>, 
 Scott Cheloha <cheloha@linux.ibm.com>, Andrew Donnellan <ajd@linux.ibm.com>, 
 Nick Child <nnac123@linux.ibm.com>, Laurent Dufour <ldufour@linux.ibm.com>, 
 Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1678138471; l=1294;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=VfnuSEQxaGUIbnOLjv4z+HHxfo/T4W0MG/POU4Uq4CQ=;
 b=V+ZCPAQi3+0isRkO9hw+PjrczsFROAYdmfl975syJxP/uIa0hk7+JG8Ri2R3Np3D/2GpEM6hs
 nMcntOuk21eBIhwZ/4GiChHcHtjvwQ+EGOivRHMKTOIWCjX77EPrcrR
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Proposed changes for the RTAS subsystem and client code.

Fixes that are subject to backporting are at the front of the queue,
followed by documentation and cleanups, with enhancements at the end.

Noteworthy changes:
* Change sys_rtas() to consume -2/990x statuses instead of returning
  them to user space.
* Lockdep annotations for invariants in rtas.c.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
Nathan Lynch (8):
      powerpc/rtas: ensure 8-byte alignment for struct rtas_args
      powerpc/rtas: use memmove for potentially overlapping buffer copy
      powerpc/rtas: rtas_call_unlocked() kerneldoc
      powerpc/rtas: fix miswording in rtas_function kerneldoc
      powerpc/rtas: rename va_rtas_call_unlocked() to va_rtas_call()
      powerpc/rtas: lockdep annotations
      powerpc/rtas: warn on unsafe argument to rtas_call_unlocked()
      powerpc/rtas: consume retry statuses in sys_rtas()

 arch/powerpc/include/asm/rtas-types.h |  5 +-
 arch/powerpc/kernel/rtas.c            | 92 +++++++++++++++++++++++++----------
 2 files changed, 69 insertions(+), 28 deletions(-)
---
base-commit: 422fbcbf91303706823bc3babceb1df1a42112bf
change-id: 20230220-rtas-queue-for-6-4-214eb2ba1407

Best regards,
-- 
Nathan Lynch <nathanl@linux.ibm.com>

