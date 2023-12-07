From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Thu, 07 Dec 2023 17:35:46 -0600
Subject: [PATCH v5 07/13] powerpc/rtas: Serialize firmware activation
 sequences
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231207-papr-sys_rtas-vs-lockdown-v5-7-2ce965636a58@linux.ibm.com>
References: <20231207-papr-sys_rtas-vs-lockdown-v5-0-2ce965636a58@linux.ibm.com>
In-Reply-To: <20231207-papr-sys_rtas-vs-lockdown-v5-0-2ce965636a58@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>
Cc: linuxppc-dev@lists.ozlabs.org, 
 =?utf-8?q?Michal_Such=C3=A1nek?= <msuchanek@suse.de>, 
 "Aneesh Kumar K.V (IBM)" <aneesh.kumar@kernel.org>, tyreld@linux.ibm.com, 
 gcwilson@linux.ibm.com, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1701992313; l=1051;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=UOm9HvAsTc/2SCJvSH6seGkHJWpLyM9TkKI30m0VEQY=;
 b=VSxu2JLFqVAz5ub/OAkz2cCPHtMsrBEeGKKHnrig4qDA5FwskcnXYyu5up7o3vQqDJwo1VwTm
 ijDaBtM0lbsCpkFH2rlaFYCzXrIQ+FPIJl6p3qWBkubDSsSecga5VMe
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use rtas_ibm_activate_firmware_lock to prevent interleaving call
sequences of the ibm,activate-firmware RTAS function, which typically
requires multiple calls to complete the update. While the spec does
not specifically prohibit interleaved sequences, there's almost
certainly no advantage to allowing them.

Reviewed-by: Aneesh Kumar K.V (IBM) <aneesh.kumar@kernel.org>
Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/kernel/rtas.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/arch/powerpc/kernel/rtas.c b/arch/powerpc/kernel/rtas.c
index 4d28983e8b1d..72f6b5a402dd 100644
--- a/arch/powerpc/kernel/rtas.c
+++ b/arch/powerpc/kernel/rtas.c
@@ -1734,10 +1734,14 @@ void rtas_activate_firmware(void)
 		return;
 	}
 
+	mutex_lock(&rtas_ibm_activate_firmware_lock);
+
 	do {
 		fwrc = rtas_call(token, 0, 1, NULL);
 	} while (rtas_busy_delay(fwrc));
 
+	mutex_unlock(&rtas_ibm_activate_firmware_lock);
+
 	if (fwrc)
 		pr_err("ibm,activate-firmware failed (%i)\n", fwrc);
 }

-- 
2.41.0

