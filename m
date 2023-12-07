From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Thu, 07 Dec 2023 17:35:41 -0600
Subject: [PATCH v5 02/13] powerpc/rtas: Add for_each_rtas_function()
 iterator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231207-papr-sys_rtas-vs-lockdown-v5-2-2ce965636a58@linux.ibm.com>
References: <20231207-papr-sys_rtas-vs-lockdown-v5-0-2ce965636a58@linux.ibm.com>
In-Reply-To: <20231207-papr-sys_rtas-vs-lockdown-v5-0-2ce965636a58@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>
Cc: linuxppc-dev@lists.ozlabs.org, 
 =?utf-8?q?Michal_Such=C3=A1nek?= <msuchanek@suse.de>, 
 "Aneesh Kumar K.V (IBM)" <aneesh.kumar@kernel.org>, tyreld@linux.ibm.com, 
 gcwilson@linux.ibm.com, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1701992313; l=1528;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=NWsKJAvOyJ6+fcTpCAe3hP9I68yS9JzeFyNNJdqL2GM=;
 b=t3rePbLwg/TsE/GU2yOBX8+1bShA6minwRF868QjivL/AqvPHfFBW+psT1ZHLnwGpnAJyNMWQ
 TCA2BjQfM1UCUaMAeTpY5RVz/4yJCd7UQwuzFD2pBCM2BbrOn0WLbHC
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a convenience macro for iterating over every element of the
internal function table and convert the one site that can use it. An
additional user of the macro is anticipated in changes to follow.

Reviewed-by: Aneesh Kumar K.V (IBM) <aneesh.kumar@kernel.org>
Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/kernel/rtas.c | 9 +++++++--
 1 file changed, 7 insertions(+), 2 deletions(-)

diff --git a/arch/powerpc/kernel/rtas.c b/arch/powerpc/kernel/rtas.c
index ce37dc9860ef..ae9b10c954a1 100644
--- a/arch/powerpc/kernel/rtas.c
+++ b/arch/powerpc/kernel/rtas.c
@@ -454,6 +454,11 @@ static struct rtas_function rtas_function_table[] __ro_after_init = {
 	},
 };
 
+#define for_each_rtas_function(funcp)                                       \
+	for (funcp = &rtas_function_table[0];                               \
+	     funcp < &rtas_function_table[ARRAY_SIZE(rtas_function_table)]; \
+	     ++funcp)
+
 /*
  * Nearly all RTAS calls need to be serialized. All uses of the
  * default rtas_args block must hold rtas_lock.
@@ -525,10 +530,10 @@ static DEFINE_XARRAY(rtas_token_to_function_xarray);
 
 static int __init rtas_token_to_function_xarray_init(void)
 {
+	const struct rtas_function *func;
 	int err = 0;
 
-	for (size_t i = 0; i < ARRAY_SIZE(rtas_function_table); ++i) {
-		const struct rtas_function *func = &rtas_function_table[i];
+	for_each_rtas_function(func) {
 		const s32 token = func->token;
 
 		if (token == RTAS_UNKNOWN_SERVICE)

-- 
2.41.0

