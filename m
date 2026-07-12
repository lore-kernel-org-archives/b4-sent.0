From: Miles Krause <mileskrause5200@gmail.com>
Date: Sat, 11 Jul 2026 22:47:12 -0400
Subject: [PATCH] selftests/futex: Give circular-list nodes static storage
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260711-futex-robust-list-static-nodes-v1-1-723754d75cf5@gmail.com>
X-B4-Tracking: v=1; b=H4sIAC8AU2oC/yWN0QrCMAxFf2Xk2UA71Km/Invo2kwj0kqTymDs3
 436cuHA5ZwVhCqTwKVbodKbhUs28LsO4j3kGyEnY+hdf3SD9zg3pQVrmZooPtlGNChHzCWR4OD
 2p2S/c3AHMMmr0szLL3Ad/yxtelDUrxW27QM1Z93EggAAAA==
X-Change-ID: 20260711-futex-robust-list-static-nodes-7048d7119a05
To: Thomas Gleixner <tglx@kernel.org>, Ingo Molnar <mingo@redhat.com>, 
 Peter Zijlstra <peterz@infradead.org>, Darren Hart <dvhart@infradead.org>, 
 Davidlohr Bueso <dave@stgolabs.net>, 
 =?utf-8?q?Andr=C3=A9_Almeida?= <andrealmeid@igalia.com>, 
 Shuah Khan <shuah@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 Miles Krause <mileskrause5200@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783824432; l=1518;
 i=mileskrause5200@gmail.com; s=20260710; h=from:subject:message-id;
 bh=08Ia/Sl+qT3Kah/g1jX/YTW/yGaP4wipGXelK9b9UyI=;
 b=W2Kn/c7e1+v/z2sVd7S9lCOi60U7HWm6XdWHZtL6PB5obvihJuqE99467wAdqOTAfQXNdBVZO
 95s36WHxA6+DOnaERgo5LedR5rnvi5krTmsk1Fwv9ZLSAxDK94RMoN4
X-Developer-Key: i=mileskrause5200@gmail.com; a=ed25519;
 pk=QNhNjcQarqig3ColJBIEr3DYfWM1PHpP7z+6thxWXaU=
X-Endpoint-Received: by B4 Relay for mileskrause5200@gmail.com/20260710 with auth_id=861
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The registered robust-list head has static storage but points at three
automatic lock nodes. GCC warns about storing the address of a local
variable in the static head when building the selftest with -Wall.

Give the nodes static storage as well. This keeps every object in the
circular list alive through child exit without changing the list topology.

Signed-off-by: Miles Krause <mileskrause5200@gmail.com>
---
Built with:

  make -C tools/testing/selftests/futex/functional clean
  make -C tools/testing/selftests/futex/functional robust_list

Tested with:

  tools/testing/selftests/futex/functional/robust_list -t test_circular_list
---
 tools/testing/selftests/futex/functional/robust_list.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/tools/testing/selftests/futex/functional/robust_list.c b/tools/testing/selftests/futex/functional/robust_list.c
index b3fab60181d5..2300253a7e35 100644
--- a/tools/testing/selftests/futex/functional/robust_list.c
+++ b/tools/testing/selftests/futex/functional/robust_list.c
@@ -523,7 +523,7 @@ TEST(test_robust_list_multiple_elements)
 static int child_circular_list(void *arg)
 {
 	static struct robust_list_head head;
-	struct lock_struct a, b, c;
+	static struct lock_struct a, b, c;
 	int ret;
 
 	ret = set_list(&head);

---
base-commit: 051f5d223dfc1806e216f60e4b29c1bf35f5c2d3
change-id: 20260711-futex-robust-list-static-nodes-7048d7119a05

Best regards,
--  
Miles Krause <mileskrause5200@gmail.com>

