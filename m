From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Thu, 18 Sep 2025 17:24:31 +0800
Subject: [PATCH v4 2/5] param: export param_array related functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250918-sound-v4-2-82cf8123d61c@uniontech.com>
References: <20250918-sound-v4-0-82cf8123d61c@uniontech.com>
In-Reply-To: <20250918-sound-v4-0-82cf8123d61c@uniontech.com>
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Jonathan Corbet <corbet@lwn.net>, Luis Chamberlain <mcgrof@kernel.org>, 
 Petr Pavlu <petr.pavlu@suse.com>, Daniel Gomez <da.gomez@kernel.org>, 
 Sami Tolvanen <samitolvanen@google.com>
Cc: linux-sound@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Mingcong Bai <jeffbai@aosc.io>, Kexy Biscuit <kexybiscuit@aosc.io>, 
 Nie Cheng <niecheng1@uniontech.com>, Zhan Jun <zhanjun@uniontech.com>, 
 Feng Yuan <fengyuan@uniontech.com>, qaqland <anguoli@uniontech.com>, 
 kernel@uniontech.com, linux-modules@vger.kernel.org, 
 Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758187473; l=2799;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=Iu09dllz6TNtY0M5KhKHic/tph0IN8w4KA3fww/CJfM=;
 b=T3cSpNzBi5jROvwC1BFCwr4GCxzo9h8GL1HRhwx+jcUK2ExVvywIBhzmIOST4WRL8Jq+pGBa0
 NEnITolOir5CyxS2jYR7UCfLP0zx2ELqJhR2JgKDVYJMe9nju/rZ23N
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- int param_array_set(const char *val, const struct kernel_param *kp);
- int param_array_get(char *buffer, const struct kernel_param *kp);
- void param_array_free(void *arg);

It would be helpful for the new module param we designed in
snd_usb_audio, in order to run additional custom codes when params
are set in runtime, and re-use the extisted codes in param.c

Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 include/linux/moduleparam.h | 3 +++
 kernel/params.c             | 9 ++++++---
 2 files changed, 9 insertions(+), 3 deletions(-)

diff --git a/include/linux/moduleparam.h b/include/linux/moduleparam.h
index 3a25122d83e2802e6e6a1475a52816251498b26a..4ef09ad2004789855bd21783029c653fac94b9dd 100644
--- a/include/linux/moduleparam.h
+++ b/include/linux/moduleparam.h
@@ -593,6 +593,9 @@ enum hwparam_type {
 
 
 extern const struct kernel_param_ops param_array_ops;
+extern int param_array_set(const char *val, const struct kernel_param *kp);
+extern int param_array_get(char *buffer, const struct kernel_param *kp);
+extern void param_array_free(void *arg);
 
 extern const struct kernel_param_ops param_ops_string;
 extern int param_set_copystring(const char *val, const struct kernel_param *);
diff --git a/kernel/params.c b/kernel/params.c
index b96cfd693c9968012d42acb85611fee1acd47790..a936e018a1c6d0bf2b6b4566f80751840366f652 100644
--- a/kernel/params.c
+++ b/kernel/params.c
@@ -462,7 +462,7 @@ static int param_array(struct module *mod,
 	return 0;
 }
 
-static int param_array_set(const char *val, const struct kernel_param *kp)
+int param_array_set(const char *val, const struct kernel_param *kp)
 {
 	const struct kparam_array *arr = kp->arr;
 	unsigned int temp_num;
@@ -471,8 +471,9 @@ static int param_array_set(const char *val, const struct kernel_param *kp)
 			   arr->elemsize, arr->ops->set, kp->level,
 			   arr->num ?: &temp_num);
 }
+EXPORT_SYMBOL(param_array_set);
 
-static int param_array_get(char *buffer, const struct kernel_param *kp)
+int param_array_get(char *buffer, const struct kernel_param *kp)
 {
 	int i, off, ret;
 	const struct kparam_array *arr = kp->arr;
@@ -492,8 +493,9 @@ static int param_array_get(char *buffer, const struct kernel_param *kp)
 	buffer[off] = '\0';
 	return off;
 }
+EXPORT_SYMBOL(param_array_get);
 
-static void param_array_free(void *arg)
+void param_array_free(void *arg)
 {
 	unsigned int i;
 	const struct kparam_array *arr = arg;
@@ -502,6 +504,7 @@ static void param_array_free(void *arg)
 		for (i = 0; i < (arr->num ? *arr->num : arr->max); i++)
 			arr->ops->free(arr->elem + arr->elemsize * i);
 }
+EXPORT_SYMBOL(param_array_free);
 
 const struct kernel_param_ops param_array_ops = {
 	.set = param_array_set,

-- 
2.51.0

