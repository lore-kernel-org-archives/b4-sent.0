From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 22 Jan 2025 11:33:49 +0100
Subject: [PATCH] tests/module: nix-ify
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250122-jag-nix-ify-v1-1-addb3170f93c@kernel.org>
X-B4-Tracking: v=1; b=H4sIAIzJkGcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDQyMj3azEdN28zArdzLRKXcPERCMDM8Nkk8QUCyWgjoKi1LTMCrBp0bG
 1tQDH4RmHXQAAAA==
To: Luis Chamberlain <mcgrof@kernel.org>
Cc: linux-kernel@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=961;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=Iyg0ddW/CJJPTP76JMAtDW2ZxUMTCRKQkqS1CRRRagU=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGeQyZ1D6eEQyZgjZz2tRG9d9RtlfVJBPSbt3
 t4agpD9Xa/95IkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnkMmdAAoJELqXzVK3
 lkFPIRwL/2FkZUYui5xQ/m9v+5SaCo59Yb56z+w4xQ2zBLr32AY7LtdCZEbJTaK5uKmKRLWzSoO
 EEhYX//lSxpJ3/pO/TArVqEfzNnQo7xtSN4bPnJiOiLn2etdHCR/OxAFiccqIdCj+yUkjMwMhuB
 PL3gCfJzcEDoRuvz6lCYVGfUImyZtrIFRsBsNQ7MRJ1GH46bwKsoA1St1AMhaaBzVtJ3ee4Qezy
 J37wO5+/UNp/0tgEHjSYXqrf8Yl2bC1PA7Ap5Ff0B+UIeb1k+plg8k9RU0zpssFhguFYpmqUFr2
 9ndNGOq9qzXDt0fpJo7HUyrvJCI+7GzACgHCnHmJWOyVV5y8JBgzSkDYZR6LPfWeZ4z6p60hgq9
 jRbAkG2EmPZccGwuBER2flv9ksxWIu+222H9XRW1b27xevjpZ//KgmrTsOG99tP/YuAohb4DXy+
 QjIM7nT/RMcEUL2FF3LKW+GUq+RIawQ0f4NBNgVrw2FNVPMNowGnnX2z1lOZ+kzMny3Zvoqzbg6
 Yg=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use "#!/usr/bin/env bash" instead of "#!/bin/bash". This is necessary
for nix environments as they only provide /usr/bin/env at the standard
location.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
I just saw this break my allyes test build. I had usually done it in
debian, but now that its on NixOs; this patch corrects the build error.
---
 lib/tests/module/gen_test_kallsyms.sh | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/lib/tests/module/gen_test_kallsyms.sh b/lib/tests/module/gen_test_kallsyms.sh
index 561dcac0f359..31fe4ed63de8 100755
--- a/lib/tests/module/gen_test_kallsyms.sh
+++ b/lib/tests/module/gen_test_kallsyms.sh
@@ -1,4 +1,4 @@
-#!/bin/bash
+#!/usr/bin/env bash
 
 TARGET=$(basename $1)
 DIR=lib/tests/module

---
base-commit: ffd294d346d185b70e28b1a28abe367bbfe53c04
change-id: 20250122-jag-nix-ify-1aa2061c4ad8

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

