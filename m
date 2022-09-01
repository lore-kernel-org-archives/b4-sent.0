From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Thu, 01 Sep 2022 15:29:00 -0400
Subject: [PATCH v5 15/21] treewide: Drop __cficanonical
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20220901-kcfi_support-v5-15-be2007d8da63@linuxfoundation.org>
References: <20220901-kcfi_support-v5-0-be2007d8da63@linuxfoundation.org>
In-Reply-To: <20220901-kcfi_support-v5-0-be2007d8da63@linuxfoundation.org>
To: mricon@kernel.org
X-Mailer: b4 0.10.0-dev-03aea
X-Developer-Signature: v=1; a=openpgp-sha256; l=2053;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=afX9wGCB8eDrlsb9kZBlmGUdz5homye8qnV9lqIP8oI=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJIF2X+v3j5feWtthG669UEeKVMGWc513+Te+qy5GZWotfMY
 s71yRykLgxgXg6yYIkvZvthNQYUPPeTSe0xh5rAygQxh4OIUgImsDWX4Z7K7IvrX6Xhh5xPlJftkJC
 7s7irbauz1ImRnysxwGfFd2UAValpPWKTj19gE/l32ZOPCpE0zqrLySpd77OiNeHrCKZIbAA==
X-Developer-Key: i=konstantin@linuxfoundation.org; a=openpgp;
 fpr=DE0E66E32F1FDD0902666B96E63EDCA9329DD07E
X-Endpoint-Received: by B4 Submission Endpoint for konstantin@linuxfoundation.org/default with auth_id=3
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

From: Sami Tolvanen <samitolvanen@google.com>

CONFIG_CFI_CLANG doesn't use a jump table anymore and therefore,
won't change function references to point elsewhere. Remove the
__cficanonical attribute and all uses of it.

Note that the Clang definition of the attribute was removed earlier,
just clean up the no-op definition and users.

Signed-off-by: Sami Tolvanen <samitolvanen@google.com>
Reviewed-by: Kees Cook <keescook@chromium.org>
Tested-by: Kees Cook <keescook@chromium.org>

diff --git a/include/linux/compiler_types.h b/include/linux/compiler_types.h
index 4f2a819fd60a..6f2ec0976e2d 100644
--- a/include/linux/compiler_types.h
+++ b/include/linux/compiler_types.h
@@ -265,10 +265,6 @@ struct ftrace_likely_data {
 # define __nocfi
 #endif
 
-#ifndef __cficanonical
-# define __cficanonical
-#endif
-
 /*
  * Any place that could be marked with the "alloc_size" attribute is also
  * a place to be marked with the "malloc" attribute. Do this as part of the
diff --git a/include/linux/init.h b/include/linux/init.h
index 88f2964097f5..a0a90cd73ebe 100644
--- a/include/linux/init.h
+++ b/include/linux/init.h
@@ -220,8 +220,8 @@ extern bool initcall_debug;
 	__initcall_name(initstub, __iid, id)
 
 #define __define_initcall_stub(__stub, fn)			\
-	int __init __cficanonical __stub(void);			\
-	int __init __cficanonical __stub(void)			\
+	int __init __stub(void);				\
+	int __init __stub(void)					\
 	{ 							\
 		return fn();					\
 	}							\
diff --git a/include/linux/pci.h b/include/linux/pci.h
index 060af91bafcd..5da0846aa3c1 100644
--- a/include/linux/pci.h
+++ b/include/linux/pci.h
@@ -2019,8 +2019,8 @@ enum pci_fixup_pass {
 #ifdef CONFIG_LTO_CLANG
 #define __DECLARE_PCI_FIXUP_SECTION(sec, name, vendor, device, class,	\
 				  class_shift, hook, stub)		\
-	void __cficanonical stub(struct pci_dev *dev);			\
-	void __cficanonical stub(struct pci_dev *dev)			\
+	void stub(struct pci_dev *dev);					\
+	void stub(struct pci_dev *dev)					\
 	{ 								\
 		hook(dev); 						\
 	}								\

-- 
b4 0.10.0-dev-03aea
