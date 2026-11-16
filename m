From: Brad Fitzpatrick <bradfitz@tailscale.com>
Date: Mon, 16 Nov 2026 23:43:10 +0000
Subject: [PATCH] um: time-travel: don't use uninitialized fds from START
 ACK
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-bradfitz-um-tt-start-ack-fds-v1-1-c98901dfba85@tailscale.com>
X-B4-Tracking: v=1; b=H4sIAA2V+2oC/yXMSwrCMBAA0KuUWTuQFIzRq4iLfCY6ilUy0yItv
 XujLt/mLSBUmQRO3QKVJhZ+DQ1210G6heFKyLkZetM7a63DWEMurDOOT1RF0VAVQ3pgyYLROxM
 O/uj3JkMr3pUKf379+fK3jPFOSb8nrOsGKAwxxYAAAAA=
X-Change-ID: 20261116-bradfitz-um-tt-start-ack-fds-b860a789850d
To: Richard Weinberger <richard@nod.at>, 
 Anton Ivanov <anton.ivanov@cambridgegreys.com>, 
 Johannes Berg <johannes@sipsolutions.net>, 
 Mordechay Goodstein <mordechay.goodstein@intel.com>
Cc: linux-um@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Brad Fitzpatrick <bradfitz@tailscale.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794872590; l=3107;
 i=bradfitz@tailscale.com; s=20261011; h=from:subject:message-id;
 bh=svJ5VLX3SY7Jwr6l6XQ1OWwW8bhiwm/+jQGOHWzz8T0=;
 b=IOkJl5/z0TBUNrib7G4B/VeY4RTdfS4W6M/93O6qhhvWvl0no+N7OU0egfkK5LnBL2JdBbfBE
 4/KxOKojlN/Dz9GzqVCiDuFx7wEyva2Tm4jpJMDzkO/BdC0/LOYQcNx
X-Developer-Key: i=bradfitz@tailscale.com; a=ed25519;
 pk=RL25YdOUenVJzQaiZDrw/Aqu9ZEwUQBon30yMHGsIKY=
X-Endpoint-Received: by B4 Relay for bradfitz@tailscale.com/20261011 with auth_id=1152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the kernel connects to an external time-travel controller, it
expects the ACK of its UM_TIMETRAVEL_START message to carry two file
descriptors: the shared memory area and a log file. It reads them with
os_rcv_fd_msg() into an uninitialized on-stack array, and then uses
both array elements whenever the message itself was received in full.

os_rcv_fd_msg() leaves the array untouched if the message came without
an SCM_RIGHTS control message. That is what any controller that does
not implement the shared memory extension sends, which the protocol
allows: such controllers are why the kernel falls back to message
based scheduling. In that case the kernel passes stack garbage to
mmap() and then close()s both values.

With CONFIG_INIT_STACK_ALL_ZERO, the default where the compiler
supports it, the garbage is 0, so the kernel closes its own stdin. The
next file descriptor it opens, the epoll instance used for IRQs, then
becomes fd 0:

  $ ls -l /proc/$(pidof linux)/fd
  0 -> anon_inode:[eventpoll]
  1 -> /tmp/uml.log
  2 -> /tmp/uml.log
  3 -> /dev/shm/#200843
  4 -> socket:[216518625]

Without stack initialization the kernel may instead close, or map as
the scheduling area, any file descriptor at all.

Initialize the array to -1 and only use the descriptors that were
actually received. With the fix, fd 0 stays what it was and the epoll
instance gets the next free number.

Fixes: bfb80d8bc92f ("um: add shared memory optimisation for time-travel=ext")
Signed-off-by: Brad Fitzpatrick <bradfitz@tailscale.com>
---
 arch/um/kernel/time.c | 16 ++++++++++++----
 1 file changed, 12 insertions(+), 4 deletions(-)

diff --git a/arch/um/kernel/time.c b/arch/um/kernel/time.c
index d620b6d6310a5..bcb141b419722 100644
--- a/arch/um/kernel/time.c
+++ b/arch/um/kernel/time.c
@@ -141,15 +141,23 @@ static void time_travel_handle_message(struct um_timetravel_msg *msg,
 	}
 
 	if (unlikely(mode == TTMH_READ_START_ACK)) {
-		int fd[UM_TIMETRAVEL_SHARED_MAX_FDS];
+		int fd[UM_TIMETRAVEL_SHARED_MAX_FDS] = {
+			[0 ... UM_TIMETRAVEL_SHARED_MAX_FDS - 1] = -1,
+		};
 
 		ret = os_rcv_fd_msg(time_travel_ext_fd, fd,
 				    ARRAY_SIZE(fd), msg, sizeof(*msg));
 		if (ret == sizeof(*msg)) {
-			time_travel_setup_shm(fd[UM_TIMETRAVEL_SHARED_MEMFD],
-					      msg->time & UM_TIMETRAVEL_START_ACK_ID);
+			/*
+			 * A controller without shared memory support
+			 * sends no file descriptors with its ACK.
+			 */
+			if (fd[UM_TIMETRAVEL_SHARED_MEMFD] >= 0)
+				time_travel_setup_shm(fd[UM_TIMETRAVEL_SHARED_MEMFD],
+						      msg->time & UM_TIMETRAVEL_START_ACK_ID);
 			/* we don't use the logging for now */
-			os_close_file(fd[UM_TIMETRAVEL_SHARED_LOGFD]);
+			if (fd[UM_TIMETRAVEL_SHARED_LOGFD] >= 0)
+				os_close_file(fd[UM_TIMETRAVEL_SHARED_LOGFD]);
 		}
 	} else {
 		ret = os_read_file(time_travel_ext_fd, msg, sizeof(*msg));

---
base-commit: 7ea2308ccebce754fd1ac6295f26983a6878045d
change-id: 20261116-bradfitz-um-tt-start-ack-fds-b860a789850d

Best regards,
--  
Brad Fitzpatrick <bradfitz@tailscale.com>

