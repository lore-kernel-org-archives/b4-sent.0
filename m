From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sun, 15 Nov 2026 09:03:21 +0000
Subject: [PATCH] tee: optee: release the supplicant when its device file is
 closed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-optee-supp-close-v1-1-4e0b14f3a97c@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBG4avIrDtgrGbhVUoXNf6xU8SEjEpBv
 LtRl9/ivY0USaDUFhslrKISpgzzKMh9P9MAlj6bqrKyxpiGQ5wB1iVGdmNQcN30vvQe1nZPyll
 M8PK/lq/3bV26H9x8fmjfD+bgvR90AAAA
X-Change-ID: 20261115-optee-supp-close-45df0ffe66b3
To: Jens Wiklander <jenswi@kernel.org>, Sumit Garg <sumit.garg@kernel.org>, 
 Volodymyr Babchuk <Volodymyr_Babchuk@epam.com>
Cc: op-tee@lists.trustedfirmware.org, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794733400; l=3584;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=9VPYkWm0p8RjYbs/Xy1bmWk92a26aVMFxpnV9Mp2w/8=;
 b=Vm2WeCPp3VonzpMnH8cSV0X4bM7QePHJCcJnN8/8V3p/J8S5tIPV75Yzfj2bQyixAoHBBl+cj
 5m4ij9PXa/eDzjhvstMuhbyySZ/N+4LeOcDVuOzlQsJd+4UKXIfGMLU
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

optee_supp_release() runs only on the context's last reference, which
RPC shared memory can hold. If tee-supplicant exits during an RPC, the
next request waits forever and a new tee-supplicant gets -EBUSY.

Detach the supplicant in .close_context instead.

Fixes: 217e0250cccb ("tee: use reference counting for tee_context")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Tested on an Orange Pi 5 (RK3588S, SMC ABI), 7.3-based KASAN + lockdep
kernel: tee-supplicant stopped and restarted during fTPM NV writes, no
hung task; the fTPM TA then stays dead until a reboot. FF-A is
build-tested only.

Developed with Claude (Anthropic), which wrote the code and the commit
message. I reviewed it.
---
 drivers/tee/optee/core.c          | 4 +---
 drivers/tee/optee/ffa_abi.c       | 3 ++-
 drivers/tee/optee/optee_private.h | 2 +-
 drivers/tee/optee/smc_abi.c       | 3 ++-
 4 files changed, 6 insertions(+), 6 deletions(-)

diff --git a/drivers/tee/optee/core.c b/drivers/tee/optee/core.c
index a52c1f498b99..f446b40d7827 100644
--- a/drivers/tee/optee/core.c
+++ b/drivers/tee/optee/core.c
@@ -184,12 +184,10 @@ void optee_release(struct tee_context *ctx)
 	optee_release_helper(ctx, optee_close_session_helper);
 }
 
-void optee_release_supp(struct tee_context *ctx)
+void optee_close_context_supp(struct tee_context *ctx)
 {
 	struct optee *optee = tee_get_drvdata(ctx->teedev);
 
-	optee_release_helper(ctx, optee_close_session_helper);
-
 	optee_supp_release(&optee->supp);
 }
 
diff --git a/drivers/tee/optee/ffa_abi.c b/drivers/tee/optee/ffa_abi.c
index 702da7d98fbc..155ce9856de9 100644
--- a/drivers/tee/optee/ffa_abi.c
+++ b/drivers/tee/optee/ffa_abi.c
@@ -957,7 +957,8 @@ static const struct tee_driver_ops optee_ffa_supp_ops = {
 	.get_version = optee_ffa_get_version,
 	.get_tee_revision = optee_get_revision,
 	.open = optee_ffa_open,
-	.release = optee_release_supp,
+	.close_context = optee_close_context_supp,
+	.release = optee_release,
 	.supp_recv = optee_supp_recv,
 	.supp_send = optee_supp_send,
 	.shm_register = optee_ffa_shm_register, /* same as for clnt ops */
diff --git a/drivers/tee/optee/optee_private.h b/drivers/tee/optee/optee_private.h
index 94a4f251f5cf..6495e0f07deb 100644
--- a/drivers/tee/optee/optee_private.h
+++ b/drivers/tee/optee/optee_private.h
@@ -370,7 +370,7 @@ void optee_set_dev_group(struct optee *optee);
 void optee_remove_common(struct optee *optee);
 int optee_open(struct tee_context *ctx, bool cap_memref_null);
 void optee_release(struct tee_context *ctx);
-void optee_release_supp(struct tee_context *ctx);
+void optee_close_context_supp(struct tee_context *ctx);
 
 static inline void optee_from_msg_param_value(struct tee_param *p, u32 attr,
 					      const struct optee_msg_param *mp)
diff --git a/drivers/tee/optee/smc_abi.c b/drivers/tee/optee/smc_abi.c
index 51624443359b..0278dc6b0119 100644
--- a/drivers/tee/optee/smc_abi.c
+++ b/drivers/tee/optee/smc_abi.c
@@ -1264,7 +1264,8 @@ static const struct tee_driver_ops optee_supp_ops = {
 	.get_version = optee_get_version,
 	.get_tee_revision = optee_get_revision,
 	.open = optee_smc_open,
-	.release = optee_release_supp,
+	.close_context = optee_close_context_supp,
+	.release = optee_release,
 	.supp_recv = optee_supp_recv,
 	.supp_send = optee_supp_send,
 	.shm_register = optee_shm_register_supp,

---
base-commit: e21989d08e0d6abacfff71387d0cb36dd96a4079
change-id: 20261115-optee-supp-close-45df0ffe66b3

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

