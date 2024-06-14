From: Joel Granados <j.granados@samsung.com>
Date: Fri, 14 Jun 2024 14:29:41 +0200
Subject: [PATCH] sentinel_ctltable: Add a check for sentinel elements in
 ctl_table arrays
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240614-master-v1-1-c652f5aa15fb@samsung.com>
X-B4-Tracking: v=1; b=H4sIALQ3bGYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDM0MT3dzE4pLUIt2UJCNTyxQLS4OUJAMloOKCotS0zAqwQdGxtbUANGC
 Mr1gAAAA=
To: smatch@vger.kernel.org, linux-sparse@vger.kernel.org
Cc: Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2371;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=oGo94YVrdI09l3Z5ERIYpeb474uuEhI6x6Z6iNqs5t0=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGZsN9OuGyQAtOxXfZTi1ltnHeD0+UqQY47I3
 S9DOi+43a+xmokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmbDfTAAoJELqXzVK3
 lkFPJKgL+wd3nceNMmCZjNQ1d+/XLDPBJkzMgz03GezBHgLTWsvwFTnWdMcKRhsD4a7J6+DnIhk
 6YtxdNuvsogRTnCIqEPqUwE+xkJPrtXBF5gmghfqetFs7FIk7nBL3pDtXF0EfEdBOODu+mQdv+m
 cmHzXUdoi5K6ra/sMf4wyXsiENQk9ntPNzyBvC/NP5DSsUieUKiegXbfuxIULgeXCgwPz4EPDYa
 oJ41D7pOfvfhPVn956I1DAQqz1JbHc2wXvorEzqeIR+GSu6UpyJfN1cQcNTc2UA6Q12/PNrYIcy
 WVkhodUg7xgmQIgTondPNA0Qv6kOd4NxNBQIYAl3fnksHty1M1hAT1AkwphRmTY8VoVXrIDKTGU
 l8uX3b/CmaP9Ud+kSv6/wUXKxXkP7Q1nYfLOqbXnKidsdVNNTr+xrPeHv/KnGomC0517FhXPvVy
 iGy/SzesRyWP02xtMo5NI+KkQTFXRhcB4RldrurtH5ALYdjk9kmcXzMXwja4XDxuofPwfb4drP7
 DY=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Added a new check named check_sentinel_ctltable that prints a warning
when a sentinel element is detected in a ctl_table struct array.
Sentinels marking the end of a ctl_table array where completely removed
from the linux kernel in [1]. We add this warning to avoid cases where a
sentinel gets added by mistake.

[1] https://lore.kernel.org/20240604-jag-sysctl_remset-v1-0-2df7ecdba0bd@samsung.com

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
Signed-off-by: Joel Granados <j.granados@samsung.com>

--
---
 check_list.h              |  1 +
 check_sentinel_ctltable.c | 41 +++++++++++++++++++++++++++++++++++++++++
 2 files changed, 42 insertions(+)

diff --git a/check_list.h b/check_list.h
index 7115b069..a870c95f 100644
--- a/check_list.h
+++ b/check_list.h
@@ -252,6 +252,7 @@ CK(check_direct_return_instead_of_goto)
 CK(check_double_fget)
 CK(check_negative_error_code_type_promoted)
 CK(check_uninitialized_kobj)
+CK(check_sentinel_ctltable)
 
 /* wine specific stuff */
 CK(check_wine_filehandles)
diff --git a/check_sentinel_ctltable.c b/check_sentinel_ctltable.c
new file mode 100644
index 00000000..8bdb582a
--- /dev/null
+++ b/check_sentinel_ctltable.c
@@ -0,0 +1,41 @@
+#include "smatch.h"
+
+struct non_null_ctltable_elems {
+	const char *name;
+	const int len;
+};
+
+static struct non_null_ctltable_elems non_null_elems[] = {
+	{.name = "->procname", .len = 10},
+	{.name = "->proc_handler", .len = 14},
+};
+
+static int match_ctl_table_array_sentinel(struct expression *expr)
+{
+	char * member_name = NULL;
+	if (!expr)
+		return 0;
+
+	member_name = get_member_name(expr);
+	if (!member_name)
+		return 0;
+
+	if (strncmp(member_name, "(struct ctl_table)", 18) != 0)
+		return 0;
+
+	for (int i = 0 ; i < ARRAY_SIZE(non_null_elems) ; ++i) {
+		if (strncmp(member_name + 18, non_null_elems[i].name, non_null_elems[i].len) ==0) {
+			sm_warning ("(struct ctl_table)%s cannot be NULL. Expression : %s",
+				    non_null_elems[i].name, expr_to_str(expr));
+			return 0;
+		}
+	}
+
+	return 0;
+}
+
+void check_sentinel_ctltable(int id)
+{
+	add_hook(&match_ctl_table_array_sentinel, EXPR_HOOK);
+}
+

---
base-commit: ff1cc4d453ffeddf3cf3dc031c5b129eefbf3e2c
change-id: 20240614-master-db259d890db0

Best regards,
-- 
Joel Granados <j.granados@samsung.com>

