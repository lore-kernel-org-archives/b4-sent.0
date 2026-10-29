From: Remy Demangeot <remy@demangeot.net>
Date: Thu, 29 Oct 2026 08:48:02 +0100
Subject: [PATCH v2 1/2] ACPI: EC: allow drivers to create a polled EC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-m9e-ec2-v2-1-e9c4e2ba8415@demangeot.net>
References: <20261029-m9e-ec2-v2-0-e9c4e2ba8415@demangeot.net>
In-Reply-To: <20261029-m9e-ec2-v2-0-e9c4e2ba8415@demangeot.net>
To: "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <lenb@kernel.org>, 
 Eugene Shalygin <eugene.shalygin@gmail.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: Armin Wolf <W_Armin@gmx.de>, linux-acpi@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 Remy Demangeot <remy@demangeot.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793260087; l=5632;
 i=remy@demangeot.net; s=20261015; h=from:subject:message-id;
 bh=/cs87yafgZ1YRaT6jFA1fah9Em8PNXk59oRg4Wxln8U=;
 b=SJGYtPngqwrsMY4JTdkpDFBhIAECWlUUIsYKw5585DN4UsoU7Fx7Mt6Jv/SYCNPECjwUwVhtG
 gquoTchcIAhBHpIF/H8nWPTyU1qNGX4VmBFZIFINuLY0Cz6BTD7ifuf
X-Developer-Key: i=remy@demangeot.net; a=ed25519;
 pk=h/s5N2ZlgZ0m+8FpMhSaCNJt0jvb9whRBAdJwpC+VAo=
X-Endpoint-Received: by B4 Relay for remy@demangeot.net/20261015 with auth_id=1194
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some boards have a second embedded controller that uses the standard EC
protocol but is not described in the ACPI tables. For example, the ASUS
ROG MAXIMUS IX EXTREME has one at I/O ports 0x68/0x6c that holds the
water temperature sensors. Its DSDT has no EC device for it: only a WMI
method writes to these ports directly.

Add acpi_ec_create_polled() and acpi_ec_destroy_polled() so that a
driver can create a struct acpi_ec for such a controller, and
acpi_ec_read_byte() and acpi_ec_write_byte() to access it. The EC is
used in busy polling mode, like the boot EC before its GPE handler is
installed: no GPE, no IRQ, no query events and no address space handler.

An EC with neither a GPE nor an IRQ must not touch any interrupt when
its events are masked or unmasked, so check ec->irq there too.

Signed-off-by: Remy Demangeot <remy@demangeot.net>
---
 drivers/acpi/ec.c    | 89 ++++++++++++++++++++++++++++++++++++++++++++++++++--
 include/linux/acpi.h |  8 +++++
 2 files changed, 95 insertions(+), 2 deletions(-)

diff --git a/drivers/acpi/ec.c b/drivers/acpi/ec.c
index a89f10256dbb85768b86a2a970c75a7d8e3814fa..48e83e84cfdb64c28adedcb77fce29affc956e4c 100644
--- a/drivers/acpi/ec.c
+++ b/drivers/acpi/ec.c
@@ -401,7 +401,7 @@ static void acpi_ec_mask_events(struct acpi_ec *ec)
 	if (!test_bit(EC_FLAGS_EVENTS_MASKED, &ec->flags)) {
 		if (ec->gpe >= 0)
 			acpi_ec_disable_gpe(ec, false);
-		else
+		else if (ec->irq >= 0)
 			disable_irq_nosync(ec->irq);
 
 		ec_dbg_drv("Polling enabled");
@@ -415,7 +415,7 @@ static void acpi_ec_unmask_events(struct acpi_ec *ec)
 		clear_bit(EC_FLAGS_EVENTS_MASKED, &ec->flags);
 		if (ec->gpe >= 0)
 			acpi_ec_enable_gpe(ec, false);
-		else
+		else if (ec->irq >= 0)
 			enable_irq(ec->irq);
 
 		ec_dbg_drv("Polling disabled");
@@ -934,6 +934,34 @@ int ec_write(u8 addr, u8 val)
 }
 EXPORT_SYMBOL(ec_write);
 
+/**
+ * acpi_ec_read_byte - read a register of a given EC
+ * @ec: the EC, e.g. from acpi_ec_create_polled()
+ * @addr: register address
+ * @val: where to store the value
+ *
+ * Return: 0 on success, a negative error code otherwise.
+ */
+int acpi_ec_read_byte(struct acpi_ec *ec, u8 addr, u8 *val)
+{
+	return acpi_ec_read(ec, addr, val);
+}
+EXPORT_SYMBOL_GPL(acpi_ec_read_byte);
+
+/**
+ * acpi_ec_write_byte - write a register of a given EC
+ * @ec: the EC, e.g. from acpi_ec_create_polled()
+ * @addr: register address
+ * @val: value to write
+ *
+ * Return: 0 on success, a negative error code otherwise.
+ */
+int acpi_ec_write_byte(struct acpi_ec *ec, u8 addr, u8 val)
+{
+	return acpi_ec_write(ec, addr, val);
+}
+EXPORT_SYMBOL_GPL(acpi_ec_write_byte);
+
 int ec_transaction(u8 command,
 		   const u8 *wdata, unsigned wdata_len,
 		   u8 *rdata, unsigned rdata_len)
@@ -1436,6 +1464,63 @@ static struct acpi_ec *acpi_ec_alloc(void)
 	return ec;
 }
 
+/**
+ * acpi_ec_create_polled - create an EC that is not described by ACPI
+ * @command_addr: I/O port of the command/status register
+ * @data_addr: I/O port of the data register
+ * @name: name used to request the I/O ports
+ *
+ * Some boards have additional embedded controllers that use the standard
+ * EC protocol but are not described in the ACPI tables. This creates a
+ * struct acpi_ec for such a controller, to be used with acpi_ec_read_byte()
+ * and acpi_ec_write_byte(). It only works in busy polling mode: no GPE, no
+ * IRQ, no query events and no address space handler.
+ *
+ * Return: the new EC, or an ERR_PTR() on failure.
+ */
+struct acpi_ec *acpi_ec_create_polled(unsigned long command_addr,
+				      unsigned long data_addr,
+				      const char *name)
+{
+	struct acpi_ec *ec;
+
+	if (!request_region(data_addr, 1, name))
+		return ERR_PTR(-EBUSY);
+	if (!request_region(command_addr, 1, name)) {
+		release_region(data_addr, 1);
+		return ERR_PTR(-EBUSY);
+	}
+
+	ec = acpi_ec_alloc();
+	if (!ec) {
+		release_region(command_addr, 1);
+		release_region(data_addr, 1);
+		return ERR_PTR(-ENOMEM);
+	}
+	ec->command_addr = command_addr;
+	ec->data_addr = data_addr;
+	acpi_ec_start(ec, false);
+
+	return ec;
+}
+EXPORT_SYMBOL_GPL(acpi_ec_create_polled);
+
+/**
+ * acpi_ec_destroy_polled - destroy an EC created by acpi_ec_create_polled()
+ * @ec: the EC to destroy, may be NULL or an ERR_PTR()
+ */
+void acpi_ec_destroy_polled(struct acpi_ec *ec)
+{
+	if (IS_ERR_OR_NULL(ec))
+		return;
+
+	acpi_ec_stop(ec, false);
+	release_region(ec->command_addr, 1);
+	release_region(ec->data_addr, 1);
+	kfree(ec);
+}
+EXPORT_SYMBOL_GPL(acpi_ec_destroy_polled);
+
 static acpi_status
 acpi_ec_register_query_methods(acpi_handle handle, u32 level,
 			       void *context, void **return_value)
diff --git a/include/linux/acpi.h b/include/linux/acpi.h
index ddacac81209473cfc5fc83047a0de91c07ceb7b5..d657a94aed5dd90c2ba0c8c2784c7a0cb0fb3bc2 100644
--- a/include/linux/acpi.h
+++ b/include/linux/acpi.h
@@ -432,6 +432,14 @@ extern int ec_transaction(u8 command,
                           u8 *rdata, unsigned rdata_len);
 extern acpi_handle ec_get_handle(void);
 
+struct acpi_ec;
+struct acpi_ec *acpi_ec_create_polled(unsigned long command_addr,
+				      unsigned long data_addr,
+				      const char *name);
+void acpi_ec_destroy_polled(struct acpi_ec *ec);
+int acpi_ec_read_byte(struct acpi_ec *ec, u8 addr, u8 *val);
+int acpi_ec_write_byte(struct acpi_ec *ec, u8 addr, u8 val);
+
 extern bool acpi_is_pnp_device(struct acpi_device *);
 
 #if defined(CONFIG_ACPI_WMI) || defined(CONFIG_ACPI_WMI_MODULE)

-- 
2.47.3

