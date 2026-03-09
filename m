From: Pascal Eberhard <pascal.eberhard@se.com>
Date: Tue, 10 Mar 2026 00:29:41 +0100
Subject: [PATCH v2 4/4] doc: bitbake-user-manual-ref-variables: describe
 BB_FETCH_METHOD_HTTP variable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260310-add_alt_fetch_method_curl-v2-4-4789639b28f1@se.com>
References: <20260310-add_alt_fetch_method_curl-v2-0-4789639b28f1@se.com>
In-Reply-To: <20260310-add_alt_fetch_method_curl-v2-0-4789639b28f1@se.com>
To: bitbake-devel@lists.openembedded.org
Cc: Pascal Eberhard <pascal.eberhard@se.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773099103; l=1168;
 i=pascal.eberhard@se.com; s=20260304; h=from:subject:message-id;
 bh=mMN0eDTcP33G0a41mnOnUsgTrlLpjDXr5F9CTc4gENE=;
 b=tCoOqYT9U8lc+3v45Zk2wD/AotwoTq55GzTJzxnDpMj+cD/Fa10N+AFP1hQHU/3LZqRfYhWgc
 zlKbv2tgStqButDIcDaFdwSiDSvTK62jjEljlfkHtuSKCd+3hDqFhJv
X-Developer-Key: i=pascal.eberhard@se.com; a=ed25519;
 pk=J7TbFctjt1RVuN5K0juhf/w1E9bAfSeoQ/JG1vV9mWg=
X-Endpoint-Received: by B4 Relay for pascal.eberhard@se.com/20260304 with auth_id=661
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

add BB_FETCH_METHOD_HTTP variable to select between wget and curl method
for http, https, ftp, ftps protocols.

Signed-off-by: Pascal Eberhard <pascal.eberhard@se.com>
---
 doc/bitbake-user-manual/bitbake-user-manual-ref-variables.rst | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/doc/bitbake-user-manual/bitbake-user-manual-ref-variables.rst b/doc/bitbake-user-manual/bitbake-user-manual-ref-variables.rst
index 06bd53619..c459ed3af 100644
--- a/doc/bitbake-user-manual/bitbake-user-manual-ref-variables.rst
+++ b/doc/bitbake-user-manual/bitbake-user-manual-ref-variables.rst
@@ -311,6 +311,11 @@ overview of their function and contents.
       search the main :term:`SRC_URI` or
       :term:`MIRRORS`.
 
+   :term:`BB_FETCH_METHOD_HTTP`
+      When set to "curl", cause BitBake's fetcher to use curl method for
+      downloading web artifacts via http, https, ftp or ftps.
+      When not set (default) or set to "wget", wget method is used.
+
    :term:`BB_FILENAME`
       Contains the filename of the recipe that owns the currently running
       task. For example, if the ``do_fetch`` task that resides in the

-- 
2.43.0

