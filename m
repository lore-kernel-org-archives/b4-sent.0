From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Thu, 01 Sep 2022 15:28:59 -0400
Subject: [PATCH v5 14/21] treewide: Drop WARN_ON_FUNCTION_MISMATCH
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20220901-kcfi_support-v5-14-be2007d8da63@linuxfoundation.org>
References: <20220901-kcfi_support-v5-0-be2007d8da63@linuxfoundation.org>
In-Reply-To: <20220901-kcfi_support-v5-0-be2007d8da63@linuxfoundation.org>
To: mricon@kernel.org
X-Mailer: b4 0.10.0-dev-03aea
X-Developer-Signature: v=1; a=openpgp-sha256; l=2400;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=SsHFU9d5k/VW6BdpXQVaADoIwgFLGqBsF7SzaR5SK4c=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJIF2X/v2c/w1v+yOoOZ/CwxtpAj8y2eC5+1/rjx4+YnU02/
 vvd07ShlYRDjYpAVU2Qp2xe7KajwoYdceo8pzBxWJpAhDFycAjCR418ZGZ73Xuo/3GCwodW65kxb03
 zT6ZMfhh8XLH+vm6yjpHfkJhsjQ7ffod6TQt1nvrtOVW1geVPzIqQnqe71qe/1Mbe3y888zQMA
X-Developer-Key: i=konstantin@linuxfoundation.org; a=openpgp;
 fpr=DE0E66E32F1FDD0902666B96E63EDCA9329DD07E
X-Endpoint-Received: by B4 Submission Endpoint for konstantin@linuxfoundation.org/default with auth_id=3
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

From: Sami Tolvanen <samitolvanen@google.com>

CONFIG_CFI_CLANG no longer breaks cross-module function address
equality, which makes WARN_ON_FUNCTION_MISMATCH unnecessary. Remove
the definition and switch back to WARN_ON_ONCE.

Signed-off-by: Sami Tolvanen <samitolvanen@google.com>
Reviewed-by: Kees Cook <keescook@chromium.org>
Tested-by: Kees Cook <keescook@chromium.org>

diff --git a/include/asm-generic/bug.h b/include/asm-generic/bug.h
index ba1f860af38b..4050b191e1a9 100644
--- a/include/asm-generic/bug.h
+++ b/include/asm-generic/bug.h
@@ -220,22 +220,6 @@ extern __printf(1, 2) void __warn_printk(const char *fmt, ...);
 # define WARN_ON_SMP(x)			({0;})
 #endif
 
-/*
- * WARN_ON_FUNCTION_MISMATCH() warns if a value doesn't match a
- * function address, and can be useful for catching issues with
- * callback functions, for example.
- *
- * With CONFIG_CFI_CLANG, the warning is disabled because the
- * compiler replaces function addresses taken in C code with
- * local jump table addresses, which breaks cross-module function
- * address equality.
- */
-#if defined(CONFIG_CFI_CLANG) && defined(CONFIG_MODULES)
-# define WARN_ON_FUNCTION_MISMATCH(x, fn) ({ 0; })
-#else
-# define WARN_ON_FUNCTION_MISMATCH(x, fn) WARN_ON_ONCE((x) != (fn))
-#endif
-
 #endif /* __ASSEMBLY__ */
 
 #endif
diff --git a/kernel/kthread.c b/kernel/kthread.c
index 3c677918d8f2..28a6b7ab4a0f 100644
--- a/kernel/kthread.c
+++ b/kernel/kthread.c
@@ -1050,8 +1050,7 @@ static void __kthread_queue_delayed_work(struct kthread_worker *worker,
 	struct timer_list *timer = &dwork->timer;
 	struct kthread_work *work = &dwork->work;
 
-	WARN_ON_FUNCTION_MISMATCH(timer->function,
-				  kthread_delayed_work_timer_fn);
+	WARN_ON_ONCE(timer->function != kthread_delayed_work_timer_fn);
 
 	/*
 	 * If @delay is 0, queue @dwork->work immediately.  This is for
diff --git a/kernel/workqueue.c b/kernel/workqueue.c
index aeea9731ef80..16df315d2a3d 100644
--- a/kernel/workqueue.c
+++ b/kernel/workqueue.c
@@ -1651,7 +1651,7 @@ static void __queue_delayed_work(int cpu, struct workqueue_struct *wq,
 	struct work_struct *work = &dwork->work;
 
 	WARN_ON_ONCE(!wq);
-	WARN_ON_FUNCTION_MISMATCH(timer->function, delayed_work_timer_fn);
+	WARN_ON_ONCE(timer->function != delayed_work_timer_fn);
 	WARN_ON_ONCE(timer_pending(timer));
 	WARN_ON_ONCE(!list_empty(&work->entry));
 

-- 
b4 0.10.0-dev-03aea
