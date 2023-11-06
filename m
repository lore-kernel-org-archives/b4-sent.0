From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Mon, 06 Nov 2023 07:42:58 -0600
Subject: [PATCH 6/7] powerpc/rtas: Remove trailing space
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231106-rtas-trivial-v1-6-61847655c51f@linux.ibm.com>
References: <20231106-rtas-trivial-v1-0-61847655c51f@linux.ibm.com>
In-Reply-To: <20231106-rtas-trivial-v1-0-61847655c51f@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>
Cc: linuxppc-dev@lists.ozlabs.org, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1699278208; l=3543;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=mCITXmD+N9HQngnQowzT5n4gL5xQdpCJhgKeeEHHVks=;
 b=W1wYzR4ZGaBW5VY/IVzrj0J5Q8KYgySIhd2rYJvfNfC8buILM7xGddr8ZAjKrN/Rv8jYSA8jV
 ycHv+LE0hEjBXNqOSvUnBjoGxEGHRNL+q5vSC1s8iY25CbA9Eljnxsb
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use scripts/cleanfile to remove instances of trailing space in the
core RTAS code and header.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/include/asm/rtas.h |  6 +++---
 arch/powerpc/kernel/rtas.c      | 18 +++++++++---------
 2 files changed, 12 insertions(+), 12 deletions(-)

diff --git a/arch/powerpc/include/asm/rtas.h b/arch/powerpc/include/asm/rtas.h
index 2365668fc13e..1bed6be8ada3 100644
--- a/arch/powerpc/include/asm/rtas.h
+++ b/arch/powerpc/include/asm/rtas.h
@@ -268,7 +268,7 @@ typedef struct {
 #define RTAS_TYPE_DEALLOC		0xE3
 #define RTAS_TYPE_DUMP			0xE4
 #define RTAS_TYPE_HOTPLUG		0xE5
-/* I don't add PowerMGM events right now, this is a different topic */ 
+/* I don't add PowerMGM events right now, this is a different topic */
 #define RTAS_TYPE_PMGM_POWER_SW_ON	0x60
 #define RTAS_TYPE_PMGM_POWER_SW_OFF	0x61
 #define RTAS_TYPE_PMGM_LID_OPEN		0x62
@@ -461,7 +461,7 @@ static inline void rtas_cancel_event_scan(void) { }
 
 /* Error types logged.  */
 #define ERR_FLAG_ALREADY_LOGGED	0x0
-#define ERR_FLAG_BOOT		0x1 	/* log was pulled from NVRAM on boot */
+#define ERR_FLAG_BOOT		0x1	/* log was pulled from NVRAM on boot */
 #define ERR_TYPE_RTAS_LOG	0x2	/* from rtas event-scan */
 #define ERR_TYPE_KERNEL_PANIC	0x4	/* from die()/panic() */
 #define ERR_TYPE_KERNEL_PANIC_GZ 0x8	/* ditto, compressed */
@@ -471,7 +471,7 @@ static inline void rtas_cancel_event_scan(void) { }
 	(ERR_TYPE_RTAS_LOG | ERR_TYPE_KERNEL_PANIC | ERR_TYPE_KERNEL_PANIC_GZ)
 
 #define RTAS_DEBUG KERN_DEBUG "RTAS: "
- 
+
 #define RTAS_ERROR_LOG_MAX 2048
 
 /*
diff --git a/arch/powerpc/kernel/rtas.c b/arch/powerpc/kernel/rtas.c
index b5b340a91157..c49f078382a9 100644
--- a/arch/powerpc/kernel/rtas.c
+++ b/arch/powerpc/kernel/rtas.c
@@ -670,7 +670,7 @@ static void call_rtas_display_status_delay(char c)
 	static int pending_newline = 0;  /* did last write end with unprinted newline? */
 	static int width = 16;
 
-	if (c == '\n') {	
+	if (c == '\n') {
 		while (width-- > 0)
 			call_rtas_display_status(' ');
 		width = 16;
@@ -680,7 +680,7 @@ static void call_rtas_display_status_delay(char c)
 		if (pending_newline) {
 			call_rtas_display_status('\r');
 			call_rtas_display_status('\n');
-		} 
+		}
 		pending_newline = 0;
 		if (width--) {
 			call_rtas_display_status(c);
@@ -820,7 +820,7 @@ void rtas_progress(char *s, unsigned short hex)
 		else
 			rtas_call(display_character, 1, 1, NULL, '\r');
 	}
- 
+
 	if (row_width)
 		width = row_width[current_line];
 	else
@@ -840,9 +840,9 @@ void rtas_progress(char *s, unsigned short hex)
 				spin_unlock(&progress_lock);
 				return;
 			}
- 
+
 			/* RTAS wants CR-LF, not just LF */
- 
+
 			if (*os == '\n') {
 				rtas_call(display_character, 1, 1, NULL, '\r');
 				rtas_call(display_character, 1, 1, NULL, '\n');
@@ -852,7 +852,7 @@ void rtas_progress(char *s, unsigned short hex)
 				 */
 				rtas_call(display_character, 1, 1, NULL, *os);
 			}
- 
+
 			if (row_width)
 				width = row_width[current_line];
 			else
@@ -861,15 +861,15 @@ void rtas_progress(char *s, unsigned short hex)
 			width--;
 			rtas_call(display_character, 1, 1, NULL, *os);
 		}
- 
+
 		os++;
- 
+
 		/* if we overwrite the screen length */
 		if (width <= 0)
 			while ((*os != 0) && (*os != '\n') && (*os != '\r'))
 				os++;
 	}
- 
+
 	spin_unlock(&progress_lock);
 }
 EXPORT_SYMBOL_GPL(rtas_progress);		/* needed by rtas_flash module */

-- 
2.41.0

