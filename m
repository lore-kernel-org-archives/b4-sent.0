From: Anuj Bolewar <bolewara@gmail.com>
Date: Tue, 04 Aug 2026 23:13:24 +0530
Subject: [PATCH 2/2] usb: gadget: f_uac1: fix invalid-free in srate
 configfs store
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-f-uac-srate-invalid-free-v1-2-2c980378cdf5@gmail.com>
References: <20260804-f-uac-srate-invalid-free-v1-0-2c980378cdf5@gmail.com>
In-Reply-To: <20260804-f-uac-srate-invalid-free-v1-0-2c980378cdf5@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Anuj Bolewar <bolewara@gmail.com>, 
 syzbot+2532c7901f590afd0c3a@syzkaller.appspotmail.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785865402; l=2017;
 i=bolewara@gmail.com; s=20260802; h=from:subject:message-id;
 bh=usMCQequLk+4yrdjg1stFDJGlIssLlABJud84TcvNlE=;
 b=fbwM61x+ajgIkSNjGJdsGMSfnuR/DqGZkIbPZ+8UMpNE0JoLPYYdO5kYOR+P+pSz+hLOOj9YU
 dpS4Owd1HTDB8dziPStP7k/pJ3+wWKkNgHjtGOiczdk1efjk+fxc2z0
X-Developer-Key: i=bolewara@gmail.com; a=ed25519;
 pk=XxcXxqFWk9xQziyNEfhS6NRJQR1shqHRRYzkbaYamm0=
X-Endpoint-Received: by B4 Relay for bolewara@gmail.com/20260802 with auth_id=907
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Same bug as f_uac2: the store path for the p_srate/c_srate
attributes frees split_page after strsep() has advanced it into the
middle of the kstrdup()'d buffer. A non-numeric first token makes
kstrtou32() fail and kfree() is called on a pointer into the slab
object, triggering a KASAN invalid-free.

Keep the original pointer returned by kstrdup() and free that
instead.

Reported-by: syzbot+2532c7901f590afd0c3a@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=2532c7901f590afd0c3a
Fixes: 695d39ffc2b5 ("usb: gadget: f_uac1: Support multiple sampling rates")
Assisted-by: deepseek:v4-pro
Signed-off-by: Anuj Bolewar <bolewara@gmail.com>
---
 drivers/usb/gadget/function/f_uac1.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/drivers/usb/gadget/function/f_uac1.c b/drivers/usb/gadget/function/f_uac1.c
index 85c502e98f5..94c716d72c6 100644
--- a/drivers/usb/gadget/function/f_uac1.c
+++ b/drivers/usb/gadget/function/f_uac1.c
@@ -1595,6 +1595,7 @@ static ssize_t f_uac1_opts_##name##_store(struct config_item *item,	\
 {									\
 	struct f_uac1_opts *opts = to_f_uac1_opts(item);		\
 	char *split_page = NULL;					\
+	char *split_page_orig = NULL;					\
 	int ret = -EINVAL;						\
 	char *token;							\
 	u32 num;							\
@@ -1608,7 +1609,7 @@ static ssize_t f_uac1_opts_##name##_store(struct config_item *item,	\
 									\
 	i = 0;								\
 	memset(opts->name##s, 0x00, sizeof(opts->name##s));		\
-	split_page = kstrdup(page, GFP_KERNEL);				\
+	split_page_orig = split_page = kstrdup(page, GFP_KERNEL);      \
 	while ((token = strsep(&split_page, ",")) != NULL) {		\
 		ret = kstrtou32(token, 0, &num);			\
 		if (ret)						\
@@ -1619,7 +1620,7 @@ static ssize_t f_uac1_opts_##name##_store(struct config_item *item,	\
 	};								\
 									\
 end:									\
-	kfree(split_page);						\
+	kfree(split_page_orig);						\
 	mutex_unlock(&opts->lock);					\
 	return ret;							\
 }									\

-- 
2.53.0

