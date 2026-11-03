From: Dmitry Safonov <dima@arista.com>
Date: Tue, 03 Nov 2026 16:55:21 +0000
Subject: [PATCH] perf build: Override OUTPUT when building internal
 libraries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-perf-output-v1-1-df33a0368cf2@arista.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMywrCMBBFf6XM2oEm0vj4FXGRx9RGMA0ziQil/
 26iy3O552wgxJEErsMGTO8ocU0N1GEAv9j0IIyhMehRG6XGI2biGddaci04nYO5mCnokzbQjMw
 0x8+vdrv/Wap7ki890R/OCqFjm/zSp5eVQgz7/gX7J+4KiAAAAA==
X-Change-ID: 20261103-perf-output-58d6965d2726
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>
Cc: Arnaldo Carvalho de Melo <acme@redhat.com>, 
 linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Safonov <0x7f454c46@gmail.com>, 
 Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793724934; l=2896;
 i=dima@arista.com; s=20250521; h=from:subject:message-id;
 bh=l8SCNpqTNyh3+owYKih6JxRjJiWS4WDYwh5MD7aaoHE=;
 b=IXevTkU5SJ4FxscC8KtUUltaxTyySoo3Kc97o5EFCSGat23lGvJqtzK/0hiUbmodEAgN3oPbN
 ch/1qQDcdyaDqlwAZspbMw5slSBH+Vur9UuhUqTyE86e6uEK5rpUcHG
X-Developer-Key: i=dima@arista.com; a=ed25519;
 pk=/z94x2T59rICwjRqYvDsBe0MkpbkkdYrSW2J1G2gIcU=
X-Endpoint-Received: by B4 Relay for dima@arista.com/20250521 with auth_id=405
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After commit 1572ba36fbca ("perf tests: Improvements to build-test
performance"), building perf with OUTPUT on the command line fails:
  make -C tools/perf OUTPUT=/tmp/linux/bld/perf/ ARCH=x86_64 LC_ALL=C CC=gcc HOSTCC=gcc LD=ld
  ...
  make[3]: *** No rule to make target '/tmp/linux/perf/libsubcmd/libsubcmd.a'.  Stop.

MAKEFLAGS propagates the command-line OUTPUT assignment to recursive makes.
The library builds pass their output directories through $O, but the assignment
to $OUTPUT in tools/scripts/Makefile.include cannot replace a command-line
argument. This affects libapi, libperf, libsubcmd and libsymbol.

With "unexport MAKEFLAGS" returned and added $(info) debug in libsubcmd
Makefile produces:
  OUTPUT = /tmp/linux/perf/libsubcmd/
Without it, on current master it prints:
  OUTPUT = /tmp/linux/perf/

Pass OUTPUT explicitly to each library build, including the trailing slash
required when constructing file names. This follows the existing libbpf
build rule and preserves MAKEFLAGS and jobserver propagation.

Fixes: 1572ba36fbca ("perf tests: Improvements to build-test performance")
Signed-off-by: Dmitry Safonov <dima@arista.com>
---
 tools/perf/Makefile.perf | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/tools/perf/Makefile.perf b/tools/perf/Makefile.perf
index b74b534e1153..4cc5bb3011da 100644
--- a/tools/perf/Makefile.perf
+++ b/tools/perf/Makefile.perf
@@ -798,7 +798,7 @@ $(patsubst perf-%,%.o,$(PROGRAMS)): $(wildcard */*.h)
 
 $(LIBAPI): FORCE | $(LIBAPI_OUTPUT)
 	$(Q)$(MAKE) -C $(LIBAPI_DIR) O=$(LIBAPI_OUTPUT) \
-		DESTDIR=$(LIBAPI_DESTDIR) prefix= subdir= \
+		OUTPUT=$(LIBAPI_OUTPUT)/ DESTDIR=$(LIBAPI_DESTDIR) prefix= subdir= \
 		$@ install_headers
 
 $(LIBAPI)-clean:
@@ -816,7 +816,7 @@ $(LIBBPF)-clean:
 
 $(LIBPERF): FORCE | $(LIBPERF_OUTPUT)
 	$(Q)$(MAKE) -C $(LIBPERF_DIR) O=$(LIBPERF_OUTPUT) \
-		DESTDIR=$(LIBPERF_DESTDIR) prefix= subdir= \
+		OUTPUT=$(LIBPERF_OUTPUT)/ DESTDIR=$(LIBPERF_DESTDIR) prefix= subdir= \
 		$@ install_headers
 
 $(LIBPERF)-clean:
@@ -825,7 +825,7 @@ $(LIBPERF)-clean:
 
 $(LIBSUBCMD): FORCE | $(LIBSUBCMD_OUTPUT)
 	$(Q)$(MAKE) -C $(LIBSUBCMD_DIR) O=$(LIBSUBCMD_OUTPUT) \
-		DESTDIR=$(LIBSUBCMD_DESTDIR) prefix= subdir= \
+		OUTPUT=$(LIBSUBCMD_OUTPUT)/ DESTDIR=$(LIBSUBCMD_DESTDIR) prefix= subdir= \
 		$@ install_headers
 
 $(LIBSUBCMD)-clean:
@@ -834,7 +834,7 @@ $(LIBSUBCMD)-clean:
 
 $(LIBSYMBOL): FORCE | $(LIBSYMBOL_OUTPUT)
 	$(Q)$(MAKE) -C $(LIBSYMBOL_DIR) O=$(LIBSYMBOL_OUTPUT) \
-		DESTDIR=$(LIBSYMBOL_DESTDIR) prefix= subdir= \
+		OUTPUT=$(LIBSYMBOL_OUTPUT)/ DESTDIR=$(LIBSYMBOL_DESTDIR) prefix= subdir= \
 		$@ install_headers
 
 $(LIBSYMBOL)-clean:

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261103-perf-output-58d6965d2726

Best regards,
--  
Dmitry Safonov <dima@arista.com>

