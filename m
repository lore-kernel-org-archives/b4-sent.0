From: Charlie Jenkins <thecharlesjenkins@gmail.com>
Date: Mon, 02 Mar 2026 14:54:58 -0800
Subject: [PATCH] lib: sbi: fix sse_event_inject() status setting
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260302-event_inject_fix-v1-1-e88952b03aa4@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MSwqAMBDFriKztjDWL15FRLQ+dVxUaaUI4t0tL
 hNIHvJwAk9t8pBDEC+HjZClCZlttCuUzJFJs644Z60QYK9B7A5zDYvcai6zpp5QMNhQzE6HqP9
 l17/vByKMl8diAAAA
X-Change-ID: 20260302-event_inject_fix-d5187be40e0c
To: opensbi@lists.infradead.org
Cc: Charlie Jenkins <thecharlesjenkins@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772492100; l=1034;
 i=thecharlesjenkins@gmail.com; s=20260127; h=from:subject:message-id;
 bh=5cQq/4MtY0zcB4kfK5DIAgxBYsz16twf7sjEqwkkdJc=;
 b=Mcbf2V9yibMLP1prRj1vX7ulz8TcTraQuBeuYyM7AHtwZ3MJxJASyd4/TgygLjDECGL9fgGxQ
 RdNEYDlypg4BMeTU66AnVL2WN65gErPeCLHBtgU829YP+cMSf07nyy8
X-Developer-Key: i=thecharlesjenkins@gmail.com; a=ed25519;
 pk=4AzEw2rmBYSzmHkYTjITwPc2sWIvqjw/Fu3GnQmSMTI=
X-Endpoint-Received: by B4 Relay for thecharlesjenkins@gmail.com/20260127 with auth_id=619
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sse_event_inject() currently sets all status bits to 1 except for
SBI_SSE_ATTR_STATUS_PENDING_OFFSET which it sets to zero. Instead of
overwriting all the values of the status bits, sse_event_inject() is
only expected to clear SBI_SSE_ATTR_STATUS_PENDING_OFFSET. Fix
sse_event_inject() to only do the clearing.

Signed-off-by: Charlie Jenkins <thecharlesjenkins@gmail.com>
---
 lib/sbi/sbi_sse.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/lib/sbi/sbi_sse.c b/lib/sbi/sbi_sse.c
index a14754f8..818afb87 100644
--- a/lib/sbi/sbi_sse.c
+++ b/lib/sbi/sbi_sse.c
@@ -548,7 +548,7 @@ static void sse_event_inject(struct sbi_sse_event *e,
 
 	sse_event_set_state(e, SBI_SSE_STATE_RUNNING);
 
-	e->attrs.status = ~BIT(SBI_SSE_ATTR_STATUS_PENDING_OFFSET);
+	e->attrs.status &= ~BIT(SBI_SSE_ATTR_STATUS_PENDING_OFFSET);
 
 	i_ctx->a6 = regs->a6;
 	i_ctx->a7 = regs->a7;

---
base-commit: 8d1c21b38752301fc6c727eece45c15c663649b0
change-id: 20260302-event_inject_fix-d5187be40e0c

- Charlie

