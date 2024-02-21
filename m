From: Itaru Kitayama <itaru.kitayama@linux.dev>
Date: Thu, 22 Feb 2024 08:38:37 +0900
Subject: [PATCH] Build guest_memfd_test also on arm64.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240222-memfd-v1-1-7d39680286f1@linux.dev>
X-B4-Tracking: v=1; b=H4sIAHyJ1mUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDIyMj3dzU3LQUXXMjC9M0S1Mzk2TDVCWg2oKi1LTMCrA50bG1tQD+NlG
 VVwAAAA==
To: Paolo Bonzini <pbonzini@redhat.com>, Shuah Khan <shuah@kernel.org>
Cc: kvm@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Itaru Kitayama <itaru.kitayama@fujitsu.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708558724; l=1061;
 i=itaru.kitayama@linux.dev; s=20231030; h=from:subject:message-id;
 bh=lA7PzCZQ2lseoAA2i+RxO+8QEPr2soICHGzThVxFsV4=;
 b=5n1duozIxzxnBCXUW296kFTXX6lgv5V+XSAWRZRDLr6XvGcTjdyoHjOFdcVTWctswvlhZ8LNu
 L084E6chHO/Dr2DVGeC4UFBmQ/xSZcvmsNde3tZ3UnwmBdJOh/g0p/q
X-Developer-Key: i=itaru.kitayama@linux.dev; a=ed25519;
 pk=4yYhz2CbKL7F2qR5IzP7QvqM9B6c+dfWJRHWez+rMDw=
X-Endpoint-Received: by B4 Relay for itaru.kitayama@linux.dev/20231030 with auth_id=92
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>



---
on arm64 KVM_CAP_GUEST_MEMDF capability is not enabled, but
guest_memfd_test can build on arm64, let's build it on arm64 as well.

Signed-off-by: Itaru Kitayama <itaru.kitayama@fujitsu.com>
---
 tools/testing/selftests/kvm/Makefile | 1 +
 1 file changed, 1 insertion(+)

diff --git a/tools/testing/selftests/kvm/Makefile b/tools/testing/selftests/kvm/Makefile
index 492e937fab00..8a4f8afb81ca 100644
--- a/tools/testing/selftests/kvm/Makefile
+++ b/tools/testing/selftests/kvm/Makefile
@@ -158,6 +158,7 @@ TEST_GEN_PROGS_aarch64 += access_tracking_perf_test
 TEST_GEN_PROGS_aarch64 += demand_paging_test
 TEST_GEN_PROGS_aarch64 += dirty_log_test
 TEST_GEN_PROGS_aarch64 += dirty_log_perf_test
+TEST_GEN_PROGS_aarch64 += guest_memfd_test
 TEST_GEN_PROGS_aarch64 += guest_print_test
 TEST_GEN_PROGS_aarch64 += get-reg-list
 TEST_GEN_PROGS_aarch64 += kvm_create_max_vcpus

---
base-commit: 39133352cbed6626956d38ed72012f49b0421e7b
change-id: 20240222-memfd-7285f9564c1e

Best regards,
-- 
Itaru Kitayama <itaru.kitayama@linux.dev>

