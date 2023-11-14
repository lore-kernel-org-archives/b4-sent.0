From: Nathan Lynch <nathanl@linux.ibm.com>
Subject: [PATCH v2 0/5] powerpc/rtas: Trivial and coding style fixes
Date: Tue, 14 Nov 2023 11:22:24 -0600
Message-Id: <20231114-rtas-trivial-v2-0-59cbab208d57@linux.ibm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANCsU2UC/1XMQQ6DIBCF4auYWRcDo1DTVe/RuKAU6iQKBiyxM
 d691K66/F/yvg2SjWQTXKoNos2UKPgSeKrADNo/LaNHaUCOjeAoWVx0YkukTHpkaBCN7WTjWgX
 lMkfraD24W196oLSE+D70LL7rDxJc/UNZMM6U6NqzktJI4a4j+dda032qTZig3/f9A1u4JOasA
 AAA
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>
Cc: Andrew Donnellan <ajd@linux.ibm.com>, 
 Hari Bathini <hbathini@linux.ibm.com>, 
 Mahesh Salgaonkar <mahesh@linux.ibm.com>, linuxppc-dev@lists.ozlabs.org, 
 Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1699982560; l=1247;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=K25NrmNNsLE3HHYk7gFc9T9L54IqIixAVU6/pIF8tW8=;
 b=x4UfS24V4bu/AUVHUmWwuTtZIyaLbtTpzvHTp79/xc7kWjXUsa+dKGHmeZFOstUFrB565Gh1l
 1LwZosWERZODJYIPiU7N3c+NknFZiAZzXaeHEjFNEMvPPvETNL5H5Ll
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

* Make minor coding style adjustments for readability.
* Remove rtas_service_present() and an old call_rtas() declaration.
* Move a pseries-specific function prototype to pseries code.

---
Changes in v2:
- Address various checkpatch issues missed in v1.
- Drop kernel-doc fixes already applied.
- Cc recent contributors in this area.
- Link to v1: https://lore.kernel.org/r/20231106-rtas-trivial-v1-0-61847655c51f@linux.ibm.com

---
Nathan Lynch (5):
      powerpc/rtas: Drop declaration of undefined call_rtas() function
      powerpc/rtas: Remove unused rtas_service_present()
      powerpc/rtas: Move post_mobility_fixup() declaration to pseries
      powerpc/rtas: Remove trailing space
      powerpc/rtas: Remove 'extern' from function declarations in rtas.h

 arch/powerpc/include/asm/rtas.h          | 63 +++++++++++++++-----------------
 arch/powerpc/kernel/rtas.c               | 23 +++++-------
 arch/powerpc/platforms/pseries/pseries.h |  1 +
 arch/powerpc/platforms/pseries/suspend.c |  1 +
 4 files changed, 40 insertions(+), 48 deletions(-)
---
base-commit: 707df298cbde200b939c70be2577b20775fe3345
change-id: 20231025-rtas-trivial-2c22ce853f46

Best regards,
-- 
Nathan Lynch <nathanl@linux.ibm.com>

