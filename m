From: Denis Mukhin <dmukhin@ford.com>
Date: Thu, 13 Mar 2025 16:45:51 -0700
Subject: [PATCH] x86/early_printk: add MMIO-based UARTs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250313-earlyprintk-v1-1-8f818d77a8dd@ford.com>
X-B4-Tracking: v=1; b=H4sIAC5u02cC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDY0Nj3dTEopzKgqLMvJJs3TQzi6TkNEODtNSkZCWgjoKi1LTMCrBp0bG
 1tQCqvvfAXQAAAA==
X-Change-ID: 20250313-earlyprintk-f68bcf10febc
To: Jonathan Corbet <corbet@lwn.net>, Thomas Gleixner <tglx@linutronix.de>, 
 Ingo Molnar <mingo@redhat.com>, Borislav Petkov <bp@alien8.de>, 
 Dave Hansen <dave.hansen@linux.intel.com>, x86@kernel.org, 
 "H. Peter Anvin" <hpa@zytor.com>
Cc: linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741909589; l=4181;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=hyfhwTjX30IsViMitxMZyys23Irq8zRLMoLGx9pZo6s=;
 b=xZJY8y5EoFN5fT6CCK5ossSAOntuA5+L3ssJ1Fga3KugCMBZHrPQ689DGmPRfeXU/rFURONeW
 N4PjskEm3arAGBX+/o451GBaKudqerwmWZW62mRFHCrmAqRRkvAMDeZ
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

During the bring-up of an x86 board, the kernel was crashing before
reaching the platform's console driver because of a bug in the firmware,
leaving no trace of the boot progress.

It was discovered that the only available method to debug the kernel
boot process was via the platform's MMIO-based UART, as the board lacked
an I/O port-based UART, PCI UART, or functional video output.

Then it turned out that earlyprintk= does not have a knob to configure
the MMIO-mapped UART.

Extend the early printk facility to support platform MMIO-based UARTs
on x86 systems, enabling debugging during the system bring-up phase.

The command line syntax to enable platform MMIO-based UART is:
  earlyprintk=mmio,membase[,{nocfg|baudrate}][,keep]

Note, the change does not integrate MMIO-based UART support to:
  arch/x86/boot/early_serial_console.c

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 Documentation/admin-guide/kernel-parameters.txt |  4 +++
 arch/x86/kernel/early_printk.c                  | 45 ++++++++++++++++++++++++-
 2 files changed, 48 insertions(+), 1 deletion(-)

diff --git a/Documentation/admin-guide/kernel-parameters.txt b/Documentation/admin-guide/kernel-parameters.txt
index fb8752b42ec8582b8750d7e014c4d76166fa2fc1..bee9ee18a506d019dc3d330268e3e1c83434ebba 100644
--- a/Documentation/admin-guide/kernel-parameters.txt
+++ b/Documentation/admin-guide/kernel-parameters.txt
@@ -1414,11 +1414,15 @@
 			earlyprintk=pciserial[,force],bus:device.function[,baudrate]
 			earlyprintk=xdbc[xhciController#]
 			earlyprintk=bios
+			earlyprintk=mmio,membase[,{nocfg|baudrate}][,keep]
 
 			earlyprintk is useful when the kernel crashes before
 			the normal console is initialized. It is not enabled by
 			default because it has some cosmetic problems.
 
+			Use "nocfg" to skip UART configuration, assume
+			BIOS/firmware has configured UART correctly.
+
 			Append ",keep" to not disable it when the real console
 			takes over.
 
diff --git a/arch/x86/kernel/early_printk.c b/arch/x86/kernel/early_printk.c
index 44f937015e1e25bf41532eb7e1031a6be32a6523..19248c73b5b0950e9edf1a60ba67829f1cd3279e 100644
--- a/arch/x86/kernel/early_printk.c
+++ b/arch/x86/kernel/early_printk.c
@@ -191,7 +191,6 @@ static __init void early_serial_init(char *s)
 	early_serial_hw_init(divisor);
 }
 
-#ifdef CONFIG_PCI
 static void mem32_serial_out(unsigned long addr, int offset, int value)
 {
 	u32 __iomem *vaddr = (u32 __iomem *)addr;
@@ -206,6 +205,45 @@ static unsigned int mem32_serial_in(unsigned long addr, int offset)
 	return readl(vaddr + offset);
 }
 
+/*
+ * early_mmio_serial_init() - Initialize MMIO-based early serial console.
+ * @membase: UART base address.
+ * @nocfg: Skip configuration, assume BIOS has configured UART correctly.
+ * @baudrate (int): Baud rate.
+ * @keep: Keep after the real driver is available.
+ */
+static __init void early_mmio_serial_init(char *s)
+{
+	unsigned long baudrate;
+	unsigned long membase;
+	char *e;
+
+	if (*s == ',')
+		s++;
+
+	if (!strncmp(s, "0x", 2)) {
+		membase = simple_strtoul(s, &e, 16);
+		early_serial_base = (unsigned long)early_ioremap(membase, PAGE_SIZE);
+		serial_in = mem32_serial_in;
+		serial_out = mem32_serial_out;
+
+		s += strcspn(s, ",");
+		if (*s == ',')
+			s++;
+	}
+
+	if (!strncmp(s, "nocfg", 5))
+		baudrate = 0;
+	else {
+		baudrate = simple_strtoul(s, &e, 0);
+		if (baudrate == 0 || s == e)
+			baudrate = DEFAULT_BAUD;
+	}
+	if (baudrate)
+		early_serial_hw_init(115200 / baudrate);
+}
+
+#ifdef CONFIG_PCI
 /*
  * early_pci_serial_init()
  *
@@ -352,6 +390,11 @@ static int __init setup_early_printk(char *buf)
 	keep = (strstr(buf, "keep") != NULL);
 
 	while (*buf != '\0') {
+		if (!strncmp(buf, "mmio", 4)) {
+			early_mmio_serial_init(buf + 4);
+			early_console_register(&early_serial_console, keep);
+			buf += 4;
+		}
 		if (!strncmp(buf, "serial", 6)) {
 			buf += 6;
 			early_serial_init(buf);

---
base-commit: 8aed61b8334e00f4fe5de9f2df1cd183dc328a9d
change-id: 20250313-earlyprintk-f68bcf10febc

Best regards,
-- 
Denis Mukhin <dmukhin@ford.com>

