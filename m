From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Wed, 25 Oct 2023 22:24:17 -0500
Subject: [PATCH v3 03/10] powerpc/rtas: Serialize firmware activation
 sequences
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231025-papr-sys_rtas-vs-lockdown-v3-3-5eb04559e7d8@linux.ibm.com>
References: <20231025-papr-sys_rtas-vs-lockdown-v3-0-5eb04559e7d8@linux.ibm.com>
In-Reply-To: <20231025-papr-sys_rtas-vs-lockdown-v3-0-5eb04559e7d8@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>
Cc: linuxppc-dev@lists.ozlabs.org, 
 =?utf-8?q?Michal_Such=C3=A1nek?= <msuchanek@suse.de>, tyreld@linux.ibm.com, 
 gcwilson@linux.ibm.com, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1698290680; l=988;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=7xgBvR+vP8RQ93qdtkMXLJQvwa7cT0CKUnx4Yr3c24Y=;
 b=jvzk2ArQzFP9qxVZoPPMYocBR+9ND91SzbIt8Y4j9LX2vFvUVXK66H7EPWL7HRS4F7Y1QlSSN
 jxU4y4iFBumDErPpUG/At6ZUrvEsG0HfXTQt2FpB2231nT2OhjmnpJY
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
index 579a2c475bb6..864d140e7247 100644
--- a/arch/powerpc/kernel/rtas.c
+++ b/arch/powerpc/kernel/rtas.c
@@ -1738,10 +1738,14 @@ void rtas_activate_firmware(void)
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

