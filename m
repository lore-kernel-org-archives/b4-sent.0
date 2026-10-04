From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sun, 04 Oct 2026 22:48:25 +0200
Subject: [PATCH 1/2] dfu: expand ${...} env references in dfu_alt_info
 before parsing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261004-b4-dfu-alt-info-env-expand-v1-1-700eb0e54b61@protonmail.com>
References: <20261004-b4-dfu-alt-info-env-expand-v1-0-700eb0e54b61@protonmail.com>
In-Reply-To: <20261004-b4-dfu-alt-info-env-expand-v1-0-700eb0e54b61@protonmail.com>
To: u-boot@lists.u-boot-project.org, Sumit Garg <sumit.garg@kernel.org>, 
 u-boot-qcom@groups.io
Cc: Lukasz Majewski <lukma@denx.de>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Tom Rini <trini@konsulko.com>, Sean Anderson <sean.anderson@linux.dev>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Petr Pavlata <petr@acrux.cz>, David Heidelberg <david@ixit.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791146915; l=1237;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=zHNicPZo8C+Jci1O2ZgaLbRZF4h4ywq5+c81LYRcock=;
 b=TETMBfYEt56Vd2zQjwpcELzYtRy61nrRJ/aSWbTyfYizo3hUW7e5g23jRkhOEk3lMAKB8PrUR
 ksRjtjaPbF6Bez4vU4fbyAoi8rHKxbXZYkLHaKHB25cNujI0kwmjSaI
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As dfu_alt_info is read via env_get() it needs to expand the ${var}
references using cli_simple_process_macros.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 drivers/dfu/dfu.c | 16 +++++++++++++++-
 1 file changed, 15 insertions(+), 1 deletion(-)

diff --git a/drivers/dfu/dfu.c b/drivers/dfu/dfu.c
index 90d8b45ce8a..fa074db242c 100644
--- a/drivers/dfu/dfu.c
+++ b/drivers/dfu/dfu.c
@@ -6,6 +6,7 @@
  * author: Lukasz Majewski <l.majewski@samsung.com>
  */
 
+#include <cli.h>
 #include <env.h>
 #include <errno.h>
 #include <log.h>
@@ -178,7 +179,20 @@ int dfu_init_env_entities(char *interface, char *devstr)
 		return -EINVAL;
 	}
 
-	env_bkp = strdup(str_env);
+	/*
+	 * Expand the dfu_alt_info here as it's read via env_get() which
+	 * does not expand references the way hush does for a command line
+	 */
+	env_bkp = malloc(strlen(str_env) * 2 + 1);
+	if (!env_bkp)
+		return -ENOMEM;
+
+	if (cli_simple_process_macros(str_env, env_bkp,
+				      strlen(str_env) * 2 + 1)) {
+		pr_err("\"dfu_alt_info\" expansion ran out of space!\n");
+		free(env_bkp);
+		return -ENOSPC;
+	}
 	if (!interface && !devstr)
 		ret = dfu_config_interfaces(env_bkp);
 	else

-- 
2.55.0

