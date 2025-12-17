From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 17 Dec 2025 09:04:41 +0100
Subject: [PATCH 3/7] sysctl: Add CONFIG_PROC_SYSCTL guards for converter
 macros
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251217-jag-no-macro-conv-v1-3-6e4252687915@kernel.org>
References: <20251217-jag-no-macro-conv-v1-0-6e4252687915@kernel.org>
In-Reply-To: <20251217-jag-no-macro-conv-v1-0-6e4252687915@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2545;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=N7Xwq5Z5BoMOd9TzVgbIMWfFv5xGXmLMAU7dBOOPWUQ=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGlCZEr9mOFjyMw7gjZmiybtKenWNzwRuobBa
 bpqcMotcuNGKYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJpQmRKAAoJELqXzVK3
 lkFPhuEMAJPZlpJwksDL+K9bzUCMVUw7C+m1CEUwWNqhulM302vOjCVfHBgLYQKiaVmyZkYcJxK
 1IZTfJFS1ae864sVGV+QHPD1hdb6e3vCEYC+fxv8gYl7Grnc9ve+m0rt8/OK7YGbIXGzHM+eTP4
 doYXys9S9yolZshNxCcBh8WmicU2FtzSv3xksf18eGLLC77PhMRLIZzZWj39jMg65crYSnA0j0S
 PPx1yph9IJkPucce/rf4nyuZIC5u4n03Xs9OXt9u8fjxfcS9Dm+zyMG+2SKaKRSrj0VwYZSWWCU
 w/JHp/HkHIOP7NRwAvALgVp9ZSgrgq4QKfoeAeHB8ujHoKrp/E9E/Tg1fZuQnwdAlZHfvzC+uBT
 FhAnkKXZYbiCHyhcqd6zWT9Lvn8NabCqIswY9Whu5i3seL/4JSP5+NJzqKuK1veIW2ZOCwuxnLK
 ciLnEctGcy94IfC4tyhvNVWQOekdS90jkpDU4rfQhfCjgSY+11mbAqP4ozBRgQXaOQpuY6TCmg7
 AM=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Wrap sysctl converter macros with CONFIG_PROC_SYSCTL conditional
compilation. When CONFIG_PROC_SYSCTL is disabled, provide stub
implementations that return -ENOSYS to prevent link errors while
maintaining API compatibility.

This ensures converter macros are only compiled when procfs sysctl
support is enabled in the kernel configuration.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 include/linux/sysctl.h | 43 +++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 43 insertions(+)

diff --git a/include/linux/sysctl.h b/include/linux/sysctl.h
index 288fe0055cd5f7bd670a4e9797cc0595f4060e5f..0a64212a0ceb8454ae343831739831a092b6e693 100644
--- a/include/linux/sysctl.h
+++ b/include/linux/sysctl.h
@@ -73,6 +73,7 @@ extern const int sysctl_vals[];
 #define SYSCTL_USER_TO_KERN(dir) (!!(dir))
 #define SYSCTL_KERN_TO_USER(dir) (!dir)
 
+#ifdef CONFIG_PROC_SYSCTL
 #define SYSCTL_USER_TO_KERN_INT_CONV(name, u_ptr_op)		\
 int sysctl_user_to_kern_int_conv##name(const bool *negp,	\
 				       const unsigned long *u_ptr,\
@@ -173,6 +174,48 @@ int do_proc_uint_conv##name(unsigned long *u_ptr, unsigned int *k_ptr,	\
 	return 0;							\
 }
 
+#else // CONFIG_PROC_SYSCTL
+#define SYSCTL_USER_TO_KERN_INT_CONV(name, u_ptr_op)		\
+int sysctl_user_to_kern_int_conv##name(const bool *negp,	\
+				       const unsigned long *u_ptr,\
+				       int *k_ptr)		\
+{								\
+	return -ENOSYS;						\
+}
+
+#define SYSCTL_KERN_TO_USER_INT_CONV(name, k_ptr_op)		\
+int sysctl_kern_to_user_int_conv##name(bool *negp,		\
+				       unsigned long *u_ptr,	\
+				       const int *k_ptr)	\
+{								\
+	return -ENOSYS;						\
+}
+
+#define SYSCTL_INT_CONV_CUSTOM(name, user_to_kern, kern_to_user,	\
+			       k_ptr_range_check)			\
+int do_proc_int_conv##name(bool *negp, unsigned long *u_ptr, int *k_ptr,\
+			   int dir, const struct ctl_table *tbl)	\
+{									\
+	return -ENOSYS;							\
+}
+
+#define SYSCTL_USER_TO_KERN_UINT_CONV(name, u_ptr_op)		\
+int sysctl_user_to_kern_uint_conv##name(const unsigned long *u_ptr,\
+					unsigned int *k_ptr)	\
+{								\
+	return -ENOSYS;						\
+}
+
+#define SYSCTL_UINT_CONV_CUSTOM(name, user_to_kern, kern_to_user,	\
+				k_ptr_range_check)			\
+int do_proc_uint_conv##name(unsigned long *u_ptr, unsigned int *k_ptr,	\
+			   int dir, const struct ctl_table *tbl)	\
+{									\
+	return -ENOSYS;							\
+}
+
+#endif // CONFIG_PROC_SYSCTL
+
 
 extern const unsigned long sysctl_long_vals[];
 

-- 
2.50.1

