From: Pascal Eberhard <pascal.eberhard@se.com>
Date: Tue, 10 Mar 2026 00:29:40 +0100
Subject: [PATCH v2 3/4] lib/tests/fetch2: add tests for curl method
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260310-add_alt_fetch_method_curl-v2-3-4789639b28f1@se.com>
References: <20260310-add_alt_fetch_method_curl-v2-0-4789639b28f1@se.com>
In-Reply-To: <20260310-add_alt_fetch_method_curl-v2-0-4789639b28f1@se.com>
To: bitbake-devel@lists.openembedded.org
Cc: Pascal Eberhard <pascal.eberhard@se.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773099103; l=5399;
 i=pascal.eberhard@se.com; s=20260304; h=from:subject:message-id;
 bh=IFaMueW2762ELu2lI2L6fxbF1Qag0z/rfsvviir0rz4=;
 b=mAXuBqPboTozSC7lnXNsTUZIv3gEZXE3VRXB86cOtqb6sJVRqr3xlTrbJI8J9LLeAgoUMwE4/
 nqvyNm2RLeQDQzJnGCIEF1mOvUA+Ruv4xIk8iYJdfSd7cySe/L6d5qP
X-Developer-Key: i=pascal.eberhard@se.com; a=ed25519;
 pk=J7TbFctjt1RVuN5K0juhf/w1E9bAfSeoQ/JG1vV9mWg=
X-Endpoint-Received: by B4 Relay for pascal.eberhard@se.com/20260304 with auth_id=661
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Duplicate wget fetch method test cases to test curl fetch method.

Signed-off-by: Pascal Eberhard <pascal.eberhard@se.com>
---
 lib/bb/tests/fetch.py | 75 +++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 75 insertions(+)

diff --git a/lib/bb/tests/fetch.py b/lib/bb/tests/fetch.py
index 74eb73472..72257a130 100644
--- a/lib/bb/tests/fetch.py
+++ b/lib/bb/tests/fetch.py
@@ -28,6 +28,10 @@ def skipIfNoNetwork():
         return unittest.skip("network test")
     return lambda f: f
 
+def skipIfNoCurl():
+    if not shutil.which("curl"):
+        return unittest.skip("'curl' not found")
+    return lambda f: f
 
 @contextlib.contextmanager
 def hide_directory(directory):
@@ -1550,6 +1554,7 @@ class FetchLatestVersionTest(FetcherTest):
 
                     url = "http://127.0.0.1:%s/%s" % (port, data.path)
                     ud = bb.fetch2.FetchData(url, self.d)
+                    self.assertEqual(ud.method.__class__.__name__, "Wget")
                     pupver = ud.method.latest_versionstring(ud, self.d)
                     verstring = pupver[0]
                     self.assertTrue(verstring, msg="Could not find upstream version for %s" % data.pn)
@@ -1558,6 +1563,36 @@ class FetchLatestVersionTest(FetcherTest):
         finally:
             server.stop()
 
+    @skipIfNoCurl()
+    def test_curl_latest_versionstring(self):
+        self.d.setVar("BB_FETCH_METHOD_HTTP", "curl")
+        testdata = os.path.dirname(os.path.abspath(__file__)) + "/fetch-testdata"
+        server = HTTPService(testdata, host="127.0.0.1")
+        server.start()
+        port = server.port
+        try:
+            for data, v in self.test_wget_uris.items():
+                with self.subTest(pn=data.pn):
+                    self.d.setVar("PN", data.pn)
+                    self.d.setVar("PV", data.pv)
+                    if data.check_uri:
+                        checkuri = "http://127.0.0.1:%s/%s" % (port, data.check_uri)
+                        self.d.setVar("UPSTREAM_CHECK_URI", checkuri)
+                    if data.check_regex:
+                        self.d.setVar("UPSTREAM_CHECK_REGEX", data.check_regex)
+
+                    url = "http://127.0.0.1:%s/%s" % (port, data.path)
+                    ud = bb.fetch2.FetchData(url, self.d)
+                    self.assertEqual(ud.method.__class__.__name__, "Curl")
+                    pupver = ud.method.latest_versionstring(ud, self.d)
+                    verstring = pupver[0]
+                    self.assertTrue(verstring, msg="Could not find upstream version for %s" % data.pn)
+                    r = bb.utils.vercmp_string(v, verstring)
+                    self.assertTrue(r == -1 or r == 0, msg="Package %s, version: %s <= %s" % (data.pn, v, verstring))
+        finally:
+            server.stop()
+        self.d.delVar("BB_FETCH_METHOD_HTTP")
+
     @skipIfNoNetwork()
     def test_crate_latest_versionstring(self):
         for k, v in self.test_crate_uris.items():
@@ -1590,6 +1625,7 @@ class FetchCheckStatusTest(FetcherTest):
             with self.subTest(url=u):
                 ud = fetch.ud[u]
                 m = ud.method
+                self.assertEqual(ud.method.__class__.__name__, "Wget")
                 ret = m.checkstatus(fetch, ud, self.d)
                 self.assertTrue(ret, msg="URI %s, can't check status" % (u))
 
@@ -1605,10 +1641,49 @@ class FetchCheckStatusTest(FetcherTest):
             with self.subTest(url=u):
                 ud = fetch.ud[u]
                 m = ud.method
+                self.assertEqual(ud.method.__class__.__name__, "Wget")
+                ret = m.checkstatus(fetch, ud, self.d)
+                self.assertTrue(ret, msg="URI %s, can't check status" % (u))
+
+        connection_cache.close_connections()
+
+    @skipIfNoCurl()
+    @skipIfNoNetwork()
+    def test_curl_checkstatus(self):
+        self.d.setVar("BB_FETCH_METHOD_HTTP", "curl")
+
+        fetch = bb.fetch2.Fetch(self.test_wget_uris, self.d)
+        for u in self.test_wget_uris:
+            with self.subTest(url=u):
+                ud = fetch.ud[u]
+                m = ud.method
+                self.assertEqual(ud.method.__class__.__name__, "Curl")
+                ret = m.checkstatus(fetch, ud, self.d)
+                self.assertTrue(ret, msg="URI %s, can't check status" % (u))
+
+        self.d.delVar("BB_FETCH_METHOD_HTTP")
+
+    @skipIfNoCurl()
+    @skipIfNoNetwork()
+    def test_curl_checkstatus_connection_cache(self):
+        from bb.fetch2 import FetchConnectionCache
+
+        self.d.setVar("BB_FETCH_METHOD_HTTP", "curl")
+
+        connection_cache = FetchConnectionCache()
+        fetch = bb.fetch2.Fetch(self.test_wget_uris, self.d,
+                    connection_cache = connection_cache)
+
+        for u in self.test_wget_uris:
+            with self.subTest(url=u):
+                ud = fetch.ud[u]
+                m = ud.method
+                self.assertEqual(ud.method.__class__.__name__, "Curl")
                 ret = m.checkstatus(fetch, ud, self.d)
                 self.assertTrue(ret, msg="URI %s, can't check status" % (u))
 
         connection_cache.close_connections()
+        self.d.delVar("BB_FETCH_METHOD_HTTP")
 
 
 class GitMakeShallowTest(FetcherTest):

-- 
2.43.0

