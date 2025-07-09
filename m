From: Vincent Whitchurch <vincent.whitchurch@datadoghq.com>
Date: Wed, 09 Jul 2025 14:47:59 +0200
Subject: [PATCH bpf-next v3 3/5] selftests/bpf: sockmap: Exit with error on
 failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250709-sockmap-splice-v3-3-b23f345a67fc@datadoghq.com>
References: <20250709-sockmap-splice-v3-0-b23f345a67fc@datadoghq.com>
In-Reply-To: <20250709-sockmap-splice-v3-0-b23f345a67fc@datadoghq.com>
To: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Sitnicki <jakub@cloudflare.com>
Cc: Kuniyuki Iwashima <kuniyu@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 netdev@vger.kernel.org, bpf@vger.kernel.org, 
 Vincent Whitchurch <vincent.whitchurch@datadoghq.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752065284; l=739;
 i=vincent.whitchurch@datadoghq.com; s=20240606; h=from:subject:message-id;
 bh=zvCxjLCWikXEcOPolUq/9Ge5sJ6PAHHwLBy0hdL4r6w=;
 b=ijVwXxlM0T4A/BbKbsyrkoIzpmHoxHafn0SUi/TfWttOHwJBkxXHr2FCXmqpv74F2UWjePEgk
 C+5DkA+sGqoDR1/X4kvPqLsS932lNm40/doE/wpWnYbMd+MBSrrIhgs
X-Developer-Key: i=vincent.whitchurch@datadoghq.com; a=ed25519;
 pk=GwUiPK96WuxbUAD4UjapyK7TOt+aX0EqABOZ/BOj+/M=
X-Endpoint-Received: by B4 Relay for vincent.whitchurch@datadoghq.com/20240606 with auth_id=170
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If any tests failed, exit the program with a non-zero
error code.

Signed-off-by: Vincent Whitchurch <vincent.whitchurch@datadoghq.com>
---
 tools/testing/selftests/bpf/test_sockmap.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/tools/testing/selftests/bpf/test_sockmap.c b/tools/testing/selftests/bpf/test_sockmap.c
index fd2da2234cc9..cf1c36ed32c1 100644
--- a/tools/testing/selftests/bpf/test_sockmap.c
+++ b/tools/testing/selftests/bpf/test_sockmap.c
@@ -2238,7 +2238,9 @@ int main(int argc, char **argv)
 	close(cg_fd);
 	if (cg_created)
 		cleanup_cgroup_environment();
-	return err;
+	if (err)
+		return err;
+	return failed ? 1 : 0;
 }
 
 void running_handler(int a)

-- 
2.34.1

