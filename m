From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Tue, 16 Jan 2024 08:09:25 -0600
Subject: [PATCH] seq_buf: make DECLARE_SEQ_BUF() usable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240116-declare-seq-buf-fix-v1-1-915db4692f32@linux.ibm.com>
X-B4-Tracking: v=1; b=H4sIABSOpmUC/x2MSwqAMBDFriKzdqCt4u8q4sLWpw6InxZFEO9uc
 ZlA8lCAFwRqkoc8LgmyrRF0mpCb+3UCyxCZjDK50trwALf0HhxwsD1HHuXmulKZLVGUtXUUy90
 j6v/adu/7ASG0Mc1lAAAA
To: "Steven Rostedt (Google)" <rostedt@goodmis.org>, 
 Kees Cook <keescook@chromium.org>
Cc: linux-kernel@vger.kernel.org, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705414172; l=1460;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=PDfnqK8MoD62TWn0JxiINKlWua/4QKsMFHUjf8S4QK8=;
 b=eWY/a5vMbGPcD8FCX6fA+B9jBCt4bD6+x6sOb6OUJ3z+QllNTc0jX2mvpktKNuyyowH9aUyQf
 n2a6Z9L3agPAbh4ONpXhTSYRoowvGZPqb1QzlG1dB0K5BgQmhXJ+HUC
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Using the address operator on the array doesn't work:

./include/linux/seq_buf.h:27:27: error: initialization of ‘char *’
  from incompatible pointer type ‘char (*)[128]’
  [-Werror=incompatible-pointer-types]
   27 |                 .buffer = &__ ## NAME ## _buffer,       \
      |                           ^

Apart from fixing that, we can improve DECLARE_SEQ_BUF() by using a
compound literal to define the buffer array without attaching a name
to it. This makes the macro a single statement, allowing constructs
such as:

  static DECLARE_SEQ_BUF(my_seq_buf, MYSB_SIZE);

to work as intended.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
Fixes: dcc4e5728eea ("seq_buf: Introduce DECLARE_SEQ_BUF and seq_buf_str()")
---
 include/linux/seq_buf.h | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/include/linux/seq_buf.h b/include/linux/seq_buf.h
index 5fb1f12c33f9..c44f4b47b945 100644
--- a/include/linux/seq_buf.h
+++ b/include/linux/seq_buf.h
@@ -22,9 +22,8 @@ struct seq_buf {
 };
 
 #define DECLARE_SEQ_BUF(NAME, SIZE)			\
-	char __ ## NAME ## _buffer[SIZE] = "";		\
 	struct seq_buf NAME = {				\
-		.buffer = &__ ## NAME ## _buffer,	\
+		.buffer = (char[SIZE]) { 0 },		\
 		.size = SIZE,				\
 	}
 

---
base-commit: 70d201a40823acba23899342d62bc2644051ad2e
change-id: 20240112-declare-seq-buf-fix-9803b7e679bc

Best regards,
-- 
Nathan Lynch <nathanl@linux.ibm.com>

