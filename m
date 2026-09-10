From: Brian Ellis <brianellis@gotenna.com>
Date: Thu, 10 Sep 2026 13:53:59 -0600
Subject: [PATCH] usb: gadget: u_serial: fix NULL deref in gs_close() after
 failed open
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260910-u_serial-gs-close-null-v1-1-9a5e848b1dfb@gotenna.com>
X-B4-Tracking: v=1; b=H4sIANYKo2oC/x2MQQqAIBAAvyJ7bkErovpKREhttSAaLkYQ/T1rb
 nOYuUEoMgn06oZIJwsHn8UUCubd+o2Ql+xQ6rLRndGYpq+wDjfB2QUh9Mk5tK22ddVkqIUcH5F
 Wvv7xMD7PC/YgSY1oAAAA
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Kuen-Han Tsai <khtsai@google.com>, 
 Prashanth K <prashanth.k@oss.qualcomm.com>, stable@vger.kernel.org, 
 Brian Ellis <brianellis@gotenna.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789070049; l=2951;
 i=brianellis@gotenna.com; s=20260910; h=from:subject:message-id;
 bh=elm183E8ARQLqVNCj2uC/Zn4AQumLckjzIgt6S1EnX0=;
 b=6fsaZbzfuwEtD5Xr3Gvzr3qRhjpR4OxD/mPqG7UrV+ekUxg3qGiM/kayiEUntWUnUkKA2Sg+o
 sjH+Mu9jzQqA+4jhG/oFJf93J+k63j1lchrThYPfFdJ8Sa0XbYrWcpe
X-Developer-Key: i=brianellis@gotenna.com; a=ed25519;
 pk=JciDR8ctfMqvKeRCDP8VPwNLUDULxCAqDum6H+/ByBY=
X-Endpoint-Received: by B4 Relay for brianellis@gotenna.com/20260910 with auth_id=1022
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gs_close() dereferences tty->driver_data without checking it:

	struct gs_port *port = tty->driver_data;
	struct gserial	*gser;

	spin_lock_irq(&port->port_lock);

but gs_open() assigns tty->driver_data only after two error returns:

	if (!port) {
		status = -ENODEV;
		goto out;
	}
	...
		status = kfifo_alloc(&port->port_write_buf,
				     WRITE_BUF_SIZE, GFP_KERNEL);
		if (status) {
			...
			goto out;
		}
	...
	tty->driver_data = port;

and when ->open() returns an error the tty core calls ->close() anyway:

	if (tty->ops->open)
		retval = tty->ops->open(tty, filp);
	...
	if (retval) {
		tty_debug_hangup(tty, "open error %d, releasing\n", retval);
		tty_unlock(tty); /* need to call tty_release without BTM */
		tty_release(inode, filp);

So opening /dev/ttyGS<n> for a port that has already been freed, or when
the write-buffer allocation fails, oopses in gs_close().

This is not the situation commit ffd603f21423 ("usb: gadget: u_serial: Add
null pointer check in gs_start_io") was reverted for. That check was
redundant because gs_start_io()'s callers are required to hold port_lock
with port.tty and port_usb non-NULL, and the dereference it hid was a race.
Here the NULL is not a race: the tty core deliberately calls ->close() for
an ->open() that failed, as its own debug message says, so driver_data is
legitimately unset on that path and every tty driver has to tolerate it.

Fixes: c1dca562be8a ("usb gadget: split out serial core")
Cc: stable@vger.kernel.org
Signed-off-by: Brian Ellis <brianellis@gotenna.com>
---
Found on a downstream 6.6-adi BSP kernel, then confirmed present in usb-linus
by inspection: gs_close() still dereferences tty->driver_data unguarded, and
gs_open() still assigns it only after its error returns.

Compile-tested against usb-linus with allmodconfig (CONFIG_USB_U_SERIAL=m).
Not boot-tested on mainline: the board it was found on needs a vendor BSP
device tree to boot, so the argument here is from source, with both halves
quoted in the commit message.
---
 drivers/usb/gadget/function/u_serial.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/usb/gadget/function/u_serial.c b/drivers/usb/gadget/function/u_serial.c
index cdd1dfc66..5bbb4d04b 100644
--- a/drivers/usb/gadget/function/u_serial.c
+++ b/drivers/usb/gadget/function/u_serial.c
@@ -695,6 +695,13 @@ static void gs_close(struct tty_struct *tty, struct file *file)
 	struct gs_port *port = tty->driver_data;
 	struct gserial	*gser;
 
+	/*
+	 * tty_open() calls tty_release(), and hence this, when ->open()
+	 * failed before gs_open() had set tty->driver_data.
+	 */
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

