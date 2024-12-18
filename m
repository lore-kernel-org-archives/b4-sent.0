From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 18 Dec 2024 11:29:55 +0100
Subject: [PATCH 01/12] Kconfig: Add error path in conf_value_to_yaml
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241218-jag-bringup_fixes-v1-1-0bf2e07c640c@kernel.org>
References: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
In-Reply-To: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=1224;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=bGbxHk/oOI1UiN1TNn3H56GZV7Xir+xzbDLx5Xo3kUg=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGdipCvz1wWmZEZZi5o483Dz4xKiud6OXcXxQ
 KCwDJyO+BRUiIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnYqQrAAoJELqXzVK3
 lkFPnYEL/01tgYp2GYYNMRI5uF5MJH6jcZWuHSDVpJFaH/wDq8ATxBNf3N7w8qa+zlhUK/vDbQT
 DHOnSSXYwHMySR1491FITI0up8nDub+XunxYdQmEXWdkQ5TQfezIsFpQP7+N52xlt/kIZab7gKi
 jd89QKMLoEpA+C40E3CzIjimuEI2SLhZRI0FBjNtHGoy1Yg6kv6hlDhfhCQDZUCm7L0t2WOidNz
 6yP2SIDss3X98e9XFVxv77VlWOWaLVtR6CaSbn56N9lJaczgoCyStTsNo36b2vlRc7oX1HUxC90
 MSefx5ByGl8B5kSZjaSUfeP1KT9tkUTuF/KUueIJSS/i5QMgpWscT4I+Ik2fOEQ4Awtmpa+FauZ
 51VqdVHtYUPERjX7M2o0ed/zxLmd8TneMq8Ay7UVRDeeCHHM27m7TgTkun/csVqyuNhe2PHH4BF
 7yh+I/qOxtLHCX944qo62TSL/NqkJ7peOYLep7AcTrmQw43G7Wi+5KThuji1ZtXeUgPpvsq9K66
 Jw=
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

