From: Pascal Eberhard <pascal.eberhard@se.com>
Date: Tue, 10 Mar 2026 00:29:39 +0100
Subject: [PATCH v2 2/4] fetch2: make curl method activable with
 BB_FETCH_METHOD_HTTP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260310-add_alt_fetch_method_curl-v2-2-4789639b28f1@se.com>
References: <20260310-add_alt_fetch_method_curl-v2-0-4789639b28f1@se.com>
In-Reply-To: <20260310-add_alt_fetch_method_curl-v2-0-4789639b28f1@se.com>
To: bitbake-devel@lists.openembedded.org
Cc: Pascal Eberhard <pascal.eberhard@se.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773099103; l=1806;
 i=pascal.eberhard@se.com; s=20260304; h=from:subject:message-id;
 bh=64aFNHzuzQvTD39bZT3zcb0N4XDTAFGjqhXZfbW5M2o=;
 b=7BS9N/jdWn7VYoBfgirMIBO0hUudTtFTbYbqL7+8eMIlpyjVjQGF4rVnQ4UUve6MlugLX0uA2
 fa5O7HM89FJBdV51AZQb1jCwMbcgcPRPwNG1pbQEYw3he+QcW6e0Dzb
X-Developer-Key: i=pascal.eberhard@se.com; a=ed25519;
 pk=J7TbFctjt1RVuN5K0juhf/w1E9bAfSeoQ/JG1vV9mWg=
X-Endpoint-Received: by B4 Relay for pascal.eberhard@se.com/20260304 with auth_id=661
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

wget is the default fetch method. curl fetch method can be activated by
setting bitbake variable:
  BB_FETCH_METHOD_HTTP = "curl"

Signed-off-by: Pascal Eberhard <pascal.eberhard@se.com>
---
 lib/bb/fetch2/__init__.py |  2 ++
 lib/bb/fetch2/wget.py     | 10 ++++++++++
 2 files changed, 12 insertions(+)

diff --git a/lib/bb/fetch2/__init__.py b/lib/bb/fetch2/__init__.py
index aaefd8602..dc1158b38 100644
--- a/lib/bb/fetch2/__init__.py
+++ b/lib/bb/fetch2/__init__.py
@@ -2107,6 +2107,7 @@ from . import gitannex
 from . import local
 from . import svn
 from . import wget
+from . import curl
 from . import ssh
 from . import sftp
 from . import s3
@@ -2123,6 +2124,7 @@ from . import gomod
 
 methods.append(local.Local())
 methods.append(wget.Wget())
+methods.append(curl.Curl())
 methods.append(svn.Svn())
 methods.append(git.Git())
 methods.append(gitsm.GitSM())
diff --git a/lib/bb/fetch2/wget.py b/lib/bb/fetch2/wget.py
index 4e3505599..3b1993f29 100644
--- a/lib/bb/fetch2/wget.py
+++ b/lib/bb/fetch2/wget.py
@@ -60,10 +60,20 @@ class Wget(FetchMethod):
         """
         return (d.getVar("BB_CHECK_SSL_CERTS") or "1") != "0"
 
+    def is_enabled(self, d):
+        """
+        wget method is enabled when BB_FETCH_METHOD_HTTP = "wget" or by default
+        when BB_FETCH_METHOD_HTTP variable is not set.
+        """
+        method_http: str = d.getVar("BB_FETCH_METHOD_HTTP") or "wget"
+        return method_http == "wget"
+
     def supports(self, ud, d):
         """
         Check to see if a given url can be fetched with wget.
         """
+        if not self.is_enabled(d):
+            return False
         return ud.type in ['http', 'https', 'ftp', 'ftps']
 
     def recommends_checksum(self, urldata):

-- 
2.43.0

