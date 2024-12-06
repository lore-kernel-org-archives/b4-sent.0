From: Denis Mukhin <dmukhin@ford.com>
Date: Thu, 05 Dec 2024 20:41:56 -0800
Subject: [PATCH v2 26/35] xen/console: make console buffer size
 configurable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241205-vuart-ns8250-v1-26-e9aa923127eb@ford.com>
References: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
In-Reply-To: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
To: xen-devel@lists.xenproject.org
Cc: Andrew Cooper <andrew.cooper3@citrix.com>, 
 Jan Beulich <jbeulich@suse.com>, Julien Grall <julien@xen.org>, 
 Stefano Stabellini <sstabellini@kernel.org>, 
 Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733460094; l=2270;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=c1A6Ce5BfoKvn4U6L7fgV9aDcO1E8jTShGZsUzA9o1w=;
 b=6nQIusazz8SZIdcS2FjkD73AGOVR3RZCfFt69UsZdbDOMeBLkjG7wc5tSw9FTJxQCypBclp6S
 qYSAqfv4s5xAyrHNjlKYKwaWHsnUW3YUkTF6v6RS2oc0+KOumBnFyY1
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
index e6e12bb4139717f9319031f51f5d20155d2caee2..3bc892fc38d8cdeb3c76ea44d747f712a8d0d372 100644
--- a/xen/drivers/char/Kconfig
+++ b/xen/drivers/char/Kconfig
@@ -96,6 +96,29 @@ config SERIAL_TX_BUFSIZE
 
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
index d22fb4a253af26f9b51d91bd408e1dbf4bb5a7c1..581ee22b85302a54db5b9d5d28e8b2d689d31403 100644
--- a/xen/drivers/char/console.c
+++ b/xen/drivers/char/console.c
@@ -104,11 +104,11 @@ static int cf_check parse_console_timestamps(const char *s);
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

