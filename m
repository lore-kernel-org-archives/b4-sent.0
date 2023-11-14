From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Tue, 14 Nov 2023 11:22:26 -0600
Subject: [PATCH v2 2/5] powerpc/rtas: Remove unused rtas_service_present()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231114-rtas-trivial-v2-2-59cbab208d57@linux.ibm.com>
References: <20231114-rtas-trivial-v2-0-59cbab208d57@linux.ibm.com>
In-Reply-To: <20231114-rtas-trivial-v2-0-59cbab208d57@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>
Cc: Andrew Donnellan <ajd@linux.ibm.com>, 
 Hari Bathini <hbathini@linux.ibm.com>, 
 Mahesh Salgaonkar <mahesh@linux.ibm.com>, linuxppc-dev@lists.ozlabs.org, 
 Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1699982560; l=1479;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=DZvLOdDIHUxKijnpi1Z0q0XnG4VEsIXvpzPh6vLb/O4=;
 b=h433Y0fJzxRdKhuzImCBja7o3vGzkAYEMEk9+L1f8QGBnGxIWgySZTi5d0AKeY50Myh0kfGQK
 olqeyKMGcPMAjA/XMxWjxp/9qJLGOLh1P5igu1S9t7shX50JaN8zPxK
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rtas_service_present() has no more users.

rtas_function_implemented() is now the appropriate API for determining
whether a given RTAS function is available to call.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/include/asm/rtas.h | 1 -
 arch/powerpc/kernel/rtas.c      | 5 -----
 2 files changed, 6 deletions(-)

diff --git a/arch/powerpc/include/asm/rtas.h b/arch/powerpc/include/asm/rtas.h
index 3bf7f0a4b07e..c6568a647cd0 100644
--- a/arch/powerpc/include/asm/rtas.h
+++ b/arch/powerpc/include/asm/rtas.h
@@ -409,7 +409,6 @@ static inline bool rtas_function_implemented(const rtas_fn_handle_t handle)
 	return rtas_function_token(handle) != RTAS_UNKNOWN_SERVICE;
 }
 extern int rtas_token(const char *service);
-extern int rtas_service_present(const char *service);
 extern int rtas_call(int token, int, int, int *, ...);
 void rtas_call_unlocked(struct rtas_args *args, int token, int nargs,
 			int nret, ...);
diff --git a/arch/powerpc/kernel/rtas.c b/arch/powerpc/kernel/rtas.c
index eddc031c4b95..b5b340a91157 100644
--- a/arch/powerpc/kernel/rtas.c
+++ b/arch/powerpc/kernel/rtas.c
@@ -900,11 +900,6 @@ int rtas_token(const char *service)
 }
 EXPORT_SYMBOL_GPL(rtas_token);
 
-int rtas_service_present(const char *service)
-{
-	return rtas_token(service) != RTAS_UNKNOWN_SERVICE;
-}
-
 #ifdef CONFIG_RTAS_ERROR_LOGGING
 
 static u32 rtas_error_log_max __ro_after_init = RTAS_ERROR_LOG_MAX;

-- 
2.41.0

