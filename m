From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Tue, 03 Nov 2026 23:41:51 +0000
Subject: [PATCH] serial: 8250: fix use-after-free of IRQ action name on
 port removal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-serial-8250-irq-uaf-v1-1-24223dcc3119@gmail.com>
X-B4-Tracking: v=1; b=H4sIAD5x6moC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQwNjXZD6xBxdCyNTA93MokLd0sQ0XYMUA+M0i0QTi0RLCyWgzoKi1LT
 MCrCp0bG1tQDmZD5zZQAAAA==
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 stable@vger.kernel.org, 
 syzbot+bc6b37960b1d13f68f9f@syzkaller.appspotmail.com, 
 Joas Antonio dos Santos <joasantonio108@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793749310; l=3589;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=Vj1DUOXxenSAPPDmSUT0HtmMZVzSOWReRJpl/rpE5m0=;
 b=RtK5sce09jMCtpUzz10809eZmaAN2TcxLlFael8IJpcwKhsR0wJZYm3UPfvtQqtuZ2Vjtn6l1
 9hl+ZqqFMV+C28dIDEk1Lbxc8PkFg4qTOt6jy+w5m8/sVYfWOeDocGp
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

serial_link_irq_chain() passes up->port.name directly to request_irq().
The IRQ subsystem stores this pointer in irqaction->name without copying
the string.

When the port that originally called request_irq() is removed while
other ports still share the same IRQ:

  1. serial_unlink_irq_chain() removes the port from the shared list
  2. Since other ports remain, free_irq() is NOT called
  3. irqaction->name still references the removed port's name string
  4. serial_core_remove_one_port() frees uport->name (kfree at line 3292)
  5. irqaction->name becomes a dangling pointer

Any subsequent read of /proc/interrupts dereferences the freed string
via show_interrupts() -> seq_printf("%s", action->name), triggering a
KASAN slab-use-after-free on the freed kmalloc-8 object.

Fix by giving struct irq_info ownership of the name string passed to
request_irq().  serial_get_or_create_irq_info() now kstrdup()s the port
name into irq_info->name when creating a new irq_info, and
serial_do_unlink() frees it alongside the irq_info.  This decouples the
IRQ action name lifetime from any individual port's lifetime.

Found by LLM-assisted code review of syzbot-reported crash patterns.

Reported-by: syzbot+bc6b37960b1d13f68f9f@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=bc6b37960b1d13f68f9f
Fixes: f7048b15900f ("tty: serial_core: Add name field to uart_port struct")
Cc: stable@vger.kernel.org
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
serial_link_irq_chain() passes up->port.name directly to request_irq().
When the first port sharing an IRQ is removed, kfree(uport->name) frees
the string while irqaction->name still references it.  Reading
/proc/interrupts then triggers a KASAN slab-use-after-free.

syzbot link: https://syzkaller.appspot.com/bug?extid=bc6b37960b1d13f68f9f
---
 drivers/tty/serial/8250/8250_core.c | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/drivers/tty/serial/8250/8250_core.c b/drivers/tty/serial/8250/8250_core.c
index 42319843c..f73113daa 100644
--- a/drivers/tty/serial/8250/8250_core.c
+++ b/drivers/tty/serial/8250/8250_core.c
@@ -47,6 +47,7 @@ struct irq_info {
 	int			irq;
 	spinlock_t		lock;	/* Protects list not the hash */
 	struct list_head	*head;
+	const char		*name;	/* owned copy for request_irq() */
 };
 
 #define IRQ_HASH_BITS		5	/* Can be adjusted later */
@@ -122,6 +123,7 @@ static void serial_do_unlink(struct irq_info *i, struct uart_8250_port *up)
 	/* List empty so throw away the hash node */
 	if (i->head == NULL) {
 		hlist_del(&i->node);
+		kfree(i->name);
 		kfree(i);
 	}
 }
@@ -145,6 +147,12 @@ static struct irq_info *serial_get_or_create_irq_info(const struct uart_8250_por
 	if (i == NULL)
 		return ERR_PTR(-ENOMEM);
 
+	i->name = kstrdup(up->port.name, GFP_KERNEL);
+	if (!i->name) {
+		kfree(i);
+		return ERR_PTR(-ENOMEM);
+	}
+
 	spin_lock_init(&i->lock);
 	i->irq = up->port.irq;
 	hash_add(irq_lists, &i->node, i->irq);
@@ -172,7 +180,7 @@ static int serial_link_irq_chain(struct uart_8250_port *up)
 		i->head = &up->list;
 	}
 
-	ret = request_irq(up->port.irq, serial8250_interrupt, up->port.irqflags, up->port.name, i);
+	ret = request_irq(up->port.irq, serial8250_interrupt, up->port.irqflags, i->name, i);
 	if (ret < 0)
 		serial_do_unlink(i, up);
 

---
base-commit: 05441d697f7f9a927264f4058cbbc6a03dfcac9d
change-id: 20261103-serial-8250-irq-uaf-0d03f8a48a98

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

