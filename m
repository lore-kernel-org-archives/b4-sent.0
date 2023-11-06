From: Nathan Lynch <nathanl@linux.ibm.com>
Subject: [PATCH 0/7] powerpc/rtas: Trivial, coding style, and kernel-doc
 fixes
Date: Mon, 06 Nov 2023 07:42:52 -0600
Message-Id: <20231106-rtas-trivial-v1-0-61847655c51f@linux.ibm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAF3tSGUC/x3MQQqAIBBA0avIrBNszIiuEi3ExhqIilEikO6et
 HyL/wskEqYEoyogdHPi86hoGwVh88dKmpdqQIO2Nei0ZJ90Fr7Z7xoDYqDB2dj1UJNLKPLz76b
 5fT/omXtAXgAAAA==
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>
Cc: linuxppc-dev@lists.ozlabs.org, Nathan Lynch <nathanl@linux.ibm.com>, 
 kernel test robot <lkp@intel.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1699278208; l=1321;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=9pQwjUL7PMtkICM3/JD7Qu1swEeqMIjv9S2iKiZDUTc=;
 b=JrW+Hf9xPog4O7u0O5jPQgBqHi0ee4XAIIbc7nwjyBCzra0D7hBuantEwSbrG/sy3UAFZMVe1
 tIkHMImp0j/CIK0h9uXpLoxss5eAw+nUo+ox14UJx4n1T3XDMKR74Tp
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

* Fix recently introduced kernel-doc warnings.
* Make minor coding style adjustments for readability.
* Remove rtas_service_present() and an old call_rtas() declaration.
* Move a pseries-specific function prototype to pseries code.

---
Nathan Lynch (7):
      powerpc/pseries/rtas-work-area: Fix rtas_work_area_reserve_arena() kernel-doc
      powerpc/rtas: Fix ppc_rtas_rmo_buf_show() kernel-doc
      powerpc/rtas: Drop declaration of undefined call_rtas() function
      powerpc/rtas: Remove unused rtas_service_present()
      powerpc/rtas: Move post_mobility_fixup() declaration to pseries
      powerpc/rtas: Remove trailing space
      powerpc/rtas: Remove 'extern' from function declarations in rtas.h

 arch/powerpc/include/asm/rtas.h                 | 62 ++++++++++++-------------
 arch/powerpc/kernel/rtas-proc.c                 |  2 +
 arch/powerpc/kernel/rtas.c                      | 23 ++++-----
 arch/powerpc/platforms/pseries/pseries.h        |  1 +
 arch/powerpc/platforms/pseries/rtas-work-area.c |  1 +
 arch/powerpc/platforms/pseries/suspend.c        |  1 +
 6 files changed, 43 insertions(+), 47 deletions(-)
---
base-commit: 303d77a6e1707498f09c9d8ee91b1dc07ca315a5
change-id: 20231025-rtas-trivial-2c22ce853f46

Best regards,
-- 
Nathan Lynch <nathanl@linux.ibm.com>

