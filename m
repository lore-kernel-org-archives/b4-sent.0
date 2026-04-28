From: Ackerley Tng <ackerleytng@google.com>
Date: Tue, 28 Apr 2026 16:25:38 -0700
Subject: [PATCH RFC v5 43/53] KVM: selftests: Support checking that data
 not equal expected
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-gmem-inplace-conversion-v5-43-d8608ccfca22@google.com>
References: <20260428-gmem-inplace-conversion-v5-0-d8608ccfca22@google.com>
In-Reply-To: <20260428-gmem-inplace-conversion-v5-0-d8608ccfca22@google.com>
To: aik@amd.com, andrew.jones@linux.dev, binbin.wu@linux.intel.com, 
 brauner@kernel.org, chao.p.peng@linux.intel.com, david@kernel.org, 
 ira.weiny@intel.com, jmattson@google.com, jthoughton@google.com, 
 michael.roth@amd.com, oupton@kernel.org, pankaj.gupta@amd.com, 
 qperret@google.com, rick.p.edgecombe@intel.com, rientjes@google.com, 
 shivankg@amd.com, steven.price@arm.com, tabba@google.com, 
 willy@infradead.org, wyihan@google.com, yan.y.zhao@intel.com, 
 forkloop@google.com, pratyush@kernel.org, suzuki.poulose@arm.com, 
 aneesh.kumar@kernel.org, Paolo Bonzini <pbonzini@redhat.com>, 
 Sean Christopherson <seanjc@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Ingo Molnar <mingo@redhat.com>, Borislav Petkov <bp@alien8.de>, 
 Dave Hansen <dave.hansen@linux.intel.com>, x86@kernel.org, 
 "H. Peter Anvin" <hpa@zytor.com>, Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Shuah Khan <shuah@kernel.org>, Vishal Annapurve <vannapurve@google.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Chris Li <chrisl@kernel.org>, 
 Kairui Song <kasong@tencent.com>, Kemeng Shi <shikemeng@huaweicloud.com>, 
 Nhat Pham <nphamcs@gmail.com>, Baoquan He <bhe@redhat.com>, 
 Barry Song <baohua@kernel.org>, Axel Rasmussen <axelrasmussen@google.com>, 
 Yuanchu Xie <yuanchu@google.com>, Wei Xu <weixugc@google.com>, 
 Youngjun Park <youngjun.park@lge.com>, Qi Zheng <qi.zheng@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Kiryl Shutsemau <kas@kernel.org>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Vlastimil Babka <vbabka@kernel.org>
Cc: kvm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, 
 linux-coco@lists.linux.dev, Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777418714; l=2851;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=7gz8kf/n4ixOaF8MVfsAM6UcG2xye98XFNb81uX9/Q0=;
 b=K0nhoHtw+bHDcFt0NTXB9H8IY5KufQrx9yXWXRDB44IJvZWG6vgqoP88UFkyWNZSvMMA4sjKx
 IeEHazMTIeLBYKybYfkuwhPvhexJMT5hxbaymArE73yb7zsZfD59Xn1
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Expand run_guest_do_rmw() to support checking that data at given pgoff is
not equal to expected_val. This will be used in a later patch that tests
that memory contents are scrambled.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 .../selftests/kvm/x86/guest_memfd_conversions_test.c    | 17 +++++++++++++----
 1 file changed, 13 insertions(+), 4 deletions(-)

diff --git a/tools/testing/selftests/kvm/x86/guest_memfd_conversions_test.c b/tools/testing/selftests/kvm/x86/guest_memfd_conversions_test.c
index 922261ebaff96..57adb6d84a053 100644
--- a/tools/testing/selftests/kvm/x86/guest_memfd_conversions_test.c
+++ b/tools/testing/selftests/kvm/x86/guest_memfd_conversions_test.c
@@ -137,6 +137,7 @@ static void __gmem_conversions_multipage_##test(test_data_t *t, int nr_pages,	\
 struct guest_check_data {
 	void *mem;
 	char expected_val;
+	bool assert_not_equal;
 	char write_val;
 };
 static struct guest_check_data guest_data;
@@ -146,7 +147,13 @@ static void guest_do_rmw(void)
 	for (;;) {
 		char *mem = READ_ONCE(guest_data.mem);
 
-		GUEST_ASSERT_EQ(READ_ONCE(*mem), READ_ONCE(guest_data.expected_val));
+		if (READ_ONCE(guest_data.assert_not_equal)) {
+			GUEST_ASSERT_NE(READ_ONCE(*mem),
+					READ_ONCE(guest_data.expected_val));
+		} else {
+			GUEST_ASSERT_EQ(READ_ONCE(*mem),
+					READ_ONCE(guest_data.expected_val));
+		}
 		WRITE_ONCE(*mem, READ_ONCE(guest_data.write_val));
 
 		GUEST_SYNC(0);
@@ -154,13 +161,15 @@ static void guest_do_rmw(void)
 }
 
 static void run_guest_do_rmw(struct kvm_vcpu *vcpu, loff_t pgoff,
-			     char expected_val, char write_val)
+			     char expected_val, char write_val,
+			     bool assert_not_equal)
 {
 	struct ucall uc;
 	int r;
 
 	guest_data.mem = (void *)GUEST_MEMFD_SHARING_TEST_GVA + pgoff * page_size;
 	guest_data.expected_val = expected_val;
+	guest_data.assert_not_equal = assert_not_equal;
 	guest_data.write_val = write_val;
 	sync_global_to_guest(vcpu->vm, guest_data);
 
@@ -191,7 +200,7 @@ static void test_private(test_data_t *t, loff_t pgoff, char starting_val,
 			 char write_val)
 {
 	TEST_EXPECT_SIGBUS(WRITE_ONCE(t->mem[pgoff * page_size], write_val));
-	run_guest_do_rmw(t->vcpu, pgoff, starting_val, write_val);
+	run_guest_do_rmw(t->vcpu, pgoff, starting_val, write_val, false);
 	TEST_EXPECT_SIGBUS(READ_ONCE(t->mem[pgoff * page_size]));
 }
 
@@ -207,7 +216,7 @@ static void test_shared(test_data_t *t, loff_t pgoff, char starting_val,
 			char host_write_val, char write_val)
 {
 	host_do_rmw(t->mem, pgoff, starting_val, host_write_val);
-	run_guest_do_rmw(t->vcpu, pgoff, host_write_val, write_val);
+	run_guest_do_rmw(t->vcpu, pgoff, host_write_val, write_val, false);
 	TEST_ASSERT_EQ(READ_ONCE(t->mem[pgoff * page_size]), write_val);
 }
 

-- 
2.54.0.545.g6539524ca2-goog

