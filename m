From: Wenqiang Zhao <berringtoni36@gmail.com>
Date: Mon, 19 Oct 2026 14:22:08 +0800
Subject: [PATCH] syscalls/select: use kernel timeval for _newselect
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-research-select-time64-rk3576-v1-1-a65d6b72e21f@gmail.com>
X-B4-Tracking: v=1; b=H4sIABC31WoC/yWMQQ6CQAxFr0K6thEGB6NXMS46Q4WqDKRFY0K4u
 4Mu389/bwFjFTY4Fwsov8VkTBmqXQGxp9QxSpsZXOmaqqxOqGxMGns0fnKccZaBmwPqo/bHBr0
 nosC1L10LuTEp3+Tz61+uf7ZXuGdxi26PQMYYlFLst2lU6STtB7KZFdb1C0zQRAChAAAA
X-Change-ID: 20261019-research-select-time64-rk3576-55aaabe3502d
To: Linux Test Project <ltp@lists.linux.it>
Cc: Wenqiang Zhao <berringtoni36@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792390928; l=2457;
 i=berringtoni36@gmail.com; s=ltp-20261019; h=from:subject:message-id;
 bh=SIoimnh8+2U5EXodlYXh0YMeysiNIjwnnrmbsPWjNZY=;
 b=59JfaGd0PGhEhjdENijlxH/Q9Vwg/nIEjSzsg7hbKGTYIjsqtP/NQxtkWjw+88FiQEEGjZ6Bv
 /hRGySrbbN2Cq3l7kE4cokNAg5TYq2eDfSZQNfo7NLEwdTy+Sdn1OKe
X-Developer-Key: i=berringtoni36@gmail.com; a=ed25519;
 pk=+YVmSxpz14KiDkWu3zCQ25HCYntxcdWyEAOBmZ859K0=
X-Endpoint-Received: by B4 Relay for berringtoni36@gmail.com/ltp-20261019 with auth_id=1236
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With _TIME_BITS=64, struct timeval has 64-bit fields on 32-bit ARM,
but _newselect still expects the old kernel timeval layout. Passing
the libc structure directly makes a subsecond timeout appear as zero.

Convert valid timeouts to struct __kernel_old_timeval before the syscall
and copy the remaining time back afterwards. Pass NULL and deliberately
faulty timeout pointers through unchanged.

On an RK3576 running a 6.1.118-rt36 aarch64 kernel with CONFIG_COMPAT=y,
the unmodified ARM32 time64 select02 reports 22 passes and 6 failures.
With this change it reports 28 passes and no failures. Both runs skip
the unsupported SYS_select variant.

Tested select01-select04 on the same board with ARM32 time32, ARM32
time64 and AArch64 static builds: 250 passes, 55 configuration skips,
no failures or broken tests. Additional local checks cover timeout
copy-back, ready fds, NULL, EFAULT, EINVAL and EINTR.

Closes: https://github.com/linux-test-project/ltp/issues/1314
Signed-off-by: Wenqiang Zhao <berringtoni36@gmail.com>
---
syscalls/select: use kernel timeval for _newselect
---
 testcases/kernel/syscalls/select/select_var.h | 20 ++++++++++++++++++--
 1 file changed, 18 insertions(+), 2 deletions(-)

diff --git a/testcases/kernel/syscalls/select/select_var.h b/testcases/kernel/syscalls/select/select_var.h
index a945fa6..e23f1fa 100644
--- a/testcases/kernel/syscalls/select/select_var.h
+++ b/testcases/kernel/syscalls/select/select_var.h
@@ -84,14 +84,30 @@ static int do_select_faulty_to(int nfds, fd_set *readfds, fd_set *writefds,
 #endif
 		return ret;
 	}
-	case 4:
+	case 4: {
 #ifdef __NR__newselect
-		return tst_syscall(__NR__newselect, nfds, readfds, writefds, exceptfds, timeout);
+		struct __kernel_old_timeval _tv;
+		void *tv = timeout;
+		int ret;
+
+		if (timeout && !faulty_to) {
+			_tv.tv_sec = timeout->tv_sec;
+			_tv.tv_usec = timeout->tv_usec;
+			tv = &_tv;
+		}
+
+		ret = tst_syscall(__NR__newselect, nfds, readfds, writefds, exceptfds, tv);
+		if (timeout && !faulty_to) {
+			timeout->tv_sec = _tv.tv_sec;
+			timeout->tv_usec = _tv.tv_usec;
+		}
+		return ret;
 #else
 		tst_brk(TCONF, "__NR__newselect not implemented");
 #endif
 	break;
 	}
+	}
 
 	return -1;
 }

---
base-commit: 1255a3be50a69950607ed76fd2e9566189447f7a
change-id: 20261019-research-select-time64-rk3576-55aaabe3502d

Best regards,
--  
Wenqiang Zhao <berringtoni36@gmail.com>

