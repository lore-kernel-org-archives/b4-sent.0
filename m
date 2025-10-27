From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 27 Oct 2025 12:28:15 +0100
Subject: [PATCH] sysctl remove __user qualifier from stack_erasing_sysctl
 buffer argument
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251027-jag-sysctl-v1-1-1c14a8a939ae@kernel.org>
X-B4-Tracking: v=1; b=H4sIAE5X/2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDAyNz3azEdN3iyuLkkhzdRENTCzMzQzNj40QjJaCGgqLUtMwKsGHRsbW
 1APfbjXxcAAAA
X-Change-ID: 20251027-jag-sysctl-a158661633a2
To: Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-hardening@vger.kernel.org, linux-kernel@vger.kernel.org, 
 kernel test robot <lkp@intel.com>, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1369;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=eD3lETxn/iz3FjZFZ/Zss/5C94rc+yleaXerSy//MiE=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGj/V1FXoKRGZaB2eLkB4Q6jFCQpUETPQF33z
 3ZMj2EmStZ+KYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJo/1dRAAoJELqXzVK3
 lkFPdYwL/3OKoew9eujeZPcfYgdJsY6TodMxQa4Vb50ZpHB1ZUCNVkNzl2fVlf0cngw9KWbsqur
 dlQJVBDQY7jOjp97s1ets7JdlYXiVHJOhwwC4baiCtiq6YtNV9vbUKXdBWfT75gxnJ1TgMzxUbb
 sluduw+Rl3amVE2tG1MJRQYRBHo3OAEFszhMah3zqr35Rba1r8/HmnT3GglNertdNqIpfkdVmJc
 qU9DUoFUyqL3inDeJOacuUd78eszUAv1FiuHLwi+EpTgpWJhVyVQGN97cNX41D0RCL36khxkcUR
 ui2C1FLHid8ql2/yyGcJkegCwWnq+eoGH5Ipd8+/Lp3MXGuS1B8FKUaolg2uh6NTDL2GYGtyYmU
 k+dsAKn4vyMZ2JhbH5ihz+4Wz85EzScDmYj710RM7rlxwUtKEBOWOUmtk7qVBEmcA6730NIZdwC
 IU20dT0RnIYELJx73UZp4G4/Qz4XBOQvJcFPpmdQAYyiGkag33Zk//tHPtP4v9yFJc6vkSok+07
 Ss=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The buffer arg in proc handler functions have been void* (no __user
qualifier) since commit 32927393dc1c ("sysctl: pass kernel pointers to
->proc_handler"). The __user qualifier was erroneously brought back in
commit 0df8bdd5e3b3 ("stackleak: move stack_erasing sysctl to
stackleak.c"). This fixes the error by remiving the __user qualifier.

Reported-by: kernel test robot <lkp@intel.com>
Closes: https://lore.kernel.org/oe-kbuild-all/202510221719.3ggn070M-lkp@intel.com/
Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/kstack_erase.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/kernel/kstack_erase.c b/kernel/kstack_erase.c
index e49bb88b4f0a32eca192003f1995e2923d6a4afa..d4449884084c7d9e483d6980e4fa1e73f0305e9e 100644
--- a/kernel/kstack_erase.c
+++ b/kernel/kstack_erase.c
@@ -23,7 +23,7 @@ static DEFINE_STATIC_KEY_FALSE(stack_erasing_bypass);
 
 #ifdef CONFIG_SYSCTL
 static int stack_erasing_sysctl(const struct ctl_table *table, int write,
-			void __user *buffer, size_t *lenp, loff_t *ppos)
+			void *buffer, size_t *lenp, loff_t *ppos)
 {
 	int ret = 0;
 	int state = !static_branch_unlikely(&stack_erasing_bypass);

---
base-commit: 3a8660878839faadb4f1a6dd72c3179c1df56787
change-id: 20251027-jag-sysctl-a158661633a2

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

