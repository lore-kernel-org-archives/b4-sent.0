From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Thu, 17 Aug 2023 11:21:53 -0500
Subject: [PATCH 2/2] selftests/powerpc: add const qualification where
 possible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230817-powerpc-selftest-misc-v1-2-a84cc1ef78b2@linux.ibm.com>
References: <20230817-powerpc-selftest-misc-v1-0-a84cc1ef78b2@linux.ibm.com>
In-Reply-To: <20230817-powerpc-selftest-misc-v1-0-a84cc1ef78b2@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>
Cc: linuxppc-dev@lists.ozlabs.org, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1692289329; l=3437;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=cXmcYeJu/th0ypEBfTe/UbVon+xU8aryVUO4EdX1T54=;
 b=NAesJg3dtI9CrKNCcAOSr08g64hAHFOZ9K8mA/rEkuYfx7frMDT6tvhZPORJHhwV8ildyhEK9
 W996PvVj3fcC/PjtuYlj730F7uftSuOuyIzt5R1wAxcmYV0pBj0o114
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Various char * parameters in the common powerpc selftest APIs can be
const.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 tools/testing/selftests/powerpc/harness.c         |  4 ++--
 tools/testing/selftests/powerpc/include/subunit.h | 16 ++++++++--------
 tools/testing/selftests/powerpc/include/utils.h   |  2 +-
 3 files changed, 11 insertions(+), 11 deletions(-)

diff --git a/tools/testing/selftests/powerpc/harness.c b/tools/testing/selftests/powerpc/harness.c
index 0ad4f12b3d43..5876220d8ff2 100644
--- a/tools/testing/selftests/powerpc/harness.c
+++ b/tools/testing/selftests/powerpc/harness.c
@@ -24,7 +24,7 @@
 /* Setting timeout to -1 disables the alarm */
 static uint64_t timeout = 120;
 
-int run_test(int (test_function)(void), char *name)
+int run_test(int (test_function)(void), const char *name)
 {
 	bool terminated;
 	int rc, status;
@@ -101,7 +101,7 @@ void test_harness_set_timeout(uint64_t time)
 	timeout = time;
 }
 
-int test_harness(int (test_function)(void), char *name)
+int test_harness(int (test_function)(void), const char *name)
 {
 	int rc;
 
diff --git a/tools/testing/selftests/powerpc/include/subunit.h b/tools/testing/selftests/powerpc/include/subunit.h
index 068d55fdf80f..b0bb774617c9 100644
--- a/tools/testing/selftests/powerpc/include/subunit.h
+++ b/tools/testing/selftests/powerpc/include/subunit.h
@@ -6,37 +6,37 @@
 #ifndef _SELFTESTS_POWERPC_SUBUNIT_H
 #define _SELFTESTS_POWERPC_SUBUNIT_H
 
-static inline void test_start(char *name)
+static inline void test_start(const char *name)
 {
 	printf("test: %s\n", name);
 }
 
-static inline void test_failure_detail(char *name, char *detail)
+static inline void test_failure_detail(const char *name, const char *detail)
 {
 	printf("failure: %s [%s]\n", name, detail);
 }
 
-static inline void test_failure(char *name)
+static inline void test_failure(const char *name)
 {
 	printf("failure: %s\n", name);
 }
 
-static inline void test_error(char *name)
+static inline void test_error(const char *name)
 {
 	printf("error: %s\n", name);
 }
 
-static inline void test_skip(char *name)
+static inline void test_skip(const char *name)
 {
 	printf("skip: %s\n", name);
 }
 
-static inline void test_success(char *name)
+static inline void test_success(const char *name)
 {
 	printf("success: %s\n", name);
 }
 
-static inline void test_finish(char *name, int status)
+static inline void test_finish(const char *name, int status)
 {
 	if (status)
 		test_failure(name);
@@ -44,7 +44,7 @@ static inline void test_finish(char *name, int status)
 		test_success(name);
 }
 
-static inline void test_set_git_version(char *value)
+static inline void test_set_git_version(const char *value)
 {
 	printf("tags: git_version:%s\n", value);
 }
diff --git a/tools/testing/selftests/powerpc/include/utils.h b/tools/testing/selftests/powerpc/include/utils.h
index 36c30c611457..66d7b2368dd4 100644
--- a/tools/testing/selftests/powerpc/include/utils.h
+++ b/tools/testing/selftests/powerpc/include/utils.h
@@ -32,7 +32,7 @@ typedef uint16_t u16;
 typedef uint8_t u8;
 
 void test_harness_set_timeout(uint64_t time);
-int test_harness(int (test_function)(void), char *name);
+int test_harness(int (test_function)(void), const char *name);
 
 int read_auxv(char *buf, ssize_t buf_size);
 void *find_auxv_entry(int type, char *auxv);

-- 
2.41.0

