From: shorezero <shorezero@proton.me>
Date: Wed, 25 Nov 2026 10:43:08 -0500
Subject: [PATCH] gpiolib: acpi: Add ignore_wake quirk for Lenovo Legion Pro
 5 16ADR10
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-legion-gpio-wake-v1-1-8d49be040868@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQyNT3ZzUdKAS3fSCzHzd8sTsVF0DixQzUwNDI+NUcwsloLaCotS0zAq
 wkdGxEH5xaVJWanIJyByl2loAIKrvNXQAAAA=
X-Change-ID: 20261125-legion-gpio-wake-08d650123e78
To: Mika Westerberg <westeri@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-gpio@vger.kernel.org, linux-acpi@vger.kernel.org, 
 shorezero <shorezero@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2981; i=shorezero@proton.me;
 h=from:subject:message-id; bh=HKljuG8IXgLzJKgOm9anjabO6803T7j6Njn0CeH5tXA=;
 b=owGbwMvMwCU25VMaw6w3TVmMp9WSGLLZmfglm7/svsSxsoQp98T2YrYVxfflVxku9OVcuC1/8
 aV7x5g/d5SyMIhxMciKKbLoKtbMvVe5/EiHKXM4zBxWJpAhDFycAjCR6+8ZGY6Yf9Ty6D1cZ7Iu
 vKQg+vWxg9u5l00uzOOYLa9UHXbcoo/hf8GeU/GXHuxtNrp9f9MxneyHroxls5+oRLOGLD74arP
 yNX4A
X-Developer-Key: i=shorezero@proton.me; a=openpgp;
 fpr=2D217C9DDE79A7C48835035794F266009AEC826A
X-Endpoint-Received: by B4 Relay for shorezero@proton.me/default with auth_id=1637
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the Lenovo Legion Pro 5 16ADR10 (83LT) the system resumes from S3
immediately after entering it, unless an external display is being
driven by the discrete NVIDIA GPU. A lid-close suspend therefore turns
into a suspend/resume loop (36 cycles in 11 minutes, about 10% battery).

With pm_debug_messages enabled the wake is attributed to pin 4 of the
AMD GPIO controller:

  PM: Triggering wakeup from IRQ 7
  GPIO 4 is active: 0x30047c00

Pin 4 is the only ACPI event interrupt the firmware declares
(\_SB.GPIO._AEI: GpioInt Edge, ActiveBoth, ExclusiveAndWake, debounce
0x1F4). Its _EVT handler only deals with the dGPU: in hybrid graphics
mode it runs the EC eject handshake (\_SB.GZFD.HTPE) and then does
Notify(\_SB.PCI0.GPP0.PEGP, 0x81). Lid events are delivered by the EC
through GPE 0x07, not through this pin.

Booting with gpiolib_acpi.ignore_wake=AMDI0030:00@4 makes suspend hold
(an RTC-timed suspend and a real lid-close suspend on battery with
nothing attached), and opening the lid still wakes the machine. Add a
DMI quirk to apply this automatically.

The investigation and this patch were prepared with an AI coding
assistant (Anthropic Claude: Opus 5.5 and Fable 5.2 models, run through
the Hermes agent). It collected and analysed the kernel logs,
disassembled the ACPI tables with iasl, proposed the test matrix, and
drafted the quirk entry and this changelog. I ran the hardware tests on
my machine and reviewed the change. Testing: the quirk entry was build-
tested with W=1 and passes checkpatch.pl --strict; the runtime behaviour
was verified with the equivalent gpiolib_acpi.ignore_wake= command line
parameter on 7.3.6, not with a kernel containing this patch.

Signed-off-by: shorezero <shorezero@proton.me>
---
 drivers/gpio/gpiolib-acpi-quirks.c | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/drivers/gpio/gpiolib-acpi-quirks.c b/drivers/gpio/gpiolib-acpi-quirks.c
index 3f89a8760..07613e13a 100644
--- a/drivers/gpio/gpiolib-acpi-quirks.c
+++ b/drivers/gpio/gpiolib-acpi-quirks.c
@@ -465,6 +465,22 @@ static const struct dmi_system_id gpiolib_acpi_quirks[] __initconst = {
 			.ignore_wake = "GTCH7503:00@10",
 		},
 	},
+	{
+		/*
+		 * Spurious wakeups from the dGPU event pin (_AEI pin 4, handled
+		 * by _EVT -> Notify(\_SB.PCI0.GPP0.PEGP, 0x81)): the system
+		 * resumes from S3 immediately unless an external display is
+		 * driven by the dGPU. Lid wake uses the EC GPE and is unaffected.
+		 * Found in BIOS RLCN29WW, hybrid graphics mode.
+		 */
+		.matches = {
+			DMI_MATCH(DMI_SYS_VENDOR, "LENOVO"),
+			DMI_MATCH(DMI_PRODUCT_NAME, "83LT"),
+		},
+		.driver_data = &(struct acpi_gpiolib_dmi_quirk) {
+			.ignore_wake = "AMDI0030:00@4",
+		},
+	},
 	{} /* Terminating entry */
 };
 

---
base-commit: 4dce97c6c265544342e716e62fd24bbb232590c5
change-id: 20261125-legion-gpio-wake-08d650123e78

Best regards,
--  
shorezero <shorezero@proton.me>

