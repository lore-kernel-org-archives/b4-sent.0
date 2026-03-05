From: Pascal Eberhard <pascal.eberhard@se.com>
Date: Thu, 05 Mar 2026 16:32:16 +0100
Subject: [PATCH 3/4] lib/tests/fetch2: add tests for curl method
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260305-add_alt_fetch_method_curl-v1-3-0d0220e5fa59@se.com>
References: <20260305-add_alt_fetch_method_curl-v1-0-0d0220e5fa59@se.com>
In-Reply-To: <20260305-add_alt_fetch_method_curl-v1-0-0d0220e5fa59@se.com>
To: bitbake-devel@lists.openembedded.org
Cc: Pascal Eberhard <pascal.eberhard@se.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772724738; l=5017;
 i=pascal.eberhard@se.com; s=20260304; h=from:subject:message-id;
 bh=UaiA9e2FKgpaMtTOgq8g3apGKeVH2UE6u0BEkf4ti6I=;
 b=LWVdmEF5vO47Le3Uoh4IzaJLH1WRTHoGSglqElCbF3nJZu5CcOm2dc1HMREguk2M39QMjxYpL
 zqEBnEWdtMgB/aK+3J2eAmfqdsS7Iqyc8dmBn5vmgWnWJCyGjodxBco
X-Developer-Key: i=pascal.eberhard@se.com; a=ed25519;
 pk=J7TbFctjt1RVuN5K0juhf/w1E9bAfSeoQ/JG1vV9mWg=
X-Endpoint-Received: by B4 Relay for pascal.eberhard@se.com/20260304 with auth_id=661
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Duplicate wget fetch method test cases to test curl fetch method.

Signed-off-by: Pascal Eberhard <pascal.eberhard@se.com>
---
 lib/bb/tests/fetch.py | 68 +++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 68 insertions(+)

diff --git a/lib/bb/tests/fetch.py b/lib/bb/tests/fetch.py
index 74eb73472..5c587d7b4 100644
--- a/lib/bb/tests/fetch.py
+++ b/lib/bb/tests/fetch.py
@@ -1550,6 +1550,7 @@ class FetchLatestVersionTest(FetcherTest):
 
                     url = "http://127.0.0.1:%s/%s" % (port, data.path)
                     ud = bb.fetch2.FetchData(url, self.d)
+                    self.assertEqual(ud.method.__class__.__name__, "Wget")
                     pupver = ud.method.latest_versionstring(ud, self.d)
                     verstring = pupver[0]
                     self.assertTrue(verstring, msg="Could not find upstream version for %s" % data.pn)
@@ -1558,6 +1559,35 @@ class FetchLatestVersionTest(FetcherTest):
         finally:
             server.stop()
 
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
@@ -1590,6 +1620,7 @@ class FetchCheckStatusTest(FetcherTest):
             with self.subTest(url=u):
                 ud = fetch.ud[u]
                 m = ud.method
+                self.assertEqual(ud.method.__class__.__name__, "Wget")
                 ret = m.checkstatus(fetch, ud, self.d)
                 self.assertTrue(ret, msg="URI %s, can't check status" % (u))
 
@@ -1605,10 +1636,47 @@ class FetchCheckStatusTest(FetcherTest):
             with self.subTest(url=u):
                 ud = fetch.ud[u]
                 m = ud.method
+                self.assertEqual(ud.method.__class__.__name__, "Wget")
+                ret = m.checkstatus(fetch, ud, self.d)
+                self.assertTrue(ret, msg="URI %s, can't check status" % (u))
+
+        connection_cache.close_connections()
+
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

