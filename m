From: Petr Hodina <petr.hodina@protonmail.com>
Date: Fri, 11 Sep 2026 20:18:47 +0200
Subject: [PATCH 1/4] common: Add command line parsing utilities
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260911-b4-android-bootargs-carryover-v1-1-6ebb43da3df0@protonmail.com>
References: <20260911-b4-android-bootargs-carryover-v1-0-6ebb43da3df0@protonmail.com>
In-Reply-To: <20260911-b4-android-bootargs-carryover-v1-0-6ebb43da3df0@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Peng Fan <peng.fan@nxp.com>, 
 Simon Glass <sjg@chromium.org>, Kory Maincent <kory.maincent@bootlin.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Philip Molloy <philip.molloy@analog.com>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Markus Niebel <Markus.Niebel@ew.tq-group.com>, 
 Alexey Charkov <alchark@gmail.com>, Heiko Schocher <hs@nabladev.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Anshul Dalal <anshuld@ti.com>, Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 David Heidelberg <david@ixit.cz>, Petr Pavlata <petr@acrux.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789150739; l=4144;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=ZdXxyiEAeOugrDHWmQZ2fyrZPJ4bt6tClmkXHuoPbrU=;
 b=5r3/mMK8Zq6Bz7V7Dht68o6Nr/XgdUt4GrWSOJTi7yeElJ2xldLc6MVnGW83qlYmG5vFDVK01
 LPGl/cY3lNPB3btwQIGnEZpEiTWI7oczcCCWLjc7Bci7m2LTH2UyLZm
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a new utility library for parsing command line parameters in
key=value format. This provides a reusable interface for extracting
multiple parameters from command line strings.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 MAINTAINERS             |  6 ++++
 include/cmdline_utils.h | 21 +++++++++++
 lib/Makefile            |  1 +
 lib/cmdline_utils.c     | 96 +++++++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 124 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 45e9076de67..ed697d11349 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1065,6 +1065,12 @@ T:	git https://source.denx.de/u-boot/custodians/u-boot-clk.git
 F:	drivers/clk/
 F:	drivers/clk/imx/
 
+CMDLINE_UTILS
+M:	Petr Hodina <petr.hodina@protonmail.com>
+S:	Maintained
+F:	include/cmdline_utils.h
+F:	lib/cmdline_utils.c
+
 CPU
 M:	Simon Glass <sjg@chromium.org>
 M:	Hou Zhiqiang <Zhiqiang.Hou@nxp.com>
diff --git a/include/cmdline_utils.h b/include/cmdline_utils.h
new file mode 100644
index 00000000000..cf127b64e55
--- /dev/null
+++ b/include/cmdline_utils.h
@@ -0,0 +1,21 @@
+/* SPDX-License-Identifier: GPL-2.0+ */
+/*
+ * Command line parsing utilities
+ *
+ * Copyright (c) 2026 Petr Hodina
+ */
+
+#ifndef _CMDLINE_UTILS_H_
+#define _CMDLINE_UTILS_H_
+
+#include <linux/types.h>
+
+struct cmdline_param {
+	const char *key;
+	char *value;
+	bool found;
+};
+
+int parse_cmdline_params(const char *cmdline, struct cmdline_param *params, int count);
+
+#endif /* _CMDLINE_UTILS_H_ */
diff --git a/lib/Makefile b/lib/Makefile
index d0ffabc2b47..67ac974487b 100644
--- a/lib/Makefile
+++ b/lib/Makefile
@@ -126,6 +126,7 @@ obj-$(CONFIG_$(PHASE_)OF_LIBFDT) += fdtdec.o fdtdec_common.o
 obj-y += hang.o
 obj-y += linux_compat.o
 obj-y += linux_string.o
+obj-y += cmdline_utils.o
 obj-$(CONFIG_$(PHASE_)LMB) += lmb.o
 obj-y += membuf.o
 obj-$(CONFIG_REGEX) += slre.o
diff --git a/lib/cmdline_utils.c b/lib/cmdline_utils.c
new file mode 100644
index 00000000000..b4798c439b8
--- /dev/null
+++ b/lib/cmdline_utils.c
@@ -0,0 +1,96 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Command line parsing utilities
+ *
+ * Copyright (C) 2026 Petr Hodina
+ */
+
+#include <cmdline_utils.h>
+#include <malloc.h>
+#include <string.h>
+#include <errno.h>
+#include <linux/kernel.h>
+
+static const char *find_cmdline_key(const char *cmdline, const char *key_with_equals)
+{
+	const char *p = cmdline;
+
+	while ((p = strstr(p, key_with_equals)) != NULL) {
+		if (p == cmdline || *(p - 1) == ' ')
+			return p;
+		p++;
+	}
+
+	return NULL;
+}
+
+int parse_cmdline_params(const char *cmdline, struct cmdline_param *params, int count)
+{
+	int i;
+	const char *p, *p_end;
+	int key_len, val_len;
+	char *key_with_equals;
+
+	if (!cmdline || !params || count <= 0)
+		return -EINVAL;
+
+	for (i = 0; i < count; i++) {
+		params[i].found = false;
+		params[i].value = NULL;
+	}
+
+	for (i = 0; i < count; i++) {
+		if (!params[i].key)
+			continue;
+
+		key_len = strlen(params[i].key);
+		if (key_len == 0)
+			continue;
+
+		if (params[i].key[key_len - 1] == '=') {
+			p = find_cmdline_key(cmdline, params[i].key);
+			if (!p)
+				continue;
+			p += key_len;
+		} else {
+			key_with_equals = malloc(key_len + 2);
+			if (!key_with_equals)
+				goto cleanup_error;
+
+			strcpy(key_with_equals, params[i].key);
+			strcat(key_with_equals, "=");
+
+			p = find_cmdline_key(cmdline, key_with_equals);
+			free(key_with_equals);
+
+			if (!p)
+				continue;
+			p += key_len + 1;
+		}
+
+		p_end = strstr(p, " ");
+		if (!p_end)
+			val_len = strlen(p);
+		else
+			val_len = p_end - p;
+
+		params[i].value = malloc(val_len + 1);
+		if (!params[i].value)
+			goto cleanup_error;
+
+		strlcpy(params[i].value, p, val_len + 1);
+		params[i].found = true;
+	}
+
+	return 0;
+
+cleanup_error:
+	for (i = 0; i < count; i++) {
+		if (params[i].value) {
+			free(params[i].value);
+			params[i].value = NULL;
+		}
+		params[i].found = false;
+	}
+	return -ENOMEM;
+}

-- 
2.55.0

