From: Anuj Bolewar <bolewara@gmail.com>
Date: Tue, 04 Aug 2026 23:13:23 +0530
Subject: [PATCH 1/2] usb: gadget: f_uac2: fix invalid-free in srate
 configfs store
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-f-uac-srate-invalid-free-v1-1-2c980378cdf5@gmail.com>
References: <20260804-f-uac-srate-invalid-free-v1-0-2c980378cdf5@gmail.com>
In-Reply-To: <20260804-f-uac-srate-invalid-free-v1-0-2c980378cdf5@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Anuj Bolewar <bolewara@gmail.com>, 
 syzbot+38bab69d2760cc99cfbe@syzkaller.appspotmail.com, 
 syzbot+a4f65284f1451010b0a8@syzkaller.appspotmail.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785865402; l=2146;
 i=bolewara@gmail.com; s=20260802; h=from:subject:message-id;
 bh=h3b3cUpt9LNSykl6ZTC6+F63cumiiyAJh4aXLLAwcDA=;
 b=WC4mjhIguPighvd51eNzBqB5v8kUH9yBvAF+q+Xt2NcT/Z3eLs5rXwoc9fIsUjUlsLBqoVRdu
 Y8qWyWDmYiNASsl1oA88Ul3BkxlxIvVudvxUcW01VCRqS6lTKDSrJ7i
X-Developer-Key: i=bolewara@gmail.com; a=ed25519;
 pk=XxcXxqFWk9xQziyNEfhS6NRJQR1shqHRRYzkbaYamm0=
X-Endpoint-Received: by B4 Relay for bolewara@gmail.com/20260802 with auth_id=907
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The store path for the p_srate/c_srate attributes calls kfree() on
split_page after it has been advanced by strsep(). When the first
token fails to parse, strsep() leaves split_page pointing into the
middle of the kstrdup()'d buffer and the subsequent kfree() triggers
a KASAN invalid-free.

Keep the original pointer returned by kstrdup() and free that
instead.

Reported-by: syzbot+38bab69d2760cc99cfbe@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=38bab69d2760cc99cfbe
Reported-by: syzbot+a4f65284f1451010b0a8@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=a4f65284f1451010b0a8
Fixes: a7339e4f5788 ("usb: gadget: f_uac2: Support multiple sampling rates")
Assisted-by: deepseek:v4-pro
Signed-off-by: Anuj Bolewar <bolewara@gmail.com>
---
 drivers/usb/gadget/function/f_uac2.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/drivers/usb/gadget/function/f_uac2.c b/drivers/usb/gadget/function/f_uac2.c
index 897787d0803..1ea1bedef9a 100644
--- a/drivers/usb/gadget/function/f_uac2.c
+++ b/drivers/usb/gadget/function/f_uac2.c
@@ -2013,6 +2013,7 @@ static ssize_t f_uac2_opts_##name##_store(struct config_item *item,	\
 {									\
 	struct f_uac2_opts *opts = to_f_uac2_opts(item);		\
 	char *split_page = NULL;					\
+	char *split_page_orig = NULL;					\
 	int ret = -EINVAL;						\
 	char *token;							\
 	u32 num;							\
@@ -2026,7 +2027,7 @@ static ssize_t f_uac2_opts_##name##_store(struct config_item *item,	\
 									\
 	i = 0;								\
 	memset(opts->name##s, 0x00, sizeof(opts->name##s));		\
-	split_page = kstrdup(page, GFP_KERNEL);				\
+	split_page_orig = split_page = kstrdup(page, GFP_KERNEL);      \
 	while ((token = strsep(&split_page, ",")) != NULL) {		\
 		ret = kstrtou32(token, 0, &num);			\
 		if (ret)						\
@@ -2037,7 +2038,7 @@ static ssize_t f_uac2_opts_##name##_store(struct config_item *item,	\
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

