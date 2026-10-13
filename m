From: Brian Ellis <brianellis@gotenna.com>
Date: Tue, 13 Oct 2026 14:57:03 -0600
Subject: [PATCH v4] usb: gadget: u_serial: fix NULL deref in gs_close()
 after failed open
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-u_serial-gs-close-null-v4-1-9ea038501994@gotenna.com>
X-B4-Tracking: v=1; b=H4sIAB6bzmoC/4XN0Q6CIBQG4FdpXEcTRIWueo/WGsJB2QwaqKs53
 z30ytZc5+7/t/87E4oQLER0PkwowGij9S4Fdjwg1UrXALY6ZUQzWmaCZHi4LwvZ4SZi1fkI2A1
 dhyXPJMvLdMBRGj8DGPta4est5dbG3of3+mckS/uXHAkmWMgCOOM10aa+NL4H5+RJ+Qda0JFuI
 FrtQjRBtQZtisqAKM0vlG8hvgvlCVIl51rkNVNMfEPzPH8AmhFavlABAAA=
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Kuen-Han Tsai <khtsai@google.com>, 
 Prashanth K <prashanth.k@oss.qualcomm.com>, 
 Syed Tayyab Farooq <syedtayyabfarooq08@gmail.com>, 
 Krystian Kaniewski <krystianmkaniewski@gmail.com>, 
 syzbot+782b2f1063e38ba8fa6e@syzkaller.appspotmail.com, 
 stable@vger.kernel.org, Brian Ellis <brianellis@gotenna.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791925022; l=4895;
 i=brianellis@gotenna.com; s=20260910; h=from:subject:message-id;
 bh=w9DTZeMtZkRd3FXGUqJ8HyiRNMOLz1JAQ9tb8EK17uE=;
 b=iESdUBqYiTWAx0NzwAsbRuSLsYWTQYTCqqki4XjUH+QXlOWIeGwwgDPXXjga/pYuWuM3SSmew
 IcjUACmyrhODZ6Wf9l8c3qHqa68PQOIS+k5ZgHK3mXsoX8rv3nvrfZv
X-Developer-Key: i=brianellis@gotenna.com; a=ed25519;
 pk=JciDR8ctfMqvKeRCDP8VPwNLUDULxCAqDum6H+/ByBY=
X-Endpoint-Received: by B4 Relay for brianellis@gotenna.com/20260910 with auth_id=1022
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gs_close() opens with

	struct gs_port *port = tty->driver_data;
	...
	spin_lock_irq(&port->port_lock);

and never checks port.  gs_open() assigns tty->driver_data only on the
port.count 0 -> 1 edge, so any failure earlier in gs_open() leaves it NULL,
and tty_open() calls tty_release(), and hence ->close(), when ->open()
fails.

syzbot hit exactly this on arm64.  Fault injection failed the kfifo_alloc()
of the write buffer in gs_open():

   __kfifo_alloc_node+0x10c/0x208 lib/kfifo.c:44
   gs_open+0x144/0x514 drivers/usb/gadget/function/u_serial.c:636
   tty_open+0x404/0x89c drivers/tty/tty_io.c:2137

and the tty core's close of the failed open then took port_lock through
the NULL port:

  BUG: unable to handle kernel paging request in gs_close
  KASAN: null-ptr-deref in range [0x00000000000003a0-0x00000000000003a7]
  Call trace:
   spin_lock_irq include/linux/spinlock.h:372 [inline]
   gs_close+0xac/0x65c drivers/usb/gadget/function/u_serial.c:698
   tty_release+0x2c4/0xffc drivers/tty/tty_io.c:1745
   tty_open+0x46c/0x89c drivers/tty/tty_io.c:2146

Return early instead.  There is nothing to release when the open never got
far enough to claim the port.

Unlike the check reverted by commit f6c7bc4a6823 ("Revert "usb: gadget:
u_serial: Add null pointer check in gs_start_io""), this is not hiding a
race: the tty core calls ->close() for an ->open() that failed by design,
so driver_data is legitimately unset on that path.

Fixes: c1dca562be8a ("usb gadget: split out serial core")
Reported-by: syzbot+782b2f1063e38ba8fa6e@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=782b2f1063e38ba8fa6e
Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: Brian Ellis <brianellis@gotenna.com>
---
Found by reading the code while working on a downstream 6.6-based gadget
kernel, where gserial_free_line() clearing ports[n].port makes the same
path reachable, and matched to the syzbot report afterwards.  It has not
been hit here, and syzbot has no reproducer for it.

Compile-tested against usb-linus with allmodconfig (CONFIG_USB_U_SERIAL=m).
Not boot-tested on mainline, and the failed-open path has not been
exercised.

Two lifetime reworks posted for a different syzbot report in this driver
(fe63e4d633540f230624) add the same check as part of larger changes:

  https://lore.kernel.org/r/20260910105359.12915-1-syedtayyabfarooq08@gmail.com
  https://lore.kernel.org/r/6941beb7-8cae-4cc5-ba07-e1c8a8753fe1@mail.kernel.org

This is the minimal fix, aimed at stable.  If either of those lands first,
this one is redundant.
---
Changes in v4:
- Reported-by:/Closes: now use the ID from syzbot's public report; v3
  used the ID from its moderation stage.
- Quote the trace from the public report, including the injected
  kfifo_alloc() failure in gs_open().  v3 misread the shadow index 0x74 as
  the offset (it is 0x3a0) and quoted a "Write" line not in the report.
- Correct v3's notes: syzbot has no reproducer, and this was found by
  reading the code, not hit downstream.
- Mention the two overlapping lifetime reworks.
- Add Assisted-by: LLM.
- Link to v3: https://lore.kernel.org/r/20260928-u_serial-gs-close-null-v3-1-c688d93b4c49@gotenna.com

Changes in v3:
- Restore the Reported-by:/Closes: syzbot tags and the KASAN trace. They were
  dropped from v1 and v2 in error when the commit message was rewritten. The
  report is still open, and without Closes: syzbot cannot associate this fix
  with it.
- Say why this differs from the check reverted in f6c7bc4a6823, since that
  revert's reasoning is the obvious objection here.
- Link to v2: https://lore.kernel.org/r/20260927-u_serial-gs-close-null-v2-1-bdedf57fe96f@gotenna.com

Changes in v2:
- Remove the comment above the check, rather than reword it as Prashanth
  suggested. The commit message already explains the path that leaves
  tty->driver_data NULL, so the comment only restated it. Happy to add a
  reworded one instead if that is preferred.
- Link to v1: https://lore.kernel.org/r/20260910-u_serial-gs-close-null-v1-1-9a5e848b1dfb@gotenna.com
---
 drivers/usb/gadget/function/u_serial.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/usb/gadget/function/u_serial.c b/drivers/usb/gadget/function/u_serial.c
index cdd1dfc66..892d2673e 100644
--- a/drivers/usb/gadget/function/u_serial.c
+++ b/drivers/usb/gadget/function/u_serial.c
@@ -695,6 +695,9 @@ static void gs_close(struct tty_struct *tty, struct file *file)
 	struct gs_port *port = tty->driver_data;
 	struct gserial	*gser;
 
+	if (!port)
+		return;
+
 	spin_lock_irq(&port->port_lock);
 
 	if (port->port.count != 1) {

---
base-commit: be4219dd98608736e13e0b790ef742b76a13254d
change-id: 20260910-u_serial-gs-close-null-a80a436666e8

Best regards,
-- 
Brian Ellis <brianellis@gotenna.com>

