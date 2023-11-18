From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Fri, 17 Nov 2023 23:14:24 -0600
Subject: [PATCH v4 06/13] powerpc/rtas: Serialize firmware activation
 sequences
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231117-papr-sys_rtas-vs-lockdown-v4-6-b794d8cb8502@linux.ibm.com>
References: <20231117-papr-sys_rtas-vs-lockdown-v4-0-b794d8cb8502@linux.ibm.com>
In-Reply-To: <20231117-papr-sys_rtas-vs-lockdown-v4-0-b794d8cb8502@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>
Cc: linuxppc-dev@lists.ozlabs.org, 
 =?utf-8?q?Michal_Such=C3=A1nek?= <msuchanek@suse.de>, tyreld@linux.ibm.com, 
 gcwilson@linux.ibm.com, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1700284468; l=988;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=dJaCJaqg/DdTqoNctBZGI5Ok6TMM/PY/XHoMFKqAZp8=;
 b=1rLdthHglpipy1dOTgUUu8ILlIJPtwJUPLzUYy6RO0K5cr4L1A5prGYUuSfwkC/Ub35jXviRw
 1NQhHdVDTOVC9XicKoGpvPnoxjEQcAz9m6W72UAaE6q+qNngqOkwuMj
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use the function lock API to prevent interleaving call sequences of
the ibm,activate-firmware RTAS function, which typically requires
multiple calls to complete the update. While the spec does not
specifically prohibit interleaved sequences, there's almost certainly
no advantage to allowing them.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/kernel/rtas.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/arch/powerpc/kernel/rtas.c b/arch/powerpc/kernel/rtas.c
index 52f2242d0c28..e38ba05ad613 100644
--- a/arch/powerpc/kernel/rtas.c
+++ b/arch/powerpc/kernel/rtas.c
@@ -1753,10 +1753,14 @@ void rtas_activate_firmware(void)
 		return;
 	}
 
+	rtas_function_lock(RTAS_FN_IBM_ACTIVATE_FIRMWARE);
+
 	do {
 		fwrc = rtas_call(token, 0, 1, NULL);
 	} while (rtas_busy_delay(fwrc));
 
+	rtas_function_unlock(RTAS_FN_IBM_ACTIVATE_FIRMWARE);
+
 	if (fwrc)
 		pr_err("ibm,activate-firmware failed (%i)\n", fwrc);
 }

-- 
2.41.0

