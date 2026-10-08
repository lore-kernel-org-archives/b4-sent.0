From: Phil Rosenthal <phil@phil.gs>
Date: Thu, 08 Oct 2026 09:27:20 -0400
Subject: [PATCH] serial: 8250_pci: Add support for ASPEED BMC VUARTs over
 PCIe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-aspeed-vuart-v1-1-d2be17c99cd7@phil.gs>
X-B4-Tracking: v=1; b=H4sIADeax2oC/x3MQQ5AMBBG4avIrDWpIYKriEVjfsympEUkjbtrL
 L/Fe4kigiLSUCQKuDXq7jOqsqB5c36FUckmttxW1nbGxQMQc18unEbQcC3CcOgpJ0fAos+/G6f
 3/QBshHp5XgAAAA==
X-Change-ID: 20261008-aspeed-vuart-de423dd2eae9
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: Corey Minyard <corey@minyard.net>, 
 openipmi-developer@lists.sourceforge.net, Andy Shevchenko <andy@kernel.org>, 
 Joel Stanley <joel@jms.id.au>, Andrew Jeffery <andrew@codeconstruct.com.au>, 
 Ryan Chen <ryan_chen@aspeedtech.com>, linux-aspeed@lists.ozlabs.org, 
 Ninad Palsule <ninad@linux.ibm.com>, Andrew Lunn <andrew@lunn.ch>, 
 linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 Phil Rosenthal <phil@phil.gs>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791466042; l=11065;
 i=phil@phil.gs; s=20261008; h=from:subject:message-id;
 bh=czjVo2lcHA1KuMfHm3TWYgQ6tAwj+eybtjx/pOEEJPs=;
 b=3YZz3+TlfzbHrNf1lgEdIvrShbOped1YIN8/M58hi9A+dUbcxWuIWysO27RK1h6tmSX2OtoHv
 SywkVrOmI62CkKvN1GJ0zGnzXFn4DsVgQWpEBZk3MxGG2YVe45YmoTv
X-Developer-Key: i=phil@phil.gs; a=ed25519;
 pk=I/6AJ/pr2K5ljgV3aFteqtQglFiNZFga5ggtVMhOxmA=
X-Endpoint-Received: by B4 Relay for phil@phil.gs/20261008 with auth_id=1132
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On systems with an ASPEED BMC, the IPMI Serial over LAN (SOL) console
shows the firmware and the boot loader but goes silent once Linux
starts. The UART that the BMC bridges to SOL is not a legacy COM port:
it sits behind a PCIe function that no driver claims.

ASPEED BMCs such as the AST2600 present this "BMC device" function to
the host (1a03:2402, class 0c0701). Besides KCS, the BMC firmware can
expose up to two 16550-compatible virtual UARTs through it, and host
firmware redirects its console to them, for example "IPMI Card SOL/COM2
(Pci Bus9,Dev1,Func0,Port0)" in the AMI setup of the ASUS Pro WS
W680-ACE IPMI. Register these UARTs so that the kernel console and a
getty can be used over SOL.

The UART registers are in BAR1 at the VUART's LPC I/O address shifted
left by two, one 32-bit register per 4 bytes: VUART0 at 0xfe0
(0x3f8 << 2) and VUART1 at 0xbe0 (0x2f8 << 2). A VUART that the BMC has
not enabled reads back as all ones; skip it so that the ports present
are numbered contiguously. If the BMC exposes no VUART at all, decline
the device so that it stays available to other drivers such as ipmi_si,
whose PCI table matches the same class code.

The function has no INTx pin and advertises 32 MSI vectors. On the ASUS
board (BMC firmware 1.3.13) no interrupt was delivered on MSI vector 16,
which is the vector ASPEED's own host driver uses for VUART0: transmit
stalled and nothing was received. Poll the ports instead.

The same function also exposes the BMC's KCS interface in BAR1.
8250_pci does not request the BAR, so an ipmi_si interface described by
firmware (ACPI or SMBIOS) can still use those registers. ipmi_si's PCI
driver, which matches the function by class code, can no longer bind it
while a VUART is enabled.

Tested on an ASUS Pro WS W680-ACE IPMI (BMC firmware 1.3.13): the kernel
console and a getty run on ttyS5 over IPMI SOL, while a non-PCI ipmi_si
interface uses the KCS registers in the same BAR.

The register layout and MSI vector assignment follow the host driver
from ASPEED's SDK as posted in 2023, which was not merged.

Link: https://lore.kernel.org/r/20230823173104.3219128-2-ninad@linux.ibm.com
Assisted-by: LLM sparse
Signed-off-by: Phil Rosenthal <phil@phil.gs>
---
Ownership of the PCI function (question for IPMI and ASPEED folks):

  1a03:2402 has class 0c0701 (IPMI KCS), so ipmi_si's PCI driver also
  matches it, and with this patch 8250_pci binds the function first once
  the BMC enables a VUART. I believe this costs nothing in practice:
  ipmi_si's PCI probe looks for the KCS registers at the start of BAR0,
  but on this device they are in BAR1 (at 0xe88 on the tested board), so
  that probe fails ("Interface detection failed") and in-band IPMI comes
  from the firmware-described (SMBIOS/ACPI) interface instead, which is
  unaffected. Is anyone aware of BMC firmware that puts KCS at the start
  of BAR0 on this function? If no VUART is enabled, 8250_pci declines the
  device and leaves it to ipmi_si.

Polling:

  The function on the test board has no INTx pin. With all 32 MSI vectors
  allocated, vector 16 (the one ASPEED's 2023 host driver uses for VUART0)
  stayed at 0 interrupts on every CPU: TX stalled and typed input was
  never received. So the ports are polled on all platforms. On IBM POWER
  this means polling where ASPEED's driver used INTx; a follow-up can add
  INTx for functions that have a pin, with testing from someone who has
  that hardware.

Tested:

  - ASUS Pro WS W680-ACE IPMI, BIOS 4601 (05/22/2026).
  - BMC: hardware R1.04, firmware 1.3.13 (ipmitool mc info reports
    "1.03", which is the same version without the build number).
  - Proxmox 7.0.14 kernel with this change backported (identical apart
    from the serial_pci_tbl[] entry style); console=ttyS5,115200n8.
  - One 16550A registered at BAR1+0xfe0 with irq 0. VUART1 (0xbe0) reads
    all ones on this BMC and is skipped.
  - Kernel console and a getty over IPMI SOL, interactive input. In-band
    IPMI (ipmitool) keeps working.
  - Built on tty-next with W=1 and sparse. Both clean.

Suspend/resume:

  With pm_test=devices, the BMC's PCIe function stops responding after
  resume on the tested board. The ASPEED bridge (08:00.0) reports
  uncorrectable non-fatal AER errors before any driver's resume callback
  runs, and afterwards both the VUART and the KCS registers read all ones
  until the host is rebooted. The result is the same with an out-of-tree
  driver that has no PM callbacks, so this looks like a BMC firmware or
  hardware limitation rather than something this patch can address. While
  the function is in that state, each poll of the dead port adds to a
  continuous stream of AER reports. Real S3 was not tried.

Not tested:

  - A BMC with no VUART enabled (probe should fail and leave the function
    to ipmi_si).
  - Two VUARTs enabled.
  - Hardware with INTx.

AI assistance:

  This patch was developed with an LLM coding assistant (Claude, model
  claude-opus-5-5) driven from a Claude Code session. The assistant:

  - investigated the hardware (register probing, MSI experiment);
  - wrote the code and the changelog;
  - built and booted the test kernels;
  - ran W=1, sparse and checkpatch.

Two further independent LLM reviews (Claude Fable 5.1 via Claude Code,
  and GPT-5.6 Sol via Codex) produced changes that are folded in: the
  presence test, error codes, board entry cleanup, MMIO BAR check and
  the KCS wording in the changelog. I reviewed the result and tested it
  on my hardware. The prompts were, in summary: make IPMI SOL work on
  this board, then turn that into a mainline-quality 8250_pci patch and
  address review findings.
---
 drivers/tty/serial/8250/8250_pci.c | 115 +++++++++++++++++++++++++++++++++++++
 1 file changed, 115 insertions(+)

diff --git a/drivers/tty/serial/8250/8250_pci.c b/drivers/tty/serial/8250/8250_pci.c
index 6e53d6d72a8e20336fc1dd05cf57850774b4babb..8c243c4fd58a9126aad2e4aecc017e32640353be 100644
--- a/drivers/tty/serial/8250/8250_pci.c
+++ b/drivers/tty/serial/8250/8250_pci.c
@@ -13,6 +13,7 @@
 #include <linux/kernel.h>
 #include <linux/math.h>
 #include <linux/slab.h>
+#include <linux/sizes.h>
 #include <linux/delay.h>
 #include <linux/tty.h>
 #include <linux/serial_reg.h>
@@ -72,6 +73,7 @@
 #define PCI_DEVICE_ID_AGESTAR_9375	0x6872
 #define PCI_DEVICE_ID_BROADCOM_TRUMANAGE 0x160a
 #define PCI_DEVICE_ID_AMCC_ADDIDATA_APCI7800 0x818e
+#define PCI_DEVICE_ID_ASPEED_BMC_DEV	0x2402
 
 #define PCI_DEVICE_ID_WCHIC_CH384_4S	0x3470
 #define PCI_DEVICE_ID_WCHIC_CH384_8S	0x3853
@@ -1597,6 +1599,93 @@ pci_brcm_trumanage_setup(struct serial_private *priv,
 	return ret;
 }
 
+/*
+ * The PCIe BMC device function of ASPEED BMCs can expose two VUARTs to the
+ * host. Their registers are in BAR1 at the VUART's LPC I/O address shifted
+ * left by two, one 32-bit register per 4 bytes. A VUART that the BMC firmware
+ * has not enabled reads back as all ones; skip those so that the ports that
+ * are present are numbered contiguously.
+ */
+#define PCI_ASPEED_VUART_BAR		1
+#define PCI_ASPEED_VUART_REGSHIFT	2
+
+static const u16 pci_aspeed_vuart_io[] = { 0x3f8, 0x2f8 };
+
+static unsigned int pci_aspeed_vuart_offset(unsigned int i)
+{
+	return pci_aspeed_vuart_io[i] << PCI_ASPEED_VUART_REGSHIFT;
+}
+
+/*
+ * A live 16550 can read LSR as 0xff, but never IIR, whose bits 4-5 are
+ * reserved. Only read IIR when LSR looks absent: reading IIR clears a
+ * pending THRI, and this also runs on resume while the port may be in use.
+ */
+static bool pci_aspeed_vuart_present(void __iomem *base, unsigned int offset)
+{
+	void __iomem *regs = base + offset;
+
+	return readl(regs + (UART_LSR << PCI_ASPEED_VUART_REGSHIFT)) != ~0U ||
+	       readl(regs + (UART_IIR << PCI_ASPEED_VUART_REGSHIFT)) != ~0U;
+}
+
+static int pci_aspeed_vuart_init(struct pci_dev *dev)
+{
+	void __iomem *base;
+	int i, n = 0;
+
+	if (!(pci_resource_flags(dev, PCI_ASPEED_VUART_BAR) & IORESOURCE_MEM) ||
+	    pci_resource_len(dev, PCI_ASPEED_VUART_BAR) < SZ_4K)
+		return -ENODEV;
+
+	base = pci_iomap_range(dev, PCI_ASPEED_VUART_BAR, 0, SZ_4K);
+	if (!base)
+		return -ENOMEM;
+
+	for (i = 0; i < ARRAY_SIZE(pci_aspeed_vuart_io); i++)
+		if (pci_aspeed_vuart_present(base, pci_aspeed_vuart_offset(i)))
+			n++;
+
+	pci_iounmap(dev, base);
+
+	/* Leave the function to other drivers if the BMC exposes no VUART. */
+	return n ?: -ENODEV;
+}
+
+static int
+pci_aspeed_vuart_setup(struct serial_private *priv,
+		       const struct pciserial_board *board,
+		       struct uart_8250_port *port, int idx)
+{
+	unsigned int offset;
+	int i, ret;
+
+	ret = setup_port(priv, port, PCI_ASPEED_VUART_BAR, 0,
+			 PCI_ASPEED_VUART_REGSHIFT);
+	if (ret)
+		return ret;
+
+	/* Use the idx-th VUART that is present. */
+	for (i = 0; i < ARRAY_SIZE(pci_aspeed_vuart_io); i++) {
+		offset = pci_aspeed_vuart_offset(i);
+		if (!pci_aspeed_vuart_present(port->port.membase, offset))
+			continue;
+		if (idx == 0)
+			break;
+		idx--;
+	}
+	if (i == ARRAY_SIZE(pci_aspeed_vuart_io))
+		return 1;
+
+	port->port.mapbase += offset;
+	port->port.membase += offset;
+	port->port.iotype = UPIO_MEM32;
+	port->port.type = PORT_16550A;
+	port->port.flags |= UPF_FIXED_PORT | UPF_FIXED_TYPE;
+
+	return 0;
+}
+
 /* RTS will control by MCR if this bit is 0 */
 #define FINTEK_RTS_CONTROL_BY_HW	BIT(4)
 /* only worked with FINTEK_RTS_CONTROL_BY_HW on */
@@ -2042,6 +2131,17 @@ static struct pci_serial_quirk pci_serial_quirks[] = {
 		.subdevice	= PCI_ANY_ID,
 		.setup		= afavlab_setup,
 	},
+	/*
+	 * ASPEED BMC VUARTs over PCIe
+	 */
+	{
+		.vendor		= PCI_VENDOR_ID_ASPEED,
+		.device		= PCI_DEVICE_ID_ASPEED_BMC_DEV,
+		.subvendor	= PCI_ANY_ID,
+		.subdevice	= PCI_ANY_ID,
+		.init		= pci_aspeed_vuart_init,
+		.setup		= pci_aspeed_vuart_setup,
+	},
 	/*
 	 * HP Diva
 	 */
@@ -3045,6 +3145,7 @@ enum pci_board_num_t {
 	pbn_omegapci,
 	pbn_NETMOS9900_2s_115200,
 	pbn_brcm_trumanage,
+	pbn_aspeed_vuart,
 	pbn_fintek_4,
 	pbn_fintek_8,
 	pbn_fintek_12,
@@ -3733,6 +3834,12 @@ static struct pciserial_board pci_boards[] = {
 		.reg_shift	= 2,
 		.base_baud	= 115200,
 	},
+	/* MSI is not delivered on at least the ASUS Pro WS W680-ACE IPMI. */
+	[pbn_aspeed_vuart] = {
+		.flags		= FL_NOIRQ,
+		.num_ports	= 2,
+		.base_baud	= 115200,
+	},
 	[pbn_fintek_4] = {
 		.num_ports	= 4,
 		.uart_offset	= 8,
@@ -5922,6 +6029,14 @@ static const struct pci_device_id serial_pci_tbl[] = {
 		.driver_data = pbn_brcm_trumanage,
 	},
 
+	/*
+	 * ASPEED BMC VUARTs over PCIe
+	 */
+	{
+		PCI_VDEVICE(ASPEED, PCI_DEVICE_ID_ASPEED_BMC_DEV),
+		.driver_data = pbn_aspeed_vuart,
+	},
+
 	/*
 	 * AgeStar as-prs2-009
 	 */

---
base-commit: 36844ea19656fb41278799ef3d5cd52120d89149
change-id: 20261008-aspeed-vuart-de423dd2eae9

Best regards,
-- 
Phil Rosenthal <phil@phil.gs>

