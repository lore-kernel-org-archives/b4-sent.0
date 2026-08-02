From: Anuj Bolewar <bolewara@gmail.com>
Date: Sun, 02 Aug 2026 19:41:39 +0530
Subject: [PATCH] docs: kernel-parameters: Remove smsc-ircc2 IrDA parameters
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260802-docs-remove-smsc-ircc2-params-v1-1-91b302e90cce@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQrCMAwA0F8ZORvoapHpr4iHLku3DLqORIcw9
 u9WPb7L28FYhQ1uzQ7Km5iUpaI9NUBTXEZGGarBO39xnfM4FDJUzmVjtGyEokQe16gxG0a69iF
 xakM4Qz1W5STv339//G2vfmZ6flM4jg9hV08KgQAAAA==
X-Change-ID: 20260802-docs-remove-smsc-ircc2-params-ac9b4fef1443
To: Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Anuj Bolewar <bolewara@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785679899; l=1844;
 i=bolewara@gmail.com; s=20260802; h=from:subject:message-id;
 bh=btfNVB8ib3tu4wleNIK7XhSVR3Xyj+ZA0X1ZtsVXCSo=;
 b=APrjjc8n5oH/TQnB/gfCuIGoHR/nASyOm00vdwQsAW4DEGMK8R7yd+hwwQZNRxPKBjWrSdfOH
 +BHiTfzb3N2D71qzw9MQY9Dxuag1QLQjtYASTbQjZcnA4YEBfWvQ4V9
X-Developer-Key: i=bolewara@gmail.com; a=ed25519;
 pk=XxcXxqFWk9xQziyNEfhS6NRJQR1shqHRRYzkbaYamm0=
X-Endpoint-Received: by B4 Relay for bolewara@gmail.com/20260802 with auth_id=907
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The smsc-ircc2 module parameters reference drivers/net/irda/
smsc-ircc2.c, which was removed along with the entire IrDA stack in
commit d64c2a76123f ("staging: irda: remove the irda network stack
and drivers").

Signed-off-by: Anuj Bolewar <bolewara@gmail.com>
---
The IrDA stack and drivers were removed from the kernel in commit
d64c2a76123f ("staging: irda: remove the irda network stack and
drivers"). Remove the now-obsolete smsc-ircc2 module parameters from
the kernel parameter documentation.
---
 Documentation/admin-guide/kernel-parameters.txt | 11 -----------
 1 file changed, 11 deletions(-)

diff --git a/Documentation/admin-guide/kernel-parameters.txt b/Documentation/admin-guide/kernel-parameters.txt
index b5493a7f8f2..72afae6ea85 100644
--- a/Documentation/admin-guide/kernel-parameters.txt
+++ b/Documentation/admin-guide/kernel-parameters.txt
@@ -7006,17 +7006,6 @@ Kernel parameters
 			take as long as they take.  Specifying 300,000
 			for this value provides a 5-minute timeout.
 
-	smsc-ircc2.nopnp	[HW] Don't use PNP to discover SMC devices
-	smsc-ircc2.ircc_cfg=	[HW] Device configuration I/O port
-	smsc-ircc2.ircc_sir=	[HW] SIR base I/O port
-	smsc-ircc2.ircc_fir=	[HW] FIR base I/O port
-	smsc-ircc2.ircc_irq=	[HW] IRQ line
-	smsc-ircc2.ircc_dma=	[HW] DMA channel
-	smsc-ircc2.ircc_transceiver= [HW] Transceiver type:
-				0: Toshiba Satellite 1800 (GP data pin select)
-				1: Fast pin select (default)
-				2: ATC IRMode
-
 	smt=		[KNL,MIPS,S390,EARLY] Set the maximum number of threads
 			(logical CPUs) to use per physical CPU on systems
 			capable of symmetric multithreading (SMT). Will

---
base-commit: 2d2338c93da79b3bfe4b6099a931d9468d539952
change-id: 20260802-docs-remove-smsc-ircc2-params-ac9b4fef1443

Best regards,
--  
Anuj Bolewar <bolewara@gmail.com>

