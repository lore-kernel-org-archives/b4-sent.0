From: Gleb Pesin <dormancygrace@gmail.com>
Date: Tue, 06 Oct 2026 03:35:54 +0300
Subject: [PATCH 1/3] riscv: vector: Check the xtheadvector status field in
 riscv_v_is_on()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261006-riscv-xtheadvector-vs-v1-1-b00e5abc9f7a@gmail.com>
References: <20261006-riscv-xtheadvector-vs-v1-0-b00e5abc9f7a@gmail.com>
In-Reply-To: <20261006-riscv-xtheadvector-vs-v1-0-b00e5abc9f7a@gmail.com>
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Andy Chiu <tchiu@tenstorrent.com>, 
 Charlie Jenkins <thecharlesjenkins@gmail.com>, stable@vger.kernel.org, 
 Gleb Pesin <dormancygrace@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791246959; l=1590;
 i=dormancygrace@gmail.com; s=20261006; h=from:subject:message-id;
 bh=WbIFXRUyFkHtN9RwI0mQ1+iF69lCdC2VEx0eUHFoGCs=;
 b=yk3lp8q7evGbvckSl50Aw/aQCB+qoIGwkGRubmwV8cu24M8wRDDTPR6PMBtV/kgRrOrxTWTlZ
 wq/OYhlnzB/CkuJfbWiF4GDTJnpSObYye5a7UL4gDbNaclA3nn4y9Wf
X-Developer-Key: i=dormancygrace@gmail.com; a=ed25519;
 pk=Ha8pk6XE0bhPh/mNtu1MKWgYqiX+CxZdhLyDR1rgD/M=
X-Endpoint-Received: by B4 Relay for dormancygrace@gmail.com/20261006 with auth_id=1121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

riscv_v_is_on() tests only the standard sstatus.VS field. Since commit
d863910eabaf ("riscv: vector: Support xtheadvector save/restore"),
riscv_v_enable() and riscv_v_disable() set and clear SR_VS_THEAD instead
on cores with xtheadvector, so riscv_v_is_on() returns false there even
while the vector unit is enabled.

__switch_to_vector() relies on riscv_v_is_on() to recognise a task that
is switched out inside a preemptible kernel-mode vector section. On
xtheadvector cores that check never succeeds: the outgoing task neither
disables the vector unit nor sets RISCV_PREEMPT_V_IN_SCHEDULE, and
riscv_v_enable() is skipped when the task is switched back in.

Test the status field that the running core actually uses.

Fixes: d863910eabaf ("riscv: vector: Support xtheadvector save/restore")
Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: Gleb Pesin <dormancygrace@gmail.com>
---
 arch/riscv/include/asm/vector.h | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/arch/riscv/include/asm/vector.h b/arch/riscv/include/asm/vector.h
index fffe72a77..910313dd0 100644
--- a/arch/riscv/include/asm/vector.h
+++ b/arch/riscv/include/asm/vector.h
@@ -128,7 +128,9 @@ static __always_inline void riscv_v_disable(void)
 
 static __always_inline bool riscv_v_is_on(void)
 {
-	return !!(csr_read(CSR_SSTATUS) & SR_VS);
+	unsigned long mask = has_xtheadvector() ? SR_VS_THEAD : SR_VS;
+
+	return !!(csr_read(CSR_SSTATUS) & mask);
 }
 
 static __always_inline void __vstate_csr_save(struct __riscv_v_ext_state *dest)

-- 
2.53.0

