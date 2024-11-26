From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:22:19 -0800
Subject: [PATCH 29/36] xen/console: make console buffer size configurable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-29-87b9a8375b7a@ford.com>
References: <20241126-vuart-ns8250-v1-v1-0-87b9a8375b7a@ford.com>
In-Reply-To: <20241126-vuart-ns8250-v1-v1-0-87b9a8375b7a@ford.com>
To: Jan Beulich <jbeulich@suse.com>, 
 Andrew Cooper <andrew.cooper3@citrix.com>, 
 =?utf-8?q?Roger_Pau_Monn=C3=A9?= <roger.pau@citrix.com>, 
 "Daniel P. Smith" <dpsmith@apertussolutions.com>, 
 Stefano Stabellini <sstabellini@kernel.org>, Julien Grall <julien@xen.org>, 
 Bertrand Marquis <bertrand.marquis@arm.com>, 
 Michal Orzel <michal.orzel@amd.com>, Rahul Singh <rahul.singh@arm.com>, 
 Volodymyr Babchuk <Volodymyr_Babchuk@epam.com>, 
 Alistair Francis <alistair.francis@wdc.com>, 
 Bob Eshleman <bobbyeshleman@gmail.com>, 
 Connor Davis <connojdavis@gmail.com>, 
 Oleksii Kurochko <oleksii.kurochko@gmail.com>, 
 Shawn Anastasio <sanastasio@raptorengineering.com>, 
 Anthony PERARD <anthony.perard@vates.tech>, Juergen Gross <jgross@suse.com>, 
 Christian Lindig <christian.lindig@citrix.com>, 
 David Scott <dave@recoil.org>, 
 =?utf-8?q?Marek_Marczykowski-G=C3=B3recki?= <marmarek@invisiblethingslab.com>
Cc: xen-devel@lists.xenproject.org, Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=2270;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=AKwyQAvwjj+wQmu1WwmpWDVO3KxHtjslwmqsRTzrAD0=;
 b=2HaC4h5V7Nqz/P9NOv91yjhDKAIlxkFFwtZ/HQqHYBGIHO0FUCz24w2vidaasH3dA1AmaxlAe
 FHROVQWFA36AM3r9ufqu45LJzuW/14PyrFrvxk30PhdkkGk/KDETzzI
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add new CONRING_LOG_SHIFT Kconfig parameter to specify the boot console buffer
size as a power of 2.

Bump default size to 32 KiB.

Link: https://gitlab.com/xen-project/xen/-/issues/185
Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/drivers/char/Kconfig   | 23 +++++++++++++++++++++++
 xen/drivers/char/console.c |  4 ++--
 2 files changed, 25 insertions(+), 2 deletions(-)

diff --git a/xen/drivers/char/Kconfig b/xen/drivers/char/Kconfig
index e175d07c022b051c5af4e689061adba72f9b54a0..2c754545cf05e740bd3d59d88de464f3653fb68e 100644
--- a/xen/drivers/char/Kconfig
+++ b/xen/drivers/char/Kconfig
@@ -93,6 +93,29 @@ config SERIAL_TX_BUFSIZE
 
 	  Default value is 32768 (32KiB).
 
+config CONRING_LOG_SHIFT
+	int "Console buffer size"
+	range 14 25
+	default 15
+	help
+	  Select the boot console buffer size as a power of 2.
+	  Run-time console buffer size is the same as the boot console size,
+	  unless enforced via 'conring_size=' boot parameter.
+
+	  Examples:
+	    25 =>  32 MiB
+	    24 =>  16 MiB
+	    23 =>   8 MiB
+	    22 =>   4 MiB
+	    21 =>   2 MiB
+	    20 =>   1 MiB
+	    19 => 512 KiB
+	    18 => 256 KiB
+	    17 => 128 KiB
+	    16 =>  64 KiB
+	    15 =>  32 KiB
+	    14 =>  16 KiB
+
 config XHCI
 	bool "XHCI DbC UART driver"
 	depends on X86
diff --git a/xen/drivers/char/console.c b/xen/drivers/char/console.c
index 9f67ecb26f5ab1183d17c83631a17b45cfefd5ab..24a8263045b0e5ecf901d08e627f34a80edd297d 100644
--- a/xen/drivers/char/console.c
+++ b/xen/drivers/char/console.c
@@ -102,11 +102,11 @@ static int cf_check parse_console_timestamps(const char *s);
 custom_runtime_param("console_timestamps", parse_console_timestamps,
                      con_timestamp_mode_upd);
 
-/* conring_size: allows a large console ring than default (16kB). */
+/* conring_size: allows a large console ring than default (32 KiB). */
 static uint32_t __initdata opt_conring_size;
 size_param("conring_size", opt_conring_size);
 
-#define _CONRING_SIZE 16384
+#define _CONRING_SIZE       (1U << CONFIG_CONRING_LOG_SHIFT)
 #define CONRING_IDX_MASK(i) ((i)&(conring_size-1))
 static char __initdata _conring[_CONRING_SIZE];
 static char *__read_mostly conring = _conring;

-- 
2.34.1

