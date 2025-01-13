From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 13 Jan 2025 12:52:59 +0100
Subject: [PATCH RESEND 01/12] Kconfig: Add error path in conf_value_to_yaml
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250113-jag-bringup_fixes-v1-1-fb28030b1f26@kernel.org>
References: <20250113-jag-bringup_fixes-v1-0-fb28030b1f26@kernel.org>
In-Reply-To: <20250113-jag-bringup_fixes-v1-0-fb28030b1f26@kernel.org>
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, mcgrof@kernel.org, 
 da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=1224;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=bGbxHk/oOI1UiN1TNn3H56GZV7Xir+xzbDLx5Xo3kUg=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGeE/qLccEOdp+Z9kH3Kj7HRdarmGvBKO+beK
 zqz4GVYI29D+IkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnhP6iAAoJELqXzVK3
 lkFPGaIL/RJEVIvcivcFaEOzQc9S4M1OxImLWFEDCAt1L7Y/htMmnTYrZQZe9RDOCbecOKpTRS3
 4u2ELGIdMxWOrSoRY0Gm2QiMdziOpsGG2pkk8idx3/7CvnDERA62wpARPUpyxSsBL9Z/+kj9kC5
 xL4qepsGc0PjDZjViWPEW3v7gc1kTKUwnlZeIpMhrW3+zJvqNrBAKR0LnvJ3JaRb4DTfXzSzi0H
 /hCOb0ebMD6JNkqNu4A96M+zuTv+hk0rvnnXwOpJ9oOyb5t0ZgFKN7JfHvv73r9RLOaiRgQQYxu
 48aZtvJfKwTJ8uMVWKwzGoOEp5LP8SvQdCJQ83p4KaacaRrQYtuXhz57SOrTyWutyS6EUK0XSfQ
 hIvGzW4Ujo7dhYTfq4srYdj6kAiRoNbxMvRjSQkwvskdCB/Rweu1WFdUPvaL6u4qex4gzj4nZr0
 G9wRZizU69l8338RGrAydZydtb1X9extqD0uG5WCT3e6dBFEzDagqZfFT7rOfkYUsA7LMOQQeA7
 4k=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The asprintf call returns -1 on error. In this case the value of
yaml_value is undefined. Return NULL, so the caller can handle the
error.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 scripts/kconfig/confdata.c | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)

diff --git a/scripts/kconfig/confdata.c b/scripts/kconfig/confdata.c
index 0156b38..49a5729 100644
--- a/scripts/kconfig/confdata.c
+++ b/scripts/kconfig/confdata.c
@@ -669,14 +669,14 @@ static char *conf_value_to_yaml(struct symbol *sym, const char *val)
 		yaml_value = strdup(val);
 		break;
 	case S_HEX:
-            asprintf(&yaml_value, "0x%s", val);
-            break;
-        case S_STRING:
-	    /* Wrap strings in quotes */
-            asprintf(&yaml_value, "\"%s\"", val);
-            break;
-        case S_BOOLEAN:
-        case S_TRISTATE:
+		if (asprintf(&yaml_value, "0x%s", val) < 0)
+			return NULL;
+	case S_STRING:
+		/* Wrap strings in quotes */
+		if (asprintf(&yaml_value, "\"%s\"", val) < 0)
+			return NULL;
+	case S_BOOLEAN:
+	case S_TRISTATE:
 		if (strcmp(val, "y") == 0)
 			yaml_value = strdup("True");
 		else if (strcmp(val, "n") == 0)

-- 
2.44.2

